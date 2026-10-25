# Lógica del recorrido: un moco por jugador, cronómetro, puntos de control, caída al vacío,
# meta y reinicio. Las áreas solo las decide el anfitrión.
extends Node2D

const ESCENA_JUGADOR := preload("res://scenes/jugador.tscn")
const CAMARA := preload("res://scripts/camara.gd")
const BURBUJA := preload("res://scripts/burbuja.gd")
const ARO := preload("res://scripts/aro.gd")
const FONDO := preload("res://scripts/fondo.gd")
const ESPERA_TRAS_PRIMERO := 20.0  # segundos que tienen los demás tras llegar el primero
const SEGUNDOS_RESULTADOS := 5.0
const SEGUNDOS_POSTAL := 2.5  # la postal de "RONDA N" con los mocos quietos
const SEGUNDOS_FINAL := 8.0  # el ganador del torneo antes de volver a la sala

var ronda := 1  # en todos los PCs
var semilla_actual := 0
var tema := "azotea"  # el mapa de esta ronda (Temas): paleta, fondo y si hay aros
var nombres := {}  # id -> "JUGADOR N", fijo desde que sale su moco
var llegados: Array[int] = []  # quién ha cruzado la meta esta ronda, en todos los PCs
var espectadores: Array[int] = []  # llegaron y se cayeron: miran hasta el final de la ronda
var marcador_filas := []  # [[id, victorias, segundos totales], ...] ya ordenado; lo manda el anfitrión
var camara_espectador: Camera2D = null
var objetivo_espectador := 0  # a quién mira; uno más que los que juegan = el mapa entero
var tiempo := 0.0
var mejor := INF
var corriendo := true
var ultimos_controles := {}  # id de jugador -> último punto de control
var clasificacion := Clasificacion.new()  # solo la usa el anfitrión
var desde_primero := -1.0  # segundos desde que llegó el primero; -1 = nadie aún
var en_resultados := false
var colores := {}  # id -> color de su moco, en todos los PCs
var cuenta := -1.0  # segundos que quedan tras llegar el primero (en todos los PCs)
var piezas := Node2D.new()  # techos, descansos y obstáculos generados

@onready var hud := $HUD


func _ready() -> void:
	Musica.tocar("carrera")
	$Spawner.spawn_function = crear_jugador
	if multiplayer.is_server():
		var ids: Array[int] = [1]  # sin red: solo el jugador local
		if Red.es_online():
			ids = Red.ids
		for i in ids.size():
			$Spawner.spawn([ids[i], i])
		Red.jugadores_cambiaron.connect(_quitar_desconectados)
	$Caida.body_entered.connect(_al_caer)
	$Meta.body_entered.connect(_al_llegar)
	_estilo_acuarela($Meta/Bandera, 99, Acuarela.CIRUELA)  # ningún moco es ciruela: se lee como meta
	piezas.name = "Piezas"
	add_child(piezas)
	move_child(piezas, $Jugadores.get_index())  # detrás de los mocos
	construir(Red.semilla)
	hud.get_node("Menu").pressed.connect(volver_al_menu)
	var pausa := Node.new()  # mismo nombre en todos los PCs: así le llegan los rpc
	pausa.name = "Pausa"
	pausa.set_script(preload("res://scripts/pausa.gd"))
	add_child(pausa)
	reiniciar()


# Monta el mapa de esta semilla. Todos los PCs lo llaman con la misma, así es idéntico.
func construir(semilla: int) -> void:
	for viejo in piezas.get_children() + $Controles.get_children():
		viejo.get_parent().remove_child(viejo)
		viejo.queue_free()
	semilla_actual = semilla
	tema = Temas.de_ronda(Red.config.mapas, Red.semilla, ronda)
	var mapa := Generador.generar(semilla)
	for i in mapa.piezas.size():
		var p: Dictionary = mapa.piezas[i]
		var cuerpo := StaticBody2D.new()
		cuerpo.name = p.nombre
		cuerpo.position = p.pos
		if p.enganchable:
			cuerpo.add_to_group("enganchable")
		var forma := CollisionPolygon2D.new()
		forma.polygon = p.poly
		var dibujo := Polygon2D.new()
		dibujo.name = "Dibujo"
		dibujo.polygon = p.poly
		cuerpo.add_child(forma)
		cuerpo.add_child(dibujo)
		piezas.add_child(cuerpo)
		_estilo_acuarela(dibujo, semilla + i)
	for pos: Vector2 in mapa.controles:
		var control := Area2D.new()
		control.position = pos
		control.collision_mask = 3
		var caja := CollisionShape2D.new()
		caja.shape = RectangleShape2D.new()
		caja.shape.size = Vector2(220, 120)
		control.add_child(caja)
		control.body_entered.connect(_al_pasar_control.bind(control))
		$Controles.add_child(control)
	if Red.config.poderes:
		for i in mapa.burbujas.size():
			var b := Area2D.new()
			b.set_script(BURBUJA)
			b.name = "Burbuja%d" % i
			b.position = mapa.burbujas[i].pos
			b.set("tipo", mapa.burbujas[i].tipo)  # set(): Area2D no sabe que el script tiene `tipo`
			b.body_entered.connect(_al_tocar_burbuja.bind(b))
			piezas.add_child(b)  # con las piezas: se borran solas al cambiar de mapa
	if Red.config.aros and Temas.DATOS[tema].aros:
		for i in mapa.aros.size():
			var a := Area2D.new()
			a.set_script(ARO)
			a.name = "Aro%d" % i
			a.position = mapa.aros[i].pos
			a.set("mov", mapa.aros[i].mov)
			a.body_entered.connect(_al_tocar_aro.bind(a))
			piezas.add_child(a)
	$Meta.position = mapa.meta
	$Caida.position.x = mapa.caida_x
	$Caida/Forma.shape.size.x = mapa.caida_ancho
	_pintar_tema(mapa.meta.x)


# Cielo, siluetas del fondo, lo que se mueve y el suelo de salida con los colores del tema.
func _pintar_tema(fin_x: float) -> void:
	var d: Dictionary = Temas.DATOS[tema]
	var cielo: ShaderMaterial = $Ciudad/Cielo/Pintura.material
	for k in 3:
		var c: Color = d.cielo[k]
		cielo.set_shader_parameter(["arriba", "medio", "abajo"][k], Vector3(c.r, c.g, c.b))
	cielo.set_shader_parameter("luna", 1.0 if d.luna else 0.0)
	hud.oscuro(d.cielo[1].get_luminance() < 0.5)
	for capa in ["Lejos", "Cerca"]:
		var edificios := get_node("Ciudad/%s/Edificios" % capa)
		edificios.visible = d.fondo == "ciudad"
		edificios.set("color_edificio", d[capa.to_lower()])
		edificios.set("color_ventana", d.ventanas)
		edificios.set("guirnaldas", tema == "noche" and capa == "Cerca")
		edificios.queue_redraw()
		_poner_fondo(get_node("Ciudad/" + capa), capa.to_lower(), fin_x)
	if d.superficie != "":
		_poner_fondo(self, "superficie", fin_x).z_index = 5  # delante de los mocos: el que cae se hunde
	else:
		_poner_fondo(self, "", fin_x)  # solo quita la del mapa anterior
	var suelo: Polygon2D = $SueloInicio/Dibujo
	for viejo in suelo.get_children():
		viejo.free()
	_estilo_acuarela(suelo, 0)


func _poner_fondo(padre: Node, capa: String, fin_x: float) -> Node2D:
	var nombre := "Superficie" if padre == self else "Fondo"
	var viejo := padre.get_node_or_null(nombre)
	if viejo != null:
		padre.remove_child(viejo)
		viejo.queue_free()
	if capa == "":
		return null
	var fondo := Node2D.new()
	fondo.set_script(FONDO)
	fondo.name = nombre
	fondo.set("tema", tema)
	fondo.set("capa", capa)
	fondo.set("hasta_x", fin_x + 2000.0)
	padre.add_child(fondo)
	return fondo


# Cada forma se pinta como mancha de acuarela, sin contorno: techos enganchables en rosa
# o lavanda, azoteas en lavanda oscuro. Solo cambia el dibujo; la colisión sigue siendo exacta.
func _estilo_acuarela(dibujo: Polygon2D, i: int, forzado := Color.TRANSPARENT) -> void:
	var color := Acuarela.MENTA if forzado == Color.TRANSPARENT else forzado
	if dibujo.get_parent().is_in_group("enganchable"):
		color = Acuarela.ROSA if i % 2 == 0 else Acuarela.LAVANDA
	elif dibujo.get_parent() is StaticBody2D:
		color = Temas.DATOS[tema].suelo
	# Base opaca: lo que se puede tocar no deja ver el fondo, así se lee como sólido.
	var base := Polygon2D.new()
	base.polygon = Tinta.irregular(dibujo.polygon, i, 2.0, 30.0)
	base.color = color.lightened(0.35)
	dibujo.add_child(base)
	for capa in Acuarela.capas(dibujo.polygon, i):
		var mancha := Polygon2D.new()
		mancha.polygon = capa
		mancha.color = Color(color, Acuarela.OPACIDAD_CAPA)
		dibujo.add_child(mancha)
	dibujo.color = Color.TRANSPARENT


func _physics_process(delta: float) -> void:
	if corriendo:
		tiempo += delta
	hud.mostrar(tiempo, mejor, not Red.es_online())
	if cuenta >= 0.0:
		cuenta = maxf(cuenta - delta, 0.0)
	hud.cuenta_atras(cuenta if not en_resultados else -1.0)
	var mio := jugador_local()
	if mio != null and mio.papel_activo:
		hud.ocultar_ayuda()  # ya sabe lanzar el papel
	if mio != null:
		hud.poder(mio.poder, mio.poder_restante, Poderes.DURACION.get(mio.poder, 1.0))
	if desde_primero >= 0.0 and not en_resultados and multiplayer.is_server():
		desde_primero += delta
		if clasificacion.todos_llegaron(Red.ids) or desde_primero >= ESPERA_TRAS_PRIMERO:
			_terminar_ronda()


func _process(_delta: float) -> void:
	if camara_espectador == null:
		return
	var jugando := _jugando()
	objetivo_espectador = objetivo_espectador % (jugando.size() + 1)
	if objetivo_espectador < jugando.size():
		camara_espectador.global_position = jugando[objetivo_espectador].global_position
		camara_espectador.zoom = Vector2(0.85, 0.85)
	else:  # el mapa entero, de la salida a la meta
		var ancho: float = $Meta.position.x + 600.0
		camara_espectador.global_position = Vector2(ancho / 2.0 - 300.0, 400.0)
		var z: float = get_viewport_rect().size.x / ancho
		camara_espectador.zoom = Vector2(z, z)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("volver_menu"):
		volver_al_menu()
	if evento.is_action_pressed("reiniciar") and not Red.es_online():  # online manda la ronda
		reiniciar()
	if Red.es_online() and not en_resultados:  # Tab: el marcador mientras se mantiene
		if evento.is_action_pressed("marcador"):
			hud.marcador(_filas_vista())
		elif evento.is_action_released("marcador"):
			hud.limpiar_tabla()
	if camara_espectador != null and evento.is_action_pressed("lanzar"):
		objetivo_espectador += 1  # clic: el siguiente que juega y, tras el último, el mapa


# Mocos que siguen en carrera; si ya llegaron todos, los que quedan visibles.
func _jugando() -> Array[Jugador]:
	var visibles := jugadores().filter(func(j: Jugador) -> bool: return not j.id_dueno() in espectadores)
	var sin_llegar := visibles.filter(func(j: Jugador) -> bool: return not j.id_dueno() in llegados)
	var lista: Array[Jugador] = []
	lista.assign(sin_llegar if not sin_llegar.is_empty() else visibles)
	return lista


func nombre(id: int) -> String:
	return "TÚ" if id == multiplayer.get_unique_id() else nombres.get(id, "JUGADOR")


# El marcador listo para pintar: [color, nombre, victorias, segundos].
func _filas_vista() -> Array:
	if marcador_filas.is_empty():  # primera ronda: todos a cero
		return jugadores().map(func(j: Jugador) -> Array: return [colores[j.id_dueno()], nombre(j.id_dueno()), 0, 0.0])
	return marcador_filas.map(func(f: Array) -> Array: return [colores.get(f[0], Acuarela.CIRUELA), nombre(f[0]), f[1], f[2]])


# El MultiplayerSpawner llama a esto en todos los PCs con los mismos datos: [id, índice].
func crear_jugador(datos: Array) -> Node:
	var id: int = datos[0]
	var indice: int = datos[1]
	var j: Jugador = ESCENA_JUGADOR.instantiate()
	j.name = str(id)
	j.position = $Inicio.global_position + Vector2(indice * 90, 0)
	j.pintar(Jugador.COLORES[indice % Jugador.COLORES.size()])
	colores[id] = j.get_node("Visual/Moco").color
	nombres[id] = "JUGADOR %d" % (indice + 1)  # el mismo que en la sala
	if id == multiplayer.get_unique_id():  # cada PC sigue con la cámara solo a su moco
		var camara := Camera2D.new()
		camara.set_script(CAMARA)
		camara.zoom = Vector2(0.85, 0.85)
		camara.position_smoothing_enabled = true
		j.add_child(camara)
	return j


func jugadores() -> Array[Jugador]:
	var lista: Array[Jugador] = []
	for j in $Jugadores.get_children():
		lista.append(j)
	return lista


func jugador_local() -> Jugador:
	return $Jugadores.get_node_or_null(str(multiplayer.get_unique_id()))


func _quitar_desconectados() -> void:
	for j in jugadores():
		if not j.id_dueno() in Red.ids:
			j.queue_free()  # el Spawner lo borra también en los demás PCs


func reiniciar() -> void:
	tiempo = 0.0
	corriendo = true
	desde_primero = -1.0
	en_resultados = false
	cuenta = -1.0
	ultimos_controles.clear()
	llegados.clear()
	espectadores.clear()
	hud.limpiar()
	_dejar_de_mirar()
	for j in jugadores():
		j.visible = true
	if multiplayer.is_server():
		var lista := jugadores()
		for i in lista.size():
			lista[i].reaparecer($Inicio.global_position + Vector2(i * 90, 0))  # en fila, no apilados
			lista[i].poder = ""  # cada ronda se empieza sin poderes
	if Red.es_online():
		_postal()


# "RONDA N DE M" con los mocos quietos y el reloj parado; luego, a correr.
func _postal() -> void:
	corriendo = false
	_congelar(true)
	var victorias := _filas_vista().map(func(f: Array) -> Array: return [f[0], f[2]])
	hud.postal("RONDA %d DE %d · %s" % [ronda, Red.config.rondas, Temas.DATOS[tema].nombre], semilla_actual, victorias, tema)
	var esta_ronda := ronda
	await get_tree().create_timer(SEGUNDOS_POSTAL).timeout
	if not is_inside_tree() or ronda != esta_ronda:
		return
	hud.ocultar_postal()
	_congelar(false)
	corriendo = true


func _congelar(si: bool) -> void:
	if multiplayer.is_server():
		for j in jugadores():
			j.congelado = si


# El anfitrión decide quién la coge; todos la quitan a la vez.
func _al_tocar_burbuja(cuerpo: Node2D, burbuja: Area2D) -> void:
	if not (cuerpo is Jugador and multiplayer.is_server()) or not burbuja.visible:
		return
	(cuerpo as Jugador).dar_poder(burbuja.get("tipo"))
	cuerpo.efecto.rpc("poder", burbuja.global_position)
	burbuja_cogida.rpc(burbuja.name)


# Aro de fuego: lo decide el anfitrión, como todo lo que toca a los mocos.
func _al_tocar_aro(cuerpo: Node2D, aro: Area2D) -> void:
	if cuerpo is Jugador and multiplayer.is_server() and not cuerpo.congelado:
		(cuerpo as Jugador).quemarse(aro.global_position)


@rpc("authority", "call_local", "reliable")
func burbuja_cogida(nombre_burbuja: String) -> void:
	var b := piezas.get_node_or_null(nombre_burbuja)
	if b != null:
		b.recogida()


func _al_pasar_control(cuerpo: Node2D, control: Area2D) -> void:
	if cuerpo is Jugador and multiplayer.is_server():
		ultimos_controles[cuerpo.name] = control.global_position


func _al_caer(cuerpo: Node2D) -> void:
	if not (cuerpo is Jugador and multiplayer.is_server()):
		return
	if Red.es_online() and cuerpo.id_dueno() in clasificacion.llegadas:  # ya llegó: a mirar
		(cuerpo as Jugador).congelado = true
		cuerpo.reaparecer.call_deferred(Vector2($Meta.position.x, -4000.0))  # fuera de en medio
		espectador.rpc(cuerpo.id_dueno())
		return
	var punto: Vector2 = ultimos_controles.get(cuerpo.name, $Inicio.global_position)
	cuerpo.reaparecer.call_deferred(punto, true)  # no mover cuerpos dentro de una señal de física


@rpc("authority", "call_local", "reliable")
func espectador(id: int) -> void:
	espectadores.append(id)
	var j := $Jugadores.get_node_or_null(str(id)) as Jugador
	if j != null:
		j.visible = false
	if id == multiplayer.get_unique_id():
		hud.mensaje.text = ""
		hud.titular("¡LLEGASTE A LA META! · MODO ESPECTADOR\nCLIC: CAMBIAR DE CÁMARA")
		camara_espectador = Camera2D.new()
		camara_espectador.position_smoothing_enabled = true
		add_child(camara_espectador)
		camara_espectador.make_current()
		objetivo_espectador = 0


# Vuelve a la cámara de mi moco (al empezar ronda).
func _dejar_de_mirar() -> void:
	if camara_espectador == null:
		return
	camara_espectador.queue_free()
	camara_espectador = null
	var mio := jugador_local()
	if mio != null:
		for c in mio.get_children():
			if c is Camera2D:
				c.make_current()


# El anfitrión apunta el puesto y avisa a todos; cada PC para su cronómetro si es su moco.
func _al_llegar(cuerpo: Node2D) -> void:
	if not (cuerpo is Jugador and multiplayer.is_server()) or en_resultados:
		return
	var id: int = cuerpo.id_dueno()
	var nuevo := not id in clasificacion.llegadas
	var t := _reloj()
	var puesto := clasificacion.registrar_llegada(id, t)
	if nuevo:
		desde_primero = maxf(desde_primero, 0.0)
		llegada.rpc(id, puesto, t)


# Segundos de ronda en el anfitrión. Su propio cronómetro se para cuando llega él,
# así que después se cuenta desde la llegada del primero.
func _reloj() -> float:
	if desde_primero < 0.0 or clasificacion.llegadas.is_empty():
		return tiempo
	return clasificacion.tiempos[clasificacion.llegadas[0]] + desde_primero


@rpc("authority", "call_local", "reliable")
func llegada(id: int, puesto: int, t: float) -> void:
	llegados.append(id)
	var j := $Jugadores.get_node_or_null(str(id)) as Jugador
	if j != null:
		j.efecto_red.emit("meta", j.global_position)  # ya llega a todos los PCs: este rpc es call_local
	if puesto == 1 and Red.es_online():
		cuenta = ESPERA_TRAS_PRIMERO
	if id == multiplayer.get_unique_id() and corriendo:
		corriendo = false
		tiempo = t  # el reloj del anfitrión: cada PC cargó la escena en un momento distinto
		hud.meta(tiempo, mejor, puesto, not Red.es_online())
		mejor = minf(mejor, tiempo)


# Sin red no hay rondas: se repite con R, como en la fase 1.
func _terminar_ronda() -> void:
	if not Red.es_online():
		desde_primero = -1.0
		return
	en_resultados = true
	clasificacion.cerrar_ronda(Red.ids, _reloj())
	var filas := clasificacion.orden(Red.ids).map(func(id: int) -> Array:
		return [id, clasificacion.victorias.get(id, 0), clasificacion.tiempo_total.get(id, 0.0)])
	if ronda >= Red.config.rondas:
		fin_torneo.rpc(filas, clasificacion.gana_por_tiempo(Red.ids))
		await get_tree().create_timer(SEGUNDOS_FINAL).timeout
		if is_inside_tree():  # si el anfitrión salió al menú mientras tanto, ya no hay torneo
			Red.volver_a_sala.rpc()
		return
	mostrar_resultados.rpc(filas)
	await get_tree().create_timer(SEGUNDOS_RESULTADOS).timeout
	if is_inside_tree():
		nueva_ronda.rpc(randi(), ronda + 1)  # cada ronda, mapa nuevo


@rpc("authority", "call_local", "reliable")
func mostrar_resultados(filas: Array) -> void:
	marcador_filas = filas
	en_resultados = true
	hud.mensaje.text = ""
	hud.marcador(_filas_vista())


# Último resultado del torneo. (El podio con flores llega en otro bloque.)
@rpc("authority", "call_local", "reliable")
func fin_torneo(filas: Array, por_tiempo: bool) -> void:
	mostrar_resultados(filas)
	var ganador := nombre(filas[0][0])
	hud.titular(("¡HAS GANADO EL TORNEO!" if ganador == "TÚ" else "GANA " + ganador)
			+ ("\nEMPATE EN VICTORIAS · GANA POR TIEMPO" if por_tiempo else ""))


@rpc("authority", "call_local", "reliable")
func nueva_ronda(semilla: int, numero: int) -> void:
	ronda = numero
	construir(semilla)
	reiniciar()


# Si sale el anfitrión, los demás vuelven solos al menú (Red avisa de que se ha ido).
func volver_al_menu() -> void:
	Red.salir()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

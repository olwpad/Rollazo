# Lógica de la escena de carrera: un moco por jugador, cronómetro, puntos de control, caída al
# vacío, meta, rondas y espectador. Es el "controlador" del nivel: construye el mapa que dicta
# la semilla y el anfitrión (servidor) decide todo; los demás PCs solo reciben los @rpc.
extends Node2D

const ESCENA_JUGADOR := preload("res://scenes/jugador.tscn")
const CAMARA := preload("res://scripts/camara.gd")
const BURBUJA := preload("res://scripts/burbuja.gd")
const ARO := preload("res://scripts/aro.gd")
const FONDO := preload("res://scripts/fondo.gd")
const ESPERA_TRAS_PRIMERO := 20.0  # segundos que tienen los demás tras llegar el primero
const SEGUNDOS_RESULTADOS := 5.0
const SEGUNDOS_POSTAL := 2.5  # la postal de "RONDA N" con los mocos quietos
const SEGUNDOS_MAPA_NUEVO := 3.0  # solo: tras llegar, el tiempo a la vista antes del mapa siguiente
const SEGUNDOS_FINAL := 8.0  # el ganador del torneo antes de volver a la sala

# --- Estado de la ronda (igual en todos los PCs) ---
var ronda := 1
var semilla_actual := 0
var tema := "azotea"  # el mapa de esta ronda (Temas): paleta, fondo y si hay aros
var nombres := {}  # id -> "JUGADOR N", fijo desde que sale su moco
var llegados: Array[int] = []  # quién ha cruzado la meta esta ronda, en todos los PCs
var espectadores: Array[int] = []  # llegaron y se cayeron: miran hasta el final de la ronda
var marcador_filas := []  # [[id, victorias, segundos totales], ...] ya ordenado; lo manda el anfitrión
var tiempo := 0.0
var mejor := INF
var corriendo := true  # el cronómetro de este PC: se para al llegar su moco
var reloj_ronda := 0.0  # mueve las sierras: sigue aunque llegue el moco local, igual en todos los PCs
var en_postal := false
var en_resultados := false
var colores := {}  # id -> color de su moco, en todos los PCs
var cuenta := -1.0  # segundos que quedan tras llegar el primero (en todos los PCs)
var _serial_mapa := 0  # cada reinicio lo sube: un cambio de mapa pendiente de antes ya no vale

# --- Solo el anfitrión ---
var ultimos_controles := {}  # id de jugador -> último punto de control
var clasificacion := Clasificacion.new()
var desde_primero := -1.0  # segundos desde que llegó el primero; -1 = nadie aún

# --- Espectador (moco que ya llegó) ---
var camara_espectador: Camera2D = null
var objetivo_espectador := 0  # a quién mira; uno más que los que juegan = el mapa entero

# --- Mapa ---
var piezas := Node2D.new()  # techos, descansos y obstáculos generados
var limites := Rect2(0, 0, 8800, 1400)  # la caja del mapa de esta ronda (cámara del espectador)
var forma_forzada := ""  # "" = la que toque por semilla; el bot probador la fija antes de añadir la escena

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


# --- Construcción del mapa ---


# Monta el mapa de esta semilla. Todos los PCs lo llaman con la misma, así es idéntico.
func construir(semilla: int) -> void:
	for viejo in piezas.get_children() + $Controles.get_children():
		viejo.get_parent().remove_child(viejo)
		viejo.queue_free()
	semilla_actual = semilla
	tema = Temas.de_ronda(Red.config.mapas, Red.semilla, ronda)
	var mapa := Generador.generar(semilla, forma_forzada)
	_crear_piezas(mapa, semilla)
	_crear_controles(mapa)
	if Red.config.poderes:
		_crear_burbujas(mapa, semilla)
	if Red.config.aros and Temas.DATOS[tema].aros:
		_crear_aros(mapa)
	_crear_sierras(mapa)
	for v: Ventilador in Ventilador.nuevos(semilla, mapa, self):
		piezas.add_child(v)
	for t: Trampolin in Trampolin.nuevos(semilla, mapa, self):
		t.body_entered.connect(_al_tocar_trampolin.bind(t))
		piezas.add_child(t)
	mapa.zonas_puerta = []  # columnas de las puertas: los móviles del tema no las cruzan (Moviles.ocupado)
	for p: Puerta in Puerta.nuevas(semilla, mapa, self):
		p.color = Temas.DATOS[tema].suelo
		p.mordio.connect(_al_morder)
		piezas.add_child(p)
		mapa.zonas_puerta.append(Rect2(p.position.x - Puerta.ANCHO / 2.0 - 40.0, p.arriba_y, Puerta.ANCHO + 80.0, p.abajo_y - p.arriba_y))
	_poner_vivos(mapa, semilla)
	limites = mapa.limites
	_poner_moviles(mapa, semilla)
	$Inicio.position = mapa.inicio
	$SueloInicio.position = mapa.inicio + Vector2(100, 80)
	$Meta.position = mapa.meta
	hud.get_node("Progreso").ruta = PackedVector2Array([mapa.inicio] + mapa.controles + [mapa.meta])
	$Meta/Forma.shape.size = mapa.meta_tam  # formas locales a la escena: no se cuelan en otro nivel
	$Caida.position = Vector2(mapa.caida_x, mapa.caida_y)
	$Caida/Forma.shape.size.x = mapa.caida_ancho
	_pintar_tema(mapa)


# Suelos, techos y obstáculos: un cuerpo estático (colisión + dibujo de acuarela) por pieza.
func _crear_piezas(mapa: Dictionary, semilla: int) -> void:
	for i in mapa.piezas.size():
		var p: Dictionary = mapa.piezas[i]
		if p.nombre.begins_with("SueloSalida"):  # ya está el SueloInicio de la escena, que se mueve ahí abajo
			continue
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


func _crear_controles(mapa: Dictionary) -> void:
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


func _crear_burbujas(mapa: Dictionary, semilla: int) -> void:
	for i in mapa.burbujas.size():
		var b := Area2D.new()
		b.set_script(BURBUJA)
		b.name = "Burbuja%d" % i
		b.position = mapa.burbujas[i].pos
		b.set("tipo", mapa.burbujas[i].tipo)  # set(): Area2D no sabe que el script tiene `tipo`
		b.set("semilla", semilla)
		b.set("indice", i)
		b.body_entered.connect(_al_tocar_burbuja.bind(b))
		piezas.add_child(b)  # con las piezas: se borran solas al cambiar de mapa


func _crear_aros(mapa: Dictionary) -> void:
	for i in mapa.aros.size():
		var a := Area2D.new()
		a.set_script(ARO)
		a.name = "Aro%d" % i
		a.position = mapa.aros[i].pos
		a.set("mov", mapa.aros[i].mov)
		a.body_entered.connect(_al_tocar_aro.bind(a))
		piezas.add_child(a)


func _crear_sierras(mapa: Dictionary) -> void:
	for i in mapa.sierras.size():
		var s := Sierra.new()
		s.name = "Sierra%d" % i
		s.position = mapa.sierras[i].pos
		s.riel = mapa.sierras[i].riel
		s.fase = mapa.sierras[i].fase
		s.color = mapa.sierras[i].color
		s.nivel = self
		s.body_entered.connect(_al_tocar_sierra.bind(s))
		piezas.add_child(s)


# Peligros de cada tema (aves en todos; marea, estalactitas, guirnaldas y techos que se apagan).
func _poner_vivos(mapa: Dictionary, semilla: int) -> void:
	for p: Paloma in Paloma.nuevas(semilla, mapa, self, tema):  # aves en todos los temas, cada una la suya
		p.body_entered.connect(_al_tocar_paloma.bind(p))
		piezas.add_child(p)
	match tema:
		"mar":
			var marea := Marea.nueva(semilla, mapa, self)
			marea.body_entered.connect(_al_caer)  # tocar el agua es como caer
			piezas.add_child(marea)
		"cueva":
			for e: Estalactita in Estalactita.nuevas(semilla, mapa, self):
				e.body_entered.connect(_al_tocar_estalactita)
				piezas.add_child(e)
		"noche":
			for g in Guirnalda.nuevas(semilla, mapa, self):
				piezas.add_child(g)
			for a in Apagon.nuevos(semilla, mapa, self, piezas):
				piezas.add_child(a)
	# Techos agrietados, en todos los temas (en la noche, sin los que ya se apagan)
	var apagan := Apagon.indices(semilla, mapa.camino.size()) if tema == "noche" else []
	for ag in Agrietado.nuevos(semilla, mapa, self, piezas, apagan):
		piezas.add_child(ag)


# Lo que se mueve y se puede agarrar de cada tema (Moviles decide dónde); con las piezas, se borra con ellas.
func _poner_moviles(mapa: Dictionary, semilla: int) -> void:
	var cosas: Array[Node2D] = []
	match tema:
		"mar":
			for d: Dictionary in Moviles.barcos(mapa, semilla):
				var b := Barco.new()
				b.position = d.pos
				b.riel = d.riel
				b.fase = d.fase
				cosas.append(b)
		"jungla":
			for d: Dictionary in Moviles.lianas(mapa, semilla):
				var l := Liana.new()
				l.pivote = d.pivote
				l.largo = d.largo
				l.fase = d.fase
				cosas.append(l)
		"azotea":
			for d: Dictionary in Moviles.ropas(mapa, semilla):
				for k in 2:
					var p := Prenda.new()
					p.cuerda_a = d.a
					p.cuerda_b = d.b
					p.pivote = d.a.lerp(d.b, 0.3 + 0.4 * k)
					p.fase = d.fase + 0.37 * k
					p.color = [Acuarela.ROSA, Acuarela.MENTA, Acuarela.LAVANDA][(int(d.a.x / 100.0) + k) % 3]
					cosas.append(p)
		"noche":
			var gs := Moviles.globos(mapa, semilla)
			for i in gs.size():
				var g := Globo.new()
				g.x = gs[i].x
				g.abajo = gs[i].abajo
				g.alto = gs[i].alto
				g.fase = gs[i].fase
				g.color = i
				cosas.append(g)
	for i in cosas.size():
		cosas[i].name = "Movil%d" % i
		cosas[i].set("nivel", self)
		piezas.add_child(cosas[i])


# Cielo, siluetas del fondo, lo que se mueve y el suelo de salida con los colores del tema.
func _pintar_tema(mapa: Dictionary) -> void:
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
		# Que la salida se vea como siempre aunque esté arriba (bajada): el fondo se mide desde ahí
		var parallax: Parallax2D = get_node("Ciudad/" + capa)
		parallax.scroll_offset.y = (mapa.inicio.y - 640.0) * parallax.scroll_scale.y
		_poner_fondo(get_node("Ciudad/" + capa), capa.to_lower(), mapa)
	if d.superficie != "":
		_poner_fondo(self, "superficie", mapa).z_index = 5  # delante de los mocos: el que cae se hunde
	else:
		_poner_fondo(self, "", mapa)  # solo quita la del mapa anterior
	var suelo: Polygon2D = $SueloInicio/Dibujo
	for viejo in suelo.get_children():
		viejo.free()
	_estilo_acuarela(suelo, 0)


func _poner_fondo(padre: Node, capa: String, mapa: Dictionary) -> Node2D:
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
	fondo.set("desde_x", mapa.limites.position.x - 2000.0)
	fondo.set("hasta_x", mapa.limites.end.x + 2000.0)
	# Bajo todo el mapa y sobre la franja que mata: primero te hundes, luego reapareces
	fondo.set("superficie_y", maxf(mapa.caida_y - 300.0, mapa.limites.end.y))
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


# --- Cada frame y entrada ---


func _physics_process(delta: float) -> void:
	if corriendo:
		tiempo += delta
	if not (en_postal or en_resultados):
		reloj_ronda += delta
	hud.mostrar(tiempo, mejor, not Red.es_online())
	if cuenta >= 0.0:
		cuenta = maxf(cuenta - delta, 0.0)
	hud.cuenta_atras(cuenta if not en_resultados else -1.0)
	var mio := jugador_local()
	if mio != null and mio.papel_activo:
		hud.ocultar_ayuda()  # ya sabe lanzar el papel
	if mio != null:
		hud.poder(mio.poder, mio.poder_restante, Poderes.DURACION.get(mio.poder, 1.0))
	hud.progreso([] if en_postal or en_resultados else _puntos_progreso(mio))
	if Red.es_online() and multiplayer.is_server():  # en una torre se cae sobre un saliente, no a la Caida
		for j in jugadores():
			var id := j.id_dueno()
			if id in clasificacion.llegadas and not id in espectadores and j.global_position.y > $Meta.position.y + 400.0:
				_mandar_a_mirar(j)
	if multiplayer.is_server():  # quien sobrevuela la meta sin tocarla cae fuera de la franja Caida
		for j in jugadores():
			var p := j.global_position
			if not j.id_dueno() in espectadores and (p.y > limites.end.y + 600.0 or p.x < limites.position.x - 1500.0 or p.x > limites.end.x + 1500.0):
				_al_caer(j)
	if desde_primero >= 0.0 and not en_resultados and multiplayer.is_server():
		desde_primero += delta
		if clasificacion.todos_llegaron(Red.ids) or desde_primero >= ESPERA_TRAS_PRIMERO:
			_terminar_ronda()


# Un punto por moco en la barra; el mío el último para que se pinte encima.
func _puntos_progreso(mio: Jugador) -> Array:
	var ruta: PackedVector2Array = hud.get_node("Progreso").ruta
	var puntos := []
	for j in jugadores():
		if j != mio:
			puntos.append([colores.get(j.id_dueno(), Color.WHITE), BarraProgreso.fraccion(ruta, j.global_position), false])
	if mio != null:
		puntos.append([colores.get(mio.id_dueno(), Color.WHITE), BarraProgreso.fraccion(ruta, mio.global_position), true])
	return puntos


func _process(_delta: float) -> void:
	if camara_espectador == null:
		return
	var jugando := _jugando()
	objetivo_espectador = objetivo_espectador % (jugando.size() + 1)
	if objetivo_espectador < jugando.size():
		camara_espectador.global_position = jugando[objetivo_espectador].global_position
		camara_espectador.zoom = Vector2(0.85, 0.85)
	else:  # el mapa entero, con el zoom que quepa
		camara_espectador.global_position = limites.get_center()
		var hueco := get_viewport_rect().size / limites.size
		camara_espectador.zoom = Vector2.ONE * minf(hueco.x, hueco.y)


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


# --- Jugadores y marcador ---


func nombre(id: int) -> String:
	return "TÚ" if id == multiplayer.get_unique_id() else nombres.get(id, "JUGADOR")


# El marcador listo para pintar: [color, nombre, victorias, segundos, aspecto].
func _filas_vista() -> Array:
	if marcador_filas.is_empty():  # primera ronda: todos a cero
		return jugadores().map(func(j: Jugador) -> Array: return [colores[j.id_dueno()], nombre(j.id_dueno()), 0, 0.0, Red.aspecto_de(j.id_dueno())])
	return marcador_filas.map(func(f: Array) -> Array: return [colores.get(f[0], Acuarela.CIRUELA), nombre(f[0]), f[1], f[2], Red.aspecto_de(f[0])])


# El MultiplayerSpawner llama a esto en todos los PCs con los mismos datos: [id, índice].
func crear_jugador(datos: Array) -> Node:
	var id: int = datos[0]
	var indice: int = datos[1]
	var j: Jugador = ESCENA_JUGADOR.instantiate()
	j.name = str(id)
	j.position = $Inicio.global_position + Vector2(indice * 90, 0)
	j.pintar(Red.color_de(id))
	j.vestir(Red.aspecto_de(id))
	colores[id] = j.get_node("Visual/Moco").color
	j.aterrizado.connect(_al_aterrizar.bind(j))
	nombres[id] = Perfil.nombre_en(Red.aspecto_de(id), "JUGADOR %d" % (indice + 1))  # el mismo que en la sala
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


# --- Ronda: reinicio y postal ---


func reiniciar() -> void:
	_serial_mapa += 1
	en_postal = false
	if not Red.es_online():
		clasificacion.llegadas.clear()  # si no, la próxima llegada no contaría como nueva
	tiempo = 0.0
	reloj_ronda = 0.0
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
		j.congelado = false
	if multiplayer.is_server():
		var lista := jugadores()
		for i in lista.size():
			lista[i].reaparecer($Inicio.global_position + Vector2(i * 90, 0))  # en fila, no apilados
			lista[i].poder = ""  # cada ronda se empieza sin poderes
	if Red.es_online():
		_postal()


# "RONDA N DE M" con los mocos quietos y el reloj parado; luego, a correr.
func _postal() -> void:
	en_postal = true
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
	en_postal = false
	corriendo = true


func _congelar(si: bool) -> void:
	if multiplayer.is_server():
		for j in jugadores():
			j.congelado = si


# --- Peligros, burbujas y caídas (los decide el anfitrión) ---


# El anfitrión decide quién la coge; todos la quitan a la vez.
func _al_tocar_burbuja(cuerpo: Node2D, burbuja: Area2D) -> void:
	if not (cuerpo is Jugador and multiplayer.is_server()) or not burbuja.visible:
		return
	(cuerpo as Jugador).dar_poder(burbuja.get("tipo"))
	cuerpo.efecto.rpc("poder", burbuja.global_position)
	burbuja_cogida.rpc(burbuja.name)


# Aro de fuego: te quemas y vuelves al último control, como al caer. Lo decide el anfitrión.
func _al_tocar_aro(cuerpo: Node2D, _aro: Area2D) -> void:
	if cuerpo is Jugador and multiplayer.is_server() and not cuerpo.congelado:
		(cuerpo as Jugador).quemarse()
		_volver_al_control(cuerpo)


# Sierra: el papel salta en trozos y el moco salpica de vuelta en su último control, como al
# caer; si ya llegó (online), a mirar. Lo decide el anfitrión.
func _al_tocar_sierra(cuerpo: Node2D, _sierra: Sierra) -> void:
	if not (cuerpo is Jugador and multiplayer.is_server()) or cuerpo.congelado:
		return
	cuerpo.efecto.rpc("sierra", cuerpo.global_position)  # el "zing" extra, además de la "rotura"
	_golpe_y_vuelta(cuerpo)


# Mandíbula: quien se queda en el hueco al cerrarse se lleva el ñam. Lo decide el anfitrión.
func _al_morder(cuerpo: Node2D) -> void:
	if cuerpo.congelado:
		return
	cuerpo.efecto.rpc("ñam", cuerpo.global_position)
	_golpe_y_vuelta(cuerpo)


# Trampolín: quien entra cayendo sale disparado hacia arriba. Lo decide el anfitrión.
func _al_tocar_trampolin(cuerpo: Node2D, trampolin: Trampolin) -> void:
	if not (cuerpo is Jugador and multiplayer.is_server()) or cuerpo.congelado or cuerpo.velocity.y <= 0.0:
		return
	cuerpo.velocity.y = Trampolin.velocidad_rebote(cuerpo.velocity.y)
	cuerpo.efecto.rpc("boing", cuerpo.global_position)
	trampolin_rebota.rpc(trampolin.name)


@rpc("authority", "call_local", "reliable")
func trampolin_rebota(nombre_trampolin: String) -> void:
	var t := piezas.get_node_or_null(nombre_trampolin) as Trampolin
	if t != null:
		t.rebotar()


# Estalactita cayendo: igual que la sierra pero sin el "zing". Solo la ve caer el área (monitoring).
func _al_tocar_estalactita(cuerpo: Node2D) -> void:
	if cuerpo is Jugador and multiplayer.is_server() and not cuerpo.congelado:
		_golpe_y_vuelta(cuerpo)


# Paloma: solo empuja, no te devuelve al control. Lo decide el anfitrión.
func _al_tocar_paloma(cuerpo: Node2D, paloma: Paloma) -> void:
	if cuerpo is Jugador and multiplayer.is_server() and not cuerpo.congelado and paloma.empujar(cuerpo):
		cuerpo.efecto.rpc("choque", cuerpo.global_position)


func _golpe_y_vuelta(cuerpo: Node2D) -> void:
	cuerpo.efecto.rpc("rotura", cuerpo.global_position)
	if Red.es_online() and cuerpo.id_dueno() in clasificacion.llegadas:
		_mandar_a_mirar(cuerpo as Jugador)
		return
	_volver_al_control(cuerpo)  # con el efecto "reaparecer": la salpicadura


# Un techo agrietado tiembla, cae o vuelve (Agrietado.Estado): el anfitrión lo decide y todos lo ven igual.
@rpc("authority", "call_local", "reliable")
func techo_estado(nombre_techo: String, estado: int) -> void:
	var a := piezas.get_node_or_null(nombre_techo) as Agrietado
	if a != null:
		a.aplicar(estado)


@rpc("authority", "call_local", "reliable")
func burbuja_cogida(nombre_burbuja: String) -> void:
	var b := piezas.get_node_or_null(nombre_burbuja)
	if b != null:
		b.recogida()


func _al_pasar_control(cuerpo: Node2D, control: Area2D) -> void:
	if cuerpo is Jugador and multiplayer.is_server():
		if ultimos_controles.get(cuerpo.name) != control.global_position:  # solo al estrenarlo
			cuerpo.efecto.rpc_id(cuerpo.id_dueno(), "control", control.global_position)  # solo lo oye su dueño
		ultimos_controles[cuerpo.name] = control.global_position


# Llegar al fondo de un pozo sin haber frenado: salpicadura y vuelta al último control. Lo decide el anfitrión.
func _al_aterrizar(caida: float, cuerpo: Jugador) -> void:
	var choque := cuerpo.get_last_slide_collision()
	if choque != null:
		_choque_en_pozo(caida, cuerpo, (choque.get_collider() as Node).name)


# true si se estrelló
func _choque_en_pozo(caida: float, cuerpo: Jugador, suelo: String) -> bool:
	if not multiplayer.is_server() or cuerpo.congelado or caida < Generador.ESTRELLON or not suelo.begins_with("FondoPozo"):
		return false
	cuerpo.efecto.rpc("aterrizaje", cuerpo.global_position + Vector2(0, 18))
	_volver_al_control(cuerpo)
	return true


func _al_caer(cuerpo: Node2D) -> void:
	if not (cuerpo is Jugador and multiplayer.is_server()):
		return
	if Red.es_online() and cuerpo.id_dueno() in clasificacion.llegadas:  # ya llegó: a mirar
		_mandar_a_mirar(cuerpo as Jugador)
		return
	if not Red.es_online() and cuerpo.congelado:  # solo y ya en la meta: no vuelve a ningún control
		return
	_volver_al_control(cuerpo)


# --- Espectador ---


# Un moco que ya llegó deja de jugar: quieto, fuera de en medio y su PC pasa a espectador.
func _mandar_a_mirar(cuerpo: Jugador) -> void:
	cuerpo.congelado = true
	cuerpo.reaparecer.call_deferred(Vector2($Meta.position.x, limites.position.y - 4000.0))
	espectador.rpc(cuerpo.id_dueno())


func _volver_al_control(cuerpo: Node2D) -> void:
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


# --- Meta, resultados y torneo ---


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
	if not Red.es_online() and j != null:
		j.congelado = true  # (solo hay un moco, el local) quieto mientras se ve el tiempo
		var serial := _serial_mapa
		await get_tree().create_timer(SEGUNDOS_MAPA_NUEVO, false).timeout
		_mapa_nuevo_si_vigente(serial)


# Si pulsaste R mientras tanto, el aviso es de otra partida y no hace nada.
func _mapa_nuevo_si_vigente(serial: int) -> void:
	if serial == _serial_mapa:
		_mapa_nuevo_solo()


func _mapa_nuevo_solo() -> void:
	ronda += 1  # también rota el tema
	mejor = INF
	construir(semilla_nueva())
	reiniciar()


# Una semilla al azar cuyo mapa no repite la forma del que se acaba de jugar.
func semilla_nueva() -> int:
	var s := randi()
	while Generador.forma_de(s) == Generador.forma_de(semilla_actual):
		s = randi()
	return s


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
		nueva_ronda.rpc(semilla_nueva(), ronda + 1)  # cada ronda, mapa nuevo


@rpc("authority", "call_local", "reliable")
func mostrar_resultados(filas: Array) -> void:
	marcador_filas = filas
	en_resultados = true
	hud.mensaje.text = ""
	hud.marcador(_filas_vista(), true)


# Último resultado del torneo: el podio con las mismas filas ya ordenadas en todos los PCs.
@rpc("authority", "call_local", "reliable")
func fin_torneo(filas: Array, por_tiempo: bool) -> void:
	marcador_filas = filas
	en_resultados = true
	hud.mensaje.text = ""
	hud.podio(_filas_vista())
	var ganador := nombre(filas[0][0])
	var nuevo: Array = Perfil.anotar_torneo(ganador == "TÚ")  # cada PC cuenta lo suyo
	hud.titular(("¡HAS GANADO EL TORNEO!" if ganador == "TÚ" else "GANA " + ganador)
			+ ("\nEMPATE EN VICTORIAS · GANA POR TIEMPO" if por_tiempo else "")
			+ ("\n¡NUEVO PARA TU MOCO: %s!" % ", ".join(nuevo.map(func(c: String) -> String: return Perfil.NOMBRES[c])) if nuevo else ""))


@rpc("authority", "call_local", "reliable")
func nueva_ronda(semilla: int, numero: int) -> void:
	ronda = numero
	construir(semilla)
	reiniciar()


# --- Salir ---


# Si sale el anfitrión, los demás vuelven solos al menú (Red avisa de que se ha ido).
func volver_al_menu() -> void:
	Red.salir()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

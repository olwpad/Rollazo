# Menú: practicar, multijugador (crear sala o unirse con un código), tu moco y opciones. Dentro de una partida, la sala: la azotea
# con los mocos, el código, la notita con la partida y un único botón grande.
extends Control

const Mira := preload("res://scripts/mira.gd")
const PANELES := ["Multi", "Opciones"]  # los papeles que tapan el menú; Esc los cierra

@onready var codigo: LineEdit = $Multi/Papel/Caja/Fila/Codigo
@onready var estado: Label = $Caja/Estado  # el aviso del inicio; el del panel de multijugador va aparte
@onready var estado_multi: Label = $Multi/Papel/Caja/Estado
@onready var principal = $SalaUI/Principal  # sin tipo: es un boton_mancha (tiene progreso)
@onready var config: Control = $Config


func _ready() -> void:
	Musica.tocar("menu")
	var cfg := ConfigFile.new()
	cfg.load(Ajustes.ruta)
	codigo.text = Red.normalizar_codigo(cfg.get_value("red", "ultimo_codigo", ""))
	codigo.text_changed.connect(_al_escribir_codigo)
	_al_escribir_codigo(codigo.text)
	_conectar_botones()
	_montar_selector_de_mapas()
	Red.jugadores_cambiaron.connect(_actualizar)
	Red.config_cambiada.connect(_actualizar)
	Red.sala_lista.connect(_actualizar)
	Red.desconectado.connect(_avisar)
	_actualizar()
	if Red.ultimo_motivo != "":
		_avisar(Red.ultimo_motivo)
		Red.ultimo_motivo = ""


# --- Montaje (solo en _ready) ---

func _conectar_botones() -> void:
	$Caja/Multijugador.pressed.connect(_abrir_panel.bind("Multi"))
	$Caja/Opciones.pressed.connect(_abrir_panel.bind("Opciones"))
	$Multi/Papel/Caja/Crear.pressed.connect(_crear)
	$Multi/Papel/Caja/Fila/Unirse.pressed.connect(_unirse)
	$Multi/Papel/Caja/Volver.pressed.connect(_cerrar_panel)
	$Opciones/Papel/Caja/Volver.pressed.connect(_cerrar_panel)
	var op := $Opciones/Papel/Caja
	op.get_node("Pantalla/Valor").pressed.connect(func(): Ajustes.poner_pantalla_completa(not Ajustes.pantalla_completa); _pintar_opciones())
	op.get_node("Mira/Valor").pressed.connect(func(): Mira.alternar(); _pintar_opciones())
	op.get_node("Ayuda/Valor").pressed.connect(func(): Ajustes.poner_ayuda(not Ajustes.ayuda); _pintar_opciones())
	$Caja/Solo.pressed.connect(_practicar)
	$Caja/TuMoco.pressed.connect(_vestir.bind(true))
	$SalaUI/TuMoco.pressed.connect(_vestir.bind(true))  # también desde el lobby
	$Vestidor.cerrado.connect(_vestir.bind(false))
	$Salir.pressed.connect(_salir)
	principal.pressed.connect(_pulsar_principal)
	$SalaUI/Codigo/Fila/Copiar.pressed.connect(_copiar_codigo)
	$SalaUI/Notita/Caja/Cambiar.pressed.connect(func(): config.visible = true)
	$Config/Papel/Caja/Hecho.pressed.connect(func(): config.visible = false)
	$Config/Papel/Caja/Pegatinas/Poderes.pressed.connect(func(): Red.poner_poderes(not Red.config.poderes))
	$Config/Papel/Caja/Pegatinas/Rondas.pressed.connect(func():  # 3 → 5 → 7 → 10 → 3
		Red.poner_rondas(Red.RONDAS[(Red.RONDAS.find(Red.config.rondas) + 1) % Red.RONDAS.size()]))
	$Config/Papel/Caja/Pegatinas/Aros.visible = false  # aros quitados de momento (ver red.gd)


# Una postal por mapa, más el botón "PONER TODOS" en el hueco que queda.
func _montar_selector_de_mapas() -> void:
	for t in Temas.LISTA:  # una postal por mapa; tocarla lo quita o lo pone
		var mapa := Postal.new()
		mapa.name = t
		mapa.custom_minimum_size = Vector2(190, 130)
		mapa.titulo = Temas.DATOS[t].nombre
		mapa.tema = t
		mapa.semilla = 2026  # de muestra; cada ronda sale un trazado distinto
		mapa.gui_input.connect(_tocar_mapa.bind(t))
		$Config/Papel/Caja/Mapas.add_child(mapa)
	var todos := Button.new()  # el hueco que queda en la segunda fila
	todos.name = "Todos"
	todos.text = "PONER TODOS"
	todos.focus_mode = Control.FOCUS_NONE
	todos.set_script(preload("res://scripts/boton_mancha.gd"))
	todos.custom_minimum_size = Vector2(190, 130)
	todos.add_theme_font_size_override("font_size", 30)
	todos.pressed.connect(func(): Red.poner_mapas(Temas.LISTA))
	$Config/Papel/Caja/Mapas.add_child(todos)


# --- Botones del menú ---

func _avisar(texto: String) -> void:
	estado.text = texto
	estado_multi.text = texto


func _practicar() -> void:
	Red.semilla = randi()  # cada práctica, un mapa distinto
	get_tree().change_scene_to_file(Red.RECORRIDO)


func _copiar_codigo() -> void:
	DisplayServer.clipboard_set(Red.codigo_sala)
	var boton: Button = $SalaUI/Codigo/Fila/Copiar
	boton.text = "¡COPIADA!"
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(boton):
		boton.text = "COPIAR"


func _tocar_mapa(evento: InputEvent, t: String) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		var lista: Array = Red.config.mapas.duplicate()
		if t in lista:
			lista.erase(t)
		else:
			lista.append(t)
		Red.poner_mapas(lista)  # quitar el último no hace nada: siempre queda uno


func _crear() -> void:
	var err := Red.crear_sala()
	_avisar("NO HAY CONEXIÓN CON EL SERVIDOR" if err != OK else "")
	_actualizar()


# Solo mayúsculas y letras del alfabeto; sin 4 letras válidas, UNIRSE se apaga.
func _al_escribir_codigo(texto: String) -> void:
	var limpio := Red.normalizar_codigo(texto)
	if limpio != texto:
		codigo.text = limpio
		codigo.caret_column = limpio.length()
	$Multi/Papel/Caja/Fila/Unirse.disabled = not Red.codigo_valido(limpio)


func _unirse() -> void:
	var sala := codigo.text
	if Red.unirse_sala(sala) != OK:
		_avisar("NO HAY CONEXIÓN CON EL SERVIDOR")
	else:
		_avisar("Conectando a %s…" % sala)
		Ajustes.guardar("red", "ultimo_codigo", sala)  # la próxima vez ya sale escrito
	_actualizar()


# Atrás desde la sala. Si sale el anfitrión, los demás vuelven solos con "El anfitrión se ha ido".
func _salir() -> void:
	Red.salir()
	_avisar("")
	config.visible = false
	_actualizar()


# --- Sala: entrada y repintado ---


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("volver_menu") and _panel_abierto() != "":
		_cerrar_panel()
	elif evento.is_action_pressed("volver_menu") and Red.es_online():  # Esc, como pone el botón
		if config.visible:
			config.visible = false
		else:
			_salir()


# El anfitrión empieza (cuando todos están listos); los demás dicen si están listos.
func _pulsar_principal() -> void:
	if multiplayer.is_server():
		if Red.todos_listos():
			Red.empezar_carrera.rpc(randi())
	else:
		Red.marcar_listo.rpc_id(1, not Red.listos.get(multiplayer.get_unique_id(), false))


func _actualizar() -> void:
	if $Vestidor.visible or $Opciones.visible:  # los avisos de la red no pintan la sala encima; al cerrarlo, _vestir lo repinta
		return
	var online := Red.es_online()
	var anfitrion := online and multiplayer.is_server()
	var en_sala := online and multiplayer.get_unique_id() in Red.ids  # conectando todavía no
	if $Multi.visible:
		if not en_sala:  # conectando o con un error: el panel sigue
			return
		$Multi.visible = false  # ya dentro: a la sala
	# Ya dentro de una partida: ni practicar, ni crear otra, ni unirse a otra (dejaría a los demás colgados).
	for opcion in [$Caja/Solo, $Caja/Multijugador, $Caja/Opciones]:
		opcion.visible = not online
	$Caja.visible = not en_sala
	$SalaUI.visible = en_sala
	# El columpio sigue en la sala (inicio y sala son la misma azotea), entre el código y la nota.
	$Columpio.position = Vector2(600, 40) if en_sala else Vector2(760, 60)
	$Columpio.largo = 160.0 if en_sala else 230.0  # en la sala, corto: que no baje hasta los carteles de la grada
	$Pie.visible = not online  # en la sala, abajo a la izquierda va SALIR
	$Nota.visible = not online
	$Salir.visible = online
	$Sala.position = Vector2(580, 493) if en_sala else Vector2(740, 560)
	if en_sala:  # sobre la azotea morada, el texto claro
		$Salir.add_theme_color_override("font_color", Color("fffaf4"))
	else:
		$Salir.remove_theme_color_override("font_color")
	$Sala.tarjetas = en_sala
	var solo_yo: Array[int] = [1]
	$Sala.mostrar(Red.ids if online else solo_yo, multiplayer.get_unique_id(), Red.listos)
	if not en_sala:
		config.visible = false
		return
	$SalaUI/Codigo.visible = anfitrion  # los amigos ya lo escribieron para entrar
	$SalaUI/Codigo/Fila/Valor.text = Red.codigo_sala if Red.codigo_sala != "" else "CREANDO SALA…"
	$SalaUI/Codigo/Fila/Copiar.disabled = Red.codigo_sala == ""
	var mapas: Array = Red.config.mapas
	$SalaUI/Notita/Caja/Resumen.text = "%d RONDAS · %s\n%s" % [Red.config.rondas,
			Temas.DATOS[mapas[0]].nombre if mapas.size() == 1 else "%d MAPAS" % mapas.size(),
			"CON PODERES" if Red.config.poderes else "SIN PODERES"]
	$Config/Papel/Caja/Pegatinas/Rondas.text = str(Red.config.rondas)
	$Config/Papel/Caja/Pegatinas/Poderes.text = "SÍ" if Red.config.poderes else "NO"
	for mapa in $Config/Papel/Caja/Mapas.get_children():
		if mapa is Postal:
			mapa.apagada = not mapa.name in mapas
	$SalaUI/Notita/Caja/Cambiar.visible = anfitrion
	$SalaUI/PistaCodigo.visible = anfitrion
	# El anfitrión cuenta como listo: con 3 jugadores, "2/3", no "1/2".
	var faltan := []
	for i in Red.ids.size():
		if Red.ids[i] != 1 and not Red.listos.get(Red.ids[i], false):
			faltan.append(Perfil.nombre_en(Red.aspecto_de(Red.ids[i]), "JUGADOR %d" % (i + 1)))  # el mismo nombre que en su tarjeta
	var total := Red.ids.size()
	if anfitrion:
		principal.text = "¡A CORRER!" if faltan.is_empty() else "¡A CORRER! · %d/%d LISTOS" % [total - faltan.size(), total]
		principal.progreso = float(total - faltan.size()) / total
		$SalaUI/Estado.text = "" if faltan.is_empty() else ("FALTA: " if faltan.size() == 1 else "FALTAN: ") + ", ".join(faltan)
	else:
		var yo_listo: bool = Red.listos.get(multiplayer.get_unique_id(), false)
		principal.text = "¡LISTO! (QUITAR)" if yo_listo else "ESTOY LISTO"
		principal.progreso = -1.0
		$SalaUI/Estado.text = "ESPERANDO AL ANFITRIÓN" if yo_listo else "PULSA CUANDO QUIERAS EMPEZAR"


# El vestidor ocupa la pantalla: fuera el menú, la azotea de adorno y el columpio mientras tanto.
func _vestir(si: bool) -> void:
	for nodo in [$Caja, $Sala, $Columpio, $Pie, $Nota, $SalaUI, $Salir]:
		nodo.visible = not si
	if si:
		$Vestidor.abrir()
	else:
		Red.avisar_aspecto()  # en el lobby, los demás te ven cambiado
		_actualizar()  # el moco «TÚ» de la azotea sale ya vestido


func _panel_abierto() -> String:
	for nombre in PANELES:
		if get_node(nombre).visible:
			return nombre
	return ""


# Multijugador y Opciones: papel sobre el cielo. Fuera la lista de opciones, la azotea y el columpio;
# la notita de la música se queda (el papel no llega hasta ella).
func _abrir_panel(nombre: String) -> void:
	for nodo in [$Caja, $Sala, $Columpio]:
		nodo.visible = false
	get_node(nombre).visible = true
	if nombre == "Opciones":
		_pintar_opciones()


func _cerrar_panel() -> void:
	for nombre in PANELES:
		get_node(nombre).visible = false
	if Red.es_online():  # se había pulsado CREAR/UNIRSE y aún conecta: volver atrás lo cancela
		Red.salir()
	_avisar("")
	for nodo in [$Sala, $Columpio]:
		nodo.visible = true
	_actualizar()


func _pintar_opciones() -> void:
	var op := $Opciones/Papel/Caja
	op.get_node("Pantalla/Valor").text = "SÍ" if Ajustes.pantalla_completa else "NO"
	op.get_node("Mira/Valor").text = "SÍ" if Mira.activa() else "NO"
	op.get_node("Ayuda/Valor").text = "SÍ" if Ajustes.ayuda else "NO"
	for valor in [op.get_node("Pantalla/Valor"), op.get_node("Mira/Valor"), op.get_node("Ayuda/Valor")]:
		valor.queue_redraw()

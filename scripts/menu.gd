# Menú: practicar, crear partida o unirse por IP. Dentro de una partida, la sala: la azotea
# con los mocos, tu IP, la notita con la partida y un único botón grande.
extends Control

const AJUSTES := "user://ajustes.cfg"  # el mismo archivo que la mira

@onready var ip: LineEdit = $Caja/Fila/IP
@onready var estado: Label = $Caja/Estado
@onready var principal = $SalaUI/Principal  # sin tipo: es un boton_mancha (tiene progreso)
@onready var config: Control = $Config


func _ready() -> void:
	Musica.tocar("menu")
	var cfg := ConfigFile.new()
	cfg.load(AJUSTES)
	ip.text = cfg.get_value("red", "ultima_ip", "")
	ip.text_changed.connect(_al_escribir_ip)
	_al_escribir_ip(ip.text)
	$Caja/Crear.pressed.connect(_crear)
	$Caja/Fila/Unirse.pressed.connect(_unirse)
	$Caja/Solo.pressed.connect(_practicar)
	$Caja/TuMoco.pressed.connect(_vestir.bind(true))
	$Vestidor.cerrado.connect(_vestir.bind(false))
	$Salir.pressed.connect(_salir)
	principal.pressed.connect(_pulsar_principal)
	$SalaUI/Ip/Fila/Copiar.pressed.connect(_copiar_ip)
	$SalaUI/Notita/Caja/Cambiar.pressed.connect(func(): config.visible = true)
	$Config/Papel/Caja/Hecho.pressed.connect(func(): config.visible = false)
	$Config/Papel/Caja/Pegatinas/Poderes.pressed.connect(func(): Red.poner_poderes(not Red.config.poderes))
	$Config/Papel/Caja/Pegatinas/Rondas.pressed.connect(func():  # 3 → 5 → 7 → 10 → 3
		Red.poner_rondas(Red.RONDAS[(Red.RONDAS.find(Red.config.rondas) + 1) % Red.RONDAS.size()]))
	$Config/Papel/Caja/Pegatinas/Aros.visible = false  # aros quitados de momento (ver red.gd)
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
	Red.jugadores_cambiaron.connect(_actualizar)
	Red.config_cambiada.connect(_actualizar)
	Red.desconectado.connect(func(motivo): estado.text = motivo)
	_actualizar()
	if Red.ultimo_motivo != "":
		estado.text = Red.ultimo_motivo
		Red.ultimo_motivo = ""


func _practicar() -> void:
	Red.semilla = randi()  # cada práctica, un mapa distinto
	get_tree().change_scene_to_file(Red.RECORRIDO)


func _copiar_ip() -> void:
	DisplayServer.clipboard_set($SalaUI/Ip/Fila/Valor.text)
	var boton: Button = $SalaUI/Ip/Fila/Copiar
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
	var err := Red.crear_partida()
	estado.text = "No se pudo crear (¿puerto ocupado?)" if err != OK else ""
	_actualizar()


# Sin IP no hay a quién unirse: el botón se apaga en vez de decir "IP no válida".
func _al_escribir_ip(texto: String) -> void:
	$Caja/Fila/Unirse.disabled = texto.strip_edges() == ""


func _unirse() -> void:
	var direccion := ip.text.strip_edges()
	if Red.unirse(direccion) != OK:
		estado.text = "IP no válida"
	else:
		estado.text = "Conectando a %s…" % direccion
		var cfg := ConfigFile.new()  # la próxima vez ya sale escrita
		cfg.load(AJUSTES)
		cfg.set_value("red", "ultima_ip", direccion)
		cfg.save(AJUSTES)
	_actualizar()


# Atrás desde la sala. Si sale el anfitrión, los demás vuelven solos con "El anfitrión se ha ido".
func _salir() -> void:
	Red.salir()
	estado.text = ""
	config.visible = false
	_actualizar()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("volver_menu") and Red.es_online():  # Esc, como pone el botón
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
	var online := Red.es_online()
	var anfitrion := online and multiplayer.is_server()
	var en_sala := online and multiplayer.get_unique_id() in Red.ids  # conectando todavía no
	# Ya dentro de una partida: ni practicar, ni crear otra, ni unirse a otra (dejaría a los demás colgados).
	for opcion in [$Caja/Solo, $Caja/Crear, $Caja/Fila]:
		opcion.visible = not online
	$Caja.visible = not en_sala
	$SalaUI.visible = en_sala
	# El columpio sigue en la sala (inicio y sala son la misma azotea), entre la IP y la nota.
	$Columpio.position = Vector2(600, 40) if en_sala else Vector2(760, 60)
	$Pie.visible = not online
	$Salir.visible = online
	$Sala.position = Vector2(265, 493) if en_sala else Vector2(740, 560)
	if en_sala:  # sobre la azotea morada, el texto claro
		$Salir.add_theme_color_override("font_color", Color("fffaf4"))
	else:
		$Salir.remove_theme_color_override("font_color")
	$Sala.separacion = 250.0 if en_sala else 135.0
	$Sala.tarjetas = en_sala
	var solo_yo: Array[int] = [1]
	$Sala.mostrar(Red.ids if online else solo_yo, multiplayer.get_unique_id(), Red.listos)
	if not en_sala:
		config.visible = false
		return
	$SalaUI/Ip.visible = anfitrion  # los amigos ya la escribieron para entrar
	$SalaUI/Ip/Fila/Valor.text = Red.ip_propia()
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
	$SalaUI/PistaIp.visible = anfitrion
	# El anfitrión cuenta como listo: con 3 jugadores, "2/3", no "1/2".
	var faltan := []
	for i in Red.ids.size():
		if Red.ids[i] != 1 and not Red.listos.get(Red.ids[i], false):
			faltan.append("JUGADOR %d" % (i + 1))  # el mismo nombre que en su tarjeta
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
	for nodo in [$Caja, $Sala, $Columpio, $Pie]:
		nodo.visible = not si
	if si:
		$Vestidor.abrir()
	else:
		_actualizar()  # el moco «TÚ» de la azotea sale ya vestido

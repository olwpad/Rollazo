# Menú: practicar, crear partida o unirse por IP. Dentro de una partida, la sala: la azotea
# con los mocos, tu IP, la notita con la partida y un único botón grande.
extends Control

@onready var ip: LineEdit = $Caja/Fila/IP
@onready var estado: Label = $Caja/Estado
@onready var principal = $SalaUI/Principal  # sin tipo: es un boton_mancha (tiene progreso)
@onready var config: Control = $Config


func _ready() -> void:
	Musica.tocar("menu")
	$Caja/Crear.pressed.connect(_crear)
	$Caja/Fila/Unirse.pressed.connect(_unirse)
	$Caja/Solo.pressed.connect(_practicar)
	$Salir.pressed.connect(_salir)
	principal.pressed.connect(_pulsar_principal)
	$SalaUI/Ip/Fila/Copiar.pressed.connect(func(): DisplayServer.clipboard_set($SalaUI/Ip/Fila/Valor.text))
	$SalaUI/Notita/Caja/Cambiar.pressed.connect(func(): config.visible = true)
	$Config/Papel/Caja/Hecho.pressed.connect(func(): config.visible = false)
	$Config/Papel/Caja/Poderes.pressed.connect(func(): Red.poner_poderes(not Red.config.poderes))
	for n in Red.RONDAS:
		get_node("Config/Papel/Caja/Rondas/R%d" % n).pressed.connect(Red.poner_rondas.bind(n))
	var mapa: Postal = $Config/Papel/Caja/Mapas/Azotea
	mapa.titulo = Generador.NOMBRE
	mapa.semilla = 2026  # de muestra; cada ronda sale un mapa distinto
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


func _crear() -> void:
	var err := Red.crear_partida()
	estado.text = "No se pudo crear (¿puerto ocupado?)" if err != OK else ""
	_actualizar()


func _unirse() -> void:
	estado.text = "Conectando a %s…" % ip.text if Red.unirse(ip.text.strip_edges()) == OK else "IP no válida"
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
	$Columpio.visible = not en_sala  # en la sala, los únicos mocos son los jugadores
	$Pie.visible = not online
	$Salir.visible = online
	$Sala.position = Vector2(265, 390) if en_sala else Vector2(740, 560)
	$Sala.separacion = 250.0 if en_sala else 135.0
	$Sala.tarjetas = en_sala
	var solo_yo: Array[int] = [1]
	$Sala.mostrar(Red.ids if online else solo_yo, multiplayer.get_unique_id(), Red.listos)
	if not en_sala:
		config.visible = false
		return
	$SalaUI/Ip.visible = anfitrion  # los amigos ya la escribieron para entrar
	$SalaUI/Ip/Fila/Valor.text = Red.ip_propia()
	$SalaUI/Notita/Caja/Resumen.text = "%d RONDAS · %s\n%s" % [Red.config.rondas, Generador.NOMBRE,
			"CON PODERES" if Red.config.poderes else "SIN PODERES"]
	$Config/Papel/Caja/Poderes.text = "PODERES: " + ("SÍ" if Red.config.poderes else "NO")
	$SalaUI/Notita/Caja/Cambiar.visible = anfitrion
	for n in Red.RONDAS:
		var b = get_node("Config/Papel/Caja/Rondas/R%d" % n)
		b.principal = n == Red.config.rondas  # la elegida lleva la mancha puesta
		b._mostrar(false)
	var amigos := Red.ids.filter(func(id: int) -> bool: return id != 1)
	var listos := amigos.filter(func(id: int) -> bool: return Red.listos.get(id, false)).size()
	if anfitrion:
		principal.text = "¡A CORRER!" if amigos.is_empty() or listos == amigos.size() else "¡A CORRER! · %d/%d LISTOS" % [listos, amigos.size()]
		principal.progreso = 1.0 if amigos.is_empty() else float(listos) / amigos.size()
		$SalaUI/Estado.text = "PASA TU IP A LOS DEMÁS" if amigos.is_empty() else ("" if listos == amigos.size() else "ESPERANDO A QUE ESTÉN LISTOS")
	else:
		var yo_listo: bool = Red.listos.get(multiplayer.get_unique_id(), false)
		principal.text = "¡LISTO! (QUITAR)" if yo_listo else "ESTOY LISTO"
		principal.progreso = -1.0
		$SalaUI/Estado.text = "ESPERANDO AL ANFITRIÓN" if yo_listo else "PULSA CUANDO QUIERAS EMPEZAR"

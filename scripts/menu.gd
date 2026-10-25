# Menú: crear partida, unirse por IP y empezar (solo el anfitrión).
extends Control

@onready var ip: LineEdit = $Caja/IP
@onready var estado: Label = $Caja/Estado
@onready var empezar: Button = $Caja/Empezar


func _ready() -> void:
	Musica.tocar("menu")
	$Caja/Crear.pressed.connect(_crear)
	$Caja/Unirse.pressed.connect(_unirse)
	$Caja/Solo.pressed.connect(_practicar)
	empezar.pressed.connect(func(): Red.empezar_carrera.rpc(randi()))
	Red.jugadores_cambiaron.connect(_actualizar)
	Red.desconectado.connect(func(motivo): estado.text = motivo)
	multiplayer.connected_to_server.connect(func(): estado.text = "Conectado. Esperando a que el anfitrión empiece…")
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


func _actualizar() -> void:
	var anfitrion := Red.es_online() and multiplayer.is_server()
	empezar.visible = anfitrion
	$Caja/Solo.visible = not Red.es_online()  # practicar con la partida abierta dejaría a los demás colgados
	if anfitrion:
		estado.text = "Jugadores: %d/%d" % [Red.ids.size(), Red.MAX_JUGADORES]

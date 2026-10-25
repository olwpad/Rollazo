# Menú: crear partida, unirse por IP, configurar la partida y empezar (solo el anfitrión).
extends Control

@onready var ip: LineEdit = $Caja/Fila/IP
@onready var estado: Label = $Caja/Estado
@onready var empezar: Button = $Caja/Empezar
@onready var listo: Button = $Caja/Listo
@onready var partida: VBoxContainer = $Caja/Partida


func _ready() -> void:
	Musica.tocar("menu")
	$Caja/Crear.pressed.connect(_crear)
	$Caja/Fila/Unirse.pressed.connect(_unirse)
	$Caja/Solo.pressed.connect(_practicar)
	empezar.pressed.connect(func(): Red.empezar_carrera.rpc(randi()))
	listo.pressed.connect(func(): Red.marcar_listo.rpc_id(1, not Red.listos.get(multiplayer.get_unique_id(), false)))
	$Caja/Partida/Rondas/Menos.pressed.connect(_cambiar_rondas.bind(-1))
	$Caja/Partida/Rondas/Mas.pressed.connect(_cambiar_rondas.bind(1))
	partida.get_node("Mapa").titulo = Generador.NOMBRE
	partida.get_node("Mapa").semilla = 2026  # de muestra; cada ronda sale un mapa distinto
	Red.jugadores_cambiaron.connect(_actualizar)
	Red.config_cambiada.connect(_actualizar)
	Red.desconectado.connect(func(motivo): estado.text = motivo)
	multiplayer.connected_to_server.connect(func(): estado.text = "Conectado. Pulsa LISTO cuando quieras")
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


func _cambiar_rondas(paso: int) -> void:
	var i := clampi(Red.RONDAS.find(Red.config.rondas) + paso, 0, Red.RONDAS.size() - 1)
	Red.poner_rondas(Red.RONDAS[i])


func _actualizar() -> void:
	var online := Red.es_online()
	var anfitrion := online and multiplayer.is_server()
	# Ya dentro de una partida: ni practicar, ni crear otra, ni unirse a otra (dejaría a los demás colgados).
	for opcion in [$Caja/Solo, $Caja/Crear, $Caja/Fila]:
		opcion.visible = not online
	partida.visible = online
	$Caja/Partida/Rondas/Valor.text = str(Red.config.rondas)
	for boton: Button in [$Caja/Partida/Rondas/Menos, $Caja/Partida/Rondas/Mas]:
		boton.disabled = not anfitrion  # los demás ven la partida pero no la tocan
		boton.modulate.a = 1.0 if anfitrion else 0.0
	empezar.visible = anfitrion
	var faltan := Red.ids.filter(func(id: int) -> bool: return id != 1 and not Red.listos.get(id, false)).size()
	empezar.disabled = faltan > 0
	empezar.text = "¡Empezar carrera!" if faltan == 0 else "Faltan %d por estar listos" % faltan
	var yo_listo: bool = Red.listos.get(multiplayer.get_unique_id(), false)
	listo.visible = online and not anfitrion and multiplayer.get_unique_id() in Red.ids
	listo.text = "¡Listo! ✓ (quitar)" if yo_listo else "Estoy listo"
	var solo_yo: Array[int] = [1]
	$Sala.mostrar(Red.ids if online else solo_yo, multiplayer.get_unique_id(), Red.listos)
	var mocos := "%d/%d MOCOS · " % [Red.ids.size(), Red.MAX_JUGADORES] if online else ""
	$Pie.text = mocos + "ESC VOLVER · M MÚSICA"
	if anfitrion:
		estado.text = "Pasa tu IP a los demás y pulsa empezar cuando estén listos"

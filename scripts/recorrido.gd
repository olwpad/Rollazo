# Lógica del recorrido: un moco por jugador, cronómetro, puntos de control, caída al vacío,
# meta y reinicio. Las áreas solo las decide el anfitrión.
extends Node2D

const ESCENA_JUGADOR := preload("res://scenes/jugador.tscn")
const CAMARA := preload("res://scripts/camara.gd")

var tiempo := 0.0
var mejor := INF
var corriendo := true
var ultimos_controles := {}  # id de jugador -> último punto de control

@onready var hud := $HUD


func _ready() -> void:
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
	for control: Area2D in $Controles.get_children():
		control.body_entered.connect(_al_pasar_control.bind(control))
	var i := 0
	for dibujo: Polygon2D in find_children("Dibujo", "Polygon2D"):
		_estilo_acuarela(dibujo, i)
		i += 1
	_estilo_acuarela($Meta/Bandera, 99)
	reiniciar()


# Cada forma se pinta como mancha de acuarela, sin contorno: techos enganchables en rosa
# o lavanda, azoteas en lavanda oscuro. Solo cambia el dibujo; la colisión sigue siendo exacta.
func _estilo_acuarela(dibujo: Polygon2D, i: int) -> void:
	var color := Acuarela.MENTA
	if dibujo.get_parent().is_in_group("enganchable"):
		color = Acuarela.ROSA if i % 2 == 0 else Acuarela.LAVANDA
	elif dibujo.get_parent() is StaticBody2D:
		color = Acuarela.AZOTEA
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
	hud.mostrar(tiempo, mejor)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("reiniciar"):
		reiniciar()


# El MultiplayerSpawner llama a esto en todos los PCs con los mismos datos: [id, índice].
func crear_jugador(datos: Array) -> Node:
	var id: int = datos[0]
	var indice: int = datos[1]
	var j: Jugador = ESCENA_JUGADOR.instantiate()
	j.name = str(id)
	j.position = $Inicio.global_position + Vector2(indice * 50, 0)
	j.get_node("Visual/Moco").color = Jugador.COLORES[indice % Jugador.COLORES.size()]
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
	ultimos_controles.clear()
	hud.limpiar()
	if multiplayer.is_server():
		for j in jugadores():
			j.reaparecer($Inicio.global_position)


func _al_pasar_control(cuerpo: Node2D, control: Area2D) -> void:
	if cuerpo is Jugador and multiplayer.is_server():
		ultimos_controles[cuerpo.name] = control.global_position


func _al_caer(cuerpo: Node2D) -> void:
	if cuerpo is Jugador and multiplayer.is_server():
		var punto: Vector2 = ultimos_controles.get(cuerpo.name, $Inicio.global_position)
		cuerpo.reaparecer.call_deferred(punto)  # no mover cuerpos dentro de una señal de física


func _al_llegar(cuerpo: Node2D) -> void:
	if cuerpo == jugador_local() and corriendo:
		corriendo = false
		hud.meta(tiempo, mejor)
		mejor = minf(mejor, tiempo)

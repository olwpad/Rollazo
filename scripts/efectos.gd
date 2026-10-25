# Efectos físicos del jugador (sin texto): salpicadura de moco, goteo, estela y temblor de pantalla.
extends Node2D

const VELOCIDAD_ESTELA := 800.0
const ESTELA_PUNTOS := 10

@onready var jugador: Jugador = get_parent()
@onready var estela: Line2D = $Estela
@onready var salpicadura: CPUParticles2D = $Salpicadura
@onready var goteo: CPUParticles2D = $Goteo


func _ready() -> void:
	top_level = true  # los efectos se quedan en el mundo aunque el jugador se mueva
	# Intensidad según la importancia del evento: enganchar es pequeño, caer y romperse, medio.
	jugador.papel_lanzado.connect(func():
		_salpicar(jugador.papel.ancla)
		_moco().aplastar(Vector2(0.8, 1.25)))
	jugador.aterrizaje_fuerte.connect(func():
		_salpicar(jugador.global_position + Vector2(0, 18))
		_moco().aplastar(Vector2(1.35, 0.65))
		_temblar(0.35))
	jugador.papel_roto.connect(func(): _temblar(0.45))


func _process(_delta: float) -> void:
	goteo.global_position = jugador.global_position
	goteo.emitting = jugador.velocity.length() > 200.0
	if jugador.velocity.length() > VELOCIDAD_ESTELA:
		estela.add_point(jugador.global_position, 0)
		if estela.get_point_count() > ESTELA_PUNTOS:
			estela.remove_point(estela.get_point_count() - 1)
	elif estela.get_point_count() > 0:
		estela.remove_point(estela.get_point_count() - 1)


func _salpicar(pos: Vector2) -> void:
	salpicadura.global_position = pos
	salpicadura.restart()


func _temblar(trauma: float) -> void:
	var camara := get_viewport().get_camera_2d()
	if camara != null and camara.has_method("add_trauma"):
		camara.add_trauma(trauma)


func _moco() -> MocoVisual:
	return jugador.get_node("Visual/Moco")

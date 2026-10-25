# Dibuja el papel del jugador: blanco cuando es nuevo, rojo cuando va a romperse.
extends Line2D

var _ultimo_tramo := [Vector2.ZERO, Vector2.ZERO]

@onready var jugador: Jugador = get_parent()
@onready var trozos: CPUParticles2D = $Trozos


func _ready() -> void:
	top_level = true  # los puntos van en coordenadas del mundo, no del jugador
	jugador.papel_roto.connect(_al_romperse)


func _process(_delta: float) -> void:
	clear_points()
	var papel := jugador.papel
	if papel == null:
		$Contorno.clear_points()
		return
	var ancla := papel.ancla
	if papel.aguante < 0.3:  # tiembla: aviso de que se va a romper
		ancla += Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
	add_point(jugador.global_position)
	add_point(ancla)
	$Contorno.points = points
	default_color = Color.WHITE.lerp(Color(0.9, 0.15, 0.15), 1.0 - papel.aguante)
	_ultimo_tramo = [jugador.global_position, papel.ancla]


func _al_romperse() -> void:
	trozos.global_position = (_ultimo_tramo[0] + _ultimo_tramo[1]) / 2.0
	trozos.restart()

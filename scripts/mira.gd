# Mira de apuntado (solo la ve el dueño del moco): línea de puntos de su color hasta donde
# se engancharía el papel, o un punto gris al máximo alcance si no hay nada enganchable.
# Solo dibuja: el lanzamiento real lo sigue decidiendo el anfitrión.
extends Node2D

const AJUSTES := "user://ajustes.cfg"  # en Windows: %APPDATA%/Godot/app_userdata/Rollazo

static var _activa: Variant = null  # null = aún sin leer del disco

@onready var jugador: Jugador = get_parent()


# Static: compartida por todas las miras, como un campo static de Java.
static func activa() -> bool:
	if _activa == null:
		var cfg := ConfigFile.new()
		cfg.load(AJUSTES)
		_activa = cfg.get_value("juego", "mira", true)
	return _activa


static func alternar() -> void:
	_activa = not activa()
	var cfg := ConfigFile.new()
	cfg.load(AJUSTES)
	cfg.set_value("juego", "mira", _activa)
	cfg.save(AJUSTES)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("mira"):
		alternar()


func _ready() -> void:
	top_level = true  # coordenadas del mundo


# [engancha: bool, punto: Vector2] apuntando hacia `objetivo`.
func calcular(objetivo: Vector2) -> Array:
	var desde := jugador.global_position
	var hasta := desde + (objetivo - desde).normalized() * PapelRope.LARGO_MAX
	var consulta := PhysicsRayQueryParameters2D.create(desde, hasta, 1)  # capa 1: escenario, no mocos
	var choque := get_world_2d().direct_space_state.intersect_ray(consulta)
	if choque and (choque.collider as Node).is_in_group("enganchable"):
		return [true, choque.position]
	return [false, choque.position if choque else hasta]


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if jugador.papel_activo or not activa():
		return
	var r := calcular(get_global_mouse_position())
	var desde := jugador.global_position
	if r[0]:
		var color: Color = jugador.get_node("Visual/Moco").color
		draw_dashed_line(desde, r[1], Color(color, 0.7), 3.0, 10.0)
		draw_circle(r[1], 7.0, color)
	else:
		draw_circle(r[1], 5.0, Color(Acuarela.CIRUELA, 0.25))

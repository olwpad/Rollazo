# Cámara con temblor por "trauma": los golpes suman, el temblor se apaga solo y es suave
# (seno, no azar en cada frame). Mueve solo la vista, nunca al jugador.
extends Camera2D

@export var intensidad := 1.0  # 0 = sin temblor (opción de accesibilidad)
@export var decaimiento := 1.6
@export var desplazamiento_max := Vector2(14, 10)
@export var giro_max := 0.06

var trauma := 0.0
var _t := 0.0


func _ready() -> void:
	ignore_rotation = false


func add_trauma(cantidad: float) -> void:
	trauma = clampf(trauma + cantidad, 0.0, 1.0)


func _process(delta: float) -> void:
	if trauma <= 0.0:
		return
	trauma = maxf(trauma - decaimiento * delta, 0.0)
	var fuerza := trauma * trauma * intensidad
	_t += delta * 30.0
	offset = Vector2(desplazamiento_max.x * fuerza * sin(_t * 1.7), desplazamiento_max.y * fuerza * sin(_t * 2.3))
	rotation = giro_max * fuerza * sin(_t * 1.1)

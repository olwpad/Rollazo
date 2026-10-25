# El papel higiénico enganchado al techo. Lógica pura, sin nodos:
# como un POJO de Java, se puede testear sin abrir el juego.
class_name PapelRope
extends RefCounted

const LARGO_MIN := 40.0
const LARGO_MAX := 420.0

var ancla: Vector2
var largo: float
var aguante: float = 1.0  # 1 = nuevo, 0 = roto
var roto: bool = false
var _segundos_aguante: float


func _init(p_ancla: Vector2, p_largo: float, segundos_aguante: float = 3.0) -> void:
	ancla = p_ancla
	largo = clampf(p_largo, LARGO_MIN, LARGO_MAX)
	_segundos_aguante = segundos_aguante


# tension: 0 colgando tranquilo, sube con los tirones bruscos (ver Pendulo.tension).
func gastar(delta: float, tension: float) -> void:
	aguante -= delta * (1.0 + tension) / _segundos_aguante
	if aguante <= 0.0:
		aguante = 0.0
		roto = true


func cambiar_largo(d: float) -> void:
	largo = clampf(largo + d, LARGO_MIN, LARGO_MAX)

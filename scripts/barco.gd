# Barquito que va y viene por el agua. El mástil con la vela rosa es enganchable y te lleva con
# él (jugador.gd mueve el ancla del papel con el cuerpo). Posición por `reloj_ronda`: igual en todos los PCs.
class_name Barco
extends AnimatableBody2D

const PERIODO := 18.0  # ida y vuelta
const COLOR_CASCO := Color("f2c27a")
const COLOR_VELA := Color("fffaf4")

var riel := 1000.0
var fase := 0.0
var nivel: Node = null
var _base := Vector2.ZERO


func _ready() -> void:
	add_to_group("enganchable")
	sync_to_physics = false  # lo movemos nosotros en _physics_process
	_base = position
	var forma := CollisionShape2D.new()
	forma.shape = RectangleShape2D.new()
	forma.shape.size = Vector2(30.0, 120.0)
	forma.position = Vector2(0, -75)
	add_child(forma)


func _physics_process(_delta: float) -> void:
	if nivel != null:
		position = _base + Vector2(posicion_en(nivel.reloj_ronda), 0)
	queue_redraw()


func posicion_en(t: float) -> float:
	return riel * (1.0 - cos(TAU * (t / PERIODO + fase))) / 2.0


func _draw() -> void:
	var t: float = nivel.reloj_ronda if nivel != null else 0.0
	var dir := 1.0 if sin(TAU * (t / PERIODO + fase)) >= 0.0 else -1.0  # la proa mira a donde va
	draw_set_transform(Vector2(0, sin(t * 2.0 + fase * 9.0) * 3.0), 0.0, Vector2(dir, 1.0))  # cabecea con las olas
	Moviles.mancha(self, PackedVector2Array([Vector2(-48, -14), Vector2(48, -14), Vector2(30, 14), Vector2(-30, 14)]), COLOR_CASCO, 41)
	draw_rect(Rect2(-2.5, -130, 5, 118), Color("a98a6a"))
	Moviles.mancha(self, PackedVector2Array([Vector2(3, -126), Vector2(34, -50), Vector2(3, -50)]), COLOR_VELA, 42)
	Moviles.mancha(self, PackedVector2Array([Vector2(-18, -138), Vector2(18, -138), Vector2(18, -126), Vector2(-18, -126)]), Acuarela.ROSA, 43)

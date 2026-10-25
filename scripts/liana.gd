# Liana que se mece sola como un péndulo: la punta rosa es enganchable y te arrastra con su
# vaivén. El ángulo sale de `reloj_ronda`, igual en todos los PCs. La ropa tendida (Prenda) es lo mismo.
class_name Liana
extends AnimatableBody2D

var pivote := Vector2.ZERO  # de dónde cuelga (global)
var largo := 170.0
var amplitud := 0.5  # radianes a cada lado
var periodo := 3.2
var fase := 0.0
var nivel: Node = null


func _ready() -> void:
	add_to_group("enganchable")
	sync_to_physics = false  # lo movemos nosotros en _physics_process
	var forma := CollisionShape2D.new()
	forma.shape = CircleShape2D.new()
	forma.shape.radius = 16.0
	add_child(forma)
	_mover(0.0)


func _physics_process(_delta: float) -> void:
	if nivel != null:
		_mover(nivel.reloj_ronda)
	queue_redraw()


func angulo_en(t: float) -> float:
	return amplitud * sin(TAU * (t / periodo + fase))


func punta_en(t: float) -> Vector2:
	var a := angulo_en(t)
	return pivote + largo * Vector2(sin(a), cos(a))


func _mover(t: float) -> void:
	position = punta_en(t)
	rotation = angulo_en(t)


func _draw() -> void:
	var p := to_local(pivote)
	Moviles.mancha(self, _hojas(p), Color("7fae6a"), 51)  # el follaje de donde cuelga
	draw_line(p, Vector2.ZERO, Color("5e9150"), 5.0, true)
	Moviles.mancha(self, Moviles.elipse(12, 8), Acuarela.ROSA, 52)


# La elipse del follaje, contrarrestando el giro del nodo para que no se incline.
func _hojas(centro: Vector2) -> PackedVector2Array:
	var poly := Moviles.elipse(36, 16)
	for i in poly.size():
		poly[i] = centro + poly[i].rotated(-rotation)
	return poly

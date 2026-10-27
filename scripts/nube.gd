# Nube de tormenta: zona que fulmina a quien entra (lo decide el anfitrión, recorrido.gd).
# Va pegada a la cara de arriba de un techo ("techo") o es una columna de cielo prohibido sobre
# la ruta ("cielo"). Aquí solo hay forma y dibujo: nubecitas lila oscuro con una calima encima.
class_name Nube
extends Area2D

const COLOR := Color("8f86b8")

var poly := PackedVector2Array()  # en coordenadas globales (la nube se queda en el origen)
var tipo := "techo"
var _nubes := Node2D.new()  # las nubecitas flotan solas: se mueve este nodo, sin redibujar
var _caja := Rect2()


func _ready() -> void:
	collision_mask = 2  # solo mocos
	var forma := CollisionPolygon2D.new()
	forma.polygon = poly
	add_child(forma)
	_caja = Rect2(poly[0], Vector2.ZERO)
	for v in poly:
		_caja = _caja.expand(v)
	_nubes.draw.connect(_dibujar_nubes)
	add_child(_nubes)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	_nubes.position = Vector2(sin(t * 0.5 + _caja.position.x) * 8.0, sin(t * 0.8 + _caja.position.x * 0.01) * 5.0)


func _draw() -> void:
	# Calima: solo la franja de abajo en el cielo (la columna llega muy arriba)
	var alto := minf(_caja.size.y, 120.0)
	draw_rect(Rect2(_caja.position.x, _caja.end.y - alto, _caja.size.x, alto), Color(COLOR, 0.16))


func _dibujar_nubes() -> void:
	var y := _caja.end.y - 10.0 if tipo == "cielo" else _caja.position.y - 8.0  # cielo: colgando del borde de abajo
	var n := maxi(1, int(_caja.size.x / 90.0))
	for i in n:
		var x := _caja.position.x + (i + 0.5) * _caja.size.x / n
		var rx := 55.0 + 12.0 * ((i * 7 + int(_caja.position.x)) % 3)
		Moviles.mancha(_nubes, Transform2D(0.0, Vector2(x, y + (i % 2) * 14.0 - 14.0)) * Moviles.elipse(rx, rx * 0.45), COLOR, i + int(_caja.position.x))

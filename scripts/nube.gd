# Nube de tormenta: zona que fulmina a quien entra (lo decide el anfitrión, recorrido.gd).
# Va pegada a la cara de arriba de un techo ("techo") o es una columna de cielo prohibido sobre
# la ruta ("cielo"). Aquí solo hay forma y dibujo: nubecitas lila oscuro con una calima encima.
class_name Nube
extends Area2D

const COLOR := Color("7f8c99")  # gris de tormenta (el lila se confundía con los techos)
const CHISPA := Color("f5d38a")

var poly := PackedVector2Array()  # en coordenadas globales (la nube se queda en el origen)
var tipo := "techo"
var _nubes := Node2D.new()  # las nubecitas flotan solas: se mueve este nodo, sin redibujar
var _caja := Rect2()
var _visible := true


func _ready() -> void:
	collision_mask = 2  # solo mocos
	var forma := CollisionPolygon2D.new()
	forma.polygon = poly
	add_child(forma)
	_caja = Rect2(poly[0], Vector2.ZERO)
	for v in poly:
		_caja = _caja.expand(v)
	# Los techos avisan siempre; del cielo solo se ven algunas (quien vuela tan alto ya hace trampa)
	_visible = tipo == "techo" or hash(int(_caja.position.x / 10.0)) % 3 == 0
	_nubes.draw.connect(_dibujar_nubes)
	add_child(_nubes)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	_nubes.position = Vector2(sin(t * 0.5 + _caja.position.x) * 8.0, sin(t * 0.8 + _caja.position.x * 0.01) * 5.0)
	if tipo == "techo" and _visible:
		queue_redraw()  # las chispas parpadean


func _draw() -> void:
	if tipo == "cielo" or not _visible:
		return
	# Techo: chispitas amarillas que saltan de vez en cuando entre las nubecitas
	var t := Time.get_ticks_msec() / 1000.0
	var n := maxi(1, int(_caja.size.x / 45.0))
	for i in n:
		if sin(t * 2.3 + i * 1.7 + _caja.position.x) < 0.93:
			continue
		var x := _caja.position.x + (i + 0.5) * _caja.size.x / n
		var y := _caja.end.y - 24.0
		draw_polyline(PackedVector2Array([Vector2(x - 3, y - 14), Vector2(x + 4, y - 6), Vector2(x - 2, y - 4), Vector2(x + 3, y + 4)]), CHISPA, 2.5)


func _dibujar_nubes() -> void:
	if not _visible:
		return
	if tipo == "techo":  # nubecitas bajas pegadas a la cara de arriba: avisan sin tapar el mapa
		var m := maxi(1, int(_caja.size.x / 45.0))
		for i in m:
			var x := _caja.position.x + (i + 0.5) * _caja.size.x / m
			var rx := 18.0 + 5.0 * ((i * 7 + int(_caja.position.x)) % 3)
			Moviles.mancha(_nubes, Transform2D(0.0, Vector2(x, _caja.end.y - 14.0 - (i % 2) * 5.0)) * Moviles.elipse(rx, rx * 0.5), Color(COLOR, 0.8), i + int(_caja.position.x))
		return
	var rx := 55.0 + 12.0 * (int(_caja.position.x) % 3)  # cielo: una nube colgando del borde de abajo
	Moviles.mancha(_nubes, Transform2D(0.0, Vector2(_caja.get_center().x, _caja.end.y - 24.0)) * Moviles.elipse(rx, rx * 0.45), COLOR, int(_caja.position.x))

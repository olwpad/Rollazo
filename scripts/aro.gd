# Aro de fuego: quema solo el borde; por el centro se pasa. Puede estar quieto o subir y bajar.
# Quién se quema lo decide el anfitrión (recorrido.gd); aquí solo hay forma y dibujo.
extends Area2D

const RX := 36.0
const RY := 82.0
const GROSOR := 10.0  # radio de cada bolita de la zona que quema
const SUBIDA := 70.0  # cuánto sube y baja el que se mueve
const PERIODO := 3.2

const LLAMA := Color("f2a07f")
const BRASA := Color("f5d38a")

var mov := "quieto"
var _base := Vector2.ZERO
var _t := 0.0


func _ready() -> void:
	collision_mask = 2  # solo mocos
	_base = position
	for i in 16:  # bolitas a lo largo del borde: el hueco del centro no quema
		var forma := CollisionShape2D.new()
		forma.shape = CircleShape2D.new()
		forma.shape.radius = GROSOR
		forma.position = _punto(TAU * i / 16.0)
		add_child(forma)


func _physics_process(delta: float) -> void:
	# shortcut: cada PC lleva su reloj, así que el aro que sube puede ir algo desfasado entre PCs;
	# quema lo que ve el anfitrión. Si se nota, sincronizar con el tiempo de ronda del anfitrión.
	_t += delta
	if mov == "sube":
		position.y = _base.y + sin(_t * TAU / PERIODO) * SUBIDA
	queue_redraw()


func _punto(angulo: float, crecer := 0.0) -> Vector2:
	return Vector2(cos(angulo) * (RX + crecer), sin(angulo) * (RY + crecer))


func _draw() -> void:
	var foto := Tinta.fotograma()
	var anillo := PackedVector2Array()
	for i in 33:
		anillo.append(_punto(TAU * i / 32.0))
	draw_polyline(Tinta.temblar(anillo, 3, foto, 2.0), Color(LLAMA, 0.55), GROSOR * 2.4)  # dos capas, como acuarela
	draw_polyline(Tinta.temblar(anillo, 5, foto, 2.0), Color(LLAMA, 0.6), GROSOR * 1.5)
	draw_polyline(anillo, BRASA, 4.0)
	for i in 7:  # lenguas de fuego hacia fuera, que hierven a 12 fps
		var a := TAU * i / 7.0 + 0.3
		var lengua := PackedVector2Array([_punto(a - 0.18, 6.0), _punto(a, 26.0 + 8.0 * sin(foto * 1.7 + i)), _punto(a + 0.18, 6.0)])
		draw_colored_polygon(Tinta.temblar(lengua, i, foto, 2.5), Color(LLAMA, 0.7))

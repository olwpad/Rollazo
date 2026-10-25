# Aro de fuego de circo visto de lado: quema el arco de arriba y el de abajo; por el centro se pasa. Puede estar quieto o subir y bajar.
# Quién se quema lo decide el anfitrión (recorrido.gd); aquí solo hay forma y dibujo.
extends Area2D

const RX := 34.0  # estrecho: es la perspectiva del aro, no un muro
const RY := 100.0  # hueco de ~180 de alto: el moco mide 84
const GROSOR := 10.0  # radio de cada bolita de la zona que quema
const SUBIDA := 70.0  # cuánto sube y baja el que se mueve
const PERIODO := 3.2

const LLAMA := Color("f2a07f")
const BRASA := Color("f5d38a")

var mov := "quieto"
var _base := Vector2.ZERO
var _t := 0.0
var _frente := Node2D.new()  # la mitad derecha del aro, por delante del moco que lo cruza


func _ready() -> void:
	collision_mask = 2  # solo mocos
	_base = position
	_frente.z_index = 5
	_frente.draw.connect(_pintar.bind(_frente, -PI / 2.0))
	add_child(_frente)
	for i in 16:  # bolitas solo arriba y abajo: los lados son la perspectiva, por ahí se entra
		if absf(sin(TAU * i / 16.0)) < 0.7:
			continue
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
	_frente.queue_redraw()


func _punto(angulo: float, crecer := 0.0) -> Vector2:
	return Vector2(cos(angulo) * (RX + crecer), sin(angulo) * (RY + crecer))


func _draw() -> void:
	_pintar(self, PI / 2.0)  # mitad izquierda, por detrás


# Media vuelta del aro (de `desde` a `desde + PI`) sobre `lienzo`.
func _pintar(lienzo: CanvasItem, desde: float) -> void:
	var foto := Tinta.fotograma()
	var anillo := PackedVector2Array()
	for i in 17:
		anillo.append(_punto(desde + PI * i / 16.0))
	lienzo.draw_polyline(Tinta.temblar(anillo, 3, foto, 2.0), Color(LLAMA, 0.55), GROSOR * 2.4)  # dos capas, como acuarela
	lienzo.draw_polyline(Tinta.temblar(anillo, 5, foto, 2.0), Color(LLAMA, 0.6), GROSOR * 1.5)
	lienzo.draw_polyline(anillo, BRASA, 4.0)
	for i in 4:  # lenguas de fuego hacia fuera, que hierven a 12 fps
		var a := desde + PI * (i + 0.5) / 4.0
		var lengua := PackedVector2Array([_punto(a - 0.18, 6.0), _punto(a, 26.0 + 8.0 * sin(foto * 1.7 + i + desde)), _punto(a + 0.18, 6.0)])
		lienzo.draw_colored_polygon(Tinta.temblar(lengua, i, foto, 2.5), Color(LLAMA, 0.7))

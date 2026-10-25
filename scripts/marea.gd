# Marea del muelle: agua que sube y baja despacio. Tocarla = como caer (lo decide el anfitrión,
# recorrido.gd); aquí solo hay nivel, movimiento y dibujo.
class_name Marea
extends Area2D

const PERIODO := 18.0
const MARGEN := 300.0  # la marea alta queda al menos esto bajo el techo más bajo del camino
const SUBE_MAX := 320.0
const AGUA := Color("8fc9d9", 0.8)

var base_y := 1000.0  # el nivel más bajo
var sube := 0.0  # cuánto sube a marea alta
var fase := 0.0  # en vueltas (0..1)
var nivel: Node = null  # el recorrido: su `reloj_ronda` mueve el agua igual en todos los PCs
var desde_x := 0.0
var hasta_x := 1.0


static func nueva(semilla: int, m: Dictionary, nivel_: Node) -> Marea:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(semilla, 31))
	var a := Marea.new()
	a.name = "Marea"
	a.base_y = maxf(m.caida_y - 300.0, m.limites.end.y)  # donde ya están las olas del fondo
	var techo_bajo := -INF  # el más bajo en pantalla = mayor y
	for c: Vector2 in m.camino:
		techo_bajo = maxf(techo_bajo, c.y)
	a.sube = clampf(a.base_y - (techo_bajo + MARGEN), 0.0, SUBE_MAX)
	a.fase = rng.randf()
	a.desde_x = m.limites.position.x - 2000.0
	a.hasta_x = m.limites.end.x + 2000.0
	a.nivel = nivel_
	return a


func _ready() -> void:
	collision_mask = 2  # solo mocos
	z_index = 5  # delante de los mocos, como las olas del fondo
	var forma := CollisionShape2D.new()
	forma.shape = RectangleShape2D.new()
	forma.shape.size = Vector2(hasta_x - desde_x, 1200.0)
	forma.position = Vector2((desde_x + hasta_x) / 2.0, 600.0)
	add_child(forma)
	_mover()


func _physics_process(_delta: float) -> void:
	_mover()
	queue_redraw()


func _mover() -> void:
	position.y = y_en(nivel.reloj_ronda if nivel != null else 0.0)


# Altura de la superficie en el segundo `t`: sale de abajo, sube a mitad de periodo y baja.
func y_en(t: float) -> float:
	return base_y - sube * (1.0 - cos(TAU * (t / PERIODO + fase))) / 2.0


func _draw() -> void:
	var inv := get_canvas_transform().affine_inverse()
	var vista := get_viewport().get_visible_rect()
	var izq := snappedf((inv * vista.position).x - 120.0, 40.0)  # solo lo que se ve: el agua mide miles de px
	var der := (inv * vista.end).x + 120.0
	var t := Time.get_ticks_msec() / 1000.0
	var ola := PackedVector2Array()
	var x := izq
	while x <= der:
		ola.append(Vector2(x, sin(x / 70.0 + t * 1.8) * 7.0))
		x += 40.0
	var relleno := ola.duplicate()
	relleno.append(Vector2(der, 900.0))
	relleno.append(Vector2(izq, 900.0))
	draw_colored_polygon(relleno, AGUA)
	draw_polyline(ola, Color(1, 1, 1, 0.55), 4.0)  # espuma

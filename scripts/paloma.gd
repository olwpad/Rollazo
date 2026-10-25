# Paloma que cruza el mapa volando. Si la tocas te empuja (lo aplica el anfitrión, recorrido.gd);
# aquí solo hay trayectoria, forma y dibujo.
class_name Paloma
extends Area2D

const VEL := 300.0  # px/s
const RADIO := 24.0
const EMPUJE := Vector2(430.0, -230.0)  # x se multiplica por `dir`

var dir := 1.0  # 1 = de izquierda a derecha, -1 al revés
var fase := 0.0  # en vueltas (0..1)
var y := 400.0
var desde := 0.0  # el vuelo va de `desde` a `desde + largo`
var largo := 1000.0
var nivel: Node = null
var golpeados := {}  # nombre de moco -> ms del último empujón: una paloma no lo empuja dos veces seguidas


static func nuevas(semilla: int, m: Dictionary, nivel_: Node) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(semilla, 33))
	var lista := []
	for i in rng.randi_range(3, 5):
		var p := Paloma.new()
		p.name = "Paloma%d" % i
		var c: Vector2 = m.camino[rng.randi_range(0, m.camino.size() - 1)]
		p.y = c.y + rng.randf_range(-60.0, 240.0)  # a la altura de donde se columpia
		p.dir = 1.0 if i % 2 == 0 else -1.0
		p.fase = rng.randf()
		p.desde = m.limites.position.x - 300.0
		p.largo = m.limites.size.x + 600.0
		p.nivel = nivel_
		lista.append(p)
	return lista


func posicion_en(t: float) -> Vector2:
	var u := fposmod(t * VEL / largo + fase, 1.0)
	return Vector2(desde + (u if dir > 0.0 else 1.0 - u) * largo, y + sin(t * 2.0 + fase * TAU) * 30.0)


func _ready() -> void:
	collision_mask = 2  # solo mocos
	var forma := CollisionShape2D.new()
	forma.shape = CircleShape2D.new()
	forma.shape.radius = RADIO
	add_child(forma)
	position = posicion_en(0.0 if nivel == null else nivel.reloj_ronda)
	scale.x = dir  # mira hacia donde vuela


func _physics_process(_delta: float) -> void:
	position = posicion_en(nivel.reloj_ronda if nivel != null else 0.0)
	queue_redraw()


# Empuja a `cuerpo` salvo que ya lo haya hecho hace poco; true si lo empujó.
func empujar(cuerpo: Node2D) -> bool:
	var ahora := Time.get_ticks_msec()
	if ahora - golpeados.get(cuerpo.name, -100000) < 800:
		return false
	golpeados[cuerpo.name] = ahora
	cuerpo.velocity += Vector2(EMPUJE.x * dir, EMPUJE.y)
	return true


func _draw() -> void:
	var aleteo := sin(Time.get_ticks_msec() / 90.0 + fase * TAU)
	var cuerpo := Color("e9e4f2")
	draw_colored_polygon(PackedVector2Array([Vector2(-6, -4), Vector2(-26, -2 + aleteo * 3.0), Vector2(-8, 8), Vector2(14, 8), Vector2(18, -2), Vector2(8, -8)]), cuerpo)  # cuerpo y cola
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -2), Vector2(-12, -22 * aleteo - 6), Vector2(6, -4)]), cuerpo.darkened(0.12))  # ala
	draw_circle(Vector2(16, -8), 7.0, cuerpo)
	draw_colored_polygon(PackedVector2Array([Vector2(22, -9), Vector2(30, -6), Vector2(22, -6)]), Color("f5b38a"))  # pico
	draw_circle(Vector2(18, -10), 1.6, Acuarela.CIRUELA)

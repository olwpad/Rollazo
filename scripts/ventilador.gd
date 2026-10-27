# Ventilador que sopla un chorro de viento hacia arriba o de lado. El anfitrión empuja a quien
# esté dentro del chorro (los demás PCs reciben la posición por el Sync); aquí hay sitio, forma,
# empuje y dibujo. Las aspas y las rayas de viento salen de `nivel.reloj_ronda`: iguales en todos los PCs.
class_name Ventilador
extends Area2D

const ANCHO := 120.0  # del chorro
const LARGO := Vector2(500.0, 700.0)  # (mín, máx)
const ACEL_ARRIBA := 2000.0  # px/s²: gana a la gravedad (1400) pero con poco sobrante
const ACEL_LADO := 1200.0  # de lado no hay gravedad que vencer: un empujón suave
const RAYAS := 8

var dir := Vector2.UP
var largo := 600.0
var nivel: Node = null


# Entre 1 y 3 por mapa, en los huecos entre dos techos seguidos de un tramo horizontal o de bajada:
# soplando hacia arriba desde debajo del hueco o de lado a lo ancho de él. Si no cabe, no se pone.
static func nuevos(semilla: int, m: Dictionary, nivel_: Node) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(semilla, 61))
	var huecos := []
	for t: Dictionary in m.tramos:
		if t.tipo in ["horizontal", "bajada"]:
			for i in range(t.i0 + 1, t.i1):
				huecos.append([m.camino[i - 1], m.camino[i]])
	var lista := []
	var zonas: Array[Rect2] = []
	var quiere := rng.randi_range(1, 3)
	for intento in 30:
		if lista.size() >= quiere or huecos.is_empty():
			break
		var h: Array = huecos[rng.randi_range(0, huecos.size() - 1)]
		var v := Ventilador.new()
		v.nivel = nivel_
		v.dir = [Vector2.UP, Vector2.RIGHT, Vector2.LEFT][rng.randi_range(0, 2)]
		v.largo = rng.randf_range(LARGO.x, LARGO.y)
		var medio: float = (h[0].x + h[1].x) / 2.0
		var bajo: float = maxf(h[0].y, h[1].y)
		if v.dir == Vector2.UP:
			v.position = Vector2(medio, bajo + 330.0)  # a la altura del suelo, bajo el hueco
		else:
			v.position = Vector2(medio - v.dir.x * 250.0, bajo + 170.0)  # donde se columpia, cruzando el hueco
		var zona := v.zona()
		var libre := not Moviles.ocupado(m, zona) and not zona.grow(400.0).has_point(m.inicio) and not zona.grow(400.0).has_point(m.meta) \
				and zonas.all(func(z: Rect2) -> bool: return not z.grow(100.0).intersects(zona))
		if libre:
			v.name = "Ventilador%d" % lista.size()
			lista.append(v)
			zonas.append(zona)
		else:
			v.free()
	return lista


# El rectángulo que ocupa el ventilador con su chorro (en coordenadas globales).
func zona() -> Rect2:
	var chorro := Rect2(position + dir * largo / 2.0 - _tam() / 2.0, _tam())
	return chorro.merge(Rect2(position - Vector2(45, 45), Vector2(90, 90)))


func _tam() -> Vector2:
	return Vector2(ANCHO, largo) if dir.x == 0.0 else Vector2(largo, ANCHO)


# Cuánto empuja a una fracción `f` del largo del chorro (0 = el ventilador, 1 = la punta): entero
# hasta la mitad y luego se apaga hasta cero, así el moco flota en la punta en vez de salir disparado.
static func fuerza_en(f: float) -> float:
	return clampf(2.0 - 2.0 * f, 0.0, 1.0)


# Aceleración que le toca a quien está en `local` (relativo al ventilador).
func aceleracion_en(local: Vector2) -> Vector2:
	var f := local.dot(dir) / largo
	return dir * (ACEL_ARRIBA if dir == Vector2.UP else ACEL_LADO) * fuerza_en(f)


func _ready() -> void:
	collision_mask = 2  # solo mocos
	var forma := CollisionShape2D.new()
	forma.shape = RectangleShape2D.new()
	forma.shape.size = _tam()
	forma.position = dir * largo / 2.0
	add_child(forma)


func _physics_process(delta: float) -> void:
	queue_redraw()
	if not multiplayer.is_server():
		return
	for c in get_overlapping_bodies():
		if c is Jugador and not c.congelado:
			c.velocity += aceleracion_en(c.global_position - global_position) * delta


func _draw() -> void:
	var t: float = nivel.reloj_ronda if nivel != null else 0.0
	var lado := dir.rotated(PI / 2.0)
	# El chorro: una calima suave y rayas crema que lo recorren de la boca a la punta
	draw_colored_polygon(PackedVector2Array([-lado * ANCHO / 2.0, lado * ANCHO / 2.0, lado * ANCHO / 2.0 + dir * largo, -lado * ANCHO / 2.0 + dir * largo]), Color(Acuarela.LAVANDA, 0.12))
	for k in RAYAS:
		var u := fposmod(t * 0.9 + k * 0.37, 1.0)
		var ancho := (fposmod(k * 0.618, 1.0) - 0.5) * (ANCHO - 20.0)
		var a := lado * ancho + dir * (50.0 + u * (largo - 130.0))
		draw_line(a, a + dir * 46.0, Color(1.0, 0.98, 0.96, 0.85 * sin(u * PI)), 4.0)
	# El ventilador: jaula lavanda, tres aspas menta y un cubo crema, sobre un pie corto
	draw_line(Vector2(0, 30), Vector2(0, 62), Acuarela.LAVANDA.darkened(0.15), 8.0)
	draw_circle(Vector2.ZERO, 38.0, Acuarela.LAVANDA.lightened(0.35))
	for k in 3:
		var giro := t * 14.0 + k * TAU / 3.0
		var aspa := Transform2D(giro, Vector2.ZERO) * Transform2D(0.0, Vector2(0, -19)) * Moviles.elipse(9.0, 19.0)
		draw_colored_polygon(aspa, Color(Acuarela.MENTA, 0.9))
	draw_arc(Vector2.ZERO, 36.0, 0.0, TAU, 24, Acuarela.LAVANDA, 5.0)
	draw_circle(Vector2.ZERO, 6.0, Color("fffaf4"))

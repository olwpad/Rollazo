# Guirnalda de bombillas entre dos techos del camino: parpadean de adorno (sin reglas de juego).
class_name Guirnalda
extends Node2D

const COLORES := [Color("f5d38a"), Color("f58aa8"), Color("8ec5e8"), Color("c7d97a")]
const BOMBILLAS := 9

var a := Vector2.ZERO  # de a a b, globales
var b := Vector2.ZERO
var fase := 0
var nivel: Node = null


static func nuevas(semilla: int, m: Dictionary, nivel_: Node) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(semilla, 34))
	var lista := []
	for i in range(1, m.camino.size()):
		var p: Vector2 = m.camino[i - 1] + Vector2(110, 25)  # del borde de un techo al del siguiente
		var q: Vector2 = m.camino[i] + Vector2(-110, 25)
		if q.x - p.x < 120.0 or rng.randf() > 0.55:
			continue
		var g := Guirnalda.new()
		g.name = "Guirnalda%d" % lista.size()
		g.a = p
		g.b = q
		g.fase = rng.randi_range(0, 3)
		g.nivel = nivel_
		lista.append(g)
	return lista


# La bombilla k está encendida en el segundo `t`: parpadean a su ritmo, 2 veces por segundo.
func encendida(k: int, t: float) -> bool:
	return (int(t * 2.0) + k * 2 + fase) % 3 != 0


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t: float = nivel.reloj_ronda if nivel != null else 0.0
	var cable := PackedVector2Array()
	for k in BOMBILLAS + 2:
		var u := k / float(BOMBILLAS + 1)
		cable.append(a.lerp(b, u) + Vector2(0, sin(u * PI) * 70.0))
	draw_polyline(cable, Acuarela.CIRUELA.lightened(0.3), 3.0)
	for k in BOMBILLAS:
		var p := cable[k + 1] + Vector2(0, 9)
		var c: Color = COLORES[(k + fase) % COLORES.size()]
		if encendida(k, t):
			draw_circle(p, 17.0, Color(c, 0.22))  # resplandor
			draw_circle(p, 8.0, c)
		else:
			draw_circle(p, 7.0, c.darkened(0.45))

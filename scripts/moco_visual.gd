# El moco: se dibuja con código. Tiembla, se estira hacia donde va y tiene los ojos desiguales.
class_name MocoVisual
extends Node2D

const RADIO := 22.0
const COLOR_MOCO := Color(0.21, 0.84, 0.91)

var velocidad := Vector2.ZERO  # la pone el Jugador cada frame


# Puntos del contorno. Estática y pura para poder testearla sin abrir el juego.
static func forma(n: int, t: float, vel: Vector2) -> PackedVector2Array:
	var estiron := clampf(vel.length() / 1500.0, 0.0, 0.6)
	var dir := vel.normalized() if vel.length() > 1.0 else Vector2.RIGHT
	var puntos := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		var r := RADIO * (1.0 + 0.06 * sin(3.0 * a + t * 5.0) + 0.04 * sin(5.0 * a - t * 7.0))
		var p := Vector2(cos(a), sin(a)) * r
		var a_lo_largo := p.dot(dir)
		var lateral := p - dir * a_lo_largo
		puntos.append(dir * a_lo_largo * (1.0 + estiron) + lateral * (1.0 - estiron * 0.4))
	return puntos


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var contorno := forma(28, t, velocidad)
	draw_colored_polygon(contorno, COLOR_MOCO)
	var cerrado := contorno.duplicate()
	cerrado.append(contorno[0])
	draw_polyline(cerrado, Color.BLACK, 5.0, true)
	draw_circle(Vector2(-9, -12), 5.0, Color(1, 1, 1, 0.55))  # brillo viscoso
	var mira := velocidad.normalized() * 3.0 if velocidad.length() > 30.0 else Vector2.ZERO
	_ojo(Vector2(-6, -4), 9.0, mira)
	_ojo(Vector2(9, -7), 5.5, mira)
	draw_arc(Vector2(2, 8), 6.0, 0.3, PI - 0.3, 8, Color.BLACK, 3.0)


func _ojo(centro: Vector2, radio: float, mira: Vector2) -> void:
	draw_circle(centro, radio, Color.WHITE)
	draw_arc(centro, radio, 0.0, TAU, 16, Color.BLACK, 2.5)
	draw_circle(centro + mira, radio * 0.45, Color.BLACK)

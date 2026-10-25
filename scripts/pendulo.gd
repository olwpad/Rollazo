# Matemática del columpio. Funciones estáticas, como una clase utilitaria de Java (Math).
class_name Pendulo
extends RefCounted


# Si el jugador está más lejos del ancla que el largo del papel, lo vuelve a poner
# sobre el círculo y le quita la velocidad que lo alejaba. La tangencial se conserva:
# eso es lo que hace que se columpie.
# Devuelve [pos_nueva, vel_nueva, velocidad_radial_quitada].
static func restringir(pos: Vector2, vel: Vector2, ancla: Vector2, largo: float) -> Array:
	var desde_ancla := pos - ancla
	if desde_ancla.length() <= largo:
		return [pos, vel, 0.0]
	var dir := desde_ancla.normalized()
	var radial := vel.dot(dir)
	var vel_nueva := vel
	if radial > 0.0:
		vel_nueva -= dir * radial
	return [ancla + dir * largo, vel_nueva, maxf(radial, 0.0)]


# Un tirón brusco (mucha velocidad radial quitada de golpe) gasta más papel.
static func tension(vel_radial_quitada: float) -> float:
	return clampf(vel_radial_quitada / 600.0, 0.0, 2.0)

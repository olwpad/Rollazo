# Cálculos sueltos de geometría (métodos static, como una clase de utilidades en Java).
class_name Geometria
extends RefCounted


# Distancia de un punto al trozo de recta entre a y b (no a la recta infinita).
static func distancia_a_segmento(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	if ab.length_squared() == 0.0:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)

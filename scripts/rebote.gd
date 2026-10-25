# Rebote entre dos mocos de igual masa: se intercambian la velocidad en la dirección del
# choque (como bolas de billar) y se amplifica un poco para que sea exagerado y gracioso.
# Lo de lado (tangencial) no se toca. Como un método static de Java: sin estado.
class_name Rebote


static func calcular(v1: Vector2, v2: Vector2, normal: Vector2, rebote := 1.2) -> Array:
	var n := normal.normalized()
	var n1 := v1.dot(n)
	var n2 := v2.dot(n)
	return [v1 + n * (n2 * rebote - n1), v2 + n * (n1 * rebote - n2)]

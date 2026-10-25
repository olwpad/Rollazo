# Trazo "a mano": formas irregulares y tinta que hierve a 12 fps, como la animación
# "a doses" de Spider-Verse. Funciones puras: mismo fotograma + semilla = mismo dibujo.
class_name Tinta
extends RefCounted

const FPS := 12


static func fotograma(ms: int = -1) -> int:
	if ms < 0:
		ms = Time.get_ticks_msec()
	return ms * FPS / 1000


# Mueve cada punto un poco, distinto en cada fotograma.
static func temblar(puntos: PackedVector2Array, semilla: int, foto: int, amplitud: float) -> PackedVector2Array:
	var salida := PackedVector2Array()
	for i in puntos.size():
		salida.append(puntos[i] + _ruido(semilla, foto, i) * amplitud)
	return salida


# Convierte un polígono perfecto en uno dibujado a mano: parte los lados largos
# cada `paso` píxeles y desplaza los puntos al azar (fijo para cada semilla).
static func irregular(puntos: PackedVector2Array, semilla: int, amplitud: float, paso: float) -> PackedVector2Array:
	var salida := PackedVector2Array()
	for i in puntos.size():
		var a := puntos[i]
		var b := puntos[(i + 1) % puntos.size()]
		var trozos := maxi(1, int(a.distance_to(b) / paso))
		for k in trozos:
			salida.append(a.lerp(b, float(k) / trozos))
	return temblar(salida, semilla, 0, amplitud)


static func _ruido(semilla: int, foto: int, i: int) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(semilla, foto, i))
	return Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))

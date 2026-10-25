# Una fila de edificios dibujada a mano con código: tejados torcidos, antenas, depósitos de agua,
# ventanas desiguales y un "fantasma" cian desplazado como impresión de cómic mal alineada.
extends Node2D

@export var semilla := 1
@export var ancho_total := 2400.0
@export var base_y := 900.0
@export var alto_min := 250.0
@export var alto_max := 700.0
@export var color_edificio := Color(0.08, 0.03, 0.15)
@export var con_ventanas := true

const TINTA := Color(0.02, 0.0, 0.05)


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var x := 0.0
	var n := 0
	while x < ancho_total:
		var ancho := rng.randf_range(90.0, 200.0)
		var alto := rng.randf_range(alto_min, alto_max)
		var techo_i := base_y - alto + rng.randf_range(-10.0, 10.0)
		var techo_d := base_y - alto + rng.randf_range(-10.0, 10.0)
		var der := x + ancho - 12.0
		var silueta := Tinta.irregular(PackedVector2Array([
			Vector2(x, techo_i), Vector2(der, techo_d), Vector2(der, base_y + 800.0), Vector2(x, base_y + 800.0)
		]), semilla * 100 + n, 2.0, 60.0)
		var fantasma := PackedVector2Array()
		for p in silueta:
			fantasma.append(p + Vector2(-6, 0))
		draw_colored_polygon(fantasma, Color(0.0, 0.9, 1.0, 0.35))
		draw_colored_polygon(silueta, color_edificio)
		_tejado(rng, x, der, minf(techo_i, techo_d))
		if con_ventanas:
			_ventanas(rng, x, der, maxf(techo_i, techo_d))
		x += ancho
		n += 1


func _tejado(rng: RandomNumberGenerator, izq: float, der: float, techo: float) -> void:
	var suerte := rng.randf()
	var cx := rng.randf_range(izq + 20.0, der - 20.0)
	if suerte < 0.35:  # antena
		draw_line(Vector2(cx, techo), Vector2(cx + rng.randf_range(-4, 4), techo - 50.0), TINTA, 3.0)
		draw_circle(Vector2(cx, techo - 50.0), 3.0, Color(1.0, 0.3, 0.6))
	elif suerte < 0.6:  # depósito de agua
		draw_line(Vector2(cx - 10, techo), Vector2(cx - 12, techo - 16), TINTA, 3.0)
		draw_line(Vector2(cx + 10, techo), Vector2(cx + 12, techo - 16), TINTA, 3.0)
		draw_colored_polygon(Tinta.irregular(PackedVector2Array([
			Vector2(cx - 16, techo - 16), Vector2(cx + 16, techo - 16), Vector2(cx + 14, techo - 44), Vector2(cx - 14, techo - 44)
		]), int(cx), 1.5, 10.0), color_edificio.darkened(0.3))


func _ventanas(rng: RandomNumberGenerator, izq: float, der: float, techo: float) -> void:
	var y := techo + rng.randf_range(16.0, 30.0)
	while y < base_y - 20.0:
		var vx := izq + rng.randf_range(10.0, 18.0)
		while vx < der - 20.0:
			if rng.randf() < 0.3:
				var color := Color(1.0, 0.88, 0.3) if rng.randf() < 0.75 else Color(1.0, 0.3, 0.6)
				var w := rng.randf_range(9.0, 15.0)
				var h := rng.randf_range(12.0, 18.0)
				draw_colored_polygon(Tinta.irregular(PackedVector2Array([
					Vector2(vx, y), Vector2(vx + w, y), Vector2(vx + w, y + h), Vector2(vx, y + h)
				]), int(vx * 7 + y), 1.2, 20.0), color)
			vx += rng.randf_range(22.0, 30.0)
		y += rng.randf_range(30.0, 40.0)

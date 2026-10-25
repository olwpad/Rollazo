# Una fila de edificios dibujada con código, con un "fantasma" cian desplazado
# como en una impresión de cómic mal alineada (estilo Spider-Verse).
extends Node2D

@export var semilla := 1
@export var ancho_total := 2400.0
@export var base_y := 900.0
@export var alto_min := 250.0
@export var alto_max := 700.0
@export var color_edificio := Color(0.08, 0.03, 0.15)
@export var con_ventanas := true


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var x := 0.0
	while x < ancho_total:
		var ancho := rng.randf_range(90.0, 200.0)
		var alto := rng.randf_range(alto_min, alto_max)
		var r := Rect2(x, base_y - alto, ancho - 12.0, alto + 800.0)
		draw_rect(Rect2(r.position + Vector2(-6, 0), r.size), Color(0.0, 0.9, 1.0, 0.35))
		draw_rect(r, color_edificio)
		if con_ventanas:
			_ventanas(r, rng)
		x += ancho


func _ventanas(r: Rect2, rng: RandomNumberGenerator) -> void:
	var y := r.position.y + 20.0
	while y < base_y - 20.0:
		var vx := r.position.x + 14.0
		while vx < r.end.x - 24.0:
			if rng.randf() < 0.35:
				var color := Color(1.0, 0.88, 0.3) if rng.randf() < 0.7 else Color(1.0, 0.3, 0.6)
				draw_rect(Rect2(vx, y, 12.0, 16.0), color)
			vx += 26.0
		y += 34.0

# Una fila de edificios pintada en acuarela con código: siluetas irregulares, tejados torcidos,
# antenas, depósitos de agua y ventanas desiguales. Sin contornos: todo se separa por color.
extends Node2D

@export var semilla := 1
@export var ancho_total := 2400.0
@export var base_y := 900.0
@export var alto_min := 250.0
@export var alto_max := 700.0
@export var color_edificio := Acuarela.AZUL_EDIFICIO
@export var con_ventanas := true
@export var color_ventana := Color(1, 1, 1, 0.6)
@export var guirnaldas := false  # luces de verbena de un tejado al siguiente


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	var x := 0.0
	var n := 0
	var tejados := []  # las dos esquinas de cada tejado, para las guirnaldas
	while x < ancho_total:
		var ancho := rng.randf_range(90.0, 200.0)
		var alto := rng.randf_range(alto_min, alto_max)
		var techo_i := base_y - alto + rng.randf_range(-10.0, 10.0)
		var techo_d := base_y - alto + rng.randf_range(-10.0, 10.0)
		var der := x + ancho - 12.0
		var silueta := PackedVector2Array([
			Vector2(x, techo_i), Vector2(der, techo_d), Vector2(der, base_y + 800.0), Vector2(x, base_y + 800.0)
		])
		Acuarela.pintar(self, silueta, color_edificio, semilla * 100 + n)
		_tejado(rng, x, der, minf(techo_i, techo_d))
		if con_ventanas:
			_ventanas(rng, x, der, maxf(techo_i, techo_d))
		tejados.append([Vector2(x, techo_i), Vector2(der, techo_d)])
		x += ancho
		n += 1
	if guirnaldas:
		for i in range(0, tejados.size() - 1, 2):
			if absf(tejados[i][1].y - tejados[i + 1][0].y) < 90.0:  # solo entre tejados parecidos: si no, cuelga en diagonal
				_guirnalda((tejados[i][0] + tejados[i][1]) / 2.0, (tejados[i + 1][0] + tejados[i + 1][1]) / 2.0)


func _tejado(rng: RandomNumberGenerator, izq: float, der: float, techo: float) -> void:
	var trazo := color_edificio.darkened(0.25)
	var suerte := rng.randf()
	var cx := rng.randf_range(izq + 20.0, der - 20.0)
	if suerte < 0.35:  # antena
		draw_line(Vector2(cx, techo), Vector2(cx + rng.randf_range(-4, 4), techo - 50.0), trazo, 3.0)
		draw_circle(Vector2(cx, techo - 50.0), 3.0, Acuarela.ROSA)
	elif suerte < 0.6:  # depósito de agua
		draw_line(Vector2(cx - 10, techo), Vector2(cx - 12, techo - 16), trazo, 3.0)
		draw_line(Vector2(cx + 10, techo), Vector2(cx + 12, techo - 16), trazo, 3.0)
		Acuarela.pintar(self, PackedVector2Array([
			Vector2(cx - 16, techo - 16), Vector2(cx + 16, techo - 16), Vector2(cx + 14, techo - 44), Vector2(cx - 14, techo - 44)
		]), trazo, int(cx))


func _ventanas(rng: RandomNumberGenerator, izq: float, der: float, techo: float) -> void:
	var y := techo + rng.randf_range(16.0, 30.0)
	while y < base_y - 20.0:
		var vx := izq + rng.randf_range(10.0, 18.0)
		while vx < der - 20.0:
			if rng.randf() < 0.3:
				var w := rng.randf_range(9.0, 15.0)
				var h := rng.randf_range(12.0, 18.0)
				draw_colored_polygon(Tinta.irregular(PackedVector2Array([
					Vector2(vx, y), Vector2(vx + w, y), Vector2(vx + w, y + h), Vector2(vx, y + h)
				]), int(vx * 7 + y), 1.2, 20.0), color_ventana)
			vx += rng.randf_range(22.0, 30.0)
		y += rng.randf_range(30.0, 40.0)


# Cable que cuelga entre dos tejados con bombillas que brillan.
func _guirnalda(a: Vector2, b: Vector2) -> void:
	var puntos := PackedVector2Array()
	for k in 11:
		var f := k / 10.0
		puntos.append(a.lerp(b, f) + Vector2(0, sin(f * PI) * 40.0))
	draw_polyline(puntos, Acuarela.CIRUELA, 2.0)
	for k in range(1, 10, 2):
		draw_circle(puntos[k], 12.0, Color("f5d38a", 0.2))
		draw_circle(puntos[k], 5.0, Color("f5d38a"))

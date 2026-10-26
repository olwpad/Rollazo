# Lo que se mueve en el fondo de cada mapa, en acuarela. Tres capas:
#   "lejos" y "cerca": dentro de los Parallax2D (mismas medidas que los edificios: 2400 de ancho).
#   "superficie": en el mundo, abajo del todo y delante de los mocos (lava, olas): si caes, te traga.
# Las formas se calculan una vez; cada fotograma solo se mueven.
extends Node2D

const ANCHO := 2400.0

var tema := "azotea"
var capa := "lejos"
var desde_x := -2000.0  # solo superficie: de dónde a dónde cubre
var hasta_x := 10000.0
var superficie_y := 1000.0  # la caída mata más abajo (300 px): primero te hundes, luego reapareces
var _formas := []  # [polígono, color] fijos, ya en acuarela
var _cosas := []  # lo que se mueve: posiciones y semillas


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(tema + capa)
	var d: Dictionary = Temas.DATOS[tema]
	match [tema, capa]:
		["azotea", "lejos"]:
			_lejos_azotea(rng, d)
		["noche", "lejos"]:
			_lejos_noche(rng, d)
		["cueva", "lejos"]:
			_lejos_cueva(rng, d)
		["cueva", "cerca"]:
			_cerca_cueva(rng, d)
		["mar", "lejos"]:
			_lejos_mar(rng, d)
		["mar", "cerca"]:
			_cerca_mar(rng, d)
		["jungla", "lejos"]:
			_lejos_jungla(rng, d)
		["jungla", "cerca"]:
			_cerca_jungla(rng, d)
		["cueva", "superficie"], ["mar", "superficie"]:
			_superficie(rng)
	for f in _formas:  # a acuarela una vez; si el temblor cruza un pico fino, esa capa va sin temblor
		f.append(Acuarela.capas(f[0], hash(f[0])).map(func(c: PackedVector2Array) -> PackedVector2Array:
			return c if not Geometry2D.triangulate_polygon(c).is_empty() else f[0]))


# --- Formas y cosas de cada tema y capa (se llaman desde _ready; el orden de rng cuenta) ---

func _lejos_azotea(rng: RandomNumberGenerator, _d: Dictionary) -> void:  # nubes que pasan
	for i in 5:
		_cosas.append({"pos": Vector2(i * 480.0 + rng.randf_range(0, 200), rng.randf_range(-40, 220)), "vel": rng.randf_range(8, 16),
				"capas": Acuarela.capas(_nube(rng), i)})


func _lejos_noche(rng: RandomNumberGenerator, _d: Dictionary) -> void:  # estrellas y farolillos que suben
	for i in 40:
		_cosas.append({"pos": Vector2(rng.randf_range(0, ANCHO), rng.randf_range(-300, 250)), "fase": rng.randf() * TAU, "tipo": "estrella"})
	for i in 12:
		_cosas.append({"pos": Vector2(rng.randf_range(0, ANCHO), rng.randf_range(0, 900)), "vel": rng.randf_range(14, 26), "fase": rng.randf() * TAU, "tipo": "farolillo"})


func _lejos_cueva(rng: RandomNumberGenerator, d: Dictionary) -> void:
	_formas.append([_dientes(rng, -700.0, 40.0, 220.0, true), d.lejos])  # estalactitas
	_formas.append([_dientes(rng, 1700.0, 900.0, 520.0, false), d.lejos])  # rocas del fondo
	for i in 25:  # chispas que suben de la lava
		_cosas.append({"pos": Vector2(rng.randf_range(0, ANCHO), rng.randf_range(0, 900)), "vel": rng.randf_range(20, 45), "fase": rng.randf() * TAU})


func _cerca_cueva(rng: RandomNumberGenerator, d: Dictionary) -> void:
	_formas.append([_dientes(rng, -700.0, -40.0, 120.0, true), d.cerca])
	_formas.append([_dientes(rng, 1900.0, 1000.0, 700.0, false), d.cerca])


func _lejos_mar(rng: RandomNumberGenerator, d: Dictionary) -> void:  # mar abierto hasta el horizonte, islas y el faro
	_formas.append([PackedVector2Array([Vector2(-40, 600), Vector2(ANCHO + 40, 600), Vector2(ANCHO + 40, 1800), Vector2(-40, 1800)]), Color("a8dccf")])
	for k in 3:
		var x := k * 800.0 + rng.randf_range(0, 300)
		_formas.append([PackedVector2Array([Vector2(x, 610), Vector2(x + 60, 510 - k * 20), Vector2(x + 180, 470), Vector2(x + 300, 530), Vector2(x + 380, 610)]), d.lejos.darkened(0.08)])
	_formas.append([PackedVector2Array([Vector2(1500, 610), Vector2(1512, 350), Vector2(1548, 350), Vector2(1560, 610)]), Color("fffaf4")])  # faro
	_formas.append([PackedVector2Array([Vector2(1508, 410), Vector2(1552, 410), Vector2(1550, 440), Vector2(1510, 440)]), Acuarela.ROSA])
	for i in 30:  # brillos sobre el agua
		_cosas.append({"pos": Vector2(rng.randf_range(0, ANCHO), rng.randf_range(640, 1000)), "fase": rng.randf() * TAU, "tipo": "brillo"})
	for i in 6:  # gaviotas
		_cosas.append({"pos": Vector2(rng.randf_range(0, ANCHO), rng.randf_range(-100, 250)), "vel": rng.randf_range(30, 60), "fase": rng.randf() * TAU, "tipo": "gaviota"})


func _cerca_mar(rng: RandomNumberGenerator, d: Dictionary) -> void:  # postes del muelle asomando
	for i in 10:
		var x := i * 240.0 + rng.randf_range(0, 80)
		_formas.append([PackedVector2Array([Vector2(x, 1800), Vector2(x, 880 + rng.randf_range(0, 120)), Vector2(x + 26, 880), Vector2(x + 26, 1800)]), d.cerca])


func _lejos_jungla(rng: RandomNumberGenerator, d: Dictionary) -> void:  # troncos finos y torcidos, copas arriba, matas abajo y hojas enormes que se mecen
	for i in 6:
		var x := i * 400.0 + rng.randf_range(0, 150)
		var curva := rng.randf_range(-60, 60)
		_formas.append([PackedVector2Array([Vector2(x, 1800), Vector2(x + curva, 500), Vector2(x + 14, -400), Vector2(x + 40, -400),
				Vector2(x + curva + 30, 500), Vector2(x + 46, 1800)]), d.lejos.lightened(0.1)])
	_formas.append([_dientes(rng, -800.0, -120.0, 200.0, true), d.lejos])
	_formas.append([_dientes(rng, 1700.0, 950.0, 260.0, false), d.lejos])
	for i in 14:
		_cosas.append({"pos": Vector2(rng.randf_range(0, ANCHO), rng.randf_range(-200, 700)), "fase": rng.randf() * TAU,
				"giro": rng.randf_range(-PI, PI), "largo": rng.randf_range(110, 200), "color": d.lejos})


func _cerca_jungla(rng: RandomNumberGenerator, _d: Dictionary) -> void:  # lianas con flores
	for i in 9:
		_cosas.append({"pos": Vector2(i * 270.0 + rng.randf_range(0, 120), -500), "largo": rng.randf_range(500, 850), "fase": rng.randf() * TAU})


func _superficie(rng: RandomNumberGenerator) -> void:  # burbujas de lava o espuma
	for i in 40:
		_cosas.append({"x": rng.randf_range(desde_x, hasta_x), "fase": rng.randf() * TAU})


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for f in _formas:
		for capa_pintura: PackedVector2Array in f[2]:
			draw_colored_polygon(capa_pintura, Color(f[1], Acuarela.OPACIDAD_CAPA + 0.2))
	match [tema, capa]:
		["azotea", "lejos"]:
			for c: Dictionary in _cosas:
				draw_set_transform(Vector2(fposmod(c.pos.x + t * c.vel, ANCHO + 400.0) - 200.0, c.pos.y))
				for capa_pintura: PackedVector2Array in c.capas:
					draw_colored_polygon(capa_pintura, Color(1, 1, 1, 0.45))
			draw_set_transform(Vector2.ZERO)
		["noche", "lejos"]:
			for c: Dictionary in _cosas:
				if c.tipo == "estrella":
					draw_circle(c.pos, 2.0, Color(1, 0.98, 0.95, 0.5 + 0.5 * sin(t * 2.0 + c.fase)))
				else:
					var p := Vector2(c.pos.x + sin(t * 0.8 + c.fase) * 14.0, 900.0 - fposmod(900.0 - c.pos.y + t * c.vel, 1300.0))
					draw_circle(p, 20.0, Color("f5d38a", 0.18))
					draw_rect(Rect2(p - Vector2(8, 11), Vector2(16, 22)), Color("f2a07f", 0.9))
					draw_rect(Rect2(p - Vector2(5, 6), Vector2(10, 12)), Color("f5d38a", 0.8))
		["cueva", "lejos"]:
			for c: Dictionary in _cosas:
				var y := 900.0 - fposmod(900.0 - c.pos.y + t * c.vel, 1000.0)
				draw_circle(Vector2(c.pos.x + sin(t + c.fase) * 10.0, y), 3.0, Color("f5d38a", clampf((y + 100.0) / 900.0, 0.0, 0.8)))
		["mar", "lejos"]:
			var luz := 0.35 + 0.35 * sin(t * 2.5)  # el faro parpadea
			draw_circle(Vector2(1530, 380), 34.0, Color("f5d38a", luz * 0.5))
			draw_circle(Vector2(1530, 380), 10.0, Color("f5d38a", 0.6 + luz))
			for c: Dictionary in _cosas:
				if c.tipo == "brillo":  # rayitas de luz que aparecen y se van
					draw_line(c.pos, c.pos + Vector2(22, 0), Color(1, 1, 1, maxf(0.0, sin(t * 1.3 + c.fase)) * 0.6), 3.0)
					continue
				var p := Vector2(fposmod(c.pos.x + t * c.vel, ANCHO), c.pos.y + sin(t + c.fase) * 12.0)
				var ala := 6.0 * sin(t * 6.0 + c.fase)
				draw_polyline(PackedVector2Array([p + Vector2(-16, ala), p, p + Vector2(16, ala)]), Acuarela.CIRUELA, 2.5)
		["jungla", "lejos"]:
			for c: Dictionary in _cosas:
				draw_set_transform(c.pos, c.giro + sin(t * 0.9 + c.fase) * 0.12)
				var l: float = c.largo
				draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2(l * 0.4, -l * 0.22), Vector2(l, 0), Vector2(l * 0.4, l * 0.22)]), Color(c.color, 0.6))
			draw_set_transform(Vector2.ZERO)
		["jungla", "cerca"]:
			for c: Dictionary in _cosas:
				var vaiven := sin(t * 1.1 + c.fase) * 18.0
				var fin: Vector2 = c.pos + Vector2(vaiven, c.largo)
				draw_polyline(PackedVector2Array([c.pos, c.pos + Vector2(vaiven * 0.3, c.largo * 0.5), fin]), Acuarela.MENTA.darkened(0.15), 5.0)
				draw_circle(fin, 9.0, Color(Acuarela.ROSA, 0.85))
				draw_circle(fin + Vector2(3, -2), 5.0, Color("f5d38a", 0.9))
		["cueva", "superficie"]:
			_ondas(t, Color("f2a07f"), Color("ef8fae"), Color("f5d38a"))
		["mar", "superficie"]:
			_ondas(t, Color("8fd0c6"), Color("6cc3b0"), Color("fffaf4"))


# Dos capas de ondas con burbujas (lava) o espuma (mar). Llega muy abajo: tapa al que cae.
func _ondas(t: float, arriba: Color, abajo: Color, punto: Color) -> void:
	for k in 2:
		var ola := PackedVector2Array()
		var x := desde_x
		while x <= hasta_x:
			ola.append(Vector2(x, superficie_y + k * 18.0 + sin(x / 90.0 + t * (1.6 - k * 0.5) + k) * 9.0))
			x += 40.0
		ola.append(Vector2(hasta_x, superficie_y + 900.0))
		ola.append(Vector2(desde_x, superficie_y + 900.0))
		draw_colored_polygon(ola, Color(arriba if k == 0 else abajo, 0.9))
	draw_rect(Rect2(desde_x, superficie_y - 120.0, hasta_x - desde_x, 120.0), Color(arriba, 0.08))  # el brillo encima
	for c: Dictionary in _cosas:
		var vida := fposmod(t * 0.5 + c.fase, 1.0)  # crece y estalla
		draw_circle(Vector2(c.x, superficie_y + 10.0 - vida * 14.0), 3.0 + vida * 6.0, Color(punto, 1.0 - vida))


func _nube(rng: RandomNumberGenerator) -> PackedVector2Array:
	var poly := PackedVector2Array()
	var ancho := rng.randf_range(160, 260)
	for k in 20:  # óvalo achatado con bultos por arriba
		var a := TAU * k / 20.0
		var bulto := 1.0 + (0.25 * absf(sin(a * 3.0)) if sin(a) < 0.0 else 0.0)
		poly.append(Vector2(cos(a) * ancho / 2.0, sin(a) * ancho * 0.22 * bulto))
	return poly


# Fila de pinchos (estalactitas hacia abajo o rocas hacia arriba) pegada a `base`.
func _dientes(rng: RandomNumberGenerator, base: float, borde: float, alto: float, colgando: bool) -> PackedVector2Array:
	var poly := PackedVector2Array([Vector2(-40, base)])
	var x := -40.0
	while x < ANCHO + 40.0:
		var dir := 1.0 if colgando else -1.0
		poly.append(Vector2(x, borde))
		poly.append(Vector2(x + rng.randf_range(20, 45), borde + dir * rng.randf_range(alto * 0.3, alto)))
		x += rng.randf_range(60, 130)
	poly.append(Vector2(ANCHO + 40.0, borde))
	poly.append(Vector2(ANCHO + 40.0, base))
	return poly

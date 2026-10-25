# El moco: se dibuja con código. Tiembla, se estira hacia donde va y tiene los ojos desiguales.
class_name MocoVisual
extends Node2D

const RADIO := 22.0
var color := Acuarela.MENTA
var velocidad := Vector2.ZERO  # la pone el Jugador cada frame
var pelo := "calvo"  # ver Perfil.FILAS
var sombrero := "nada"
var cara := "nada"
var ropa := "nada"

const FUENTE := preload("res://assets/fuentes/Bangers-Regular.ttf")
const ROSA := Color("ef8fae")
const ROJO := Color("e2675f")
const RUBIO := Color("f0c674")
const CASTANO := Color("c98a5a")
const CREMA := Color("fffaf4")
const C := Acuarela.CIRUELA
const OSCURO := Color("4a3530")  # pelo oscuro: el ciruela casi negro lo volvía una mancha
# Cada cosa: lista de piezas [puntos, color], en coordenadas del moco (coronilla en y = -22, ojos en y = -5).
# Delante de la cara nada baja de y = -14 entre x = -15 y 15: los ojos siempre se ven.
const COSAS := {
	"cresta": [[[[-4, -20], [-7, -33], [-2, -24], [0, -37], [2, -24], [7, -34], [5, -20]], ROSA]],
	"skrillex": [[[[-17, -10], [-12, -26], [2, -30], [18, -24], [6, -22], [-4, -18], [-14, -12], [-20, 4]], OSCURO]],
	"tupe": [[[[-17, -11], [-18, -22], [-10, -30], [0, -36], [12, -40], [22, -36], [18, -33], [10, -31], [16, -26], [17, -14], [8, -19], [-6, -18]], OSCURO],
			[[[-20, -10], [-17, -10], [-17, 2], [-20, 0]], OSCURO]],
	"melena": [[[[-17, -13], [-15, -24], [0, -28], [15, -24], [17, -13], [8, -18], [0, -16], [-8, -18]], CASTANO]],
	"diva": [[[[-14, -16], [-15, -28], [-12, -40], [-5, -46], [3, -47], [10, -43], [14, -34], [14, -18], [6, -21], [-4, -21]], Color("3a3048")]],
	"tupe_rubio": [[[[-17, -11], [-16, -22], [-8, -28], [6, -30], [18, -27], [23, -21], [19, -19], [12, -22], [4, -20], [-6, -17], [-12, -15]], Color("f5d07a")]],
	"engominado": [[[[-15, -13], [-14, -23], [-6, -28], [4, -30], [14, -27], [16, -15], [10, -20], [0, -21], [-8, -19]], OSCURO]],
	"rizos": [[[[-17, -12], [-15, -24], [0, -29], [15, -24], [17, -12], [6, -19], [-4, -17]], RUBIO]],
	"cinta": [[[[-16, -14], [-14, -26], [0, -30], [14, -26], [16, -14], [0, -21]], OSCURO], [[[-17, -18], [17, -19], [17, -15], [-17, -14]], CREMA]],
	"corto": [[[[-15, -13], [-13, -25], [-3, -29], [8, -28], [15, -23], [16, -13], [10, -19], [2, -17], [-6, -20]], CASTANO]],
	"raya": [[[[-15, -13], [-14, -25], [-4, -28], [-3, -22], [-1, -28], [12, -27], [16, -16], [6, -21], [-6, -19]], CASTANO]],
	"rulos": [],  # solo bolas (ver _draw)
	"cepillo": [[[[-15, -15], [-14, -25], [14, -25], [15, -15], [6, -19], [-6, -19]], Color("8a6a4a")]],
	"gorra": [[[[-14, -15], [-12, -27], [0, -31], [12, -28], [14, -17], [26, -16], [25, -13], [-14, -12]], ROSA]],
	"lana": [[[[-15, -14], [-13, -29], [0, -35], [13, -29], [15, -14]], Color("6cc3b0")]],
	"chistera": [[[[-16, -19], [-9, -21], [-9, -44], [9, -44], [9, -21], [16, -19], [16, -16], [-16, -16]], C]],
	"corona": [[[[-13, -16], [-13, -30], [-7, -23], [0, -33], [7, -23], [13, -30], [13, -16]], Color("f5d38a")]],
	"bombin": [[[[-12, -20], [-12, -30], [-7, -37], [0, -39], [7, -37], [12, -30], [12, -20]], C], [[[-18, -21], [18, -21], [17, -17], [-17, -17]], C]],
	"vaquero": [[[[-10, -21], [-11, -36], [-3, -34], [0, -31], [3, -34], [11, -36], [10, -21]], CASTANO],
			[[[-26, -28], [-16, -21], [0, -19], [16, -21], [26, -28], [22, -17], [0, -14], [-22, -17]], CASTANO]],
	"boina": [[[[-16, -17], [-17, -29], [2, -31], [19, -29], [18, -21], [5, -16]], ROSA]],
	"boina_roja": [[[[-17, -14], [-18, -24], [-6, -30], [10, -30], [20, -25], [19, -18], [6, -15]], ROJO]],
	"bigotito": [[[[-0.5, 3], [4.5, 3], [4.5, 6.5], [-0.5, 6.5]], C]],
	"estrella": [[[[-17, -10], [16, -12], [15, -5], [10, -1], [4, -4], [0, -5], [-4, -2], [-10, -1], [-16, -4]], C]],
	"barba": [[[[-17, 4], [-12, 14], [-4, 19], [4, 20], [12, 17], [17, 8], [13, 10], [8, 15], [2, 16], [-4, 15], [-10, 11]], Color("8a5a3a")]],
	"corbata": [[[[0, 14], [5, 14], [4.5, 16], [6, 22], [2.5, 25], [-1, 22], [0.5, 16]], ROJO]],
	"ciborg": [[[[-19, -12], [18, -13], [17, -5], [4, -3], [1, -6], [-2, -3], [-18, -3]], C]],
	"oca": [[[[-15, -17], [-14, -25], [-6, -29], [2, -30], [4, -38], [3, -46], [7, -50], [12, -49], [13, -45], [9, -40], [10, -30], [15, -25], [16, -17]], CREMA],
			[[[13, -48], [19, -46], [13, -44]], Color("f5a05a")]],
}
# Pelo que va DETRÁS del moco (melenas, afros, rizos): hace de halo y nunca tapa la cara.
const DETRAS := {
	"melena": [[[[-22, -12], [-16, -26], [0, -31], [16, -26], [22, -12], [25, 8], [25, 20], [19, 27], [-19, 27], [-25, 20], [-25, 8]], Color("ab754c")]],
	"rizos": [[[[-20, -14], [-14, -26], [0, -30], [14, -26], [20, -14], [24, 0], [22, 10], [26, 20], [18, 26], [-18, 26], [-26, 20], [-22, 10], [-24, 0]], Color("ddb66b")]],
}
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


# Se aplasta o se estira de golpe y vuelve con un rebote elástico.
func aplastar(escala: Vector2) -> void:
	scale = escala
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var foto := Tinta.fotograma()
	var t := foto / float(Tinta.FPS)  # el temblor avanza a 12 fps, como dibujado a mano
	var cuerpo := Tinta.temblar(forma(28, t, velocidad), 77, foto, 0.8)
	_detras(foto)
	# Sin contorno: una capa base y otra más pequeña y clara encima dan volumen de acuarela.
	draw_colored_polygon(cuerpo, color.darkened(0.12))
	var interior := PackedVector2Array()
	for p in cuerpo:
		interior.append(p * 0.82 + Vector2(-1, -2))
	draw_colored_polygon(interior, color.lightened(0.12))
	if pelo == "tupe_rubio":  # el magnate, con su moreno naranja
		draw_colored_polygon(interior, Color("f5a060", 0.35))
	draw_circle(Vector2(-9, -12), 5.0, Color(1, 1, 1, 0.55))  # brillo viscoso
	_ropa(cuerpo, foto)
	if cara == "barba":  # la barba va por debajo de la boca: la sonrisa se ve encima
		_cosa(COSAS.barba[0][0], COSAS.barba[0][1], foto)
	var mira := velocidad.normalized() * 3.0 if velocidad.length() > 30.0 else Vector2.ZERO
	_ojo(Vector2(-6, -4), 9.0, mira)
	_ojo(Vector2(9, -7), 5.5, mira)
	draw_arc(Vector2(2, 8), 6.0, 0.3, PI - 0.3, 8, Acuarela.CIRUELA, 3.0)
	if cara in ["mascara_roja", "mascara_negra"]:  # máscara de héroe genérica: sin telarañas ni arañas
		var mascara := PackedVector2Array()
		for q in cuerpo:
			mascara.append(Vector2(q.x, minf(q.y, 9.0)))
		draw_colored_polygon(mascara, ROJO if cara == "mascara_roja" else Color("2e2a3a"))
		if cara == "mascara_roja":  # traje azul de cuello para abajo
			var traje := PackedVector2Array()
			for q in cuerpo:
				traje.append(Vector2(q.x, maxf(q.y, 9.0)))
			draw_colored_polygon(traje, Color("4f7fc9"))
		else:  # dos marcas rojas en V a los lados
			for lado in [-1.0, 1.0]:
				draw_polyline(PackedVector2Array([Vector2(lado * 13, -4), Vector2(lado * 16, 0), Vector2(lado * 19, -4)]), ROJO, 2.0)
		for ojo in [[[-15, -3], [-14, -11], [-9, -14], [-3, -9], [-4, -2]], [[3, -9], [10, -14], [16, -12], [16, -4], [6, -2]]]:
			var o := PackedVector2Array()
			for xy in ojo:
				o.append(Vector2(xy[0], xy[1]))
			draw_colored_polygon(o, CREMA)
	match cara:  # lo que no es un polígono relleno
		"redondas":
			for ojo in [[Vector2(-6, -4), 11.0], [Vector2(9, -7), 7.5]]:
				draw_arc(ojo[0], ojo[1], 0, TAU, 16, C, 2.0)
			draw_line(Vector2(5, -6), Vector2(1.5, -5), C, 2.0)
		"pasta":
			draw_rect(Rect2(-16, -13, 20, 16), C, false, 3.0)
			draw_rect(Rect2(4, -14, 12, 13), C, false, 3.0)
		"sonrisa":
			var boca := PackedVector2Array()
			for i in 9:
				boca.append(Vector2(2, 6) + Vector2(cos(PI * i / 8.0), sin(PI * i / 8.0)) * 9.0)
			draw_colored_polygon(boca, CREMA)
			draw_polyline(boca, C, 1.5)
			draw_line(Vector2(-7, 6), Vector2(11, 6), C, 1.5)
		"rizado":  # bigote fino con las puntas muy hacia arriba, por fuera de los ojos
			draw_polyline(PackedVector2Array([Vector2(1, 5), Vector2(-6, 5), Vector2(-13, 3), Vector2(-17, -3), Vector2(-18, -13)]), C, 2.5)
			draw_polyline(PackedVector2Array([Vector2(3, 5), Vector2(9, 4), Vector2(14, 1), Vector2(16, -6), Vector2(16, -15)]), C, 2.5)
	for cosa: String in [pelo, cara, sombrero]:  # la cara encima del pelo: las gafas no quedan tapadas
		if cosa == "barba" or cosa == "corbata":
			continue  # ya pintadas (la barba bajo la boca, la corbata con la ropa)
		for pieza: Array in COSAS.get(cosa, []):
			_cosa(pieza[0], pieza[1], foto)
	match cara:  # brillos encima de las gafas
		"estrella":
			draw_line(Vector2(-12, -9), Vector2(-6, -10), Color(1, 1, 1, 0.5), 2.0)
		"ciborg":  # el ojo pequeño es el de cíborg
			draw_circle(Vector2(9, -7), 6.0, Color("ff4a3a", 0.35))
			draw_circle(Vector2(9, -7), 3.0, Color("ff4a3a"))
		"bigotito":
			pass
	match pelo:
		"tupe", "tupe_rubio", "engominado":  # brillo de gomina
			draw_line(Vector2(-4, -27), Vector2(9, -32), Color(1, 1, 1, 0.45), 2.5)
		"diva":
			draw_circle(Vector2(8, -38), 3.0, ROSA)
			draw_line(Vector2(-15, -6), Vector2(-19, -10), C, 2.0)  # raya de ojos
			draw_line(Vector2(14, -8), Vector2(17, -11), C, 2.0)
		"rulos":  # los de arriba; los de los lados van detrás
			for xy in [[-14, -19], [-8, -26], [0, -29], [8, -26], [14, -19]]:
				draw_circle(Vector2(xy[0], xy[1]), 6.5, OSCURO.lightened(0.06 * (int(xy[0]) % 3)))
	match sombrero:
		"lana":
			draw_circle(Vector2(0, -37), 4.5, CREMA)
		"chistera":
			draw_rect(Rect2(-9, -25, 18, 4), Color(Acuarela.ROSA, 0.9))
		"corona":
			for x in [-7.0, 0.0, 7.0]:
				draw_circle(Vector2(x, -21), 1.5, Acuarela.ROSA if x == 0.0 else Color("8ec5e8"))
		"vaquero":
			draw_rect(Rect2(-10, -23, 20, 3), ROJO)
		"boina", "boina_roja":
			draw_line(Vector2(1, -30), Vector2(2, -34), COSAS[sombrero][0][1], 2.5)
		"oca":
			draw_circle(Vector2(10, -46), 1.3, C)


# Melenas, afros y rizos por detrás del cuerpo.
func _detras(foto: int) -> void:
	for pieza: Array in DETRAS.get(pelo, []):
		_cosa(pieza[0], pieza[1], foto)
	match pelo:
		"afro":
			for bola in [[Vector2(0, -22), 20.0], [Vector2(-16, -14), 15.0], [Vector2(16, -14), 15.0], [Vector2(-22, 0), 10.0], [Vector2(22, 0), 10.0]]:
				draw_circle(bola[0], bola[1], Color("5a4038").lightened(0.08 if bola[0].x != 0.0 else 0.0))
		"rizos":
			for lado in [-1.0, 1.0]:
				for xy in [[23, 4], [21, 14], [24, 22]]:
					draw_circle(Vector2(lado * xy[0], xy[1]), 5.0, RUBIO)
		"cinta":
			for lado in [-1.0, 1.0]:
				for y in [-10.0, -2.0, 6.0, 14.0]:
					draw_circle(Vector2(lado * 21, y), 4.5, OSCURO)
		"rulos":
			for lado in [-1.0, 1.0]:
				draw_circle(Vector2(lado * 21, -4), 6.0, OSCURO)
		"rulos_cortos":  # rulos alrededor de la coronilla
			for i in 9:
				var a := deg_to_rad(200.0 + 140.0 * i / 8.0)
				draw_circle(Vector2(cos(a), sin(a)) * 23.0, 4.5, Color("4a3530").lightened(0.07 * (i % 2)))


func vestir(aspecto: Dictionary) -> void:
	pelo = aspecto.pelo
	sombrero = aspecto.sombrero
	cara = aspecto.get("cara", "nada")
	ropa = aspecto.get("ropa", "nada")


# Camisetas y uniformes: la parte de abajo del moco (por debajo de la boca) pintada encima del cuerpo.
func _ropa(cuerpo: PackedVector2Array, foto: int) -> void:
	if ropa == "corbata":
		_cosa(COSAS.corbata[0][0], COSAS.corbata[0][1], foto)
		return
	if ropa == "nada":
		return
	var abajo := PackedVector2Array()
	for q in cuerpo:
		abajo.append(Vector2(q.x, maxf(q.y, 15.0 - 0.45 * absf(q.x))))  # cuello curvo: sube por los lados y pasa por debajo de la boca
	var franjas := []  # [rectángulo, color]
	match ropa:
		"militar":
			franjas = [[Rect2(-30, 0, 60, 40), Color("6f7d4a")], [Rect2(-1, 0, 2, 40), Color("566238")]]  # verde oliva con la tapeta
		"diez":
			franjas = [[Rect2(-30, 0, 60, 40), CREMA], [Rect2(-14, 0, 5, 40), Color("8ec5e8")], [Rect2(-2, 0, 5, 40), Color("8ec5e8")], [Rect2(10, 0, 5, 40), Color("8ec5e8")]]
		"siete":
			franjas = [[Rect2(-30, 0, 60, 40), ROJO]]
		"amarilla":
			franjas = [[Rect2(-30, 0, 60, 40), Color("f5d38a")], [Rect2(-30, 0, 60, 9), Color("7cc48a")]]
		"traje":
			franjas = [[Rect2(-30, 0, 60, 40), Color("4f5f99")], [Rect2(-3, 0, 7, 40), CREMA]]
		"cafetera":
			franjas = [[Rect2(-30, 0, 60, 40), Color("f5d38a")], [Rect2(-30, 18, 60, 3), Color("4f7fc9")], [Rect2(-30, 21, 60, 20), ROJO]]
		"reloj":
			franjas = [[Rect2(-30, 0, 60, 40), CREMA], [Rect2(-2.5, 0, 5, 40), C]]
	for f: Array in franjas:
		var r: Rect2 = f[0]
		var caja := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
		for trozo in Geometry2D.intersect_polygons(Tinta.temblar(abajo, 41, foto, 0.6), caja):
			draw_colored_polygon(trozo, f[1])
	match ropa:
		"diez", "amarilla", "cafetera":
			draw_string(FUENTE, Vector2(-5, 21.5), "10", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, C if ropa == "diez" else Color("4f7fc9"))
		"reloj":  # reloj verde de héroe en un lado
			draw_circle(Vector2(-11, 17.5), 3.5, Color("7cc48a"))
			draw_circle(Vector2(-11, 17.5), 1.5, Color("2e2a3a"))
		"militar":  # botones dorados, bolsillos de pecho y charreteras
			for y in [16.5, 20.0]:
				draw_circle(Vector2(0, y), 1.3, Color("f5d38a"))
			for x in [-11.0, 6.0]:
				draw_rect(Rect2(x, 15.5, 6, 3.5), Color("566238"))
				draw_line(Vector2(x, 15.5), Vector2(x + 6, 15.5), Color("4a5530"), 1.2)
			for lado in [-1.0, 1.0]:
				draw_rect(Rect2(lado * 17 - 3.5, 8.5, 7, 2.5), Color("f5d38a"))
		"siete":
			draw_string(FUENTE, Vector2(-1.5, 21.5), "7", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, CREMA)
		"traje":
			draw_colored_polygon(PackedVector2Array([Vector2(-1, 14), Vector2(2, 14), Vector2(2, 20), Vector2(0.5, 22), Vector2(-1, 20)]), ROJO)


# Sin contorno, como el cuerpo: base más oscura y encima otra capa más clara, temblando a 12 fps.
func _cosa(puntos: Array, c: Color, foto: int) -> void:
	var p := PackedVector2Array()
	for xy: Array in puntos:
		p.append(Vector2(xy[0], xy[1]))
	draw_colored_polygon(Tinta.temblar(p, 31, foto, 0.6), c.darkened(0.1))
	for dentro in Geometry2D.offset_polygon(p, -1.5):  # vacío en piezas finas: bigotes, cintas
		if Geometry2D.is_polygon_clockwise(dentro) == Geometry2D.is_polygon_clockwise(p):
			draw_colored_polygon(dentro, Color(c.lightened(0.15), 0.8))


func _ojo(centro: Vector2, radio: float, mira: Vector2) -> void:
	draw_circle(centro, radio, Color.WHITE)
	draw_circle(centro + mira, radio * 0.45, Acuarela.CIRUELA)

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
# Cada cosa: lista de piezas [puntos, color], en coordenadas del moco (coronilla en y = -22, ojos en y = -5).
const COSAS := {
	"cresta": [[[[-4, -20], [-7, -33], [-2, -24], [0, -37], [2, -24], [7, -34], [5, -20]], ROSA]],
	"skrillex": [[[[-15, -12], [-9, -27], [5, -27], [16, -21], [5, -21], [-3, -15], [-9, -4], [-14, -2]], C]],
	"tupe": [[[[-15, -13], [-16, -25], [-4, -31], [12, -33], [22, -27], [12, -25], [15, -19], [0, -22]], C]],
	"melena": [[[[-16, -14], [-10, -27], [2, -28], [14, -26], [18, -12], [21, 8], [16, 2], [15, -14], [4, -20], [-8, -19], [-15, -16], [-17, -3], [-21, 8]], CASTANO]],
	"diva": [[[[-12, -18], [-13, -40], [0, -47], [13, -40], [12, -18], [0, -22]], C]],
	"tupe_rubio": [[[[-16, -12], [-14, -26], [2, -30], [17, -27], [20, -18], [8, -23], [-6, -20]], RUBIO]],
	"engominado": [[[[-15, -14], [-13, -26], [1, -29], [14, -26], [15, -15], [9, -21], [3, -19], [1, -23], [-8, -20]], C]],
	"rizos": [[[[-16, -14], [-14, -26], [0, -29], [14, -26], [16, -14], [0, -21]], RUBIO]],
	"cinta": [[[[-16, -14], [-14, -26], [0, -30], [14, -26], [16, -14], [0, -21]], Color("4a3530")], [[[-16, -19], [16, -20], [16, -16], [-16, -15]], CREMA]],
	"raya": [[[[-15, -13], [-14, -25], [-4, -28], [-3, -22], [-1, -28], [12, -27], [16, -16], [6, -21], [-6, -19]], CASTANO]],
	"gorra": [[[[-14, -15], [-12, -27], [0, -31], [12, -28], [14, -17], [26, -17], [24, -13], [-14, -12]], ROSA]],
	"lana": [[[[-15, -14], [-13, -29], [0, -35], [13, -29], [15, -14]], Color("6cc3b0")]],
	"chistera": [[[[-16, -19], [-9, -21], [-9, -44], [9, -44], [9, -21], [16, -19], [16, -16], [-16, -16]], C]],
	"corona": [[[[-11, -18], [-12, -32], [-6, -25], [0, -35], [6, -25], [12, -32], [11, -18]], Color("f5d38a")]],
	"bombin": [[[[-11, -21], [-11, -33], [-5, -38], [5, -38], [11, -33], [11, -21]], C], [[[-17, -22], [17, -22], [16, -18], [-16, -18]], C]],
	"vaquero": [[[[-10, -21], [-11, -36], [-3, -34], [0, -31], [3, -34], [11, -36], [10, -21]], CASTANO], [[[-24, -25], [0, -20], [24, -25], [20, -18], [0, -15], [-20, -18]], CASTANO]],
	"boina": [[[[-16, -17], [-17, -29], [2, -31], [19, -29], [18, -21], [5, -16]], ROSA]],
	"boina_roja": [[[[-16, -17], [-17, -29], [2, -31], [19, -29], [18, -21], [5, -16]], ROJO]],
	"bigotito": [[[[-1, 2], [6, 2], [6, 6], [-1, 6]], C]],
	"rizado": [[[[2, 5], [-4, 4], [-9, -1], [-11, -5], [-6, 1], [2, 2], [10, 1], [14, -6], [12, 0], [8, 4]], C]],
	"estrella": [[[[-17, -10], [16, -12], [15, -5], [10, -1], [4, -4], [0, -5], [-4, -2], [-10, -1], [-16, -4]], C]],
	"barba": [[[[-19, -3], [-15, 10], [-6, 17], [3, 19], [12, 16], [18, 8], [20, -5], [15, 3], [10, 6], [3, 7], [-5, 6], [-13, 2]], Color("b07a52")]],
	"corbata": [[[[-2, 6], [5, 6], [4, 9], [6, 21], [1.5, 26], [-3, 21], [-1, 9]], ROJO]],
	"cepillo": [[[[-14, -16], [-14, -30], [14, -30], [14, -16], [8, -21], [-8, -21]], CASTANO]],
	"ciborg": [[[[-18, -11], [17, -12], [16, -3], [-17, -2]], C], [[[6, -9], [12, -9], [12, -5], [6, -5]], ROJO]],
	"oca": [[[[-12, -18], [-10, -30], [-2, -34], [0, -46], [6, -50], [12, -48], [20, -46], [12, -43], [8, -40], [6, -30], [12, -18]], CREMA], [[[20, -46], [27, -45], [20, -42]], Color("f5b38a")]],
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
	# Sin contorno: una capa base y otra más pequeña y clara encima dan volumen de acuarela.
	draw_colored_polygon(cuerpo, color.darkened(0.12))
	var interior := PackedVector2Array()
	for p in cuerpo:
		interior.append(p * 0.82 + Vector2(-1, -2))
	draw_colored_polygon(interior, color.lightened(0.12))
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
		if cara == "mascara_negra":
			draw_line(Vector2(-18, 2), Vector2(18, 0), ROJO, 2.5)
		for ojo in [[[-14, -2], [-12, -12], [-2, -8], [-3, -1]], [[4, -9], [14, -13], [15, -4], [6, -2]]]:
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
	for cosa: String in [pelo, cara, sombrero]:  # la cara encima del pelo: las gafas no quedan tapadas
		if cosa == "barba":
			continue  # ya pintada debajo de la boca
		for pieza: Array in COSAS.get(cosa, []):
			_cosa(pieza[0], pieza[1], foto)
	match pelo:
		"afro":
			for bola in [[Vector2(0, -29), 15.0], [Vector2(-15, -21), 9.0], [Vector2(15, -21), 9.0]]:
				draw_circle(bola[0], bola[1], C.lightened(0.05))
		"rizos", "cinta":
			for lado in [-1, 1]:
				for y in [-12, -4, 4, 12]:
					draw_circle(Vector2(lado * 19, y), 4.0, RUBIO if pelo == "rizos" else Color("4a3530"))
		"diva":
			draw_circle(Vector2(6, -36), 2.5, ROSA)
		"rulos", "rulos_cortos":
			var rulo := C if pelo == "rulos" else Color("6b4a3a")
			var grande := 7.0 if pelo == "rulos" else 5.5
			for xy in [[-15, -19], [-8, -27], [0, -30], [8, -27], [15, -19], [-18, -9], [18, -9]]:
				if pelo == "rulos_cortos" and absf(xy[1]) < 10:
					continue  # los cortos no bajan por los lados
				draw_circle(Vector2(xy[0], xy[1]), grande, rulo.lightened(0.08 * (xy[0] % 3)))
	match sombrero:
		"lana":
			draw_circle(Vector2(0, -37), 4.5, CREMA)
		"chistera":
			draw_rect(Rect2(-9, -25, 18, 4), Color(Acuarela.ROSA, 0.9))
		"corona":
			draw_circle(Vector2(0, -27), 2.0, Acuarela.ROSA)
		"boina", "boina_roja":
			draw_line(Vector2(1, -31), Vector2(2, -35), COSAS[sombrero][0][1], 2.5)


func vestir(aspecto: Dictionary) -> void:
	pelo = aspecto.pelo
	sombrero = aspecto.sombrero
	cara = aspecto.get("cara", "nada")
	ropa = aspecto.get("ropa", "nada")


# Camisetas y chándal: la parte de abajo del moco (por debajo de la boca) pintada encima del cuerpo.
func _ropa(cuerpo: PackedVector2Array, foto: int) -> void:
	if ropa == "nada" or ropa == "corbata":
		return
	var abajo := PackedVector2Array()
	for q in cuerpo:
		abajo.append(Vector2(q.x, maxf(q.y, 6.0)))
	var franjas := []  # [rectángulo, color]
	match ropa:
		"chandal":
			franjas = [[Rect2(-30, 0, 60, 15), Color("f5d38a")], [Rect2(-30, 15, 60, 4), Color("4f7fc9")], [Rect2(-30, 19, 60, 20), ROJO]]
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
			draw_string(FUENTE, Vector2(-6, 17), "10", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, C if ropa == "diez" else Color("4f7fc9"))
		"reloj":  # reloj verde de héroe en un lado
			draw_circle(Vector2(-13, 13), 4.5, Color("7cc48a"))
			draw_circle(Vector2(-13, 13), 2.0, Color("2e2a3a"))
		"siete":
			draw_string(FUENTE, Vector2(-2, 17), "7", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, CREMA)
		"traje":
			draw_colored_polygon(PackedVector2Array([Vector2(-1, 7), Vector2(2, 7), Vector2(2, 19), Vector2(0.5, 21), Vector2(-1, 19)]), ROJO)


# Sin contorno, como el cuerpo: base más oscura y encima otra capa más clara, temblando a 12 fps.
func _cosa(puntos: Array, c: Color, foto: int) -> void:
	var p := PackedVector2Array()
	for xy: Array in puntos:
		p.append(Vector2(xy[0], xy[1]))
	draw_colored_polygon(Tinta.temblar(p, 31, foto, 0.6), c.darkened(0.1))
	var centro := Vector2.ZERO
	for q in p:
		centro += q / p.size()
	var dentro := PackedVector2Array()
	for q in p:
		dentro.append(centro + (q - centro) * 0.75 + Vector2(-0.5, -0.5))
	draw_colored_polygon(dentro, Color(c.lightened(0.15), 0.8))


func _ojo(centro: Vector2, radio: float, mira: Vector2) -> void:
	draw_circle(centro, radio, Color.WHITE)
	draw_circle(centro + mira, radio * 0.45, Acuarela.CIRUELA)

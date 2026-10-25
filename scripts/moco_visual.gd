# El moco: se dibuja con código. Tiembla, se estira hacia donde va y tiene los ojos desiguales.
class_name MocoVisual
extends Node2D

const RADIO := 22.0
var color := Acuarela.MENTA
var velocidad := Vector2.ZERO  # la pone el Jugador cada frame
var pelo := "calvo"  # ver Perfil.PELOS
var sombrero := "nada"  # ver Perfil.SOMBREROS

# Peinados y sombreros, en coordenadas del moco (la coronilla está en y = -22). Cada pieza: [puntos, color].
const COSAS := {
	"cresta": [[[-4, -20], [-7, -33], [-2, -24], [0, -37], [2, -24], [7, -34], [5, -20]], Color("ef8fae")],
	"skrillex": [[[-15, -12], [-9, -27], [5, -27], [16, -21], [5, -21], [-3, -15], [-9, -4], [-14, -2]], Acuarela.CIRUELA],
	"gorra": [[[-14, -15], [-12, -27], [0, -31], [12, -28], [14, -17], [26, -17], [24, -13], [-14, -12]], Color("ef8fae")],
	"lana": [[[-15, -14], [-13, -29], [0, -35], [13, -29], [15, -14]], Color("6cc3b0")],
	"chistera": [[[-16, -19], [-9, -21], [-9, -44], [9, -44], [9, -21], [16, -19], [16, -16], [-16, -16]], Acuarela.CIRUELA],
	"corona": [[[-11, -18], [-12, -32], [-6, -25], [0, -35], [6, -25], [12, -32], [11, -18]], Color("f5d38a")],
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
	var mira := velocidad.normalized() * 3.0 if velocidad.length() > 30.0 else Vector2.ZERO
	_ojo(Vector2(-6, -4), 9.0, mira)
	_ojo(Vector2(9, -7), 5.5, mira)
	draw_arc(Vector2(2, 8), 6.0, 0.3, PI - 0.3, 8, Acuarela.CIRUELA, 3.0)
	for cosa: String in [pelo, sombrero]:
		if COSAS.has(cosa):
			_cosa(COSAS[cosa][0], COSAS[cosa][1], foto)
	match sombrero:  # detalles que no son un solo polígono
		"lana":
			draw_circle(Vector2(0, -37), 4.5, Color("fffaf4"))
		"chistera":
			draw_rect(Rect2(-9, -25, 18, 4), Color(Acuarela.ROSA, 0.9))
		"corona":
			draw_circle(Vector2(0, -27), 2.0, Acuarela.ROSA)


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

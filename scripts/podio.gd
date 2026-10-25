# Podio final: escalones que suben con rebote, mocos botando, copa, ramo y papelitos.
class_name Podio
extends Control

const FUENTE := preload("res://assets/fuentes/Bangers-Regular.ttf")
const SUELO := 650.0
const COLOR_ESCALON := {1: Acuarela.ROSA, 2: Acuarela.AZUL_LEJOS, 3: Color("f6d9b8")}
const ALTO_ESCALON := {1: 180.0, 2: 130.0, 3: 80.0}
const DORADO := Color("f2c27a")
const PAPELES := [Acuarela.ROSA, Acuarela.LAVANDA, Acuarela.MENTA, DORADO]

var filas: Array = []  # [color, nombre, victorias, segundos, aspecto?], el ganador primero
var t := 0.0


# Los escalones de izquierda a derecha: el 2º, el 1º en el centro y el 3º. Con menos jugadores, los que haya.
static func escalones(n: int) -> Array:
	var lista := []
	for puesto in [2, 1, 3]:
		if puesto <= n:
			lista.append({"puesto": puesto, "x": {1: 0.0, 2: -200.0, 3: 200.0}[puesto],
					"copa": puesto == 1, "ramo": puesto == 2, "retraso": (mini(n, 3) - puesto) * 0.45 + 0.1})
	return lista


func mostrar(filas_: Array) -> void:
	filas = filas_
	t = 0.0
	for m in get_children():
		remove_child(m)
		m.queue_free()
	for i in mini(filas.size(), 4):
		var m := MocoVisual.new()
		m.color = filas[i][0]
		if filas[i].size() > 4:
			m.vestir(filas[i][4])
		add_child(m)  # el hijo i es el moco del puesto i + 1
	visible = not filas.is_empty()


func ocultar() -> void:
	visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	t += delta
	queue_redraw()


# Sube pasándose un poco y se asienta.
static func rebote(x: float) -> float:
	var q := clampf(x, 0.0, 1.0) - 1.0
	return 1.0 + 2.70158 * q * q * q + 1.70158 * q * q


func _draw() -> void:
	var cx := size.x / 2.0
	_papelitos()
	for e in escalones(filas.size()):
		var puesto: int = e.puesto
		var q: float = rebote((t - e.retraso) / 0.7)
		var alfa := clampf((t - e.retraso) / 0.2, 0.0, 1.0)
		var alto: float = ALTO_ESCALON[puesto]
		var x: float = cx + e.x
		var subida := (1.0 - q) * 200.0
		var cima := SUELO - alto + subida
		var caja := StyleBoxFlat.new()
		caja.bg_color = Color(COLOR_ESCALON[puesto], 0.88 * alfa)
		caja.set_corner_radius_all(10)
		draw_style_box(caja, Rect2(x - 70, cima, 140, alto))
		draw_string(FUENTE, Vector2(x - 70, cima + alto / 2.0 + 24), str(puesto), HORIZONTAL_ALIGNMENT_CENTER, 140, 72, Color(1, 1, 1, 0.9 * alfa))
		draw_string(FUENTE, Vector2(x - 90, SUELO + 40), filas[puesto - 1][1], HORIZONTAL_ALIGNMENT_CENTER, 180, 34, Color(Acuarela.CIRUELA, alfa))
		var moco: MocoVisual = get_child(puesto - 1)
		var s := sin(t * 5.0 + puesto)  # cada uno bota a su ritmo
		moco.modulate.a = alfa
		moco.scale = Vector2(1.5 * (1.0 + 0.06 * s), 1.5 * (1.0 - 0.06 * s))
		moco.position = Vector2(x, cima - MocoVisual.RADIO * moco.scale.y)
		if e.copa:
			_copa(Vector2(x, cima - 135.0), alfa)
		if e.ramo:
			_ramo(Vector2(x + 62, cima - 28.0), alfa)
	if filas.size() > 3:  # el 4º, pequeño en el suelo con su puesto
		var m4: MocoVisual = get_child(3)
		m4.scale = Vector2(0.9, 0.9)
		m4.position = Vector2(cx + 400, SUELO - 20)
		draw_string(FUENTE, Vector2(cx + 330, SUELO + 40), "4. " + filas[3][1], HORIZONTAL_ALIGNMENT_CENTER, 140, 30, Color(Acuarela.CIRUELA, 0.8))


func _copa(c: Vector2, alfa: float) -> void:
	var oro := Color(DORADO, alfa)
	var base := Color("e3ad5a", alfa)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-26, -26), c + Vector2(26, -26), c + Vector2(22, -2), c + Vector2(0, 14), c + Vector2(-22, -2)]), oro)
	draw_rect(Rect2(c + Vector2(-5, 12), Vector2(10, 14)), base)
	draw_rect(Rect2(c + Vector2(-18, 24), Vector2(36, 9)), base)
	draw_circle(c + Vector2(-10, -14), 5.0, Color(1, 1, 1, 0.5 * alfa))


func _ramo(c: Vector2, alfa: float) -> void:
	var tallo := Color("7fae6a", alfa)
	for dx in [-10.0, 0.0, 10.0]:
		draw_line(c + Vector2(0, 40), c + Vector2(dx, 0), tallo, 5.0)
	for flor in [[Vector2(-10, -2), Acuarela.ROSA], [Vector2(10, -2), DORADO], [Vector2(0, -16), Acuarela.LAVANDA]]:
		draw_circle(c + flor[0], 11.0, Color(flor[1], alfa))
		draw_circle(c + flor[0], 4.0, Color(1, 1, 1, 0.6 * alfa))


# Determinista: cada papelito sale de su número, sin azar global.
func _papelitos() -> void:
	for i in 36:
		var x := fposmod(i * 197.0, size.x)
		var vel := 90.0 + (i * 37) % 70
		var y := fposmod(t * vel + i * 83.0, size.y + 60.0) - 30.0
		draw_set_transform(Vector2(x + sin(t + i) * 14.0, y), t * 2.0 + i)
		draw_rect(Rect2(-6, -3, 12, 6), Color(PAPELES[i % 4], 0.8))
	draw_set_transform(Vector2.ZERO)

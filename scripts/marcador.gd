# Tarjetas del marcador: una por moco, con barra de victorias. Sirve para el final de ronda y para Tab.
class_name Marcador
extends Control

const FUENTE := preload("res://assets/fuentes/Bangers-Regular.ttf")
const ANCHO := 760.0
const ALTO := 76.0
const PASO := 88.0
const SEGUNDOS := 2.4

var filas: Array = []  # [color, nombre, victorias, segundos, aspecto?], el primero arriba
var previo := {}  # clave -> [puesto, victorias] de la última ronda mostrada con animación
var desde := {}  # lo mismo, pero solo mientras dura la animación en curso
var p := 1.0  # progreso de la animación; 1 = todo en su sitio
var animando := false
var tween: Tween


static func clave(f: Array) -> String:
	return "%s%s" % [f[1], (f[0] as Color).to_html()]


# Las claves de quien ha sumado victorias desde la ronda anterior: reciben el «+1».
static func ganadores(filas_: Array, previo_: Dictionary) -> Array:
	return filas_.filter(func(f: Array) -> bool: return f[2] > previo_.get(clave(f), [0, 0])[1]).map(clave)


func mostrar(filas_: Array, animar: bool) -> void:
	filas = filas_
	for m in get_children():
		remove_child(m)
		m.queue_free()
	for f: Array in filas:
		var m := MocoVisual.new()
		m.color = f[0]
		m.scale = Vector2(0.7, 0.7)
		if f.size() > 4:
			m.vestir(f[4])
		add_child(m)
	if tween:
		tween.kill()
	animando = animar
	desde = previo if animar else {}
	p = 0.0 if animar else 1.0
	if animar:
		tween = create_tween()
		tween.tween_property(self, "p", 1.0, SEGUNDOS)
		previo = {}
		for i in filas.size():
			previo[clave(filas[i])] = [i, filas[i][2]]
	visible = not filas.is_empty()


func ocultar() -> void:
	visible = false


func _puesto_visto(i: int) -> float:
	var antes: Array = desde.get(clave(filas[i]), [i, 0])
	return lerpf(antes[0], i, ease(clampf((p - 0.4) / 0.4, 0.0, 1.0), -2.0))  # desliza a su nuevo puesto


func _process(_delta: float) -> void:
	if not visible:
		return
	var y0 := (size.y - (filas.size() * PASO - 12.0)) / 2.0
	for i in filas.size():
		get_child(i).position = Vector2(100, y0 + _puesto_visto(i) * PASO + ALTO / 2.0 + 4.0)
	queue_redraw()


func _barra(x: float, y: float, w: float, c: Color) -> void:
	var caja := StyleBoxFlat.new()
	caja.bg_color = c
	caja.set_corner_radius_all(11)
	draw_style_box(caja, Rect2(x, y, maxf(w, 0.0), 22.0))


func _draw() -> void:
	var y0 := (size.y - (filas.size() * PASO - 12.0)) / 2.0
	var maximo := 1
	for f: Array in filas:
		maximo = maxi(maximo, f[2])
	var suben := ganadores(filas, desde) if animando else []
	var x0 := (size.x - ANCHO) / 2.0
	for i in filas.size():
		var f: Array = filas[i]
		var y := y0 + _puesto_visto(i) * PASO
		var tuyo: bool = f[1] == "TÚ"
		var caja := StyleBoxFlat.new()
		caja.bg_color = Color(1, 0.98, 0.957, 0.98 if tuyo else 0.8)
		caja.set_corner_radius_all(26)
		if tuyo:  # el borde de tu color en vez de contorno: tu tarjeta se distingue sin pintar líneas
			caja.shadow_color = Color(f[0], 0.55)
			caja.shadow_size = 8
		draw_style_box(caja, Rect2(x0, y, ANCHO, ALTO))
		var tinta := Color(Acuarela.CIRUELA, 1.0 if tuyo else 0.82)
		draw_string(FUENTE, Vector2(x0 + 22, y + 52), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 44, tinta)
		draw_string(FUENTE, Vector2(x0 + 130, y + 50), f[1], HORIZONTAL_ALIGNMENT_LEFT, 170, 36, tinta)
		var antes: int = desde.get(clave(f), [i, 0])[1]
		var barra: float = lerpf(antes, f[2], clampf(p / 0.4, 0.0, 1.0)) / maximo * 220.0
		draw_style_box(_fondo_barra(), Rect2(x0 + 310, y + 27, 220, 22))
		_barra(x0 + 310, y + 27, barra, Color(f[0], 0.85 if tuyo else 0.7))
		draw_string(FUENTE, Vector2(x0 + 576, y + 50), _derecha(f), HORIZONTAL_ALIGNMENT_LEFT, 170, 32, tinta)
		if clave(f) in suben:
			var q := clampf((p - 0.4) / 0.6, 0.0, 1.0)
			draw_string(FUENTE, Vector2(x0 + 536, y + 50 - 34 * q), "+1", HORIZONTAL_ALIGNMENT_LEFT, -1, 44,
					Color((f[0] as Color).darkened(0.35), sin(q * PI)))  # entre la barra y las victorias


static func minutos(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


func _fondo_barra() -> StyleBoxFlat:
	var c := StyleBoxFlat.new()
	c.bg_color = Color(Acuarela.CIRUELA, 0.1)
	c.set_corner_radius_all(11)
	return c


func _derecha(f: Array) -> String:
	if f[2] > 0:
		return "%d %s" % [f[2], "VICTORIA" if f[2] == 1 else "VICTORIAS"]
	return "0 · %s" % minutos(f[3])

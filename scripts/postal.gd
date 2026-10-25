# Postal pintada de un mapa: papel crema algo torcido, miniatura del recorrido real de la
# semilla y el título debajo. Con `filas` añade al lado las victorias de cada moco.
# La usan la configuración de partida (pequeña) y la transición entre rondas (grande).
class_name Postal
extends Control

const FUENTE := preload("res://assets/fuentes/Bangers-Regular.ttf")
const PAPEL := Color("fffaf4")

var titulo := "":
	set(v): titulo = v; queue_redraw()
var semilla := 0:
	set(v): semilla = v; _mapa = Generador.generar(v); queue_redraw()
var tema := "azotea":  # sus colores: cielo, siluetas y suelo
	set(v): tema = v; queue_redraw()
var apagada := false:  # en la configuración: mapa que no saldrá
	set(v): apagada = v; queue_redraw()
var filas := []:  # [[color, victorias], ...]
	set(v): filas = v; queue_redraw()
var _mapa := {}


func _draw() -> void:
	var ancho := size.x - (110.0 if not filas.is_empty() else 0.0)
	draw_set_transform(Vector2(ancho / 2.0, size.y / 2.0), -0.05, Vector2.ONE)
	var papel := Rect2(-ancho / 2.0, -size.y / 2.0, ancho, size.y)
	draw_rect(papel, PAPEL)
	var margen := ancho * 0.05
	var alto_titulo := size.y * 0.2
	var foto := Rect2(papel.position + Vector2(margen, margen), Vector2(ancho - 2 * margen, size.y - 2 * margen - alto_titulo))
	var d: Dictionary = Temas.DATOS[tema]
	draw_rect(foto, d.cielo[1].lerp(d.cielo[0], 0.4))
	_miniatura(foto, d)
	if apagada:  # el papel tapa la foto y un sello torcido: ese mapa no va
		draw_rect(papel, Color(PAPEL, 0.7))
		draw_set_transform(Vector2(ancho / 2.0, size.y / 2.0), -0.3, Vector2.ONE)
		draw_string(FUENTE, Vector2(-ancho / 2.0, alto_titulo * 0.1), "FUERA", HORIZONTAL_ALIGNMENT_CENTER, ancho, int(size.y * 0.3), Acuarela.ROSA)
		draw_set_transform(Vector2(ancho / 2.0, size.y / 2.0), -0.05, Vector2.ONE)
	var letra := int(alto_titulo * 0.8)
	while letra > 8 and FUENTE.get_string_size(titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, letra).x > ancho * 0.92:
		letra -= 1  # nombres largos ("VERBENA EN LOS TEJADOS"): más pequeño antes que cortado
	draw_string(FUENTE, Vector2(papel.position.x, papel.end.y - alto_titulo * 0.3), titulo, HORIZONTAL_ALIGNMENT_CENTER, ancho, letra, Acuarela.CIRUELA)
	draw_set_transform(Vector2.ZERO)
	for i in filas.size():  # victorias, al lado de la postal
		var y := 40.0 + i * 54.0
		draw_circle(Vector2(size.x - 80.0, y), 16.0, filas[i][0])
		draw_string(FUENTE, Vector2(size.x - 50.0, y + 14.0), str(filas[i][1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Acuarela.CIRUELA)


# El primer tramo del recorrido dentro de la foto, con los colores del juego. Entero sería
# una tira de rayitas: el mapa es 10 veces más largo que alto.
func _miniatura(foto: Rect2, d: Dictionary) -> void:
	if _mapa.is_empty():
		return
	var mundo := Rect2(300.0, 0.0, 1100.0 * foto.size.x / foto.size.y, 1100.0)
	var escala := foto.size.y / mundo.size.y
	var origen := foto.position - mundo.position * escala
	var ciudad := PackedVector2Array()  # edificios del fondo, para que se lea como "tejados"
	for k in 7:
		var x := foto.position.x + foto.size.x * k / 7.0
		var alto := foto.size.y * (0.25 + 0.15 * ((k * 37 + semilla) % 5) / 4.0)
		ciudad.append_array([Vector2(x, foto.end.y - alto), Vector2(x + foto.size.x / 7.0 - 3.0, foto.end.y - alto)])
	ciudad.append_array([foto.end, Vector2(foto.position.x, foto.end.y)])
	Acuarela.pintar(self, ciudad, d.lejos, semilla)
	for p: Dictionary in _mapa.piezas:
		if p.pos.x > mundo.end.x + 200.0:
			continue
		var color: Color = Acuarela.ROSA if p.enganchable else d.suelo
		var poly := PackedVector2Array()
		for v: Vector2 in p.poly:
			poly.append(origen + (p.pos + v) * escala)
		if Array(poly).all(func(q: Vector2) -> bool: return foto.has_point(q)):  # lo que no cabe entero, fuera
			Acuarela.pintar(self, poly, color, hash(p.nombre))

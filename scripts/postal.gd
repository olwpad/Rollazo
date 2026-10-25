# Postal pintada de un mapa: papel crema algo torcido, miniatura del recorrido real de la
# semilla y el título debajo. Con `filas` añade al lado las victorias de cada moco.
# La usan la configuración de partida (pequeña) y la transición entre rondas (grande).
class_name Postal
extends Control

const FUENTE := preload("res://assets/fuentes/Bangers-Regular.ttf")
const PAPEL := Color("fffaf4")
const CIELO := Color("ddd6f2")

var titulo := "":
	set(v): titulo = v; queue_redraw()
var semilla := 0:
	set(v): semilla = v; _mapa = Generador.generar(v); queue_redraw()
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
	draw_rect(foto, CIELO)
	_miniatura(foto)
	var letra := int(alto_titulo * 0.8)
	draw_string(FUENTE, Vector2(papel.position.x, papel.end.y - alto_titulo * 0.3), titulo, HORIZONTAL_ALIGNMENT_CENTER, ancho, letra, Acuarela.CIRUELA)
	draw_set_transform(Vector2.ZERO)
	for i in filas.size():  # victorias, al lado de la postal
		var y := 40.0 + i * 54.0
		draw_circle(Vector2(size.x - 80.0, y), 16.0, filas[i][0])
		draw_string(FUENTE, Vector2(size.x - 50.0, y + 14.0), str(filas[i][1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Acuarela.CIRUELA)


# El recorrido entero encogido dentro de la foto, con los colores del juego.
func _miniatura(foto: Rect2) -> void:
	if _mapa.is_empty():
		return
	var mundo := Rect2(-100.0, 0.0, _mapa.meta.x + 500.0, 900.0)
	var escala := minf(foto.size.x / mundo.size.x, foto.size.y / mundo.size.y)
	var origen := foto.position + (foto.size - mundo.size * escala) / 2.0 - mundo.position * escala
	for p: Dictionary in _mapa.piezas:
		var color := Acuarela.ROSA if p.enganchable else Acuarela.AZOTEA
		var poly := PackedVector2Array()
		for v: Vector2 in p.poly:
			var punto: Vector2 = origen + (p.pos + v) * escala
			poly.append(punto.clamp(foto.position, foto.end))  # los pilares no se salen de la foto
		draw_colored_polygon(poly, Color(color, 0.8))
	draw_circle(origen + _mapa.meta * escala, maxf(3.0, 40.0 * escala), Acuarela.CIRUELA)

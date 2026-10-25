# Pegatina redonda de acuarela: título pequeño arriba y el valor grande (el `text` del botón).
# Al pulsarla, quien la usa cambia el valor (5 → 7 rondas, SÍ ↔ NO).
extends Button

const FUENTE := preload("res://assets/fuentes/Bangers-Regular.ttf")

@export var color := Acuarela.LAVANDA
@export var titulo := ""
@export var letra_oscura := false  # sobre colores claros (amarillo) el texto va en ciruela
@export var inclinacion := 0.0  # en el dibujo: el contenedor le quitaría la rotación al nodo

var _encima := false


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	add_theme_color_override("font_color", Color.TRANSPARENT)  # el texto lo pinta _draw, encima del círculo
	add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	mouse_entered.connect(func(): _encima = true; queue_redraw())
	mouse_exited.connect(func(): _encima = false; queue_redraw())


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 * (1.06 if _encima else 1.0)
	draw_set_transform(c, inclinacion, Vector2.ONE)  # gira alrededor del centro
	c = Vector2.ZERO
	draw_circle(c, r, Color(color, 0.6))
	draw_circle(c + Vector2(2, -1), r * 0.9, Color(color, 0.55))  # dos capas, borde más intenso
	var tinta := Acuarela.CIRUELA if letra_oscura else Color("fffaf4")
	draw_string(FUENTE, Vector2(-size.x / 2.0, -r * 0.2), titulo, HORIZONTAL_ALIGNMENT_CENTER, size.x, int(r * 0.24), tinta)
	draw_string(FUENTE, Vector2(-size.x / 2.0, r * 0.45), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, int(r * 0.62), tinta)

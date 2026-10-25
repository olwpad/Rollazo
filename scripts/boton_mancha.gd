# Botón de texto sin caja: al pasar el ratón aparece detrás una mancha de acuarela rosa.
# El principal (Empezar) la lleva siempre puesta.
extends Button

@export var principal := false

var mancha := Polygon2D.new()


func _ready() -> void:
	flat = true
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	mancha.show_behind_parent = true  # se dibuja detrás del texto del botón
	mancha.color = Color(Acuarela.ROSA, 0.55)
	add_child(mancha)
	resized.connect(_pintar_mancha)
	mouse_entered.connect(_mostrar.bind(true))
	mouse_exited.connect(_mostrar.bind(false))
	_pintar_mancha()
	mancha.visible = principal


func _pintar_mancha() -> void:
	var ancho := get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size("font_size")).x + 36.0
	var caja := PackedVector2Array([Vector2(-14, 6), Vector2(ancho, 2), Vector2(ancho + 4, size.y - 4), Vector2(-10, size.y - 2)])
	mancha.polygon = Tinta.irregular(caja, hash(text), 4.0, 20.0)


func _mostrar(encima: bool) -> void:
	mancha.visible = encima or principal
	if encima:  # pequeño "pop" al aparecer
		mancha.scale = Vector2(0.9, 0.8)
		create_tween().tween_property(mancha, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

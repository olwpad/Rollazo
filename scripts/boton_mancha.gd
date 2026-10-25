# Botón de texto sin caja: al pasar el ratón aparece detrás una mancha de acuarela rosa.
# El principal (Empezar) la lleva siempre puesta.
extends Button

@export var principal := false
## 0..1: la mancha se llena por partes (jugadores listos). Negativo = mancha normal.
var progreso := -1.0:
	set(v): progreso = v; _pintar_mancha()

var mancha := Polygon2D.new()
var lleno := Polygon2D.new()
var _texto_pintado := ""


func _ready() -> void:
	flat = true
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	for p: Polygon2D in [mancha, lleno]:
		p.show_behind_parent = true  # se dibuja detrás del texto del botón
		add_child(p)
	mancha.color = Color(Acuarela.ROSA, 0.55)
	lleno.color = Color(Acuarela.ROSA, 0.8)
	resized.connect(_pintar_mancha)
	mouse_entered.connect(_mostrar.bind(true))
	mouse_exited.connect(_mostrar.bind(false))
	_pintar_mancha()
	mancha.visible = principal


func _process(_delta: float) -> void:
	if text != _texto_pintado:  # el texto cambió (p. ej. "2/3 LISTOS"): la mancha debe abarcarlo
		_pintar_mancha()


func _pintar_mancha() -> void:
	_texto_pintado = text
	var ancho := get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size("font_size")).x + 36.0
	var caja := PackedVector2Array([Vector2(-14, 6), Vector2(ancho, 2), Vector2(ancho + 4, size.y - 4), Vector2(-10, size.y - 2)])
	mancha.polygon = Tinta.irregular(caja, hash(text), 4.0, 20.0)
	mancha.color.a = 0.3 if progreso >= 0.0 else 0.55
	lleno.visible = progreso > 0.0
	var fin := -10.0 + (ancho + 14.0) * clampf(progreso, 0.0, 1.0)
	lleno.polygon = Tinta.irregular(PackedVector2Array([Vector2(-14, 6), Vector2(fin, 4), Vector2(fin, size.y - 4), Vector2(-10, size.y - 2)]), hash(text) + 1, 4.0, 20.0)


func _mostrar(encima: bool) -> void:
	mancha.visible = encima or principal
	if encima:  # pequeño "pop" al aparecer
		mancha.scale = Vector2(0.9, 0.8)
		create_tween().tween_property(mancha, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

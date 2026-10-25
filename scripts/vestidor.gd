# "TU MOCO": tu moco de pie en la azotea y, al lado, flechas ‹ › para sombrero, pelo, cara, ropa y color.
# Lo que tiene candado se puede ver puesto, pero solo se guarda lo desbloqueado.
extends Control

signal cerrado

const FILAS := ["Sombrero", "Pelo", "Cara", "Ropa", "Color"]
const CARTA := Vector2(340, 84)
const PASO := 116.0  # de una carta a la siguiente: cabe el requisito debajo
const ARRIBA := 70.0
const CARTA_X := 860.0
const CREMA := Color("fffaf4")

var moco := MocoVisual.new()
var _indices := {"Sombrero": 0, "Pelo": 0, "Cara": 0, "Ropa": 0, "Color": 0}


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var grande := Node2D.new()  # escala aparte: aplastar() devuelve el moco a escala 1
	grande.position = Vector2(470, 600 - MocoVisual.RADIO * 4.0)  # de pie en la azotea
	grande.scale = Vector2(4.0, 4.0)
	grande.add_child(moco)
	add_child(grande)
	for i in FILAS.size():
		var fila := Control.new()
		fila.name = FILAS[i]
		fila.position = Vector2(CARTA_X, ARRIBA + i * PASO)
		fila.size = CARTA
		add_child(fila)
		_etiqueta(fila, "Titulo", FILAS[i].to_upper(), 18, Acuarela.AZOTEA, Vector2(0, 6))
		_etiqueta(fila, "Valor", "", 28, Acuarela.CIRUELA, Vector2(0, 30))
		_etiqueta(fila, "Requisito", "", 17, CREMA, Vector2(0, CARTA.y + 2))
		for flecha in [["Menos", "‹", 8.0, -1], ["Mas", "›", CARTA.x - 52.0, 1]]:
			var b := Button.new()
			b.name = flecha[0]
			b.text = flecha[1]
			b.flat = true
			b.focus_mode = Control.FOCUS_NONE
			b.position = Vector2(flecha[2], 6)
			b.size = Vector2(44, 72)
			b.add_theme_font_size_override("font_size", 60)
			for estado in ["font_color", "font_hover_color", "font_pressed_color"]:
				b.add_theme_color_override(estado, Acuarela.ROSA.darkened(0.15 if estado == "font_hover_color" else 0.0))
			b.pressed.connect(_mover.bind(FILAS[i], flecha[3]))
			fila.add_child(b)
	var listo := Button.new()
	listo.name = "Listo"
	listo.text = "‹ LISTO"
	listo.set_script(load("res://scripts/boton_mancha.gd"))
	listo.position = Vector2(40, 30)
	listo.add_theme_font_size_override("font_size", 34)
	listo.pressed.connect(_cerrar)
	add_child(listo)
	visible = false


func abrir() -> void:
	_desde_perfil()
	visible = true


func _cerrar() -> void:
	_desde_perfil()  # si te quedaste mirando algo con candado, vuelves a lo tuyo
	visible = false
	cerrado.emit()


func _desde_perfil() -> void:
	for fila in ["Sombrero", "Pelo", "Cara", "Ropa"]:
		_indices[fila] = _lista(fila).find(Perfil.aspecto[fila.to_lower()])
	_indices.Color = Perfil.aspecto.color
	_pintar()


func _lista(fila: String) -> Array:
	return Perfil.NOMBRES_COLOR if fila == "Color" else Perfil.FILAS[fila.to_lower()]


func _mover(fila: String, paso: int) -> void:
	_indices[fila] = posmod(_indices[fila] + paso, _lista(fila).size())
	# Perfil.poner no guarda lo que tiene candado
	Perfil.poner(fila.to_lower(), _indices.Color if fila == "Color" else _lista(fila)[_indices[fila]])
	moco.aplastar(Vector2(1.15, 0.85))
	_pintar()


func _pintar() -> void:
	var puesto := {}
	for fila in ["Sombrero", "Pelo", "Cara", "Ropa"]:
		puesto[fila.to_lower()] = _lista(fila)[_indices[fila]]
	moco.vestir(puesto)
	moco.color = Perfil.COLORES[_indices.Color]
	for fila in FILAS:
		var cosa: String = _lista(fila)[_indices[fila]]
		var nodo := get_node(fila)
		nodo.get_node("Valor").text = cosa if fila == "Color" else Perfil.NOMBRES[cosa]
		var req := "" if fila == "Color" else Perfil.requisito(cosa)
		nodo.get_node("Requisito").text = req
		nodo.get_node("Valor").modulate.a = 0.45 if req != "" else 1.0
	queue_redraw()


func _etiqueta(padre: Control, nombre: String, texto: String, tam: int, color: Color, pos: Vector2) -> void:
	var l := Label.new()
	l.name = nombre
	l.text = texto
	l.position = pos
	l.size = Vector2(CARTA.x, tam + 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	padre.add_child(l)


func _draw() -> void:
	Acuarela.pintar(self, PackedVector2Array([Vector2(0, 600), Vector2(1280, 590), Vector2(1280, 720), Vector2(0, 720)]), Acuarela.AZOTEA, 13)
	for i in FILAS.size():
		var o := Vector2(CARTA_X, ARRIBA + i * PASO)
		Acuarela.pintar(self, PackedVector2Array([o, o + Vector2(CARTA.x, 6), o + CARTA + Vector2(-4, 0), o + Vector2(0, CARTA.y - 6)]), CREMA, 20 + i)
		if get_node(FILAS[i]).get_node("Requisito").text != "":
			_candado(o + Vector2(CARTA.x - 76, 46))


func _candado(c: Vector2) -> void:
	draw_arc(c + Vector2(0, -4), 7.0, PI, TAU, 10, Acuarela.CIRUELA, 4.0)
	draw_rect(Rect2(c + Vector2(-11, -4), Vector2(22, 18)), Acuarela.CIRUELA)

# "TU MOCO": tu moco de pie en la azotea y, al lado, flechas ‹ › para un famoso ya montado o pieza a pieza
# (sombrero, pelo, cara, ropa y color).
# Lo que tiene candado se puede ver puesto, pero solo se guarda lo desbloqueado.
# Pantalla de UI construida por código (no hay .tscn de las filas); lee y guarda en el autoload Perfil.
extends Control

signal cerrado

const FILAS := ["Famoso", "Sombrero", "Pelo", "Cara", "Ropa", "Color"]
const PIEZAS := ["Sombrero", "Pelo", "Cara", "Ropa"]
const CARTA := Vector2(340, 72)
const PASO := 100.0  # de una carta a la siguiente: cabe el requisito debajo
const ARRIBA := 48.0
const CARTA_X := 860.0
const CREMA := Color("fffaf4")

var moco := MocoVisual.new()
var _indices := {"Famoso": 0, "Sombrero": 0, "Pelo": 0, "Cara": 0, "Ropa": 0, "Color": 0}


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var grande := Node2D.new()  # escala aparte: aplastar() devuelve el moco a escala 1
	grande.position = Vector2(470, 600 - MocoVisual.RADIO * 4.0)  # de pie en la azotea
	grande.scale = Vector2(4.0, 4.0)
	grande.add_child(moco)
	add_child(grande)
	for i in FILAS.size():
		_crear_fila(i)
	var listo := Button.new()
	listo.name = "Listo"
	listo.text = "‹ LISTO"
	listo.set_script(load("res://scripts/boton_mancha.gd"))
	listo.position = Vector2(40, 30)
	listo.add_theme_font_size_override("font_size", 34)
	listo.pressed.connect(_cerrar)
	add_child(listo)
	var nombre := LineEdit.new()  # bajo el moco, como la etiqueta con tu nombre
	nombre.name = "Nombre"
	nombre.placeholder_text = "ESCRIBE TU NOMBRE"
	nombre.max_length = Perfil.LARGO_NOMBRE
	nombre.alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.position = Vector2(310, 630)
	nombre.size = Vector2(320, 56)
	nombre.add_theme_font_size_override("font_size", 30)
	var papel := StyleBoxFlat.new()  # papel crema, como las cartas de la derecha
	papel.bg_color = Color(CREMA, 0.95)
	papel.set_corner_radius_all(4)
	for estilo in ["normal", "focus"]:
		nombre.add_theme_stylebox_override(estilo, papel)
	nombre.add_theme_color_override("font_color", Acuarela.CIRUELA)
	nombre.add_theme_color_override("font_placeholder_color", Color(Acuarela.AZOTEA, 0.8))
	nombre.add_theme_color_override("caret_color", Acuarela.CIRUELA)
	nombre.text_changed.connect(Perfil.poner_nombre)
	add_child(nombre)
	visible = false


# Una fila del menú: título, valor, requisito y flechas ‹ ›.
func _crear_fila(i: int) -> void:
	var fila := Control.new()
	fila.name = FILAS[i]
	fila.position = Vector2(CARTA_X, ARRIBA + i * PASO)
	fila.size = CARTA
	add_child(fila)
	_etiqueta(fila, "Titulo", FILAS[i].to_upper(), 16, Acuarela.AZOTEA, Vector2(0, 4))
	_etiqueta(fila, "Valor", "", 24 if FILAS[i] == "Famoso" else 26, Acuarela.CIRUELA, Vector2(0, 26))
	_etiqueta(fila, "Requisito", "", 17, Acuarela.CIRUELA, Vector2(14, CARTA.y + 2))  # ciruela: se lee también sobre el sol
	for flecha in [["Menos", "‹", 8.0, -1], ["Mas", "›", CARTA.x - 52.0, 1]]:
		var b := Button.new()
		b.name = flecha[0]
		b.text = flecha[1]
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.position = Vector2(flecha[2], 0)
		b.size = Vector2(44, 66)
		b.add_theme_font_size_override("font_size", 54)
		for estado in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(estado, Acuarela.ROSA.darkened(0.15 if estado == "font_hover_color" else 0.0))
		b.pressed.connect(_mover.bind(FILAS[i], flecha[3]))
		fila.add_child(b)


func abrir() -> void:
	_desde_perfil()
	visible = true


func _cerrar() -> void:
	_desde_perfil()  # si te quedaste mirando algo con candado, vuelves a lo tuyo
	visible = false
	cerrado.emit()


func _desde_perfil() -> void:
	for fila in PIEZAS:
		_indices[fila] = _lista(fila).find(Perfil.aspecto[fila.to_lower()])
	_indices.Color = Perfil.aspecto.color
	$Nombre.text = Perfil.aspecto.get("nombre", "")
	_indices.Famoso = _lista("Famoso").find(Perfil.look_puesto()) if Perfil.look_puesto() != "" else 0
	_pintar()


func _lista(fila: String) -> Array:
	match fila:
		"Color": return Perfil.NOMBRES_COLOR
		"Famoso": return ["NINGUNO"] + Perfil.LOOKS.keys()
	return Perfil.FILAS[fila.to_lower()]


func _mover(fila: String, paso: int) -> void:
	_indices[fila] = posmod(_indices[fila] + paso, _lista(fila).size())
	if fila == "Famoso":
		if _indices.Famoso > 0:  # todo el famoso de golpe; con candado se ve pero no se guarda
			var nombre: String = _lista("Famoso")[_indices.Famoso]
			for pieza in PIEZAS:
				_indices[pieza] = _lista(pieza).find(Perfil.look(nombre)[pieza.to_lower()])
			Perfil.poner_look(nombre)
	else:  # Perfil.poner no guarda lo que tiene candado
		Perfil.poner(fila.to_lower(), _indices.Color if fila == "Color" else _lista(fila)[_indices[fila]])
		if fila != "Color":
			var famoso := Perfil.look_puesto(_puesto())
			_indices.Famoso = _lista("Famoso").find(famoso) if famoso != "" else 0
	moco.aplastar(Vector2(1.15, 0.85))
	_pintar()


func _pintar() -> void:
	moco.vestir(_puesto())
	moco.color = Perfil.COLORES[_indices.Color]
	for fila in FILAS:
		var cosa: String = _lista(fila)[_indices[fila]]
		var nodo := get_node(fila)
		nodo.get_node("Valor").text = cosa if fila in ["Color", "Famoso"] else Perfil.NOMBRES[cosa]
		var req := ""
		if fila == "Famoso":
			req = Perfil.requisito_look(cosa) if _indices.Famoso > 0 else ""
		elif fila != "Color":
			req = Perfil.requisito(cosa)
		nodo.get_node("Requisito").text = req
		nodo.get_node("Valor").modulate.a = 0.45 if req != "" else 1.0
	queue_redraw()


# Lo que se ve puesto ahora mismo (puede tener candado).
func _puesto() -> Dictionary:
	var puesto := {}
	for fila in PIEZAS:
		puesto[fila.to_lower()] = _lista(fila)[_indices[fila]]
	return puesto


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
			_candado(o + Vector2(CARTA.x / 2.0 - 104, CARTA.y + 10), 0.6)  # junto al requisito, sin pisar el nombre


func _candado(c: Vector2, escala := 1.0) -> void:
	draw_arc(c + Vector2(0, -4) * escala, 7.0 * escala, PI, TAU, 10, Acuarela.CIRUELA, 4.0 * escala)
	draw_rect(Rect2(c + Vector2(-11, -4) * escala, Vector2(22, 18) * escala), Acuarela.CIRUELA)

# Los 4 huecos de jugador, en dos formas:
# - En el menú principal: la azotea pequeña; cuando alguien entra, su moco cae de un salto
#   con su color, y los huecos libres son un charco.
# - Dentro de una partida (tarjetas = true): una tarjeta de papel por jugador con su moco,
#   su nombre y su estado; sello "¡LISTO!" para quien está listo y hueco punteado si falta gente.
extends Node2D

const FUENTE := preload("res://assets/fuentes/Bangers-Regular.ttf")
const TARJETA := Vector2(200, 240)
const CREMA := Color("fffaf4")

var separacion := 135.0:  # el menú la ensancha en la sala online
	set(v):
		separacion = v
		for i in huecos.size():
			huecos[i].nodo.position = Vector2(i * separacion, 0)
		queue_redraw()
var tarjetas := false:
	set(v):
		tarjetas = v
		for h in huecos:
			h.nombre.add_theme_color_override("font_color", Acuarela.CIRUELA if v else CREMA)
		queue_redraw()
var huecos: Array[Dictionary] = []  # {nodo, moco: MocoVisual, nombre, estado, sello: Label, ocupado: bool}


func _ready() -> void:
	for i in 4:
		var hueco := Node2D.new()
		hueco.position = Vector2(i * separacion, 0)
		var grande := Node2D.new()  # escala aparte: aplastar() devuelve el moco a escala 1
		grande.scale = Vector2(1.6, 1.6)
		grande.position = Vector2(0, 22 - MocoVisual.RADIO * 1.6)  # apoyado en la azotea
		var moco := MocoVisual.new()
		moco.color = Jugador.COLORES[i]
		moco.visible = false
		grande.add_child(moco)
		var nombre := _etiqueta(Vector2(-90, 40), 22, CREMA)
		var estado := _etiqueta(Vector2(-90, 72), 18, Acuarela.AZOTEA)
		var sello := _etiqueta(Vector2(-90, 74), 30, Acuarela.MENTA)
		sello.text = "¡LISTO!"
		sello.pivot_offset = sello.size / 2.0
		sello.rotation = -0.18  # torcido, como un sello puesto a mano
		sello.visible = false
		hueco.add_child(grande)
		for l in [nombre, estado, sello]:
			hueco.add_child(l)
		add_child(hueco)
		huecos.append({"nodo": hueco, "moco": moco, "nombre": nombre, "estado": estado, "sello": sello, "ocupado": false})
	var solo_yo: Array[int] = [1]
	mostrar(solo_yo, 1)


func _etiqueta(pos: Vector2, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(180, 36)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FUENTE)  # dentro de un Node2D no llega el tema del menú
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l


# ids en el orden de la partida (el mismo que da los colores en la carrera).
func mostrar(ids: Array[int], mi_id: int, listos := {}) -> void:
	for i in huecos.size():
		var h := huecos[i]
		var ocupado := i < ids.size()
		if ocupado and not h.ocupado:
			_caer(h.moco)
		h.moco.visible = ocupado
		h.ocupado = ocupado
		if not ocupado:
			h.nombre.text = "HUECO LIBRE" if tarjetas else "ESPERANDO…"
		elif ids[i] == mi_id:
			h.nombre.text = "TÚ"
		else:
			h.nombre.text = "JUGADOR %d" % (i + 1)
		h.nombre.modulate.a = 1.0 if ocupado else 0.6
		var listo: bool = tarjetas and ocupado and listos.get(ids[i], false)
		if listo and not h.sello.visible:  # el sello cae de golpe y se asienta
			h.sello.scale = Vector2(1.8, 1.8)
			create_tween().tween_property(h.sello, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		h.sello.visible = listo
		h.estado.text = ""
		if tarjetas and ocupado and not listo:
			h.estado.text = "ANFITRIÓN" if ids[i] == 1 else "PENSÁNDOSELO…"
	queue_redraw()


func ocupados() -> int:
	return huecos.filter(func(h: Dictionary) -> bool: return h.ocupado).size()


func etiqueta(i: int) -> String:
	return huecos[i].nombre.text


func estado(i: int) -> String:
	return huecos[i].estado.text


func sello_visible(i: int) -> bool:
	return huecos[i].sello.visible


# Cae desde arriba, rebota contra la azotea y se aplasta al tocarla.
func _caer(moco: MocoVisual) -> void:
	moco.position = Vector2(0, -260)
	var tw := create_tween()
	tw.tween_property(moco, "position", Vector2.ZERO, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(moco.aplastar.bind(Vector2(1.5, 0.6)))


func _draw() -> void:
	if tarjetas:
		_dibujar_tarjetas()
		return
	var izq := -separacion * 0.8
	var azotea := PackedVector2Array([Vector2(izq, 22), Vector2(izq + separacion * 4.45, 14), Vector2(izq + separacion * 4.45, 400), Vector2(izq, 400)])
	Acuarela.pintar(self, azotea, Acuarela.AZOTEA, 11)
	for i in huecos.size():
		if not huecos[i].ocupado:  # charco del color que tendrá quien entre
			var charco := PackedVector2Array()
			for k in 14:
				var a := TAU * k / 14
				charco.append(Vector2(i * separacion + cos(a) * 30.0, 22.0 + sin(a) * 8.0))
			draw_colored_polygon(Tinta.irregular(charco, i, 2.0, 8.0), Color(Jugador.COLORES[i], 0.45))


# Una tarjeta de papel por hueco, cada una un poco torcida; la libre, solo el borde punteado.
func _dibujar_tarjetas() -> void:
	for i in huecos.size():
		draw_set_transform(Vector2(i * separacion, 5),[-0.03, 0.025, -0.015, 0.03][i], Vector2.ONE)
		var r := Rect2(-TARJETA / 2.0, TARJETA)
		if huecos[i].ocupado:
			draw_rect(r, Color(CREMA, 0.95))
		else:
			var esquinas := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
			for k in 4:
				draw_dashed_line(esquinas[k], esquinas[k + 1], Color(CREMA, 0.8), 3.0, 12.0)
	draw_set_transform(Vector2.ZERO)

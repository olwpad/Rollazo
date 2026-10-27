# Los 6 huecos de jugador, en dos formas:
# - En el menú principal: la azotea con tu moco y 3 de adorno (los libres botan; con 6 quedaba
#   abarrotado) y un único texto "HASTA 6 JUGADORES": aún no hay partida, así que nadie "espera".
# - Dentro de una partida (tarjetas = true): la misma azotea, ya de lado a lado, con cada moco de
#   pie botando junto a su cartel clavado (nombre, estado o sello "¡LISTO!"); el hueco libre es un
#   cartel punteado con "+". Así el inicio y la sala parecen el mismo sitio.
#   Los 6 van en grada: 3 delante y 3 detrás, más altos y pequeños, entre los huecos de los de delante.
extends Node2D

const FUENTE := preload("res://assets/fuentes/Bangers-Regular.ttf")
const CARTEL := Rect2(-72, -160, 144, 80)  # encima del palo, que llega a la azotea (y=22); pequeño: que se vean los mocos
const MOCO_X := 70.0  # en la sala, el moco va al lado de su cartel
const CREMA := Color("fffaf4")

const GRADA := [Vector2(-330, 0), Vector2(0, 0), Vector2(330, 0), Vector2(-190, -122), Vector2(140, -122), Vector2(470, -122)]  # el 1 (anfitrión) delante a la izquierda
const ESCALA_ATRAS := 0.75
const ATRAS_Y := -106.0  # donde pisa la grada de atrás (la de delante, en 22)
const ADORNOS := 4  # mocos en la azotea del menú: el tuyo y 3 libres
const TILT := [-0.035, 0.025, -0.015, 0.03, -0.025, 0.02]  # carteles torcidos, a mano

var separacion := 135.0:  # solo en el menú: lo que separa a los mocos de adorno
	set(v):
		separacion = v
		_colocar()
		_colocar_capacidad()
		queue_redraw()
var tarjetas := false:
	set(v):
		tarjetas = v
		_colocar()
		for h in huecos:
			h.nombre.add_theme_color_override("font_color", Acuarela.CIRUELA if v else CREMA)
			h.nombre.position = Vector2(-90, -154) if v else Vector2(-90, 40)  # en el cartel o bajo el moco
			h.nombre.add_theme_font_size_override("font_size", 18 if v else 22)
			h.estado.position = Vector2(-90, -120)
			h.estado.add_theme_font_size_override("font_size", 14)
			h.sello.position = Vector2(-90, -126)
			h.sello.add_theme_font_size_override("font_size", 24)
			h.grande.position.x = MOCO_X if v else 0.0
		if capacidad != null:
			capacidad.visible = not v
		queue_redraw()
var capacidad: Label = null  # el texto "HASTA 6 JUGADORES" del menú
var huecos: Array[Dictionary] = []  # {nodo, grande, moco: MocoVisual, nombre, estado, sello: Label, ocupado, listo: bool}


# --- Montaje ---


func _ready() -> void:
	for i in Red.MAX_JUGADORES:
		var hueco := Node2D.new()
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
		huecos.append({"nodo": hueco, "grande": grande, "moco": moco, "nombre": nombre, "estado": estado, "sello": sello, "ocupado": false, "listo": false})
	capacidad = _etiqueta(Vector2.ZERO, 26, CREMA)
	capacidad.name = "Capacidad"
	capacidad.text = "HASTA 6 JUGADORES"
	add_child(capacidad)
	_colocar()
	_colocar_capacidad()
	var solo_yo: Array[int] = [1]
	mostrar(solo_yo, 1)


# En el menú, en fila; en la sala, en grada (los de atrás, más pequeños).
func _colocar() -> void:
	for i in huecos.size():
		huecos[i].nodo.position = GRADA[i] if tarjetas else Vector2(i * separacion, 0)
		huecos[i].nodo.visible = tarjetas or i < ADORNOS
		huecos[i].nodo.scale = Vector2.ONE * (ESCALA_ATRAS if tarjetas and i >= 3 else 1.0)


# Debajo de los 3 mocos libres, a la altura del "TÚ".
func _colocar_capacidad() -> void:
	if capacidad != null:
		capacidad.position = Vector2(separacion - 90.0, 40.0)
		capacidad.size = Vector2(separacion * (ADORNOS - 2) + 180.0, 36.0)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	if tarjetas:  # en la sala botan los que están; el que está listo, más alto
		for i in huecos.size():
			if huecos[i].ocupado:
				huecos[i].moco.position.y = -absf(sin(t * 2.4 + i * 1.3)) * (16.0 if huecos[i].listo else 5.0)
		return
	for i in huecos.size():
		if not huecos[i].ocupado:  # los de adorno botan, cada uno a su ritmo
			huecos[i].moco.position.y = -absf(sin(t * 2.4 + i * 1.3)) * 14.0


func _etiqueta(pos: Vector2, tam: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(180, 36)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FUENTE)  # dentro de un Node2D no llega el tema del menú
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	return l


# --- Qué se enseña ---


# ids en el orden de la partida (el mismo que da los colores en la carrera).
func mostrar(ids: Array[int], mi_id: int, listos := {}) -> void:
	for i in huecos.size():
		var h := huecos[i]
		var ocupado := i < ids.size()
		if ocupado and not h.ocupado:
			_caer(h.moco)
		h.moco.visible = ocupado or not tarjetas  # en el menú, los de adorno
		h.ocupado = ocupado
		var aspecto: Dictionary = Red.aspecto_de(ids[i]) if ocupado else Perfil.POR_DEFECTO
		h.moco.color = Red.color_de(ids[i]) if ocupado else Jugador.COLORES[i]
		h.moco.vestir(aspecto)
		if not ocupado:
			h.moco.position = Vector2.ZERO
			h.nombre.text = "HUECO LIBRE" if tarjetas else ""
		elif ids[i] == mi_id:
			h.nombre.text = "TÚ"
		else:
			h.nombre.text = Perfil.nombre_en(aspecto, "JUGADOR %d" % (i + 1))
		h.nombre.modulate.a = 1.0 if ocupado else 0.6
		var listo: bool = tarjetas and ocupado and listos.get(ids[i], false)
		if listo and not h.sello.visible:  # el sello cae de golpe y se asienta
			h.sello.scale = Vector2(1.8, 1.8)
			create_tween().tween_property(h.sello, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		h.sello.visible = listo
		h.listo = listo
		h.estado.text = ""
		if tarjetas and ocupado and not listo:
			h.estado.text = "LISTO · ANFITRIÓN" if ids[i] == 1 else "PENSÁNDOSELO…"
	queue_redraw()


func ocupados() -> int:
	return huecos.filter(func(h: Dictionary) -> bool: return h.ocupado).size()


func etiqueta(i: int) -> String:
	return huecos[i].nombre.text


func estado(i: int) -> String:
	return huecos[i].estado.text


func sello_visible(i: int) -> bool:
	return huecos[i].sello.visible


# --- Dibujo ---


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
	var ancho := separacion * (huecos.size() - 1 + 1.45)
	var azotea := PackedVector2Array([Vector2(izq, 22), Vector2(izq + ancho, 14), Vector2(izq + ancho, 400), Vector2(izq, 400)])
	Acuarela.pintar(self, azotea, Acuarela.AZOTEA, 11)


# La azotea de lado a lado, con una grada más alta detrás, y por hueco un cartel de papel clavado en
# un palo; el libre, punteado con un "+" y la sombra en el suelo de donde irá su moco.
func _dibujar_tarjetas() -> void:
	var grada := PackedVector2Array([Vector2(-470, ATRAS_Y), Vector2(640, ATRAS_Y - 6), Vector2(640, 40), Vector2(-470, 40)])
	Acuarela.pintar(self, grada, Acuarela.AZOTEA.darkened(0.12), 13)
	var azotea := PackedVector2Array([Vector2(-700, 27), Vector2(800, 14), Vector2(800, 400), Vector2(-700, 400)])
	draw_colored_polygon(azotea, Color(Acuarela.AZOTEA.lightened(0.12), 0.55))  # base: deja asomar un poco los edificios, sin ensuciar
	Acuarela.pintar(self, azotea, Acuarela.AZOTEA, 12)
	for n in huecos.size():
		var i := (n + 3) % 6  # primero los de atrás, que los de delante los tapen
		var pos: Vector2 = GRADA[i]
		var esc := ESCALA_ATRAS if i >= 3 else 1.0
		draw_set_transform(pos, 0.0, Vector2(esc, esc))
		draw_rect(Rect2(-4, CARTEL.end.y - 4, 8, 22 - CARTEL.end.y + 6), Acuarela.AZOTEA.darkened(0.3))  # palo
		draw_set_transform(pos, TILT[i], Vector2(esc, esc))
		if huecos[i].ocupado:
			draw_rect(CARTEL, Color(CREMA, 0.97))
		else:
			draw_rect(CARTEL, Color(CREMA, 0.6))
			var r := CARTEL
			var esquinas := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
			for k in 4:
				draw_dashed_line(esquinas[k], esquinas[k + 1], Color(CREMA, 0.9), 3.0, 12.0)
			draw_string(FUENTE, Vector2(-40, -94), "+", HORIZONTAL_ALIGNMENT_CENTER, 80, 50, Color(Acuarela.CIRUELA, 0.35))
		draw_set_transform(Vector2.ZERO)
		if not huecos[i].ocupado:
			draw_set_transform(pos + Vector2(MOCO_X, 24) * esc, 0.0, Vector2(esc, 0.3 * esc))  # sombra aplastada en el suelo
			draw_circle(Vector2.ZERO, 30.0, Color(Acuarela.CIRUELA, 0.15))
			draw_set_transform(Vector2.ZERO)

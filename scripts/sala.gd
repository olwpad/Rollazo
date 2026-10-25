# La azotea del menú con 4 huecos: cuando alguien se une, su moco cae de un salto con su
# color; los huecos libres son un charco que espera. Así ves quién ha entrado antes de empezar.
extends Node2D

const SEPARACION := 135.0
const ANCHO_AZOTEA := 600.0
const FUENTE := preload("res://assets/fuentes/Bangers-Regular.ttf")

var huecos: Array[Dictionary] = []  # {moco: MocoVisual, nombre: Label, ocupado: bool}


func _ready() -> void:
	for i in 4:
		var hueco := Node2D.new()
		hueco.position = Vector2(i * SEPARACION, 0)
		var grande := Node2D.new()  # escala aparte: aplastar() devuelve el moco a escala 1
		grande.scale = Vector2(1.6, 1.6)
		grande.position = Vector2(0, 22 - MocoVisual.RADIO * 1.6)  # apoyado en la azotea
		var moco := MocoVisual.new()
		moco.color = Jugador.COLORES[i]
		moco.visible = false
		grande.add_child(moco)
		var nombre := Label.new()
		nombre.position = Vector2(-62, 40)
		nombre.size = Vector2(124, 30)
		nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nombre.add_theme_font_override("font", FUENTE)  # dentro de un Node2D no llega el tema del menú
		nombre.add_theme_font_size_override("font_size", 22)
		nombre.add_theme_color_override("font_color", Color("fffaf4"))
		hueco.add_child(grande)
		hueco.add_child(nombre)
		add_child(hueco)
		huecos.append({"moco": moco, "nombre": nombre, "ocupado": false})
	var solo_yo: Array[int] = [1]
	mostrar(solo_yo, 1)


# ids en el orden de la partida (el mismo que da los colores en la carrera).
func mostrar(ids: Array[int], mi_id: int) -> void:
	for i in huecos.size():
		var h := huecos[i]
		var ocupado := i < ids.size()
		if ocupado and not h.ocupado:
			_caer(h.moco)
		h.moco.visible = ocupado
		h.ocupado = ocupado
		if not ocupado:
			h.nombre.text = "ESPERANDO…"
		elif ids[i] == mi_id:
			h.nombre.text = "TÚ"
		else:
			h.nombre.text = "JUGADOR %d" % (i + 1)
		h.nombre.modulate.a = 1.0 if ocupado else 0.6
	queue_redraw()


func ocupados() -> int:
	return huecos.filter(func(h: Dictionary) -> bool: return h.ocupado).size()


func etiqueta(i: int) -> String:
	return huecos[i].nombre.text


# Cae desde arriba, rebota contra la azotea y se aplasta al tocarla.
func _caer(moco: MocoVisual) -> void:
	moco.position = Vector2(0, -260)
	var tw := create_tween()
	tw.tween_property(moco, "position", Vector2.ZERO, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(moco.aplastar.bind(Vector2(1.5, 0.6)))


func _draw() -> void:
	var izq := -SEPARACION * 0.8
	var azotea := PackedVector2Array([Vector2(izq, 22), Vector2(izq + ANCHO_AZOTEA, 14), Vector2(izq + ANCHO_AZOTEA, 400), Vector2(izq, 400)])
	Acuarela.pintar(self, azotea, Acuarela.AZOTEA, 11)
	for i in huecos.size():
		if not huecos[i].ocupado:  # charco del color que tendrá quien entre
			var charco := PackedVector2Array()
			for k in 14:
				var a := TAU * k / 14
				charco.append(Vector2(i * SEPARACION + cos(a) * 30.0, 22.0 + sin(a) * 8.0))
			draw_colored_polygon(Tinta.irregular(charco, i, 2.0, 8.0), Color(Jugador.COLORES[i], 0.45))

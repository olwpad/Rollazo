# Volumen de la música (o de los efectos, con `efectos`): una pincelada crema de pista, rosa hasta donde suena y un tirador
# redondo como un moco pequeño. Sin contornos ni el tema por defecto. Arrastrar o hacer clic.
extends Control

@export var efectos := false  # false: la música (con su silencio); true: el volumen de los efectos
@export var sobre_papel := false  # la pista crema se perdería sobre una hoja crema
@export var radio := 5.5  # del tirador; el control es más alto que el dibujo para acertar fácil
var _arrastrando := false
var _foto := -1


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	Musica.cambio_silencio.connect(_al_cambiar.unbind(1))
	Ajustes.efectos_cambiaron.connect(_al_cambiar)
	_al_cambiar()


func _volumen() -> int:
	return Ajustes.efectos if efectos else Musica.volumen


func _callada() -> bool:
	return false if efectos else Musica.callada()


func _poner(valor: int, guardar: bool) -> void:
	if efectos:
		Ajustes.poner_efectos(valor, guardar)
	else:
		Musica.poner_volumen(valor, guardar)


func _al_cambiar() -> void:
	accessibility_name = "Volumen de %s %d%%" % ["los efectos" if efectos else "la música", _volumen()]
	queue_redraw()


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT:
		_arrastrando = evento.pressed
		_poner(_valor(evento.position.x), not evento.pressed)  # se guarda al soltar
		accept_event()
	elif evento is InputEventMouseMotion and _arrastrando:
		_poner(_valor(evento.position.x), false)
		accept_event()


func _valor(x: float) -> int:
	return roundi(clampf((x - radio) / (size.x - 2.0 * radio), 0.0, 1.0) * 100.0)


func _process(_delta: float) -> void:
	if Tinta.fotograma() != _foto:  # tiembla a 12 fps, como la nota
		queue_redraw()


func _draw() -> void:
	_foto = Tinta.fotograma()
	var y := size.y / 2.0
	var x := radio + (size.x - 2.0 * radio) * _volumen() / 100.0
	var pista := PackedVector2Array([Vector2(2, y - 1.5), Vector2(size.x - 2, y - 2), Vector2(size.x - 2, y + 1.5), Vector2(2, y + 2)])
	draw_colored_polygon(Tinta.temblar(Tinta.irregular(pista, 21, 0.4, 8.0), 21, _foto, 0.25), (Color(Acuarela.CIRUELA, 0.25) if sobre_papel else Color("fffaf4", 0.75)))  # crema: la lavanda se perdía en el cielo azul
	if x > 3.0:  # lo que suena, en rosa (pálido si está silenciada)
		var lleno := PackedVector2Array([Vector2(2, y - 2), Vector2(x, y - 2), Vector2(x, y + 2), Vector2(2, y + 2)])
		var rosa := Acuarela.ROSA if not _callada() else Color(Acuarela.ROSA, 0.4)
		draw_colored_polygon(Tinta.temblar(Tinta.irregular(lleno, 22, 0.4, 8.0), 22, _foto, 0.25), rosa)
	# Tirador sin contorno: capa base y otra más clara encima, como el cuerpo del moco.
	var bola := PackedVector2Array()
	for i in 12:
		bola.append(Vector2(x, y) + Vector2.from_angle(TAU * i / 12.0) * radio)
	bola = Tinta.temblar(bola, 23, _foto, 0.4)
	var color := Acuarela.CIRUELA if not _callada() else Color("8e8aae")
	draw_colored_polygon(bola, color)
	var claro := PackedVector2Array()
	for p in bola:
		claro.append(Vector2(x, y) + (p - Vector2(x, y)) * 0.65 + Vector2(-1, -1))
	draw_colored_polygon(claro, color.lightened(0.18))

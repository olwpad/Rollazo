# Interruptor de la música: una corchea pintada a mano, sin contorno, que tiembla como los mocos.
# Sonando: nota ciruela. Silenciada o a 0: nota pálida y tachada (el nivel ya lo cuenta el deslizador).
# Clic = silenciar / quitar silencio; el volumen va en el deslizador hijo.
# Hace lo mismo que la tecla M: los dos llaman a Musica.alternar_silencio().
extends Button

# Corchea dibujada en una caja de 64 x 64 (cabeza, palo y banderita) y pintada a escala ESCALA.
const ESCALA := 0.6  # ~28 px: discreta, de rincón; el botón es algo mayor para acertar fácil
const MARGEN := Vector2(3, 3)
const CABEZA_CENTRO := Vector2(24, 46)
const PALO := [Vector2(31, 45), Vector2(32, 12), Vector2(37, 12), Vector2(36, 44)]
const BANDERA := [Vector2(35, 11), Vector2(44, 16), Vector2(50, 25), Vector2(49, 36), Vector2(45, 30), Vector2(38, 25), Vector2(36, 22)]
const PALIDA := Color("8e8aae")  # ciruela mezclado con el cielo: "apagada", pero se sigue viendo la nota

var _encima := false
var _foto := -1


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE  # como los demás botones del menú: Espacio no lo pulsa por sorpresa
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pressed.connect(Musica.alternar_silencio)
	Musica.cambio_silencio.connect(_al_cambiar.unbind(1))
	mouse_entered.connect(func(): _encima = true; queue_redraw())
	mouse_exited.connect(func(): _encima = false; queue_redraw())
	_al_cambiar()


func _al_cambiar() -> void:
	accessibility_name = "Música apagada" if Musica.callada() else "Música"  # sin tooltip: el autor no quiere textos emergentes
	queue_redraw()


func _process(_delta: float) -> void:
	if Tinta.fotograma() != _foto:  # tiembla a 12 fps, no a 60
		queue_redraw()


func _draw() -> void:
	_foto = Tinta.fotograma()
	draw_set_transform(MARGEN, 0.0, Vector2(ESCALA, ESCALA))
	if _encima:  # la misma mancha rosa que sale detrás de los botones de texto
		var mancha := PackedVector2Array()
		for i in 12:
			mancha.append(Vector2(32, 33) + Vector2.from_angle(TAU * i / 12.0) * 28.0)
		Acuarela.pintar(self, mancha, Acuarela.ROSA, 7)
	var color := PALIDA if Musica.callada() else Acuarela.CIRUELA
	var cabeza := PackedVector2Array()
	for i in 14:
		cabeza.append(CABEZA_CENTRO + Vector2(11.0 * cos(TAU * i / 14.0), 8.0 * sin(TAU * i / 14.0)).rotated(-0.4))
	# Sin contorno: capa base y, encima, una más pequeña y clara, como el cuerpo del moco.
	draw_colored_polygon(Tinta.temblar(cabeza, 3, _foto, 0.7), color)
	draw_colored_polygon(Tinta.temblar(PackedVector2Array(PALO), 4, _foto, 0.5), color)
	draw_colored_polygon(Tinta.temblar(PackedVector2Array(BANDERA), 5, _foto, 0.7), color)
	var interior := PackedVector2Array()
	for p in Tinta.temblar(cabeza, 3, _foto, 0.7):
		interior.append(CABEZA_CENTRO + (p - CABEZA_CENTRO) * 0.68 + Vector2(-1, -1))
	draw_colored_polygon(interior, color.lightened(0.18))
	draw_circle(CABEZA_CENTRO + Vector2(-4, -3), 2.5, Color(1, 1, 1, 0.5))  # brillo, como el del moco
	if Musica.callada():  # una pincelada que la tacha de esquina a esquina
		var raya := PackedVector2Array([Vector2(12, 15), Vector2(16, 11), Vector2(55, 50), Vector2(51, 54)])
		draw_colored_polygon(Tinta.temblar(Tinta.irregular(raya, 9, 1.0, 10.0), 9, _foto, 0.6), Acuarela.CIRUELA)

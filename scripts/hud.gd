# Cronómetro en pantalla. CanvasLayer = se dibuja encima del juego, sin moverse con la cámara.
extends CanvasLayer

@onready var tiempo: Label = $Tiempo
@onready var mensaje: Label = $Mensaje
@onready var tabla: VBoxContainer = $Tabla


static func formatear(t: float) -> String:
	return "--.--" if t == INF else "%05.2f" % t


func mostrar(t: float, mejor: float, con_mejor := true) -> void:
	tiempo.text = "%s   mejor %s" % [formatear(t), formatear(mejor)] if con_mejor else formatear(t)


# Segundos que quedan tras llegar el primero; negativo = no hay cuenta. Late en los últimos 5.
func cuenta_atras(segundos: float) -> void:
	var cuenta: Label = $Cuenta
	cuenta.visible = segundos >= 0.0
	if not cuenta.visible:
		return
	var texto := str(ceili(segundos))
	if texto != cuenta.text and segundos <= 5.0:
		cuenta.scale = Vector2(1.4, 1.4)
		create_tween().tween_property(cuenta, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	cuenta.text = texto


func ocultar_ayuda() -> void:
	if $Ayuda.visible and $Ayuda.modulate.a == 1.0:  # una sola vez, no un tween por frame
		create_tween().tween_property($Ayuda, "modulate:a", 0.0, 0.6).finished.connect(func(): $Ayuda.visible = false)


func meta(t: float, mejor: float, puesto: int, con_repetir: bool) -> void:
	mensaje.text = "PUESTO %d  %s%s%s" % [puesto, formatear(t), "  ¡récord!" if t <= mejor else "",
			"\nR para repetir" if con_repetir else ""]


# filas: [[color del moco, puntos totales], ...] ya ordenadas de más a menos puntos.
func resultados(filas: Array) -> void:
	mensaje.text = ""
	limpiar_tabla()
	for i in filas.size():
		var fila := HBoxContainer.new()
		var mancha := Label.new()
		mancha.text = "●"
		mancha.add_theme_color_override("font_color", filas[i][0])
		var texto := Label.new()
		texto.text = str(filas[i][1])  # el orden ya dice el puesto; Bangers no tiene "º"
		texto.add_theme_color_override("font_color", Acuarela.CIRUELA)
		for l: Label in [mancha, texto]:
			l.add_theme_font_override("font", mensaje.get_theme_font("font"))
			l.add_theme_font_size_override("font_size", 56)
			fila.add_child(l)
		tabla.add_child(fila)


func limpiar() -> void:
	mensaje.text = ""
	limpiar_tabla()


func limpiar_tabla() -> void:
	for fila in tabla.get_children():
		fila.queue_free()


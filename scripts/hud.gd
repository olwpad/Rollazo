# Cronómetro en pantalla. CanvasLayer = se dibuja encima del juego, sin moverse con la cámara.
extends CanvasLayer

@onready var tiempo: Label = $Tiempo
@onready var mensaje: Label = $Mensaje
@onready var tabla: VBoxContainer = $Tabla


static func formatear(t: float) -> String:
	return "--.--" if t == INF else "%05.2f" % t


func mostrar(t: float, mejor: float) -> void:
	tiempo.text = "%s   mejor %s" % [formatear(t), formatear(mejor)]


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


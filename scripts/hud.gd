# Cronómetro en pantalla. CanvasLayer = se dibuja encima del juego, sin moverse con la cámara.
extends CanvasLayer

@onready var tiempo: Label = $Tiempo
@onready var mensaje: Label = $Mensaje


static func formatear(t: float) -> String:
	return "--.--" if t == INF else "%05.2f" % t


func mostrar(t: float, mejor: float) -> void:
	tiempo.text = "%s   mejor %s" % [formatear(t), formatear(mejor)]


func meta(t: float, mejor: float) -> void:
	mensaje.text = "¡META!  %s%s\nR para repetir" % [formatear(t), "  ¡récord!" if t <= mejor else ""]


func limpiar() -> void:
	mensaje.text = ""

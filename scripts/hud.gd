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


# filas: [[color, nombre, victorias, segundos totales], ...] ya ordenadas, el primero arriba.
# La misma tabla sirve para Tab durante la carrera y para el final de cada ronda.
func marcador(filas: Array) -> void:
	limpiar_tabla()
	for f: Array in filas:
		var fila := HBoxContainer.new()
		var mancha := Label.new()
		mancha.text = "●"
		mancha.add_theme_color_override("font_color", f[0])
		var texto := Label.new()
		texto.text = "%s · %d %s · %s" % [f[1], f[2], "VICTORIA" if f[2] == 1 else "VICTORIAS", minutos(f[3])]
		texto.add_theme_color_override("font_color", Acuarela.CIRUELA)
		for l: Label in [mancha, texto]:
			l.add_theme_font_override("font", mensaje.get_theme_font("font"))
			l.add_theme_font_size_override("font_size", 44)
			fila.add_child(l)
		tabla.add_child(fila)
	$FondoTabla.visible = not filas.is_empty()


static func minutos(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]


# El poder que llevas y cuánto le queda. tipo "" = ninguno.
func poder(tipo: String, restante: float, total: float) -> void:
	var p = $Poder  # sin tipo: es el indicador_poder
	p.visible = tipo != ""
	if tipo == "":
		return
	p.tipo = tipo
	p.fraccion = clampf(restante / total, 0.0, 1.0)
	p.queue_redraw()
	$Poder/Texto.text = "%s · %d S" % [Poderes.NOMBRE[tipo], ceili(restante)]


# Texto grande arriba: modo espectador, ganador del torneo...
func titular(texto: String) -> void:
	$Titular.text = texto


func postal(titulo_: String, semilla: int, filas: Array) -> void:
	var p: Postal = $Postal
	p.titulo = titulo_
	p.semilla = semilla
	p.filas = filas
	p.visible = true
	p.position.y = -p.size.y  # cae desde arriba y se asienta
	create_tween().tween_property(p, "position:y", (get_viewport().get_visible_rect().size.y - p.size.y) / 2.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func ocultar_postal() -> void:
	$Postal.visible = false


func limpiar() -> void:
	mensaje.text = ""
	titular("")
	limpiar_tabla()


func limpiar_tabla() -> void:
	for fila in tabla.get_children():
		tabla.remove_child(fila)  # fuera ya: queue_free sola dejaría la fila contando hasta el frame siguiente
		fila.queue_free()
	$FondoTabla.visible = false


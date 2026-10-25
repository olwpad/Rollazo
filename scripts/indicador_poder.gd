# Icono del poder bajo el reloj: círculo de papel con el dibujito y un anillo de su color
# que se va vaciando como un reloj.
extends Control

var tipo := ""
var fraccion := 1.0  # lo que queda, de 1 a 0


func _draw() -> void:
	if tipo == "":
		return
	var c := Vector2(30, 30)
	draw_circle(c, 28.0, Color("fffaf4"))
	draw_circle(c, 22.0, Color(Poderes.COLOR[tipo], 0.85))
	draw_arc(c, 28.0, -PI / 2.0, -PI / 2.0 + TAU * fraccion, 32, Poderes.COLOR[tipo], 6.0, true)
	Poderes.dibujar_icono(self, tipo, c, 22.0)

# Contorno de tinta que tiembla a 12 fps alrededor de un polígono.
extends Line2D

var base := PackedVector2Array()
var semilla := 0
var _ultimo := -1


func _process(_delta: float) -> void:
	var f := Tinta.fotograma()
	if f != _ultimo:
		_ultimo = f
		points = Tinta.temblar(base, semilla, f, 1.6)

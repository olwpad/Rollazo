# Jugador con la entrada guionizada, para simular partidas sin ratón.
extends "res://scripts/jugador.gd"

var guion: Dictionary = {}  # solo dura un frame
var sostenido: Dictionary = {}  # se mantiene hasta que se cambie


func _leer_input() -> Dictionary:
	var e := {"lanzar": false, "soltar": false, "saltar": false, "apunta": Vector2.ZERO, "eje_x": 0.0, "eje_largo": 0.0}
	e.merge(sostenido, true)
	e.merge(guion, true)
	guion = {}
	return e

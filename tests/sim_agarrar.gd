# Simulación: un moco se agarra a otro colgado, lo sigue, le pesa, y reaparecer lo suelta.
extends SceneTree

var nivel: Node
var j1: Jugador
var j2: Jugador
var ref: Jugador  # cae solo, sin nadie agarrado: para comparar
var frame := 0
var fallos: Array[String] = []


func _initialize() -> void:
	nivel = load("res://scenes/prueba_columpio.tscn").instantiate()
	j1 = nivel.get_node("Jugador")
	j1.set_script(load("res://tests/jugador_simulado.gd"))
	j2 = _nuevo("2")
	ref = _nuevo("3")
	root.add_child(nivel)


func _nuevo(nombre: String) -> Jugador:
	var j: Jugador = load("res://scenes/jugador.tscn").instantiate()
	j.name = nombre
	j.set_script(load("res://tests/jugador_simulado.gd"))
	nivel.add_child(j)
	return j


func _physics_process(_delta: float) -> bool:
	frame += 1
	if frame == 1:
		j1.global_position = Vector2(400, 500)
		j1.velocity = Vector2.ZERO
		j1.papel = PapelRope.new(Vector2(400, 320), 180.0, 3.0)
		j2.global_position = Vector2(440, 500)
		ref.global_position = Vector2(1200, 500)
	elif frame == 2:
		j2.guion = {"agarrar": true}
	elif frame == 3:
		_comprobar(j2.agarrado_a == j1, "el 2 se agarra al 1")
		_comprobar(j1.carga == 1, "el 1 lleva carga 1")
		j1.papel = null  # los dos caen a la vez que la referencia
		j1.velocity = Vector2(200, 0)
		ref.velocity = Vector2(200, 0)
		ref.global_position = Vector2(1200, j1.global_position.y)
	elif frame == 13:
		_comprobar(j2.global_position.distance_to(j1.global_position) < 60.0, "el 2 sigue al 1")
		_comprobar(j1.velocity.y > ref.velocity.y + 50.0, "con carga cae más rápido (%.0f vs %.0f)" % [j1.velocity.y, ref.velocity.y])
		j1.reaparecer(Vector2(200, 600))
	elif frame == 14:
		_comprobar(j2.agarrado_a == null, "reaparecer suelta al que estaba agarrado")
		_comprobar(j1.carga == 0, "sin carga tras reaparecer")
		print("sim_agarrar: ", "OK" if fallos.is_empty() else "FALLO " + ", ".join(fallos))
		quit(0 if fallos.is_empty() else 1)
	return false


func _comprobar(c: bool, m: String) -> void:
	if not c:
		fallos.append(m)

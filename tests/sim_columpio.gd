# Simulación con física real: godot --headless --path . --script res://tests/sim_columpio.gd
extends SceneTree

var j: Jugador
var frame := 0
var fallos: Array[String] = []
var x_al_enganchar := 0.0
var vel_antes_soltar := 0.0


func _initialize() -> void:
	var nivel: Node = load("res://scenes/prueba_columpio.tscn").instantiate()
	j = nivel.get_node("Jugador")
	j.set_script(load("res://tests/jugador_simulado.gd"))
	root.add_child(nivel)


func _physics_process(_delta: float) -> bool:
	frame += 1
	if frame == 30:  # ya en el suelo
		j.guion = {"apunta": j.global_position + Vector2(300, -500), "lanzar": true}
	elif frame == 31:
		_comprobar(j.papel != null, "se engancha al techo")
		x_al_enganchar = j.global_position.x
	elif frame == 32:
		j.guion = {"apunta": j.global_position + Vector2(0, 500), "lanzar": true}
	elif frame == 33:
		_comprobar(j.papel == null, "apuntar al suelo no engancha")
		j.guion = {"apunta": j.global_position + Vector2(300, -500), "lanzar": true}
		j.sostenido = {"eje_largo": -1.0}  # encoger con W para despegar
	elif frame == 70:
		_comprobar(j.papel != null, "sigue enganchado")
		_comprobar(j.global_position.x > x_al_enganchar + 50, "se columpia hacia el ancla")
		vel_antes_soltar = j.velocity.length()
		j.sostenido = {}
		j.guion = {"soltar": true}
	elif frame == 71:
		_comprobar(j.papel == null, "suelta el papel")
		_comprobar(j.velocity.length() > vel_antes_soltar, "sale disparado")
		j.guion = {"apunta": j.global_position + Vector2(0, -500), "lanzar": true}
	elif frame == 72:
		_comprobar(j.papel != null, "vuelve a engancharse")
	elif frame >= 72 and frame < 400:
		if j.papel == null:
			_comprobar(frame > 72 + 60, "no se rompe enseguida")
			frame = 400
	if frame >= 400:
		_comprobar(j.papel == null, "el papel acaba rompiéndose")
		print("sim_columpio: ", "OK" if fallos.is_empty() else "FALLO " + ", ".join(fallos))
		quit(0 if fallos.is_empty() else 1)
	return false


func _comprobar(c: bool, m: String) -> void:
	if not c:
		fallos.append(m)

# Bot anfitrión de un torneo entero (lo lanza run_tests.sh junto a sim_torneo_cliente.gd):
# 3 rondas, espera a que el cliente esté listo, acepta su pausa, lleva los mocos a la meta y
# comprueba que al final todos vuelven a la sala sin desconectarse.
extends SceneTree

const PUERTO := 7792
var red: Node
var t := 0.0
var empezado := false
var ronda_llevada := 0  # última ronda en la que ya llevé los mocos a la meta
var pausa_vista := false
var pausa_soltada := false
var fallos: Array[String] = []


func _process(delta: float) -> bool:
	if red == null:  # el autoload entra en el árbol después de _initialize
		red = root.get_node_or_null("Red")
		if red == null or red.crear_partida(PUERTO) != OK:
			_fin("no se pudo crear la partida")
		else:
			red.poner_rondas(3)
		return false
	t += delta
	if t > 90.0:
		_fin("el torneo no terminó en 90 s (ronda %d)" % ronda_llevada)
	if not empezado:
		if red.ids.size() == 2 and red.todos_listos():
			empezado = true
			red.empezar_carrera.rpc(42)
		return false
	var nivel := current_scene
	if nivel == null:
		return false
	if nivel.scene_file_path == "res://scenes/menu.tscn":
		if ronda_llevada < 3:
			_fin("volvió a la sala antes de acabar (ronda %d)" % ronda_llevada)
		elif not red.es_online() or red.ids.size() != 2:
			_fin("al acabar el torneo alguien se desconectó")
		elif not pausa_vista:
			_fin("la pausa pedida por el cliente nunca se activó")
		else:
			_fin("")
		return false
	if not nivel.has_node("Pausa") or not nivel.corriendo or nivel.en_resultados:
		return false
	var pausa: Node = nivel.get_node("Pausa")
	if nivel.ronda == 1 and not pausa_soltada:  # primero, la pausa del cliente
		if not paused and pausa.pendiente != 0 and not pausa_vista:
			pausa.pedir_de(1)  # acepto
		elif paused and not pausa_vista:
			pausa_vista = true
			pausa.pedir_de(1)  # y sigo: cuenta atrás de 3 s
		elif pausa_vista and not paused:
			pausa_soltada = true
		return false
	if nivel.ronda > ronda_llevada:
		ronda_llevada = nivel.ronda
		var meta: Vector2 = nivel.get_node("Meta").global_position
		for j in nivel.get_node("Jugadores").get_children():
			j.global_position = meta
	return false


func _fin(error: String) -> void:
	if error != "":
		fallos.append(error)
	print("sim_torneo: ", "OK" if fallos.is_empty() else "FALLO " + ", ".join(fallos))
	quit(0 if fallos.is_empty() else 1)

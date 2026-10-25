# Bot amigo del torneo: se une, dice que está listo, pide pausa en la ronda 1 y comprueba
# lo que ve: la postal de cada ronda, la pausa, el ganador y la vuelta a la sala.
extends SceneTree

var red: Node
var t := 0.0
var listo_enviado := false
var pausa_pedida := false
var vi_pausa := false
var max_ronda := 0
var vi_ganador := false
var estuvo_en_carrera := false
var fallos: Array[String] = []


func _process(delta: float) -> bool:
	if red == null:
		red = root.get_node_or_null("Red")
		red.unirse("127.0.0.1", 7792)
		return false
	t += delta
	if t > 95.0:
		_fin("sin terminar en 95 s (ronda %d)" % max_ronda)
	# Lanzado con --script no hay menú cargado al principio: me marco listo sin él.
	if not listo_enviado and red.multiplayer.get_unique_id() in red.ids and red.config.rondas == 3:
		listo_enviado = true
		red.marcar_listo.rpc_id(1, true)
	var escena := current_scene
	if escena == null:
		return false
	if escena.scene_file_path == "res://scenes/menu.tscn":
		if estuvo_en_carrera:
			if max_ronda != 3:
				fallos.append("vi %d rondas en vez de 3" % max_ronda)
			if not vi_pausa:
				fallos.append("no vi la pausa")
			if not vi_ganador:
				fallos.append("no vi quién ganó el torneo")
			if not escena.get_node("SalaUI").visible:
				fallos.append("al volver no estoy en la sala")
			_fin("")
		return false
	if not escena.has_node("Pausa"):
		return false
	estuvo_en_carrera = true
	max_ronda = maxi(max_ronda, escena.ronda)
	if escena.hud.get_node("Postal").visible and not ("RONDA %d DE 3" % escena.ronda) in escena.hud.get_node("Postal").titulo:
		fallos.append("postal equivocada: " + escena.hud.get_node("Postal").titulo)
	vi_pausa = vi_pausa or paused
	var titular: String = escena.hud.get_node("Titular").text
	vi_ganador = vi_ganador or titular.begins_with("GANA") or titular.begins_with("¡HAS GANADO")
	if escena.corriendo and not pausa_pedida:
		pausa_pedida = true
		escena.get_node("Pausa").pedir.rpc_id(1)
	return false


func _fin(error: String) -> void:
	if error != "":
		fallos.append(error)
	print("sim_torneo_cliente: ", "OK" if fallos.is_empty() else "FALLO " + ", ".join(fallos))
	quit(0 if fallos.is_empty() else 1)

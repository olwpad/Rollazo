# Anfitrión de la prueba de salas por WebRTC (la lanza tools/probar_salas.sh con ROLLAZO_SALAS):
# crea la sala, pasa el código al cliente por un archivo, cambia las rondas y espera su "listo".
extends SceneTree

var ARCHIVO := OS.get_environment("ROLLAZO_CODIGO_ARCHIVO")  # lo fija tools/probar_salas.sh
var red: Node
var espera := 0.0
var rondas_puestas := false


func _process(delta: float) -> bool:
	if red == null:  # el autoload entra en el árbol después de _initialize
		red = root.get_node_or_null("Red")
		if OS.get_environment("ROLLAZO_SALAS") == "" or red == null or red.crear_sala() != OK:
			_fin("falta ROLLAZO_SALAS o no se pudo crear la sala")
		return false
	espera += delta
	if red.codigo_sala != "" and not FileAccess.file_exists(ARCHIVO):
		var f := FileAccess.open(ARCHIVO, FileAccess.WRITE)
		f.store_string(red.codigo_sala)
	if not rondas_puestas and red.ids.size() == 2:
		rondas_puestas = true
		red.poner_rondas(7)
	if rondas_puestas and red.listos.get(red.ids[1], false):
		_fin("")
	elif espera > 25.0:
		_fin("el cliente no llegó a estar listo (código '%s', ids %s)" % [red.codigo_sala, red.ids])
	return false


func _fin(error: String) -> void:
	print("sim_salas: ", "OK" if error == "" else "FALLO " + error)
	quit(0 if error == "" else 1)

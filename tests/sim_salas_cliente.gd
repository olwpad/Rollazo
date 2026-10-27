# Cliente de la prueba de salas por WebRTC: lee el código del anfitrión, se une, ve su config,
# dice que está listo y comprueba que, al irse el anfitrión, vuelve solo a estar desconectado.
extends SceneTree

var ARCHIVO := OS.get_environment("ROLLAZO_CODIGO_ARCHIVO")  # lo fija tools/probar_salas.sh
var red: Node
var espera := 0.0
var unido := false
var listo := false


func _process(delta: float) -> bool:
	if red == null:
		red = root.get_node_or_null("Red")
		return false
	espera += delta
	if not unido:
		if FileAccess.file_exists(ARCHIVO):
			var codigo := FileAccess.get_file_as_string(ARCHIVO)
			if codigo.length() == 4:
				unido = true
				if red.unirse_sala(codigo) != OK:
					_fin("unirse_sala falló")
		elif espera > 15.0:
			_fin("no hay código del anfitrión")
		return false
	if not listo:
		if red.config.rondas == 7 and red.ids.size() == 2:  # config y lista del anfitrión han llegado
			listo = true
			red.marcar_listo.rpc_id(1, true)
			espera = 0.0
		elif espera > 25.0:
			_fin("no llegó la config del anfitrión (rondas %d, ids %s)" % [red.config.rondas, red.ids])
	elif not red.es_online():
		_fin("")  # el anfitrión se fue y volvimos al menú desconectados
	elif espera > 10.0:
		_fin("el anfitrión se fue y seguimos online")
	return false


func _fin(error: String) -> void:
	print("sim_salas_cliente: ", "OK" if error == "" else "FALLO " + error)
	quit(0 if error == "" else 1)

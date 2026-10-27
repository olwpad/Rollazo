# Conexión con el servidor de salas (señalización WebRTC): habla JSON por WebSocket y lo
# convierte en señales. Es como un "listener" de Java: Red se suscribe y reacciona.
# No es un nodo: alguien (Red) tiene que llamar a poll() en cada frame.
class_name Senal
extends RefCounted

signal sala(codigo: String, id: int)  # el servidor nos ha dado sala e id
signal entra(id: int)  # (anfitrión) un amigo quiere entrar
signal sale(id: int)  # (anfitrión) un amigo se ha ido
signal oferta(de: int, sdp: String)
signal respuesta(de: int, sdp: String)
signal candidato(de: int, media: String, indice: int, nombre: String)
signal error(motivo: String)  # "no_existe" o "llena"
signal cerrada  # el anfitrión cerró la sala
signal sin_conexion  # no se pudo abrir el socket, o se cayó

var _ws := WebSocketPeer.new()
var _terminado := false
var _avisado := false  # ya llegó un "error" o "cerrada"


func conectar(url: String) -> Error:
	return _ws.connect_to_url(url)


func enviar(mensaje: Dictionary) -> void:
	if _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text(JSON.stringify(mensaje))


func cerrar() -> void:
	_terminado = true  # cerrar a propósito no cuenta como "sin conexión"
	_ws.close()


func poll() -> void:
	if _terminado:
		return
	_ws.poll()
	while _ws.get_available_packet_count() > 0:  # también si ya se cerró: puede quedar el último mensaje
		_procesar(_ws.get_packet().get_string_from_utf8())
		if _terminado:
			return  # un manejador cerró el socket
	if _ws.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		_terminado = true
		# Tras un error/cerrada el servidor cierra a propósito: ya se avisó, no es un fallo más.
		if not _avisado:
			sin_conexion.emit()


func _procesar(texto: String) -> void:
	var m: Variant = JSON.parse_string(texto)
	if not m is Dictionary:
		return  # lo que llega de fuera no es de fiar
	match m.get("tipo"):
		"sala":
			sala.emit(str(m.get("codigo", "")), int(m.get("id", 0)))
		"entra":
			entra.emit(int(m.get("id", 0)))
		"sale":
			sale.emit(int(m.get("id", 0)))
		"oferta":
			oferta.emit(int(m.get("de", 0)), str(m.get("sdp", "")))
		"respuesta":
			respuesta.emit(int(m.get("de", 0)), str(m.get("sdp", "")))
		"candidato":
			candidato.emit(int(m.get("de", 0)), str(m.get("media", "")), int(m.get("indice", 0)), str(m.get("nombre", "")))
		"error":
			_avisado = true
			error.emit(str(m.get("motivo", "")))
		"cerrada":
			_avisado = true
			cerrada.emit()

# Autoload "Red": crear partida, unirse y avisar de cambios. Es como un singleton de Java:
# Godot crea un único nodo Red al arrancar y cualquier script puede usarlo por su nombre.
extends Node

signal jugadores_cambiaron
signal desconectado(motivo: String)
signal config_cambiada  # rondas o listos: el menú se repinta

const PUERTO := 7777
const MAX_JUGADORES := 4
const RECORRIDO := "res://scenes/recorrido_prueba.tscn"
const MENU := "res://scenes/menu.tscn"
const RONDAS := [3, 5, 7, 10]

var ids: Array[int] = []  # ids conectados, incluido el anfitrión (1). Solo fiable en el anfitrión.


var semilla := 0  # del mapa de la carrera; la elige el anfitrión
var ultimo_motivo := ""  # por qué volvimos al menú; el menú nuevo lo enseña
var config := {"rondas": 5}  # la elige el anfitrión y la ven todos
var listos := {}  # id -> true; el anfitrión no hace falta, es quien pulsa empezar


func _ready() -> void:
	multiplayer.peer_connected.connect(_al_conectar)
	multiplayer.peer_disconnected.connect(_al_desconectar)
	multiplayer.server_disconnected.connect(_al_caer_anfitrion)
	multiplayer.connection_failed.connect(func(): _al_caer_anfitrion("No se pudo conectar"))


func crear_partida(puerto: int = PUERTO) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(puerto, MAX_JUGADORES - 1)  # el anfitrión ya es 1 de los 4
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	ids = [1]
	jugadores_cambiaron.emit()
	return OK


func unirse(ip: String, puerto: int = PUERTO) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, puerto)
	if err == OK:
		multiplayer.multiplayer_peer = peer
	return err


func salir() -> void:
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	multiplayer.refuse_new_connections = false
	ids.clear()
	listos.clear()
	config = {"rondas": 5}
	jugadores_cambiaron.emit()


# La IP que el anfitrión pasa a los demás: la de Tailscale (100.x) si la hay; si no, la de casa.
static func elegir_ip(direcciones: PackedStringArray) -> String:
	var v4 := Array(direcciones).filter(func(d: String) -> bool: return d.count(".") == 3 and not d.begins_with("127."))
	for d: String in v4:
		if d.begins_with("100."):
			return d
	return v4[0] if not v4.is_empty() else "127.0.0.1"


func ip_propia() -> String:
	return elegir_ip(IP.get_local_addresses())


func es_online() -> bool:
	return not multiplayer.multiplayer_peer is OfflineMultiplayerPeer


# Solo el anfitrión la llama; "call_local" hace que también se ejecute en su propio PC.
@rpc("authority", "call_local", "reliable")
func empezar_carrera(p_semilla: int) -> void:
	semilla = p_semilla
	if multiplayer.is_server():
		multiplayer.refuse_new_connections = true  # quien llegue tarde no tendría moco
	get_tree().change_scene_to_file(RECORRIDO)


# Fin del torneo: todos a la sala sin desconectarse, listos para otro.
@rpc("authority", "call_local", "reliable")
func volver_a_sala() -> void:
	listos.clear()
	if multiplayer.is_server():
		multiplayer.refuse_new_connections = false  # entre torneos puede entrar alguien nuevo
	get_tree().change_scene_to_file(MENU)


func todos_listos() -> bool:
	return ids.all(func(id: int) -> bool: return id == 1 or listos.get(id, false))


# Solo el anfitrión. Cambiar la partida borra los listos: nadie empieza con opciones que no vio.
func poner_rondas(n: int) -> void:
	if not multiplayer.is_server() or not n in RONDAS:
		return
	config.rondas = n
	listos.clear()
	_config.rpc(config, listos)
	config_cambiada.emit()


@rpc("any_peer", "call_remote", "reliable")
func marcar_listo(si: bool) -> void:
	var quien := multiplayer.get_remote_sender_id()
	if not multiplayer.is_server() or not quien in ids or typeof(si) != TYPE_BOOL:
		return  # lo que manda un cliente no es de fiar
	listos[quien] = si
	_config.rpc(config, listos)
	config_cambiada.emit()


@rpc("authority", "call_remote", "reliable")
func _config(p_config: Dictionary, p_listos: Dictionary) -> void:
	config = p_config
	listos = p_listos
	config_cambiada.emit()


func _al_conectar(id: int) -> void:
	if multiplayer.is_server():
		ids.append(id)
		jugadores_cambiaron.emit()
		_lista.rpc(ids)  # los clientes también quieren saber quién está en la sala
		_config.rpc_id(id, config, listos)


func _al_desconectar(id: int) -> void:
	ids.erase(id)
	listos.erase(id)
	jugadores_cambiaron.emit()
	if multiplayer.is_server():
		_lista.rpc(ids)
		_config.rpc(config, listos)


@rpc("authority", "call_remote", "reliable")
func _lista(nuevos: Array) -> void:
	ids.assign(nuevos)
	jugadores_cambiaron.emit()


func _al_caer_anfitrion(motivo: String = "El anfitrión se ha ido") -> void:
	salir()
	ultimo_motivo = motivo  # la escena del menú aún no existe: se lo dejamos guardado
	desconectado.emit(motivo)
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

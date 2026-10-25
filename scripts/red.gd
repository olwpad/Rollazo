# Autoload "Red": crear partida, unirse y avisar de cambios. Es como un singleton de Java:
# Godot crea un único nodo Red al arrancar y cualquier script puede usarlo por su nombre.
extends Node

signal jugadores_cambiaron
signal desconectado(motivo: String)

const PUERTO := 7777
const MAX_JUGADORES := 4
const RECORRIDO := "res://scenes/recorrido_prueba.tscn"

var ids: Array[int] = []  # ids conectados, incluido el anfitrión (1). Solo fiable en el anfitrión.


var semilla := 0  # del mapa de la carrera; la elige el anfitrión
var ultimo_motivo := ""  # por qué volvimos al menú; el menú nuevo lo enseña


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
	jugadores_cambiaron.emit()


func es_online() -> bool:
	return not multiplayer.multiplayer_peer is OfflineMultiplayerPeer


# Solo el anfitrión la llama; "call_local" hace que también se ejecute en su propio PC.
@rpc("authority", "call_local", "reliable")
func empezar_carrera(p_semilla: int) -> void:
	semilla = p_semilla
	if multiplayer.is_server():
		multiplayer.refuse_new_connections = true  # quien llegue tarde no tendría moco
	get_tree().change_scene_to_file(RECORRIDO)


func _al_conectar(id: int) -> void:
	if multiplayer.is_server():
		ids.append(id)
		jugadores_cambiaron.emit()
		_lista.rpc(ids)  # los clientes también quieren saber quién está en la sala


func _al_desconectar(id: int) -> void:
	ids.erase(id)
	jugadores_cambiaron.emit()
	if multiplayer.is_server():
		_lista.rpc(ids)


@rpc("authority", "call_remote", "reliable")
func _lista(nuevos: Array) -> void:
	ids.assign(nuevos)
	jugadores_cambiaron.emit()


func _al_caer_anfitrion(motivo: String = "El anfitrión se ha ido") -> void:
	salir()
	ultimo_motivo = motivo  # la escena del menú aún no existe: se lo dejamos guardado
	desconectado.emit(motivo)
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

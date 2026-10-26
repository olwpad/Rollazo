# Autoload "Red": crear partida, unirse, config de la partida, listos y aspectos de los jugadores.
# Es como un singleton de Java: Godot crea un único nodo Red al arrancar y cualquier script
# puede usarlo por su nombre. El anfitrión (id 1) manda; los clientes reciben copias por @rpc.
extends Node

signal jugadores_cambiaron
signal desconectado(motivo: String)
signal config_cambiada  # rondas o listos: el menú se repinta

const PUERTO := 7777
const MAX_JUGADORES := 4
const RECORRIDO := "res://scenes/recorrido_prueba.tscn"
const MENU := "res://scenes/menu.tscn"
const RONDAS := [3, 5, 7, 10]
const CONFIG_INICIAL := {"rondas": 5, "poderes": true, "mapas": Temas.LISTA, "aros": false}  # aros de fuego quitados de momento: no convencieron

var ids: Array[int] = []  # ids conectados, incluido el anfitrión (1). Solo fiable en el anfitrión.
var semilla := 0  # del mapa de la carrera; la elige el anfitrión
var ultimo_motivo := ""  # por qué volvimos al menú; el menú nuevo lo enseña
var config := CONFIG_INICIAL.duplicate(true)  # la elige el anfitrión y la ven todos
var aspectos := {}  # id -> {color, pelo, sombrero}: cómo va vestido cada moco
var listos := {}  # id -> true; el anfitrión no hace falta, es quien pulsa empezar


func _ready() -> void:
	multiplayer.peer_connected.connect(_al_conectar)
	multiplayer.peer_disconnected.connect(_al_desconectar)
	multiplayer.server_disconnected.connect(_al_caer_anfitrion)
	multiplayer.connected_to_server.connect(func(): _mi_aspecto.rpc_id(1, Perfil.aspecto))
	multiplayer.connection_failed.connect(func(): _al_caer_anfitrion("No se pudo conectar"))


# --- Conexión ---


func crear_partida(puerto: int = PUERTO) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(puerto, MAX_JUGADORES - 1)  # el anfitrión ya es 1 de los 4
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	ids = [1]
	aspectos = {1: Perfil.aspecto.duplicate()}
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
	aspectos.clear()
	config = CONFIG_INICIAL.duplicate(true)
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


# --- Empezar y terminar la carrera ---


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


# --- Configuración y listos de la sala ---


func todos_listos() -> bool:
	return ids.all(func(id: int) -> bool: return id == 1 or listos.get(id, false))


# Solo el anfitrión. Cambiar la partida borra los listos: nadie empieza con opciones que no vio.
func poner_rondas(n: int) -> void:
	if n in RONDAS:
		_cambiar("rondas", n)


func poner_poderes(si: bool) -> void:
	_cambiar("poderes", si)


func poner_aros(si: bool) -> void:
	_cambiar("aros", si)


# Qué mapas salen; al menos uno y solo de los que existen.
func poner_mapas(lista: Array) -> void:
	if not lista.is_empty() and lista.all(func(t: Variant) -> bool: return t in Temas.LISTA):
		_cambiar("mapas", lista.duplicate())


func _cambiar(clave: String, valor: Variant) -> void:
	if not multiplayer.is_server():
		return
	config[clave] = valor
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


# --- Altas y bajas de jugadores ---


func _al_conectar(id: int) -> void:
	if multiplayer.is_server():
		ids.append(id)
		jugadores_cambiaron.emit()
		_lista.rpc(ids)  # los clientes también quieren saber quién está en la sala
		_config.rpc_id(id, config, listos)


func _al_desconectar(id: int) -> void:
	ids.erase(id)
	aspectos.erase(id)
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


# --- Aspectos y colores ---


# Cada cliente, al entrar, dice cómo va vestido; el anfitrión se lo cuenta a todos.
@rpc("any_peer", "call_remote", "reliable")
func _mi_aspecto(a: Variant) -> void:
	var quien := multiplayer.get_remote_sender_id()
	if not multiplayer.is_server() or not quien in ids or not Perfil.valido(a):
		return
	aspectos[quien] = a
	_aspectos.rpc(aspectos)
	jugadores_cambiaron.emit()


# Tras cambiarte de ropa o de nombre en la sala: el anfitrión lo apunta y se lo cuenta a todos.
func avisar_aspecto() -> void:
	if not es_online():
		return
	if multiplayer.is_server():
		aspectos[1] = Perfil.aspecto.duplicate()
		_aspectos.rpc(aspectos)
		jugadores_cambiaron.emit()
	else:
		_mi_aspecto.rpc_id(1, Perfil.aspecto)


@rpc("authority", "call_remote", "reliable")
func _aspectos(nuevos: Dictionary) -> void:
	aspectos = nuevos
	jugadores_cambiaron.emit()


func aspecto_de(id: int) -> Dictionary:
	if aspectos.has(id):
		return aspectos[id]
	return Perfil.aspecto if id == multiplayer.get_unique_id() else Perfil.POR_DEFECTO


# El color que se ve en la partida: si dos eligieron el mismo, el que entró después coge otro libre.
func color_de(id: int) -> Color:
	var lista: Array = ids if id in ids else [id]
	var pedidos := {}
	for i in lista:
		pedidos[i] = aspecto_de(i).color
	return Perfil.COLORES[sin_repetir(lista, pedidos)[id]]


static func sin_repetir(lista: Array, pedidos: Dictionary) -> Dictionary:
	var usados := {}
	var r := {}
	for id in lista:
		var c: int = pedidos[id]
		while usados.has(c):
			c = (c + 1) % Perfil.COLORES.size()
		usados[c] = true
		r[id] = c
	return r

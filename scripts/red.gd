# Autoload "Red": crear partida, unirse, config de la partida, listos y aspectos de los jugadores.
# Es como un singleton de Java: Godot crea un único nodo Red al arrancar y cualquier script
# puede usarlo por su nombre. El anfitrión (id 1) manda; los clientes reciben copias por @rpc.
extends Node

signal jugadores_cambiaron
signal desconectado(motivo: String)
signal config_cambiada  # rondas o listos: el menú se repinta
signal sala_lista  # el servidor ya nos dio el código de la sala

const PUERTO := 7777
const MAX_JUGADORES := 6
# Servidor de salas (ver servidor/). Pruebas y desarrollo local: variable de entorno ROLLAZO_SALAS.
const SERVIDOR_SALAS := "wss://rollazo-salas.rollazo-salas.workers.dev"
const ALFABETO := "ABCDEFGHJKMNPQRSTUVWXYZ"  # sin I, L ni O: se confunden con 1 y 0
const LARGO_CODIGO := 4
const ESPERA_RTC := 15.0  # segundos para que el amigo conecte; sin TURN, algunas redes no pueden
# Solo STUN (sin TURN: no cuesta nada). Si las dos redes son muy cerradas, no conectarán.
const ICE := {"iceServers": [{"urls": ["stun:stun.cloudflare.com:3478", "stun:stun.l.google.com:19302"]}]}
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
var codigo_sala := ""  # "" hasta que el servidor de salas lo da (o si no es una sala)

var _senal: Senal  # conexión con el servidor de salas; null si no hay sala
var _rtc: WebRTCMultiplayerPeer  # null mientras un cliente espera su id
var _conexiones := {}  # id -> WebRTCPeerConnection
var _espera := -1.0  # cuenta atrás de un cliente que aún no ha conectado con el anfitrión


func _ready() -> void:
	multiplayer.peer_connected.connect(_al_conectar)
	multiplayer.peer_disconnected.connect(_al_desconectar)
	multiplayer.server_disconnected.connect(_al_caer_anfitrion)
	multiplayer.connected_to_server.connect(func():
		_espera = -1.0
		_mi_aspecto.rpc_id(1, Perfil.aspecto))
	multiplayer.connection_failed.connect(func(): _al_caer_anfitrion("No se pudo conectar"))


func _process(delta: float) -> void:
	var senal := _senal  # copia local: un fallo dentro de poll() hace salir(), que suelta _senal
	if senal:
		senal.poll()  # el WebRTCMultiplayerPeer lo sondea el propio multiplayer
	if _espera >= 0.0:
		_espera -= delta
		if _espera < 0.0:
			_fallo_sala("NO SE PUDO CONECTAR CON EL ANFITRIÓN")


# --- Conexión ---


func crear_partida(puerto: int = PUERTO) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(puerto, MAX_JUGADORES - 1)  # el anfitrión ya es 1 de los 6
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
	if _senal:
		_senal.cerrar()
		_senal = null
	_rtc = null
	_conexiones.clear()
	codigo_sala = ""
	_espera = -1.0
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
	return _senal != null or not multiplayer.multiplayer_peer is OfflineMultiplayerPeer


# --- Salas con código (WebRTC) ---
# El servidor de salas solo presenta a los jugadores; la partida va directa entre PCs.
# El anfitrión (id 1) crea la oferta cuando entra alguien; los clientes solo hablan con él.


static func url_servidor() -> String:
	var url := OS.get_environment("ROLLAZO_SALAS")
	return url if url != "" else SERVIDOR_SALAS


# Mayúsculas y solo letras del alfabeto, hasta 4: lo que se escribe en el campo del menú.
static func normalizar_codigo(texto: String) -> String:
	var r := ""
	for c in texto.to_upper():
		if c in ALFABETO and r.length() < LARGO_CODIGO:
			r += c
	return r


static func codigo_valido(texto: String) -> bool:
	return texto.length() == LARGO_CODIGO and normalizar_codigo(texto) == texto


func crear_sala() -> Error:
	var err := _abrir_senal("/sala/nueva")
	if err != OK:
		return err
	_senal.sala.connect(func(codigo: String, _id: int):
		codigo_sala = codigo
		sala_lista.emit())
	_rtc = WebRTCMultiplayerPeer.new()
	_rtc.create_server()
	multiplayer.multiplayer_peer = _rtc
	ids = [1]
	aspectos = {1: Perfil.aspecto.duplicate()}
	jugadores_cambiaron.emit()
	return OK


func unirse_sala(codigo: String) -> Error:
	if not codigo_valido(codigo):
		return ERR_INVALID_PARAMETER
	var err := _abrir_senal("/sala/" + codigo)
	if err != OK:
		return err
	_senal.sala.connect(func(c: String, id: int):
		codigo_sala = c
		_rtc = WebRTCMultiplayerPeer.new()
		_rtc.create_client(id)
		multiplayer.multiplayer_peer = _rtc  # el anfitrión (1) ofrecerá en cuanto le avisen
		_espera = ESPERA_RTC)
	jugadores_cambiaron.emit()  # el menú ya muestra "conectando"
	return OK


func _abrir_senal(ruta: String) -> Error:
	if _senal:
		return ERR_ALREADY_IN_USE
	_senal = Senal.new()
	var err := _senal.conectar(url_servidor() + ruta)
	if err != OK:
		_senal = null
		return err
	_senal.entra.connect(_al_entrar_amigo)
	_senal.sale.connect(_al_salir_amigo)
	_senal.oferta.connect(_al_recibir_oferta)
	_senal.respuesta.connect(func(de: int, sdp: String): _con(de).set_remote_description("answer", sdp))
	_senal.candidato.connect(func(de: int, media: String, indice: int, nombre: String): _con(de).add_ice_candidate(media, indice, nombre))
	_senal.error.connect(func(motivo: String): _fallo_sala("ESA SALA NO EXISTE" if motivo == "no_existe" else "LA SALA ESTÁ LLENA"))
	_senal.sin_conexion.connect(_al_perder_servidor)
	_senal.cerrada.connect(_al_caer_anfitrion)
	return OK


# Conexión WebRTC con el jugador `id`; se crea al primer uso (offer entrante o amigo que entra).
func _con(id: int) -> WebRTCPeerConnection:
	if _conexiones.has(id):
		return _conexiones[id]
	var c := WebRTCPeerConnection.new()
	c.initialize(ICE)
	c.session_description_created.connect(func(tipo: String, sdp: String):
		c.set_local_description(tipo, sdp)
		if _senal:
			_senal.enviar({"tipo": "oferta" if tipo == "offer" else "respuesta", "a": id, "sdp": sdp}))
	c.ice_candidate_created.connect(func(media: String, indice: int, nombre: String):
		if _senal:
			_senal.enviar({"tipo": "candidato", "a": id, "media": media, "indice": indice, "nombre": nombre}))
	_rtc.add_peer(c, id)  # antes de ofrecer/responder: crea los canales de datos
	_conexiones[id] = c
	return c


func _al_entrar_amigo(id: int) -> void:
	if multiplayer.refuse_new_connections:
		return  # carrera en marcha: igual que con ENet, quien llega tarde no entra
	_con(id).create_offer()


func _al_salir_amigo(id: int) -> void:
	_conexiones.erase(id)
	if _rtc and _rtc.has_peer(id):
		_rtc.remove_peer(id)


func _al_recibir_oferta(de: int, sdp: String) -> void:
	if de == 1 and _rtc:
		_con(1).set_remote_description("offer", sdp)  # Godot genera la respuesta solo


# Mientras se monta la sala, un fallo la deshace y el menú lo cuenta. Ya dentro, el juego sigue (P2P).
func _fallo_sala(motivo: String) -> void:
	salir()
	desconectado.emit(motivo)


func _al_perder_servidor() -> void:
	if _senal and (codigo_sala == "" or _rtc == null):
		_fallo_sala("NO HAY CONEXIÓN CON EL SERVIDOR")


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

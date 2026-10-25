# Pausa compartida. Cualquiera pulsa P para pedirla; se pausa cuando otro jugador pulsa P
# también (con 4, que acepten todos dejaría que uno solo la bloqueara). Para seguir, P otra
# vez: cuenta atrás 3-2-1 visible para todos. Practicando solo, P pausa directamente.
# Este nodo sigue vivo con el juego pausado (PROCESS_MODE_ALWAYS), como un hilo aparte en Java.
extends Node

const SEGUNDOS_PARA_ACEPTAR := 6.0

var pendiente := 0  # quién pidió la pausa y espera a otro (solo en el anfitrión); 0 = nadie
var _reanudando := false

@onready var nivel := get_parent()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _exit_tree() -> void:
	get_tree().paused = false  # salir al menú o volver a la sala nunca deja el juego congelado


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("pausa"):
		if Red.es_online():
			pedir.rpc_id(1)
		else:
			alternar_local()
	elif evento.is_action_pressed("volver_menu") and get_tree().paused:  # el nivel no oye Esc en pausa
		nivel.volver_al_menu()


func alternar_local() -> void:
	if get_tree().paused:
		_reanudar()
	else:
		_pausar()


@rpc("any_peer", "call_local", "reliable")
func pedir() -> void:
	if multiplayer.is_server():
		pedir_de(maxi(multiplayer.get_remote_sender_id(), 1))  # 0 = me lo pido yo mismo


# Solo el anfitrión decide.
func pedir_de(quien: int) -> void:
	if not quien in Red.ids:
		return  # lo que llega por red no es de fiar
	if get_tree().paused:
		_reanudar.rpc()
	elif pendiente == 0 or pendiente == quien:
		pendiente = quien
		_pedida.rpc(quien)
		await get_tree().create_timer(SEGUNDOS_PARA_ACEPTAR).timeout
		if is_inside_tree() and pendiente == quien and not get_tree().paused:  # nadie aceptó
			pendiente = 0
			_pedida.rpc(0)
	else:
		pendiente = 0
		_pausar.rpc()


@rpc("authority", "call_local", "reliable")
func _pedida(quien: int) -> void:
	if quien == 0:
		nivel.hud.titular("")
	elif quien == multiplayer.get_unique_id():
		nivel.hud.titular("PAUSA PEDIDA · ESPERANDO A QUE OTRO PULSE P")
	else:
		nivel.hud.titular("%s PIDE PAUSA · P PARA ACEPTAR" % nivel.nombre(quien))


@rpc("authority", "call_local", "reliable")
func _pausar() -> void:
	get_tree().paused = true
	nivel.hud.titular("PAUSA\nP PARA SEGUIR · ESC MENÚ")


@rpc("authority", "call_local", "reliable")
func _reanudar() -> void:
	if _reanudando:
		return
	_reanudando = true
	for n in [3, 2, 1]:
		nivel.hud.titular(str(n))
		await get_tree().create_timer(1.0).timeout  # estos temporizadores corren aunque esté pausado
		if not is_inside_tree():
			return
	nivel.hud.titular("")
	pendiente = 0
	_reanudando = false
	get_tree().paused = false

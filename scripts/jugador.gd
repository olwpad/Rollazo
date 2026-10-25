# El muñeco. CharacterBody2D es un cuerpo que movemos nosotros (no lo empuja la física
# por su cuenta), así controlamos exactamente cómo se siente el columpio.
class_name Jugador
extends CharacterBody2D

signal papel_roto
signal papel_lanzado
signal aterrizaje_fuerte
signal efecto_red(tipo: String, pos: Vector2)  # llega a todos los PCs

const VELOCIDAD_PLOF := 700.0  # caer más rápido que esto hace "¡PLOF!"
const COLORES := [Color("6cc3b0"), Color("ef8fae"), Color("a99be0"), Color("f5b38a")]  # menta, rosa, lavanda, melocotón

# Valores iniciales: se ajustan jugando desde el Inspector del editor.
@export var gravedad := 1400.0
@export var velocidad_suelo := 320.0
@export var control_aire := 600.0
@export var impulso_soltar := 1.15
@export var velocidad_encoger := 300.0
@export var segundos_aguante := 3.0
@export var tiempo_min_impulso := 0.2
@export var fuerza_salto := 650.0

var papel: PapelRope = null  # null = no está enganchado. Solo existe en el anfitrión.
var _tiempo_enganchado := 0.0

# Lo que ven los demás PCs: el anfitrión lo copia de `papel` y el Sync lo replica.
var papel_activo := false
var papel_ancla := Vector2.ZERO
var papel_aguante := 1.0

const EVENTOS := ["lanzar", "saltar"]
var _remoto := {"soltar": true, "apunta": Vector2.ZERO, "eje_x": 0.0, "eje_largo": 0.0}
var _remoto_contadores := {}  # en el anfitrión: lo último que mandó el dueño
var _contadores_vistos := {}  # en el anfitrión: lo ya procesado
var _mis_contadores := {}  # en el cliente dueño

@onready var rayo: RayCast2D = $Rayo


# Cada moco se llama como el id de red de su dueño ("1" es el anfitrión).
func id_dueno() -> int:
	return name.to_int() if name.is_valid_int() else 1


# Único sitio donde se lee la entrada: del teclado si el moco es mío, de la red si no.
func _leer_input() -> Dictionary:
	if id_dueno() == multiplayer.get_unique_id():
		return _leer_teclado()
	var e := _remoto.duplicate()
	for accion in EVENTOS:  # un evento remoto cuenta una vez: cuando sube su contador
		e[accion] = _remoto_contadores.get(accion, 0) > _contadores_vistos.get(accion, 0)
		_contadores_vistos[accion] = _remoto_contadores.get(accion, 0)
	return e


func _leer_teclado() -> Dictionary:
	return {
		"lanzar": Input.is_action_just_pressed("lanzar"),
		"soltar": not Input.is_action_pressed("lanzar"),  # estado, no evento: un clic de un solo frame también suelta
		"apunta": get_global_mouse_position(),
		"eje_x": Input.get_axis("izquierda", "derecha"),
		"eje_largo": Input.get_axis("encoger", "alargar"),
		"saltar": Input.is_action_just_pressed("saltar"),
	}


# El cliente dueño manda su entrada al anfitrión cada frame. Los eventos (clic, salto) van
# como contadores que solo suben: si se pierde un paquete, el siguiente trae el clic igual.
@rpc("any_peer", "call_remote", "unreliable_ordered")
func recibir_input(estado: Dictionary, contadores: Dictionary) -> void:
	if not multiplayer.is_server() or multiplayer.get_remote_sender_id() != id_dueno():
		return  # solo el dueño de este moco puede moverlo
	# Lo que llega por red no es de fiar: solo se aceptan claves y tipos conocidos.
	_remoto = {
		"soltar": estado.get("soltar", true) == true,
		"apunta": estado.get("apunta") if estado.get("apunta") is Vector2 else global_position,
		"eje_x": clampf(float(estado.get("eje_x", 0.0)), -1.0, 1.0),
		"eje_largo": clampf(float(estado.get("eje_largo", 0.0)), -1.0, 1.0),
	}
	for accion in EVENTOS:
		_remoto_contadores[accion] = maxi(_remoto_contadores.get(accion, 0), int(contadores.get(accion, 0)))


func _enviar_input() -> void:
	var e := _leer_teclado()
	for accion in EVENTOS:
		if e.get(accion, false):
			_mis_contadores[accion] = _mis_contadores.get(accion, 0) + 1
	recibir_input.rpc_id(1, e, _mis_contadores)


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		if id_dueno() == multiplayer.get_unique_id():
			_enviar_input()
		return  # solo el anfitrión simula; los demás reciben la posición por el Sync
	var e := _leer_input()
	if e.lanzar:
		_lanzar_papel(e.apunta)
		_tiempo_enganchado = 0.0
	if e.soltar and papel != null:
		if _tiempo_enganchado >= tiempo_min_impulso:  # si no, clicar rápido multiplicaría la velocidad
			velocity *= impulso_soltar
		papel = null

	velocity.y += gravedad * delta
	if e.saltar and is_on_floor():
		velocity.y = -fuerza_salto
	if is_on_floor():
		velocity.x = move_toward(velocity.x, e.eje_x * velocidad_suelo, 3000.0 * delta)
	else:
		velocity.x += e.eje_x * control_aire * delta
	if papel != null:
		papel.cambiar_largo(e.eje_largo * velocidad_encoger * delta)

	var caida := velocity.y
	var estaba_en_aire := not is_on_floor()
	move_and_slide()
	if estaba_en_aire and is_on_floor() and caida > VELOCIDAD_PLOF:
		aterrizaje_fuerte.emit()
		efecto.rpc("aterrizaje", global_position + Vector2(0, 18))

	if papel != null:
		var r := Pendulo.restringir(global_position, velocity, papel.ancla, papel.largo)
		move_and_collide(r[0] - global_position)  # con colisión, para no atravesar paredes
		velocity = r[1]
		_tiempo_enganchado += delta
		papel.gastar(delta, Pendulo.tension(r[2]))
		if papel.roto:
			papel = null
			papel_roto.emit()
			efecto.rpc("rotura", (global_position + papel_ancla) / 2.0)
	_publicar_papel()


# El anfitrión avisa de un efecto visual a todos los PCs (también a sí mismo: call_local).
@rpc("authority", "call_local", "unreliable")
func efecto(tipo: String, pos: Vector2) -> void:
	efecto_red.emit(tipo, pos)


func _publicar_papel() -> void:
	papel_activo = papel != null
	if papel_activo:
		papel_ancla = papel.ancla
		papel_aguante = papel.aguante


func reaparecer(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	papel = null
	_publicar_papel()


func _lanzar_papel(objetivo: Vector2) -> void:
	papel = null  # nunca dos papeles a la vez
	rayo.target_position = (objetivo - global_position).normalized() * PapelRope.LARGO_MAX
	rayo.force_raycast_update()
	var choque := rayo.get_collider()
	if choque is Node and (choque as Node).is_in_group("enganchable"):
		var punto := rayo.get_collision_point()
		papel = PapelRope.new(punto, global_position.distance_to(punto), segundos_aguante)
		papel_lanzado.emit()
		efecto.rpc("enganche", punto)


# El moco se estira solo según la velocidad; aquí solo se inclina un poco.
func _process(_delta: float) -> void:
	var visual: Node2D = $Visual
	visual.rotation = lerp_angle(visual.rotation, clampf(velocity.x / 3000.0, -0.25, 0.25), 0.2)
	$Visual/Moco.velocidad = velocity

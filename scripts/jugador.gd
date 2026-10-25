# El muñeco. CharacterBody2D es un cuerpo que movemos nosotros (no lo empuja la física
# por su cuenta), así controlamos exactamente cómo se siente el columpio.
class_name Jugador
extends CharacterBody2D

signal papel_roto
signal papel_lanzado
signal aterrizaje_fuerte
signal efecto_red(tipo: String, pos: Vector2)  # llega a todos los PCs

const VELOCIDAD_PLOF := 700.0  # caer más rápido que esto hace "¡PLOF!"
const VELOCIDAD_CHOQUE := 300.0  # por debajo, dos mocos solo se tocan
const RADIO_CORTE := 50.0  # a esta distancia del papel de otro, puedes cortarlo
const DIST_AGARRE := 60.0
const LARGO_AGARRE := 45.0  # largo del hilo de moco con el que te cuelgas de otro
const PESO_POR_CARGA := 0.5  # cada moco colgado de ti suma media gravedad
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
var agarre_activo := false
var agarre_pos := Vector2.ZERO

var agarrado_a: Jugador = null  # a quién me agarro (solo en el anfitrión)
var carga := 0  # cuántos están agarrados a mí

const EVENTOS := ["lanzar", "saltar", "cortar", "agarrar"]
var _remoto := {"soltar": true, "apunta": Vector2.ZERO, "eje_x": 0.0, "eje_largo": 0.0}
var _remoto_contadores := {}  # en el anfitrión: lo último que mandó el dueño
var _contadores_vistos := {}  # en el anfitrión: lo ya procesado
var _mis_contadores := {}  # en el cliente dueño

@onready var rayo: RayCast2D = $Rayo


func _ready() -> void:
	if id_dueno() == multiplayer.get_unique_id():  # la mira solo en el PC del dueño
		var mira := Node2D.new()
		mira.name = "Mira"
		mira.set_script(preload("res://scripts/mira.gd"))
		add_child(mira)


# Color del moco y de todo lo que suelta (gotas, salpicadura, estela).
func pintar(color: Color) -> void:
	$Visual/Moco.color = color
	$Efectos/Salpicadura.color = color
	$Efectos/Goteo.color = color
	$Efectos/Estela.default_color = Color(color, 0.4)


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
		"cortar": Input.is_action_just_pressed("cortar"),
		"agarrar": Input.is_action_just_pressed("agarrar"),
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
	if e.cortar:
		_cortar_cercanos()
	if e.agarrar:
		if agarrado_a == null:
			_agarrar_cercano()
		else:
			soltar_agarre()
	if e.saltar:
		soltar_agarre()
	if e.lanzar:
		_lanzar_papel(e.apunta)
		_tiempo_enganchado = 0.0
	if e.soltar and papel != null:
		if _tiempo_enganchado >= tiempo_min_impulso:  # si no, clicar rápido multiplicaría la velocidad
			velocity *= impulso_soltar
		papel = null

	velocity.y += gravedad * (1.0 + PESO_POR_CARGA * carga) * delta
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
	var antes := velocity  # move_and_slide recorta la parte que va contra el otro moco
	move_and_slide()
	_chocar(antes)
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
	if agarrado_a != null and not is_instance_valid(agarrado_a):
		agarrado_a = null  # se desconectó
	if agarrado_a != null:
		var r := Pendulo.restringir(global_position, velocity, agarrado_a.global_position, LARGO_AGARRE)
		move_and_collide(r[0] - global_position)
		velocity = r[1]
	_publicar_papel()


# Si este moco ha chocado fuerte con otro, ambos rebotan (solo en el anfitrión).
func _chocar(antes: Vector2) -> void:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var otro := c.get_collider() as Jugador
		if otro == null or (antes - otro.velocity).dot(c.get_normal()) > -VELOCIDAD_CHOQUE:
			continue
		var r := Rebote.calcular(antes, otro.velocity, c.get_normal())
		velocity = r[0]
		otro.velocity = r[1]
		efecto.rpc("choque", c.get_position())
		otro.efecto.rpc("choque", c.get_position())
		return


# Corta el papel de todo moco cuyo papel pase cerca de mí. No hace falta estar colgado.
func _cortar_cercanos() -> void:
	var acerto := false
	for otro in get_parent().get_children():
		if not (otro is Jugador and otro != self and otro.papel != null):
			continue
		if Geometria.distancia_a_segmento(global_position, otro.global_position, otro.papel.ancla) < RADIO_CORTE:
			otro.cortar_papel()
			acerto = true
	efecto.rpc("corte" if acerto else "corte_fallido", global_position)


func _agarrar_cercano() -> void:
	var mejor: Jugador = null
	var dist_mejor := DIST_AGARRE
	for otro in get_parent().get_children():
		if not (otro is Jugador and otro != self and otro.agarrado_a != self):
			continue  # no a uno mismo, ni a quien ya está agarrado a mí (haría un bucle)
		var d := global_position.distance_to(otro.global_position)
		if d < dist_mejor:
			mejor = otro
			dist_mejor = d
	if mejor != null:
		agarrado_a = mejor
		mejor.carga += 1
		mejor.efecto.rpc("agarrado", mejor.global_position)
		efecto.rpc("enganche", mejor.global_position)


func soltar_agarre() -> void:
	if agarrado_a != null and is_instance_valid(agarrado_a):
		agarrado_a.carga -= 1
	agarrado_a = null


func _exit_tree() -> void:
	soltar_agarre()  # si me desconecto, dejo de pesarle al otro


func cortar_papel() -> void:
	efecto.rpc("cortado", (global_position + papel.ancla) / 2.0)
	papel = null
	papel_roto.emit()
	_publicar_papel()


# El anfitrión avisa de un efecto visual a todos los PCs (también a sí mismo: call_local).
@rpc("authority", "call_local", "unreliable")
func efecto(tipo: String, pos: Vector2) -> void:
	efecto_red.emit(tipo, pos)


func _publicar_papel() -> void:
	agarre_activo = agarrado_a != null
	if agarre_activo:
		agarre_pos = agarrado_a.global_position
	papel_activo = papel != null
	if papel_activo:
		papel_ancla = papel.ancla
		papel_aguante = papel.aguante


# con_efecto solo tras caerse: al empezar ronda, los demás PCs quizá aún no tienen este moco.
func reaparecer(pos: Vector2, con_efecto := false) -> void:
	global_position = pos
	if con_efecto:
		efecto.rpc("reaparecer", pos)
	velocity = Vector2.ZERO
	papel = null
	soltar_agarre()
	for otro in get_parent().get_children():
		if otro is Jugador and otro.agarrado_a == self:
			otro.soltar_agarre()
			otro._publicar_papel()
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

# El muñeco. CharacterBody2D es un cuerpo que movemos nosotros (no lo empuja la física
# por su cuenta), así controlamos exactamente cómo se siente el columpio.
# Solo el anfitrión simula (_physics_process); los clientes mandan su entrada por RPC y
# reciben posición/estado por el MultiplayerSynchronizer (variables públicas de abajo).
class_name Jugador
extends CharacterBody2D

signal papel_roto
signal papel_lanzado
signal aterrizaje_fuerte
signal aterrizado(caida: float)  # cada vez que toca suelo, con la velocidad vertical que traía
signal efecto_red(tipo: String, pos: Vector2)  # llega a todos los PCs

const VELOCIDAD_PLOF := 700.0  # caer más rápido que esto hace "¡PLOF!"
const VELOCIDAD_CHOQUE := 300.0  # por debajo, dos mocos solo se tocan
const RADIO_CORTE := 50.0  # a esta distancia del papel de otro, puedes cortarlo
const DIST_AGARRE := 60.0
const LARGO_AGARRE := 45.0  # largo del hilo de moco con el que te cuelgas de otro
const PESO_POR_CARGA := 0.5  # cada moco colgado de ti suma media gravedad
const DIST_PUNETAZO := 70.0
const FUERZA_PUNETAZO := 950.0
const COLORES := [Color("6cc3b0"), Color("ef8fae"), Color("a99be0"), Color("f5b38a"), Color("f5d38a"), Color("8ec5e8")]  # menta, rosa, lavanda, melocotón, limón, cielo

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
var _papel_cuerpo: Node2D = null  # si el enganche es en algo que se mueve (barco, liana, globo): el ancla lo sigue
var _papel_local := Vector2.ZERO  # el punto enganchado, en el espacio de ese cuerpo
var _tiempo_enganchado := 0.0

# Lo que ven los demás PCs: el anfitrión lo copia de `papel` y el Sync lo replica.
var papel_activo := false
var papel_ancla := Vector2.ZERO
var papel_aguante := 1.0
var agarre_activo := false
var agarre_pos := Vector2.ZERO

var agarrado_a: Jugador = null  # a quién me agarro (solo en el anfitrión)
var carga := 0  # cuántos están agarrados a mí
var congelado := false  # quieto: durante la postal de la ronda o ya de espectador (solo en el anfitrión)
var poder := ""  # el que lleva ahora ("" = ninguno); el Sync lo copia a todos para el brillo y el HUD
var poder_restante := 0.0
var _poder_dibujado := ""  # último poder pintado, para redibujar solo al cambiar
var _golpeados := {}  # puñetazo: a quién le pegué y cuándo, para no pegarle cada frame

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


# Pelo, sombrero, cara y ropa del perfil (el color va aparte: en la partida puede cambiar si se repite).
func vestir(aspecto: Dictionary) -> void:
	$Visual/Moco.vestir(aspecto)


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
	if not is_inside_tree() or not multiplayer.is_server() or multiplayer.get_remote_sender_id() != id_dueno():  # puede llegar justo al cambiar de escena
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
	if e.lanzar:
		papel_lanzado.emit()  # el anfitrión no sonoriza el clic de otros: suena aquí, en el PC de su dueño
	recibir_input.rpc_id(1, e, _mis_contadores)


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		if id_dueno() == multiplayer.get_unique_id():
			_enviar_input()
		return  # solo el anfitrión simula; los demás reciben la posición por el Sync
	var e := _leer_input()
	gastar_poder(delta)
	if congelado or poder == "congelado":  # se lee la entrada igual, para que un clic no salte después
		velocity = Vector2.ZERO
		return
	_seguir_ancla()
	if poder == "punetazo":
		golpear_cercanos()
	_aplicar_acciones(e)
	_aplicar_movimiento(e, delta)
	_mover_y_aterrizar()
	_aplicar_cuerda(delta)
	_aplicar_hilo_agarre()
	_publicar_papel()


# --- Física: un frame del anfitrión, por pasos ---

# Eventos y botones: cortar, agarrar, saltar (suelta el agarre), lanzar/soltar el papel.
func _aplicar_acciones(e: Dictionary) -> void:
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


# Gravedad, salto, pared y control en suelo/aire; al final, el largo de la cuerda.
func _aplicar_movimiento(e: Dictionary, delta: float) -> void:
	var en_pared := poder == "pared" and is_on_wall() and papel == null
	if en_pared and e.saltar:  # despegarse: salto hacia fuera de la pared
		velocity = get_wall_normal() * 450.0 + Vector2(0, -fuerza_de_salto())
	elif en_pared:  # pegado: un empujoncito contra la pared para seguir tocándola
		velocity = -get_wall_normal() * 30.0 + Vector2(0, e.eje_largo * velocidad_encoger)
	else:
		velocity.y += gravedad * (1.0 + PESO_POR_CARGA * carga) * delta
	if e.saltar and is_on_floor():
		velocity.y = -fuerza_de_salto()
	if is_on_floor():
		velocity.x = move_toward(velocity.x, e.eje_x * velocidad_suelo * factor_velocidad(), 3000.0 * delta)
	elif not en_pared:
		velocity.x += e.eje_x * control_aire * factor_velocidad() * delta
	if papel != null:
		papel.cambiar_largo(e.eje_largo * velocidad_encoger * delta)


# move_and_slide + choque con otros mocos + aviso de aterrizaje.
func _mover_y_aterrizar() -> void:
	var caida := velocity.y
	var estaba_en_aire := not is_on_floor()
	var antes := velocity  # move_and_slide recorta la parte que va contra el otro moco
	move_and_slide()
	_chocar(antes)
	if estaba_en_aire and is_on_floor():
		aterrizado.emit(caida)
		if caida > VELOCIDAD_PLOF:
			aterrizaje_fuerte.emit()
			efecto.rpc("aterrizaje", global_position + Vector2(0, 18))


# Columpio: la cuerda restringe la posición (péndulo) y gasta aguante según la tensión.
func _aplicar_cuerda(delta: float) -> void:
	if papel == null:
		return
	var r := Pendulo.restringir(global_position, velocity, papel.ancla, papel.largo)
	_mover_deslizando(r[0] - global_position)  # con colisión, para no atravesar paredes
	velocity = r[1]
	_tiempo_enganchado += delta
	papel.gastar(delta, Pendulo.tension(r[2]))
	if papel.roto:
		papel = null
		papel_roto.emit()
		efecto.rpc("rotura", (global_position + papel_ancla) / 2.0)


# El hilo de moco con el que cuelgo de otro funciona como una cuerda de largo fijo.
func _aplicar_hilo_agarre() -> void:
	if agarrado_a != null and not is_instance_valid(agarrado_a):
		agarrado_a = null  # se desconectó
	if agarrado_a != null:
		var r := Pendulo.restringir(global_position, velocity, agarrado_a.global_position, LARGO_AGARRE)
		_mover_deslizando(r[0] - global_position)
		velocity = r[1]


# --- Poderes ---

# Al coger una burbuja (solo en el anfitrión). Congelar no se lo queda: para a los demás.
func dar_poder(tipo: String) -> void:
	poder = tipo
	poder_restante = Poderes.DURACION[tipo]
	if tipo == "congelar":
		for otro in get_parent().get_children():
			if otro is Jugador and otro != self:
				otro.poder = "congelado"
				otro.poder_restante = Poderes.DURACION.congelado
				otro.efecto.rpc("congelado", otro.global_position)


func gastar_poder(delta: float) -> void:
	if poder == "":
		return
	poder_restante -= delta
	if poder_restante <= 0.0:
		poder = ""
		poder_restante = 0.0


func factor_velocidad() -> float:
	return 1.6 if poder == "rapidez" else 1.0


func fuerza_de_salto() -> float:
	return fuerza_salto * (1.5 if poder == "salto" else 1.0)


# Puñetazo: quien esté al lado sale volando hacia fuera (y un poco hacia arriba).
func golpear_cercanos() -> void:
	var ahora := Time.get_ticks_msec()
	for otro in get_parent().get_children():
		if not (otro is Jugador and otro != self) or global_position.distance_to(otro.global_position) > DIST_PUNETAZO:
			continue
		if ahora - _golpeados.get(otro.name, -100000) < 600:
			continue
		_golpeados[otro.name] = ahora
		var dir: Vector2 = (otro.global_position - global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		otro.velocity = dir * FUERZA_PUNETAZO + Vector2(0, -350)
		otro.papel = null  # el golpe le suelta del papel
		efecto.rpc("choque", (global_position + otro.global_position) / 2.0)


# El ancla va con el cuerpo al que me enganché; si desaparece (o deja de ser enganchable), se suelta.
func _seguir_ancla() -> void:
	if papel == null or _papel_cuerpo == null:
		return
	if is_instance_valid(_papel_cuerpo) and _papel_cuerpo.is_in_group("enganchable"):
		papel.ancla = _papel_cuerpo.to_global(_papel_local)
	else:
		papel = null
		_publicar_papel()


# Aro de fuego: se quema el papel y se chamusca. Dónde vuelve lo decide el recorrido (como al caer).
func quemarse() -> void:
	papel = null
	_publicar_papel()
	efecto.rpc("fuego", global_position)


# Como move_and_collide, pero si choca con una pared resbala por ella en vez de quedarse
# pegado (el bot probador se quedaba clavado en esquinas hasta romper el papel).
func _mover_deslizando(movimiento: Vector2) -> void:
	var c := move_and_collide(movimiento)
	if c != null:
		move_and_collide(c.get_remainder().slide(c.get_normal()))


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
		_papel_cuerpo = null
		if not choque is StaticBody2D:  # los techos fijos no hacen falta seguirlos
			_papel_cuerpo = choque as Node2D
			_papel_local = _papel_cuerpo.to_local(punto)
		papel = PapelRope.new(punto, global_position.distance_to(punto), segundos_aguante)
		papel_lanzado.emit()
		efecto.rpc("enganche", punto)


# Brillo del color del poder alrededor del moco: así se ve qué lleva cada uno.
func _draw() -> void:
	if poder != "":
		draw_circle(Vector2.ZERO, 40.0, Color(Poderes.COLOR[poder], 0.32))


# El moco se estira solo según la velocidad; aquí solo se inclina un poco.
func _process(_delta: float) -> void:
	if poder != _poder_dibujado:
		_poder_dibujado = poder
		queue_redraw()
	var visual: Node2D = $Visual
	visual.rotation = lerp_angle(visual.rotation, clampf(velocity.x / 3000.0, -0.25, 0.25), 0.2)
	$Visual/Moco.velocidad = velocity

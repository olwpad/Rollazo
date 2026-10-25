# El muñeco. CharacterBody2D es un cuerpo que movemos nosotros (no lo empuja la física
# por su cuenta), así controlamos exactamente cómo se siente el columpio.
class_name Jugador
extends CharacterBody2D

signal papel_roto
signal papel_lanzado
signal aterrizaje_fuerte

const VELOCIDAD_PLOF := 700.0  # caer más rápido que esto hace "¡PLOF!"

# Valores iniciales: se ajustan jugando desde el Inspector del editor.
@export var gravedad := 1400.0
@export var velocidad_suelo := 320.0
@export var control_aire := 600.0
@export var impulso_soltar := 1.15
@export var velocidad_encoger := 300.0
@export var segundos_aguante := 3.0
@export var tiempo_min_impulso := 0.2
@export var fuerza_salto := 650.0

var papel: PapelRope = null  # null = no está enganchado
var _tiempo_enganchado := 0.0

@onready var rayo: RayCast2D = $Rayo


# Único sitio donde se lee la entrada. En la fase 2 esto vendrá de la red.
func _leer_input() -> Dictionary:
	return {
		"lanzar": Input.is_action_just_pressed("lanzar"),
		"soltar": not Input.is_action_pressed("lanzar"),  # estado, no evento: un clic de un solo frame también suelta
		"apunta": get_global_mouse_position(),
		"eje_x": Input.get_axis("izquierda", "derecha"),
		"eje_largo": Input.get_axis("encoger", "alargar"),
		"saltar": Input.is_action_just_pressed("saltar"),
	}


func _physics_process(delta: float) -> void:
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

	if papel != null:
		var r := Pendulo.restringir(global_position, velocity, papel.ancla, papel.largo)
		move_and_collide(r[0] - global_position)  # con colisión, para no atravesar paredes
		velocity = r[1]
		_tiempo_enganchado += delta
		papel.gastar(delta, Pendulo.tension(r[2]))
		if papel.roto:
			papel = null
			papel_roto.emit()


func reaparecer(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	papel = null


func _lanzar_papel(objetivo: Vector2) -> void:
	papel = null  # nunca dos papeles a la vez
	rayo.target_position = (objetivo - global_position).normalized() * PapelRope.LARGO_MAX
	rayo.force_raycast_update()
	var choque := rayo.get_collider()
	if choque is Node and (choque as Node).is_in_group("enganchable"):
		var punto := rayo.get_collision_point()
		papel = PapelRope.new(punto, global_position.distance_to(punto), segundos_aguante)
		papel_lanzado.emit()


# El moco se estira solo según la velocidad; aquí solo se inclina un poco.
func _process(_delta: float) -> void:
	var visual: Node2D = $Visual
	visual.rotation = lerp_angle(visual.rotation, clampf(velocity.x / 3000.0, -0.25, 0.25), 0.2)
	$Visual/Moco.velocidad = velocity

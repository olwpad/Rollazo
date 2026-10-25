# El muñeco. CharacterBody2D es un cuerpo que movemos nosotros (no lo empuja la física
# por su cuenta), así controlamos exactamente cómo se siente el columpio.
class_name Jugador
extends CharacterBody2D

signal papel_roto

# Valores iniciales: se ajustan jugando desde el Inspector del editor.
@export var gravedad := 1400.0
@export var velocidad_suelo := 320.0
@export var control_aire := 600.0
@export var impulso_soltar := 1.15
@export var velocidad_encoger := 300.0
@export var segundos_aguante := 3.0

var papel: PapelRope = null  # null = no está enganchado

@onready var rayo: RayCast2D = $Rayo


# Único sitio donde se lee la entrada. En la fase 2 esto vendrá de la red.
func _leer_input() -> Dictionary:
	return {
		"lanzar": Input.is_action_just_pressed("lanzar"),
		"soltar": Input.is_action_just_released("lanzar"),
		"apunta": get_global_mouse_position(),
		"eje_x": Input.get_axis("izquierda", "derecha"),
		"eje_largo": Input.get_axis("encoger", "alargar"),
	}


func _physics_process(delta: float) -> void:
	var e := _leer_input()
	if e.lanzar:
		_lanzar_papel(e.apunta)
	elif e.soltar and papel != null:
		velocity *= impulso_soltar
		papel = null

	velocity.y += gravedad * delta
	if is_on_floor():
		velocity.x = move_toward(velocity.x, e.eje_x * velocidad_suelo, 3000.0 * delta)
	else:
		velocity.x += e.eje_x * control_aire * delta
	if papel != null:
		papel.cambiar_largo(e.eje_largo * velocidad_encoger * delta)

	move_and_slide()

	if papel != null:
		var r := Pendulo.restringir(global_position, velocity, papel.ancla, papel.largo)
		move_and_collide(r[0] - global_position)  # con colisión, para no atravesar paredes
		velocity = r[1]
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


# Que se vea blando: se inclina con la velocidad y se estira al ir rápido.
func _process(_delta: float) -> void:
	var visual: Node2D = $Visual
	visual.rotation = lerp_angle(visual.rotation, clampf(velocity.x / 1500.0, -0.5, 0.5), 0.2)
	var estiron := clampf(velocity.length() / 2000.0, 0.0, 0.25)
	visual.scale = visual.scale.lerp(Vector2(1.0 - estiron * 0.5, 1.0 + estiron), 0.3)

# Efectos físicos del jugador (sin texto): salpicadura de moco, goteo, estela y temblor de pantalla.
# Es hijo de cada Jugador (nodo Efectos) y reacciona a su señal efecto_red, que llega a todos los PCs.
extends Node2D

const VELOCIDAD_ESTELA := 800.0
const ESTELA_PUNTOS := 10
# Qué suena con cada efecto: este señal llega a todos los PCs, así cada uno oye lo que ve.
const SONIDOS := {"enganche": "enganchar", "agarrado": "enganchar", "aterrizaje": "salpicar", "choque": "salpicar",
	"reaparecer": "salpicar", "fuego": "salpicar", "cortado": "soltar", "rotura": "soltar", "corte": "soltar",
	"meta": "meta", "poder": "poder", "sierra": "sierra", "control": "control", "boing": "boing"}

@onready var jugador: Jugador = get_parent()
@onready var estela: Line2D = $Estela
@onready var salpicadura: CPUParticles2D = $Salpicadura
@onready var goteo: CPUParticles2D = $Goteo
var humo := CPUParticles2D.new()  # al quemarse en un aro


func _ready() -> void:
	top_level = true  # los efectos se quedan en el mundo aunque el jugador se mueva
	jugador.efecto_red.connect(_al_efecto)
	# jugador.gd tiene class_name y no puede nombrar autoloads en los sims: el sonido se pide desde aquí
	jugador.papel_lanzado.connect(func(): Sonidos.tocar("lanzar", jugador.global_position))  # el del anfitrión; el de un cliente suena en su PC al pulsar
	_configurar_humo()


func _configurar_humo() -> void:
	humo.name = "Humo"
	humo.emitting = false
	humo.one_shot = true
	humo.amount = 18
	humo.lifetime = 1.0
	humo.explosiveness = 0.7
	humo.direction = Vector2.UP
	humo.spread = 35.0
	humo.gravity = Vector2(0, -60)
	humo.initial_velocity_min = 40.0
	humo.initial_velocity_max = 110.0
	humo.scale_amount_min = 6.0
	humo.scale_amount_max = 14.0
	humo.color = Color(Acuarela.CIRUELA, 0.35)
	add_child(humo)


# Intensidad según la importancia del evento: enganchar es pequeño, caer y romperse, medio.
# El temblor solo lo nota el dueño del moco; lo demás lo ven todos.
func _al_efecto(tipo: String, pos: Vector2) -> void:
	var sonido: String = SONIDOS.get(tipo, "")
	if sonido != "":
		Sonidos.tocar(sonido, pos)
	match tipo:
		"enganche":
			_salpicar(pos)
			_moco().aplastar(Vector2(0.8, 1.25))
		"aterrizaje":
			_salpicar(pos)
			_moco().aplastar(Vector2(1.35, 0.65))
			_temblar(0.35)
		"choque":
			_salpicar(pos)
			_moco().aplastar(Vector2(0.7, 1.3))
			_temblar(0.5)
		"corte":  # acertaste el corte
			_moco().aplastar(Vector2(1.25, 0.8))
			_temblar(0.3)
		"corte_fallido":
			_moco().aplastar(Vector2(1.15, 0.88))
		"cortado":  # te lo cortaron: más fuerte que una rotura normal
			_trozos(pos)
			_temblar(0.6)
		"agarrado":
			_salpicar(pos)
			_moco().aplastar(Vector2(1.3, 0.75))
			_temblar(0.3)
		"reaparecer":
			_salpicar(pos)
			_moco().aplastar(Vector2(0.6, 1.4))
		"meta":
			_trozos(pos)
			_salpicar(pos)
			_moco().aplastar(Vector2(1.5, 0.6))
			_temblar(0.6)
		"rotura":
			_trozos(pos)
			_temblar(0.45)
		"poder":  # cogiste una burbuja
			_salpicar(pos)
			_moco().aplastar(Vector2(1.3, 0.75))
		"fuego":  # un aro te quemó el papel: chamuscado un momento, humo y buena sacudida
			_trozos(pos)
			humo.global_position = pos
			humo.restart()
			_moco().aplastar(Vector2(1.4, 0.6))
			var visual: Node2D = jugador.get_node("Visual")
			visual.modulate = Color(0.45, 0.32, 0.32)
			create_tween().tween_property(visual, "modulate", Color.WHITE, 1.2).set_ease(Tween.EASE_IN)
			_temblar(0.7)
		"congelado":  # te congelaron: se encoge de golpe
			_moco().aplastar(Vector2(0.75, 0.75))
			_temblar(0.25)


func _process(_delta: float) -> void:
	goteo.global_position = jugador.global_position
	goteo.emitting = jugador.velocity.length() > 200.0
	if jugador.velocity.length() > VELOCIDAD_ESTELA:
		estela.add_point(jugador.global_position, 0)
		if estela.get_point_count() > ESTELA_PUNTOS:
			estela.remove_point(estela.get_point_count() - 1)
	elif estela.get_point_count() > 0:
		estela.remove_point(estela.get_point_count() - 1)


func _salpicar(pos: Vector2) -> void:
	salpicadura.global_position = pos
	salpicadura.restart()


func _trozos(pos: Vector2) -> void:
	var trozos: CPUParticles2D = jugador.get_node("PapelVisual/Trozos")
	trozos.global_position = pos
	trozos.restart()


func _temblar(trauma: float) -> void:
	if jugador.id_dueno() != multiplayer.get_unique_id():
		return
	var camara := get_viewport().get_camera_2d()
	if camara != null and camara.has_method("add_trauma"):
		camara.add_trauma(trauma)


func _moco() -> MocoVisual:
	return jugador.get_node("Visual/Moco")

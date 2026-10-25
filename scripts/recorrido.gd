# Lógica del recorrido: cronómetro, puntos de control, caída al vacío, meta y reinicio.
extends Node2D

var tiempo := 0.0
var mejor := INF
var corriendo := true
var ultimo_control: Vector2

@onready var jugador: Jugador = $Jugador
@onready var hud := $HUD


func _ready() -> void:
	$Caida.body_entered.connect(_al_caer)
	$Meta.body_entered.connect(_al_llegar)
	for control: Area2D in $Controles.get_children():
		control.body_entered.connect(_al_pasar_control.bind(control))
	for dibujo: Polygon2D in find_children("Dibujo", "Polygon2D"):
		_poner_borde_comic(dibujo)
	reiniciar()


# Contorno negro grueso, como en los cómics.
func _poner_borde_comic(dibujo: Polygon2D) -> void:
	var borde := Line2D.new()
	borde.points = dibujo.polygon
	borde.closed = true
	borde.width = 6.0
	borde.default_color = Color.BLACK
	dibujo.add_child(borde)


func _physics_process(delta: float) -> void:
	if corriendo:
		tiempo += delta
	hud.mostrar(tiempo, mejor)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("reiniciar"):
		reiniciar()


func reiniciar() -> void:
	tiempo = 0.0
	corriendo = true
	ultimo_control = $Inicio.global_position
	jugador.reaparecer(ultimo_control)
	hud.limpiar()


func _al_pasar_control(cuerpo: Node2D, control: Area2D) -> void:
	if cuerpo == jugador:
		ultimo_control = control.global_position


func _al_caer(cuerpo: Node2D) -> void:
	if cuerpo == jugador:
		jugador.reaparecer.call_deferred(ultimo_control)  # no mover cuerpos dentro de una señal de física


func _al_llegar(cuerpo: Node2D) -> void:
	if cuerpo == jugador and corriendo:
		corriendo = false
		hud.meta(tiempo, mejor)
		mejor = minf(mejor, tiempo)

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
	var i := 0
	for dibujo: Polygon2D in find_children("Dibujo", "Polygon2D"):
		_estilo_neon(dibujo, i)
		i += 1
	reiniciar()


# Techos enganchables = carteles de neón; suelos = azoteas oscuras.
# Copia cian desplazada detrás y contorno negro grueso, como en un cómic mal impreso.
func _estilo_neon(dibujo: Polygon2D, i: int) -> void:
	if dibujo.get_parent().is_in_group("enganchable"):
		dibujo.color = Color(1.0, 0.25, 0.6) if i % 2 == 0 else Color(1.0, 0.88, 0.3)
	elif dibujo.get_parent() is StaticBody2D:
		dibujo.color = Color(0.36, 0.14, 0.55)
	var fantasma := Polygon2D.new()
	fantasma.polygon = dibujo.polygon
	fantasma.color = Color(0.0, 0.9, 1.0, 0.6)
	fantasma.position = Vector2(-6, 4)
	fantasma.show_behind_parent = true
	dibujo.add_child(fantasma)
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

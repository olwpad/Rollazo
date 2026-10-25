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
		_estilo_acuarela(dibujo, i)
		i += 1
	_estilo_acuarela($Meta/Bandera, 99)
	reiniciar()


# Cada forma se pinta como mancha de acuarela, sin contorno: techos enganchables en rosa
# o lavanda, azoteas en lavanda oscuro. Solo cambia el dibujo; la colisión sigue siendo exacta.
func _estilo_acuarela(dibujo: Polygon2D, i: int) -> void:
	var color := Acuarela.MENTA
	if dibujo.get_parent().is_in_group("enganchable"):
		color = Acuarela.ROSA if i % 2 == 0 else Acuarela.LAVANDA
	elif dibujo.get_parent() is StaticBody2D:
		color = Acuarela.AZOTEA
	# Base opaca: lo que se puede tocar no deja ver el fondo, así se lee como sólido.
	var base := Polygon2D.new()
	base.polygon = Tinta.irregular(dibujo.polygon, i, 2.0, 30.0)
	base.color = color.lightened(0.35)
	dibujo.add_child(base)
	for capa in Acuarela.capas(dibujo.polygon, i):
		var mancha := Polygon2D.new()
		mancha.polygon = capa
		mancha.color = Color(color, Acuarela.OPACIDAD_CAPA)
		dibujo.add_child(mancha)
	dibujo.color = Color.TRANSPARENT


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

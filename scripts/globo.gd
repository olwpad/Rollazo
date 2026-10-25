# Globo que sube despacio y en bucle (sale abajo, llega arriba, revienta y vuelve a salir). Enganchado
# te eleva. Mientras no está (abajo del todo o arriba del todo) no se puede enganchar.
class_name Globo
extends AnimatableBody2D

const COLORES := [Acuarela.ROSA, Acuarela.MENTA, Acuarela.LAVANDA, Color("f5b38a")]

var x := 0.0
var abajo := 1000.0  # y de salida; sube `alto` px y vuelve a empezar
var alto := 1500.0
var fase := 0.0
var color := 0
var nivel: Node = null
var _capa := 1


func _ready() -> void:
	sync_to_physics = false  # lo movemos nosotros en _physics_process
	_capa = collision_layer
	var forma := CollisionShape2D.new()
	forma.shape = CircleShape2D.new()
	forma.shape.radius = 26.0
	add_child(forma)
	_mover(0.0)


func _physics_process(_delta: float) -> void:
	if nivel != null:
		_mover(nivel.reloj_ronda)
	queue_redraw()


# Cuánto del viaje lleva (0..1)
func avance_en(t: float) -> float:
	return fposmod(t * Moviles.VELOCIDAD_GLOBO / alto + fase, 1.0)


func posicion_en(t: float) -> Vector2:
	return Vector2(x + 18.0 * sin(TAU * (t / 6.0 + fase)), abajo - alto * avance_en(t))


func presente_en(t: float) -> bool:
	return absf(avance_en(t) - 0.5) < 0.45  # un 5% al principio y al final fuera: no se agarra un globo que aparece o revienta


func _mover(t: float) -> void:
	position = posicion_en(t)
	var si := presente_en(t)
	collision_layer = _capa if si else 0
	visible = absf(avance_en(t) - 0.5) < 0.5
	modulate.a = 1.0 if si else 0.4
	if si:
		add_to_group("enganchable")
	else:
		remove_from_group("enganchable")  # si estabas enganchado, jugador.gd te suelta


func _draw() -> void:
	var c: Color = COLORES[color % COLORES.size()]
	Moviles.mancha(self, Moviles.elipse(22, 26), c, 71 + color)
	draw_line(Vector2(0, 26), Vector2(0, 62), Color("fffaf4"), 2.0)
	draw_circle(Vector2(-8, -9), 5.0, Color(1, 1, 1, 0.4))

# Sierra circular que gira: quieta o yendo y viniendo por un riel. Quién la toca lo decide
# el anfitrión (recorrido.gd); aquí solo hay forma, movimiento y dibujo.
class_name Sierra
extends Area2D

const RADIO := 26.0  # el de la zona que corta; el dibujo con dientes llega a ~31
const PERIODO := 3.0  # ida y vuelta por el riel
const DIENTES := 24
# Pastel de Perfil.COLORES sin rosa, lavanda ni chicle: se perdían junto a los techos enganchables
const COLORES := [Color("6cc3b0"), Color("f5b38a"), Color("f5d38a"), Color("8ec5e8"), Color("c7d97a")]
const RIEL := Color("8f86b8", 0.7)

var riel := Vector2.ZERO  # de su sitio a su sitio + riel y vuelta; ZERO = quieta
var fase := 0.0  # en vueltas (0..1): así no van todas a la par
var color := 0  # índice en COLORES
var nivel: Node = null  # el recorrido: su `tiempo` de ronda mueve la sierra igual en todos los PCs
var _base := Vector2.ZERO


func _ready() -> void:
	collision_mask = 2  # solo mocos
	_base = position
	var forma := CollisionShape2D.new()
	forma.shape = CircleShape2D.new()
	forma.shape.radius = RADIO
	add_child(forma)


func _physics_process(_delta: float) -> void:
	# shortcut: la sierra en riel puede verse unas décimas desfasada en otros PCs, el anfitrión manda; si molesta, enviar el instante de arranque por rpc.
	if nivel != null:
		position = _base + posicion_en(nivel.tiempo)
	queue_redraw()


# Dónde está respecto a su sitio en el segundo `t` de la ronda: sale de 0, llega a `riel` a
# mitad de periodo y vuelve, frenando en las puntas.
func posicion_en(t: float) -> Vector2:
	return riel * (1.0 - cos(TAU * (t / PERIODO + fase))) / 2.0


func _draw() -> void:
	var foto := Tinta.fotograma()
	var c: Color = COLORES[color]
	if riel != Vector2.ZERO:  # el riel no se mueve: se dibuja desde el sitio de la sierra
		var a := _base - position
		draw_line(a, a + riel, RIEL, 5.0)
		draw_circle(a, 2.5, RIEL)  # puntas redondeadas
		draw_circle(a + riel, 2.5, RIEL)
	var giro := TAU * Time.get_ticks_msec() / 1000.0  # una vuelta por segundo, suave; el temblor va a 12 fps
	var dientes := PackedVector2Array()
	for i in DIENTES * 2:
		dientes.append(Vector2.from_angle(giro + PI * i / DIENTES) * (31.0 if i % 2 == 0 else 24.0))
	draw_colored_polygon(Tinta.temblar(dientes, 11, foto, 0.8), c.darkened(0.1))  # como MocoVisual._cosa
	draw_colored_polygon(Tinta.temblar(_circulo(25.0), 12, foto, 0.8), c)
	draw_colored_polygon(Tinta.temblar(_circulo(15.0), 13, foto, 0.6), c.lightened(0.3))
	draw_circle(Vector2.ZERO, 4.0, Acuarela.CIRUELA)
	draw_circle(Vector2(-10, -10), 5.0, Color(1, 1, 1, 0.45))  # el brillo no gira: es la luz


func _circulo(r: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 20:
		p.append(Vector2.from_angle(TAU * i / 20.0) * r)
	return p

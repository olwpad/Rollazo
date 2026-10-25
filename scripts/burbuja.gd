# Burbuja de poder: acuarela del color del poder con su dibujito blanco, flotando arriba y
# abajo. La coge el primer moco que la toque (lo decide el anfitrión) y vuelve a salir al rato.
extends Area2D

const RADIO := 30.0
const SEGUNDOS_PARA_VOLVER := 10.0

var tipo := "rapidez"
var semilla := 0  # la del mapa y su sitio en él: de ahí sale el poder siguiente
var indice := 0
var _veces := 0
var _t := 0.0


func _ready() -> void:
	collision_mask = 2  # solo mocos
	var forma := CollisionShape2D.new()
	forma.shape = CircleShape2D.new()
	forma.shape.radius = RADIO
	add_child(forma)
	_t = position.x  # cada una flota a su ritmo


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()  # solo flota el dibujo; la zona para cogerla se queda quieta


func _draw() -> void:
	var c := Vector2(0, sin(_t * 2.0) * 6.0)
	var color: Color = Poderes.COLOR[tipo]
	draw_circle(c, RADIO, Color(color, 0.5))
	draw_circle(c + Vector2(2, -1), RADIO * 0.8, Color(color, 0.45))  # dos capas: borde más intenso, como acuarela
	Poderes.dibujar_icono(self, tipo, c, RADIO * 0.8)


# Se va al cogerla y vuelve más tarde (en todos los PCs, que lo llaman a la vez).
func recogida() -> void:
	visible = false
	tipo = siguiente_tipo()
	set_deferred("monitoring", false)
	await get_tree().create_timer(SEGUNDOS_PARA_VOLVER, false).timeout
	if is_inside_tree():
		visible = true
		monitoring = true


# Otro poder, el mismo en todos los PCs: sale de la semilla, sin mandar nada por la red.
func siguiente_tipo() -> String:
	_veces += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(semilla, indice * 1000 + _veces))
	var otros: Array = Poderes.TIPOS.filter(func(t: String) -> bool: return t != tipo)
	return otros[rng.randi_range(0, otros.size() - 1)]

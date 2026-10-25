# Estalactita de la cueva: cuelga, tiembla (aviso), cae, y vuelve a crecer. Si te da al caer
# lo decide el anfitrión (recorrido.gd); aquí solo hay ciclo, forma y dibujo.
class_name Estalactita
extends Area2D

const PERIODO := 7.0
const T_AVISO := 3.4  # empieza a temblar; 0,6 s después cae
const T_CAE := 4.0
const SEG_CAIDA := 0.55
const T_CRECE := 5.5  # entre que acaba de caer y aquí no hay estalactita
const DROP := 520.0
const LARGO := 110.0
const ANCHO := 40.0
enum Fase { CUELGA, TIEMBLA, CAE, AUSENTE, CRECE }

var fase := 0.0  # en vueltas (0..1): así no caen todas a la par
var nivel: Node = null
var _base := Vector2.ZERO


static func nuevas(semilla: int, m: Dictionary, nivel_: Node) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(semilla, 32))
	var lista := []
	for i in range(1, m.camino.size()):
		var c: Vector2 = m.camino[i]
		# Que se vea venir y no te devuelva lejos: nada cerca de controles, salida ni meta
		var libre: bool = c.distance_to(m.inicio) > 400.0 and c.distance_to(m.meta) > 350.0 \
				and m.controles.all(func(k: Vector2) -> bool: return c.distance_to(k) > 250.0)
		if not libre or rng.randf() > 0.4 or lista.size() >= 6:
			continue
		var e := Estalactita.new()
		e.name = "Estalactita%d" % lista.size()
		e.position = c + Vector2(rng.randf_range(50.0, 80.0) * (1.0 if rng.randf() < 0.5 else -1.0), 8.0)
		e.fase = rng.randf()
		e.nivel = nivel_
		lista.append(e)
	return lista


# Qué hace en el segundo `t` de la ronda.
func fase_en(t: float) -> Fase:
	var s := _segundo(t)
	if s < T_AVISO:
		return Fase.CUELGA
	if s < T_CAE:
		return Fase.TIEMBLA
	if s < T_CAE + SEG_CAIDA:
		return Fase.CAE
	return Fase.AUSENTE if s < T_CRECE else Fase.CRECE


# Cuánto ha bajado de su sitio (0 mientras cuelga o tiembla).
func caido_en(t: float) -> float:
	var u := clampf((_segundo(t) - T_CAE) / SEG_CAIDA, 0.0, 1.0)
	return DROP * u * u


func _segundo(t: float) -> float:
	return fposmod(t + fase * PERIODO, PERIODO)


func _ready() -> void:
	collision_mask = 2  # solo mocos
	_base = position
	monitoring = false  # solo hace daño cayendo
	var forma := CollisionShape2D.new()
	forma.shape = RectangleShape2D.new()
	forma.shape.size = Vector2(ANCHO * 0.6, LARGO * 0.8)
	forma.position = Vector2(0, LARGO * 0.5)
	add_child(forma)


func _physics_process(_delta: float) -> void:
	var t: float = nivel.reloj_ronda if nivel != null else 0.0
	position = _base + Vector2(0, caido_en(t))
	monitoring = fase_en(t) == Fase.CAE
	queue_redraw()


func _draw() -> void:
	var t: float = nivel.reloj_ronda if nivel != null else 0.0
	var f := fase_en(t)
	if f == Fase.AUSENTE:
		return
	var largo := LARGO * (clampf((_segundo(t) - T_CRECE) / (PERIODO - T_CRECE), 0.0, 1.0) if f == Fase.CRECE else 1.0)
	var tiembla := Vector2(sin(Time.get_ticks_msec() / 18.0) * 3.0, 0) if f == Fase.TIEMBLA else Vector2.ZERO
	var w := ANCHO / 2.0
	var roca := PackedVector2Array([Vector2(-w, -6), Vector2(w, -6), Vector2(w * 0.55, largo * 0.5), Vector2(w * 0.12, largo), Vector2(-w * 0.2, largo * 0.8), Vector2(-w * 0.6, largo * 0.45)])
	for i in roca.size():
		roca[i] += tiembla
	var c := Color("9a82a6") if f != Fase.TIEMBLA else Color("c98f9c")  # se enrojece al avisar
	draw_colored_polygon(roca, c)
	draw_colored_polygon(PackedVector2Array([roca[0] * 0.5 + tiembla * 0.5, roca[1] * 0.2 + tiembla * 0.8, roca[3] * 0.8 + tiembla * 0.2]), c.lightened(0.3))
	if f == Fase.TIEMBLA:  # polvillo que se desprende
		for k in 3:
			draw_circle(tiembla + Vector2((k - 1) * 9.0, 10.0 + fmod(Time.get_ticks_msec() / 6.0 + k * 20.0, 40.0)), 2.0, Color(1, 1, 1, 0.6))

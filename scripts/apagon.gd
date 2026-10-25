# Techo del camino que se "apaga" un rato en ciclo: pálido y sin admitir papel mientras tanto
# (lanzar_papel solo engancha al grupo "enganchable"; si ya estás enganchado, no te suelta).
class_name Apagon
extends Node

const PERIODO := 8.0
const APAGADO := 2.5  # segundos apagado dentro del periodo

var cuerpos: Array[StaticBody2D] = []  # el techo (si está roto, sus dos trozos)
var fase := 0.0  # en vueltas (0..1)
var nivel: Node = null
var apagado := false


# Qué techos del camino se apagan: ninguno al lado de otro, así nunca hay dos seguidos apagados.
static func indices(semilla: int, n: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(semilla, 35))
	var lista := []
	for i in range(1, n - 1):  # ni el primero (sale del descanso) ni el último
		if rng.randf() < 0.3 and not (i - 1) in lista:
			lista.append(i)
	return lista


static func nuevos(semilla: int, m: Dictionary, nivel_: Node, piezas: Node) -> Array:
	var lista := []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(semilla, 36))
	for i in indices(semilla, m.camino.size()):
		var c: Vector2 = m.camino[i]
		var ap := Apagon.new()
		ap.name = "Apagon%d" % i
		for p: Dictionary in m.piezas:
			if p.enganchable and p.nombre.begins_with("Techo") and absf(p.pos.x - c.x) < 170.0 and absf(p.pos.y - c.y) < 40.0:
				var cuerpo := piezas.get_node_or_null(p.nombre) as StaticBody2D
				if cuerpo != null:
					ap.cuerpos.append(cuerpo)
		if ap.cuerpos.is_empty():
			ap.free()
			continue
		ap.fase = rng.randf()
		ap.nivel = nivel_
		lista.append(ap)
	return lista


func apagado_en(t: float) -> bool:
	return fposmod(t + fase * PERIODO, PERIODO) < APAGADO


func _physics_process(_delta: float) -> void:
	var ahora := apagado_en(nivel.reloj_ronda if nivel != null else 0.0)
	if ahora == apagado:
		return
	apagado = ahora
	for c in cuerpos:
		if apagado:
			c.remove_from_group("enganchable")
		else:
			c.add_to_group("enganchable")
		c.get_node("Dibujo").modulate = Color(1, 1, 1, 0.4) if apagado else Color.WHITE

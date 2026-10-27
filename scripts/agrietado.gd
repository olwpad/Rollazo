# Techo del camino con grietas: si alguien cuelga de él tiembla 1,5 s y se cae; unos segundos
# después vuelve a su sitio. El anfitrión decide cuándo (mira los papeles) y avisa a todos por
# rpc (recorrido.gd: techo_estado); cada PC solo anima y apaga/enciende la colisión.
class_name Agrietado
extends Node

enum Estado { QUIETO, TIEMBLA, CAIDO }

const P_AGRIETADO := 0.22  # por techo elegible; con "nunca dos seguidos" salen ~15-20 % de los techos
const T_TIEMBLA := 1.5  # desde que alguien cuelga hasta que cae
const T_AUSENTE := 4.0  # caído, hasta que vuelve
const SEG_CAIDA := 0.9  # lo que tarda en irse cayendo y desvaneciéndose

var cuerpos: Array[StaticBody2D] = []  # el techo (si está roto, sus dos trozos)
var nivel: Node = null
var estado: int = Estado.QUIETO
var _t := 0.0  # segundos en el estado actual
var _cajas: Array[Rect2] = []  # globales, para saber quién cuelga de él


# Qué techos del camino se agrietan: solo en horizontal y bajada, nunca el primero tras un descanso
# ni el último de un tramo, ni dos seguidos, ni uno de los `excluir` (los que se apagan).
static func indices(semilla: int, m: Dictionary, excluir: Array = []) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(semilla, 63))
	var lista := []
	for t: Dictionary in m.tramos:
		for i in range(t.i0, t.i1):
			var sorteo := rng.randf()  # siempre se sortea: así cambiar una regla no mueve los demás
			if not t.tipo in ["horizontal", "bajada"] or i == t.i0 or i == t.i1 - 1 or i == m.camino.size() - 1:
				continue
			if sorteo < P_AGRIETADO and not (i - 1) in lista and not i in excluir and not _tras_descanso(m, i):
				lista.append(i)
	return lista


static func _tras_descanso(m: Dictionary, i: int) -> bool:
	var a: Vector2 = m.camino[i - 1]
	var b: Vector2 = m.camino[i]
	return m.piezas.any(func(p: Dictionary) -> bool: return p.nombre.begins_with("Descanso") and p.pos.x > a.x and p.pos.x < b.x)


# Los nodos de cada techo agrietado, con sus grietas dibujadas. `piezas` ya tiene los cuerpos del mapa.
static func nuevos(semilla: int, m: Dictionary, nivel_: Node, piezas: Node, excluir: Array = []) -> Array:
	var lista := []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(semilla, 64))
	for i in indices(semilla, m, excluir):
		var ag := Agrietado.new()
		ag.name = "Agrietado%d" % i
		for p: Dictionary in Generador.techos_en(m, m.camino[i]):
			var cuerpo := piezas.get_node_or_null(p.nombre) as StaticBody2D
			if cuerpo != null:
				ag.cuerpos.append(cuerpo)
				ag._cajas.append(Generador.caja_de(p).grow(8.0))
				ag._grietas(cuerpo, Generador.caja_de(p), rng)
		if ag.cuerpos.is_empty():
			ag.free()
			continue
		ag.nivel = nivel_
		lista.append(ag)
	return lista


# 2 o 3 grietas ciruela que bajan en zigzag desde la cara de arriba, hijas del dibujo para que lo sigan.
func _grietas(cuerpo: StaticBody2D, caja: Rect2, rng: RandomNumberGenerator) -> void:
	for k in rng.randi_range(2, 3):
		var linea := Line2D.new()
		linea.width = 3.0
		linea.default_color = Color(Acuarela.CIRUELA, 0.75)
		var x := rng.randf_range(-0.3, 0.3) * caja.size.x + caja.get_center().x - cuerpo.position.x
		var y := caja.position.y + 4.0 - cuerpo.position.y
		var puntos := PackedVector2Array()
		for paso in 4:
			puntos.append(Vector2(x, y))
			x += rng.randf_range(-12.0, 12.0)
			y += rng.randf_range(7.0, 11.0)
		linea.points = puntos
		cuerpo.get_node("Dibujo").add_child(linea)


func _physics_process(delta: float) -> void:
	_t += delta
	var host := multiplayer.is_server() and nivel != null
	match estado:
		Estado.QUIETO:
			if host and _alguien_cuelga():
				nivel.techo_estado.rpc(name, Estado.TIEMBLA)
		Estado.TIEMBLA:
			var fuerza := 1.5 + 4.0 * _t / T_TIEMBLA
			_mover_dibujo(Vector2(randf_range(-fuerza, fuerza), randf_range(-0.5, 0.5) * fuerza), 1.0)
			if host and _t >= T_TIEMBLA:
				nivel.techo_estado.rpc(name, Estado.CAIDO)
		Estado.CAIDO:
			var u := minf(_t / SEG_CAIDA, 1.0)
			_mover_dibujo(Vector2(0.0, 700.0 * u * u), 1.0 - u)
			if host and _t >= T_AUSENTE:
				nivel.techo_estado.rpc(name, Estado.QUIETO)


func _alguien_cuelga() -> bool:
	if nivel == null:
		return false
	for j: Jugador in nivel.jugadores():
		if j.papel != null and _cajas.any(func(c: Rect2) -> bool: return c.has_point(j.papel.ancla)):
			return true
	return false


# Cambio de estado: llega a todos los PCs (recorrido.gd, rpc fiable).
func aplicar(nuevo: int) -> void:
	estado = nuevo
	_t = 0.0
	for c in cuerpos:
		var cae := nuevo == Estado.CAIDO
		if cae:
			c.remove_from_group("enganchable")
		else:
			c.add_to_group("enganchable")
		for forma in c.get_children():
			if forma is CollisionPolygon2D:
				forma.set_deferred("disabled", cae)
	if nuevo == Estado.QUIETO:
		_mover_dibujo(Vector2.ZERO, 1.0)
	elif nuevo == Estado.CAIDO and multiplayer.is_server() and nivel != null:
		for j: Jugador in nivel.jugadores():  # el papel enganchado en él se suelta
			if j.papel != null and _cajas.any(func(c: Rect2) -> bool: return c.has_point(j.papel.ancla)):
				j.papel = null
				j._publicar_papel()


func _mover_dibujo(pos: Vector2, alfa: float) -> void:
	for c in cuerpos:
		var dibujo: Node2D = c.get_node("Dibujo")
		dibujo.position = pos
		dibujo.modulate = Color(1, 1, 1, alfa)

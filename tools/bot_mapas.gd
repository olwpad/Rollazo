# Bot probador: un moco que intenta pasarse el mapa solo, para saber si un mapa se puede terminar.
# Uso: godot --headless --fixed-fps 60 --path <repo> --script res://tools/bot_mapas.gd -- <semilla> [forma|-] [bots=1] [cap_s=90]
# Imprime una línea "BOT <id> FIN|STUCK|FALL ..." por moco. "-" = la forma que toque por semilla.
extends SceneTree

const SIM := "res://tests/jugador_simulado.gd"
const ALCANCE := 415.0  # un pelo menos que PapelRope.LARGO_MAX
const MARGEN_SIERRA := 50.0  # radio del moco y algo de holgura

var nivel: Node
var frame := 0
var semilla := 0
var forma := ""
var n_bots := 1
var cap := 90.0
var m: Dictionary  # el mismo mapa que construye el recorrido
var camino: Array = []
var bots: Array = []
var embudo := {}  # techo -> Vector2(x izquierda del pilar, y de arriba del pilar)
var piezas_info := {}  # nombre -> {tipo, pos, poly (mundo), nodo, idx (techo del camino más cercano)}
var meta := Vector2.ZERO


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: semilla = int(a[0])
	if a.size() > 1 and a[1] != "-": forma = a[1]
	if a.size() > 2: n_bots = int(a[2])
	if a.size() > 3: cap = float(a[3])


func _physics_process(_delta: float) -> bool:
	frame += 1
	if frame == 1:
		root.get_node("Red").semilla = semilla
		nivel = load("res://scenes/recorrido_prueba.tscn").instantiate()
		nivel.forma_forzada = forma
		root.add_child(nivel)
		return false
	if frame == 2:
		_preparar()
		return false
	for b in bots:
		_bot(b)
	var todos := true
	for b in bots:
		if not b.fin: todos = false
	if todos or frame / 60.0 >= cap:
		_informe()
		quit(0)
	return false


func _clasificar(nombre: String, poly: PackedVector2Array) -> String:
	if nombre.begins_with("Techo"):
		if poly.size() == 3: return "triangle"
		if absf(poly[1].y - poly[0].y) > 1.0:
			return "broken" if absf(poly[1].x - poly[0].x) < 150.0 else "tilted"
		if absf(poly[2].x - poly[1].x) > 1.0: return "trapezoid"
		return "flat"
	for k in ["Descanso", "Pilar", "Bloque", "Atajo", "SueloMeta", "SueloPozo", "FondoPozo", "Pared"]:
		if nombre.begins_with(k): return k
	return "?"


func _preparar() -> void:
	m = Generador.generar(semilla, forma)
	camino = m.camino
	for p in nivel.get_node("Piezas").get_children():
		if not p is StaticBody2D: continue  # burbujas y sierras
		var poly: PackedVector2Array = (p.get_child(0) as CollisionPolygon2D).polygon
		var w := PackedVector2Array()
		for v in poly: w.append(v + p.position)
		var idx := -1
		for i in camino.size():
			if idx < 0 or p.position.distance_to(camino[i]) < p.position.distance_to(camino[idx]):
				idx = i
		piezas_info[p.name] = {"tipo": _clasificar(p.name, poly), "pos": p.position, "poly": w, "nodo": p, "idx": idx}
	meta = nivel.get_node("Meta").global_position
	for n in piezas_info:  # techos sobre un embudo: el tope del pilar de debajo
		if piezas_info[n].tipo != "Pilar": continue
		var arriba := INF
		var izq := INF
		for v in piezas_info[n].poly:
			arriba = minf(arriba, v.y)
			izq = minf(izq, v.x)
		for k in piezas_info:
			if piezas_info[k].nodo.is_in_group("enganchable") and absf(piezas_info[k].pos.x - piezas_info[n].pos.x) < 200.0:
				embudo[k] = Vector2(izq, arriba)
	var jugs := nivel.get_node("Jugadores")
	var viejo: Node2D = jugs.get_node("1")
	var inicio: Vector2 = viejo.global_position
	jugs.remove_child(viejo)
	viejo.free()
	for i in n_bots:
		var j: Jugador = load("res://scenes/jugador.tscn").instantiate()
		j.set_script(load(SIM))
		j.name = str(i + 1)
		j.position = inicio + Vector2(i * 90, 0)
		jugs.add_child(j)
		var b := {"j": j, "id": i + 1, "estado": "suelo", "pend": "", "t_hook": 0.0,
			"falls": [], "sierras": [], "roturas": [], "stuck": [], "prog": 0, "idx_hook": -1, "t_prog": 0.0, "fin": false, "t_fin": -1.0,
			"last_hook": "", "prev_pos": j.global_position, "soltado": "", "rescate": 0.0, "lento": 0.0, "rescates": 0, "hooks": 0, "atajos": 0}
		j.papel_roto.connect(func() -> void: b.roturas.append([snappedf(j.global_position.x, 1), snappedf(j.global_position.y, 1), b.last_hook, _tipo(b.last_hook)]))
		bots.append(b)


func _tipo(nombre: String) -> String:
	return piezas_info.get(nombre, {}).get("tipo", "-")


func _cerca(p: Vector2, rango: float) -> String:
	var r: Array[String] = []
	for n in piezas_info:
		var pi: Dictionary = piezas_info[n]
		if pi.pos.distance_to(p) < rango:
			r.append("%s(%s@%d,%d)" % [n, pi.tipo, pi.pos.x, pi.pos.y])
	return " ".join(r)


# Paso del techo i-1 al i casi en vertical: un saliente de torre.
func _vertical(i: int) -> bool:
	return i >= 1 and i < camino.size() and absf(camino[i].x - camino[i - 1].x) < 400.0 and camino[i].y < camino[i - 1].y - 100.0


# Dónde quedaría el suelo de un tramo horizontal aquí (en horizontal puro, siempre SUELO_Y):
# las alturas que el bot usa para decidir van respecto a él.
func _suelo(p: Vector2) -> float:
	if m.forma == "horizontal" or camino.is_empty():
		return Generador.SUELO_Y
	var y: float = camino[0].y
	for i in camino.size():
		if camino[i].x <= p.x:
			y = camino[i].y
			if i + 1 < camino.size() and camino[i + 1].x > p.x:
				y = lerpf(y, camino[i + 1].y, (p.x - camino[i].x) / (camino[i + 1].x - camino[i].x))
	return y + 375.0


# ¿El columpio desde `p` colgando de `ancla` pasaría por una sierra (cualquier punto de su riel)?
func _arco_cruza_sierra(ancla: Vector2, p: Vector2, holgura := 0.0) -> bool:
	var largo := ancla.distance_to(p)
	var ang := absf(atan2(p.x - ancla.x, p.y - ancla.y)) + 0.3
	for k in 17:
		var t := lerpf(-ang, ang, k / 16.0)
		var q := ancla + largo * Vector2(sin(t), cos(t))
		for s: Dictionary in m.sierras:
			if q.distance_to(Geometry2D.get_closest_point_to_segment(q, s.pos, s.pos + s.riel)) < Sierra.RADIO + MARGEN_SIERRA + holgura:
				return true
	return false


# ¿El columpio desde `p`, recogiendo papel, se metería en un descanso que queda encima del moco?
# Se quedaría clavado contra su parte de abajo (pasa en la torre: el descanso
# va bajo el saliente siguiente). Mejor esperar a estar más alto.
func _arco_bajo_descanso(ancla: Vector2, p: Vector2) -> bool:
	var largo := ancla.distance_to(p)
	var ang := absf(atan2(p.x - ancla.x, p.y - ancla.y))
	for n in piezas_info:
		var pi: Dictionary = piezas_info[n]
		if pi.tipo != "Descanso": continue
		var r := Rect2(pi.poly[0], pi.poly[2] - pi.poly[0]).grow(22.0)
		if r.end.y > p.y + 12.0: continue  # no queda por encima del moco
		for k in 17:  # todo el abanico: el bot recoge papel mientras se columpia
			var t := lerpf(-ang, ang, k / 16.0)
			for f in 6:
				if r.has_point(ancla + lerpf(largo, PapelRope.LARGO_MIN, f / 5.0) * Vector2(sin(t), cos(t))):
					return true
	return false


# Rayo del moco a un punto: lo que toca primero, o {} si nada a tiro.
func _rayo(j: Jugador, q: Vector2) -> Dictionary:
	var p := j.global_position
	var qr := PhysicsRayQueryParameters2D.create(p, p + (q - p).normalized() * ALCANCE)
	qr.exclude = [j.get_rid()]
	qr.collision_mask = 1
	return j.get_world_2d().direct_space_state.intersect_ray(qr)


func _puntos(pi: Dictionary) -> Array:
	var puntos: Array = [pi.pos]
	for v in pi.poly: puntos.append(v.lerp(pi.pos, 0.15))
	return puntos


# Mejor gancho hacia delante: el rayo tiene que dar primero en algo enganchable.
func _objetivo(j: Jugador, min_dx: float, evitar: String = "", detras := false, mirar_sierras := true) -> Dictionary:
	var p := j.global_position
	var s := _suelo(p)
	var mejor := {}
	var mejor_score := -INF
	for n in piezas_info:
		var pi: Dictionary = piezas_info[n]
		if not pi.nodo.is_in_group("enganchable") or n == evitar: continue
		if pi.pos.x < p.x + min_dx - 200 or pi.pos.x > p.x + 700 or pi.pos.x > meta.x - 250.0: continue
		for q: Vector2 in _puntos(pi):
			var h := _rayo(j, q)
			if h.is_empty() or not (h.collider as Node).is_in_group("enganchable"): continue
			var hit: Vector2 = h.position
			var dx := hit.x - p.x
			var nom: String = (h.collider as Node).name
			if embudo.has(nom) and p.x < embudo[nom].x and hit.y + p.distance_to(hit) > embudo[nom].y - 25.0 and not detras and p.y < s - 90.0:
				continue  # engancharse ya al techo del embudo te estamparía contra el pilar
			if (detras and dx > -40.0) or (not detras and dx < min_dx) or hit.y > p.y - 60: continue
			if mirar_sierras and _arco_cruza_sierra(hit, p): continue
			var score := hit.x - absf(dx - (p.y - hit.y)) * 0.5  # mejor a ~45 grados y lo más adelante
			if detras: score = -absf(dx + 150.0)
			if score > mejor_score:
				mejor_score = score
				mejor = {"apunta": q, "hit": hit, "nombre": nom}
	return mejor


# En la torre: el saliente más alto del camino (índice >= desde) que se vea entero a tiro.
func _objetivo_arriba(j: Jugador, desde: int) -> Dictionary:
	var p := j.global_position
	var mejor := {}
	var mejor_score := -INF
	for n in piezas_info:
		var pi: Dictionary = piezas_info[n]
		if not pi.nodo.is_in_group("enganchable") or pi.idx < desde: continue
		if pi.pos.distance_to(p) > ALCANCE + 150.0: continue
		for q: Vector2 in _puntos(pi):
			var h := _rayo(j, q)
			if h.is_empty() or (h.collider as Node).name != n: continue
			var hit: Vector2 = h.position
			if hit.y > p.y - 30.0 or _arco_cruza_sierra(hit, p) or _arco_bajo_descanso(hit, p): continue
			var score: float = pi.idx * 1000.0 - hit.distance_to(p)
			if score > mejor_score:
				mejor_score = score
				mejor = {"apunta": q, "hit": hit, "nombre": n}
	return mejor


func _pilar_delante(p: Vector2) -> float:
	var tope := INF
	for n in piezas_info:
		var pi: Dictionary = piezas_info[n]
		if pi.tipo != "Pilar": continue
		var izq := INF
		var arriba := INF
		for v in pi.poly:
			izq = minf(izq, v.x)
			arriba = minf(arriba, v.y)
		if izq - p.x > -40.0 and izq - p.x < 380.0:
			tope = minf(tope, arriba)
	return tope


func _plataforma_debajo(j: Jugador) -> bool:
	var p := j.global_position
	var px := p.x + j.velocity.x * 0.35
	for n in piezas_info:
		var pi: Dictionary = piezas_info[n]
		if pi.tipo != "Descanso" and pi.tipo != "SueloMeta": continue
		var r := Rect2(pi.poly[0], pi.poly[2] - pi.poly[0])
		if px > r.position.x + 10 and px < r.end.x - 10 and p.y < r.position.y and p.y > r.position.y - 380:
			return true
	return false


func _suelo_delante(j: Jugador, dir: float) -> bool:
	var p := j.global_position
	var qr := PhysicsRayQueryParameters2D.create(p + Vector2(45 * dir, 0), p + Vector2(45 * dir, 80))
	qr.exclude = [j.get_rid()]
	return not j.get_world_2d().direct_space_state.intersect_ray(qr).is_empty()


func _bot(b: Dictionary) -> void:
	var j: Jugador = b.j
	var p := j.global_position
	var dt := 1.0 / 60.0
	if p.distance_to(b.prev_pos) > 250.0:  # reapareció: por caerse o por una sierra
		var donde := [snappedf(b.prev_pos.x, 1), snappedf(b.prev_pos.y, 1), b.last_hook, _tipo(b.last_hook), _cerca(b.prev_pos, 300)]
		if b.prev_pos.y > m.caida_y - 400.0:
			b.falls.append(donde)
		else:
			b.sierras.append(donde)
		b.estado = "suelo"
		b.pend = ""
		b.idx_hook = -1
	b.prev_pos = p
	if OS.get_environment("DBG") != "" and frame % 15 == 0 and frame / 60.0 < float(OS.get_environment("DBG")):
		print("t=%.2f p=%s v=%s floor=%s hook=%s anc=%s L=%s ag=%s last=%s prog=%d" % [frame / 60.0, p.round(), j.velocity.round(), j.is_on_floor(), j.papel != null,
			j.papel.ancla.round() if j.papel else "", round(j.papel.largo) if j.papel else "", snappedf(j.papel.aguante, 0.01) if j.papel else "", b.last_hook, b.prog])
	if b.fin:
		j.sostenido = {}
		return
	for c in nivel.get_node("Meta").get_overlapping_bodies():
		if c == j:  # antes de que el recorrido cargue otro mapa
			b.fin = true
			b.t_fin = frame / 60.0
			return
	for r: Rect2 in m.pozos:
		if p.x > r.position.x and p.x < r.end.x + 5.0 and p.y > r.position.y - 40.0 and p.y < r.end.y + 40.0:
			_pozo(b, j, p, r, dt)
			return
	# Progreso: el siguiente techo del camino por alcanzar
	var antes: int = b.prog
	if j.papel != null and b.idx_hook >= 0:
		b.prog = maxi(b.prog, b.idx_hook + 1)
	while b.prog < camino.size() and not _vertical(b.prog) and p.x > camino[b.prog].x + 100.0 and absf(p.y - camino[b.prog].y) < 500.0:
		b.prog += 1
	if b.prog > antes:
		b.t_prog = 0.0
	else:
		b.t_prog += dt
		if b.t_prog > 10.0:
			b.stuck.append([snappedf(p.x, 1), snappedf(p.y, 1), b.estado, b.prog, _cerca(p, 300)])
			b.t_prog = 0.0
	# El primer saliente de una torre puede quedar lejos (se entra andando): hasta acercarse, como siempre
	var entrada_cerca: bool = b.prog < camino.size() and p.distance_to(camino[b.prog]) < ALCANCE + 150.0
	if _vertical(b.prog) or (_vertical(b.prog + 1) and entrada_cerca) or _vertical(b.idx_hook):
		_trepar(b, j, p, dt)
		return
	var s := _suelo(p)
	var objetivo_lejano := p.x > meta.x - 900.0 and absf(p.y - meta.y) < 500.0  # al final: solo llegar al suelo de meta
	if b.pend == "lanzar":
		b.pend = ""
		var o := _objetivo(j, 60.0)
		if not o.is_empty():
			_lanzar(b, o)
			return
	if j.papel != null:
		b.t_hook += dt
		var an: Vector2 = j.papel.ancla
		var v := j.velocity
		var largo: float = j.papel.largo
		var ex := 1.0 if v.x >= 0.0 else -1.0
		var el := 0.0
		if (b.t_hook < 0.8 and largo > 260.0) or j.is_on_floor():
			el = -1.0
		if p.y > _pilar_delante(p) - 40.0:  # pilar delante: acortar para que el arco pase por encima
			el = -1.0
		if b.t_hook > 0.6 and v.length() < 80.0:  # clavado contra una pared: trepar por el papel
			el = -1.0
		if _arco_cruza_sierra(an, p, 80.0):  # acortar sube el arco por encima de la sierra (y deja lanzar desde más alto)
			el = -1.0
		j.sostenido = {"eje_x": ex, "eje_largo": el}
		var adelante := p.x - an.x
		var soltar := false
		if b.t_hook >= 0.2 and v.x > 250.0 and v.y < 0.0 and adelante > 0.25 * largo:
			var o := _objetivo(j, 150.0)
			if not o.is_empty() and o.hit.x > an.x + 200.0:
				soltar = true
				b.pend = "lanzar"
			elif adelante > 0.55 * largo or _plataforma_debajo(j) or (objetivo_lejano and v.y > -500.0):  # al final, sin salir disparado por encima de la meta
				soltar = true
		if j.papel.aguante < 0.18 and v.x > 0.0:
			soltar = true
		b.lento = b.lento + dt if v.length() < 40.0 else 0.0
		if b.lento > 0.6 and not j.is_on_floor():  # clavado: soltar y columpiarse desde atrás
			soltar = true
			b.rescate = 1.2
		if j.is_on_floor() and an.x < p.x - 20.0 and b.t_hook > 0.2:  # aterrizó pasado el ancla: que no le arrastre atrás
			soltar = true
		if soltar:
			b.soltado = b.last_hook
			j.guion = {"soltar": true}
			b.estado = "aire"
		return
	b.t_hook = 0.0
	if j.is_on_floor():
		b.estado = "suelo"
		var o := _objetivo(j, 40.0)
		if not o.is_empty() and not (objetivo_lejano and _plataforma_debajo(j)):
			_lanzar(b, o)
			return
		j.sostenido = {"eje_x": 1.0}  # andar a la derecha; saltar en el borde o si algo no le deja andar
		b.lento = b.lento + dt if absf(j.velocity.x) < 5.0 else 0.0
		if not _suelo_delante(j, 1.0) or b.lento > 0.5:
			j.guion = {"saltar": true}
			b.lento = 0.0
		return
	b.estado = "aire"
	j.sostenido = {"eje_x": 1.0 if j.velocity.x < 700.0 else 0.0}
	if p.x > meta.x + 40.0:
		j.sostenido = {"eje_x": -1.0}
	if _plataforma_debajo(j):
		return
	if b.rescate > 0.0:
		b.rescate -= dt
		var orr := _objetivo(j, 0.0, "", true)
		if not orr.is_empty():
			b.rescate = 0.0
			b.rescates += 1
			_lanzar(b, orr)
		return
	var o2 := _objetivo(j, 60.0 if p.y < s - 130.0 else -120.0, b.soltado if p.y < s - 130.0 else "")
	if o2.is_empty() and j.velocity.y > 0.0:  # cayendo: mejor colgarse aunque el arco roce una sierra (luego se recoge papel)
		o2 = _objetivo(j, 100.0, "", false, false)
	if o2.is_empty():
		return
	var dxo: float = o2.hit.x - p.x
	if j.velocity.y > -150.0 or dxo < 220.0 or p.y > s - 170.0:
		_lanzar(b, o2)


# Torre: engancharse al saliente más alto a tiro, recoger papel y, en cuanto se vea uno más
# alto, saltar a ese. Arriba del todo no hay más: columpiarse y soltarse hacia el descanso.
func _trepar(b: Dictionary, j: Jugador, p: Vector2, dt: float) -> void:
	var cima: bool = b.idx_hook >= 0 and not _vertical(b.idx_hook + 1)
	var siguiente: Vector2 = camino[mini(b.prog, camino.size() - 1)]
	var hacia := 1.0 if cima else signf(siguiente.x - p.x)
	if j.papel != null:
		b.t_hook += dt
		var o := _objetivo_arriba(j, b.idx_hook + 1)
		if not o.is_empty():
			_lanzar(b, o)
			return
		if not cima:
			j.sostenido = {"eje_x": hacia, "eje_largo": -1.0}
			if j.papel.aguante < 0.3:  # volver a lanzar al mismo saliente: papel nuevo
				o = _objetivo_arriba(j, b.idx_hook)
				if not o.is_empty():
					_lanzar(b, o)
			return
		# Columpio con el papel al mínimo, empujando a favor, y soltar yendo hacia la salida (siempre a la derecha)
		var an: Vector2 = j.papel.ancla
		var v := j.velocity
		j.sostenido = {"eje_x": signf(v.x) if absf(v.x) > 20.0 else 1.0, "eje_largo": -1.0}
		if (v.x > 220.0 and v.y < 60.0 and p.x > an.x and j.papel.largo < 60.0) or _plataforma_debajo(j) or j.papel.aguante < 0.15:
			j.guion = {"soltar": true}
			b.estado = "aire"
		return
	b.t_hook = 0.0
	# Ya en el último descanso, o en el suelo de un pozo tras entrar andando: fuera de la cima
	if cima and j.is_on_floor():
		b.idx_hook = -1
		return
	if not cima or (j.velocity.y > 150.0 and not _plataforma_debajo(j)):  # arriba, solo si va a caerse
		var o := _objetivo_arriba(j, b.prog - 2)
		if not o.is_empty():
			_lanzar(b, o)
			return
	b.estado = "suelo" if j.is_on_floor() else "aire"
	j.sostenido = {"eje_x": hacia if _suelo_delante(j, hacia) or not j.is_on_floor() else 0.0}


# Pozo: caer y, al ir demasiado rápido, engancharse al saliente más cercano por encima, soltar
# enseguida (ya sin la caída libre) y repetir. Cerca del fondo se frena antes. Abajo, salir andando.
func _pozo(b: Dictionary, j: Jugador, p: Vector2, r: Rect2, dt: float) -> void:
	var centro := r.position.x + r.size.x / 2.0
	if j.papel != null:
		b.t_hook += dt
		j.sostenido = {"eje_x": 0.0, "eje_largo": 0.0}
		if (b.t_hook > 0.25 and j.velocity.y < 250.0) or b.t_hook > 0.8 or j.papel.aguante < 0.15:
			j.guion = {"soltar": true}
		return
	b.t_hook = 0.0
	b.estado = "suelo" if j.is_on_floor() else "aire"
	if j.is_on_floor():
		j.sostenido = {"eje_x": 1.0 if p.y > r.end.y - 100.0 else signf(centro - p.x)}
		return
	var eje := 0.0
	for s: Dictionary in m.sierras:  # apartarse de una sierra que queda justo debajo
		var q: Vector2 = Geometry2D.get_closest_point_to_segment(p, s.pos, s.pos + s.riel)
		if q.y > p.y and q.y - p.y < 450.0 and absf(q.x - p.x) < 130.0:
			eje = signf(p.x - q.x) if absf(p.x - q.x) > 5.0 else signf(centro - p.x)
	j.sostenido = {"eje_x": eje}
	if j.velocity.y > (600.0 if p.y > r.end.y - 900.0 else 850.0):
		var o := _freno(j)
		if not o.is_empty():
			_lanzar(b, o)


func _freno(j: Jugador) -> Dictionary:
	var p := j.global_position
	var mejor := {}
	var mejor_d := INF
	for n in piezas_info:
		var pi: Dictionary = piezas_info[n]
		if not pi.nodo.is_in_group("enganchable") or pi.pos.distance_to(p) > ALCANCE + 150.0: continue
		for q: Vector2 in _puntos(pi):
			var h := _rayo(j, q)
			if h.is_empty() or (h.collider as Node).name != n: continue
			var hit: Vector2 = h.position
			if hit.y > p.y - 30.0 or _arco_cruza_sierra(hit, p): continue
			if hit.distance_to(p) < mejor_d:
				mejor_d = hit.distance_to(p)
				mejor = {"apunta": q, "hit": hit, "nombre": n}
	return mejor


func _lanzar(b: Dictionary, o: Dictionary) -> void:
	var j: Jugador = b.j
	j.guion = {"lanzar": true, "apunta": o.apunta}
	b.last_hook = o.nombre
	b.idx_hook = piezas_info[o.nombre].idx
	b.hooks += 1
	if str(o.nombre).begins_with("Atajo"): b.atajos += 1
	b.estado = "colgado"


func _informe() -> void:
	print("SEED ", semilla, " forma=", m.forma, " techos=", camino.size(), " sierras=", m.sierras.size())
	for b in bots:
		var res := "FIN" if b.fin else ("FALL" if b.falls.size() + b.sierras.size() > b.stuck.size() else "STUCK")
		print("BOT ", b.id, " ", res, " seed=", semilla, " forma=", m.forma, " t=", snappedf(b.t_fin, 0.01), " prog=", b.prog, "/", camino.size(),
			" hooks=", b.hooks, " atajos=", b.atajos, " falls=", b.falls.size(), " sierras=", b.sierras.size(), " breaks=", b.roturas.size(),
			" stuck=", b.stuck.size(), " rescues=", b.rescates)
		for f in b.falls: print("  FALL at ", f[0], ",", f[1], " last=", f[2], "(", f[3], ") near: ", f[4])
		for f in b.sierras: print("  SAW at ", f[0], ",", f[1], " last=", f[2], "(", f[3], ") near: ", f[4])
		for r in b.roturas: print("  BREAK at ", r[0], ",", r[1], " on ", r[2], "(", r[3], ")")
		for s in b.stuck: print("  STUCK at ", s[0], ",", s[1], " state=", s[2], " prog=", s[3], " near: ", s[4])

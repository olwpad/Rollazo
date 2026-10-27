extends Caso

const FORMAS := ["horizontal", "bajada", "hibrido", "montaña", "torre", "pozo"]


func test_velocidad_de_rebote() -> void:
	comprobar(Trampolin.velocidad_rebote(300.0) == -Trampolin.REBOTE_MIN, "caer despacio rebota con el mínimo")
	comprobar(is_equal_approx(Trampolin.velocidad_rebote(1200.0), -1260.0), "caer rápido rebota un 5 % más fuerte")
	comprobar(Trampolin.velocidad_rebote(5000.0) == -Trampolin.REBOTE_MAX, "con tope")
	comprobar(Trampolin.velocidad_rebote(-1200.0) < 0.0, "siempre hacia arriba")
	comprobar(Trampolin.aplastado(0.0) == 0.0 and Trampolin.aplastado(0.1) > 0.0 and Trampolin.aplastado(1.0) == 0.0, "se aplasta y vuelve a su sitio")


func test_trampolines_deterministas_y_en_sitio_libre() -> void:
	var total := 0
	for f in FORMAS:
		for s in 25:
			var m := Generador.generar(s, f)
			var a := Trampolin.nuevos(s, m, null)
			var b := Trampolin.nuevos(s, m, null)
			var fans := Ventilador.nuevos(s, m, null)
			comprobar(a.size() == b.size() and a.size() <= 2, "%s %d: entre 0 y 2 trampolines" % [f, s])
			if f in ["torre", "pozo"]:
				comprobar(a.is_empty(), "%s %d: ni torre ni pozo llevan trampolín" % [f, s])
			for i in a.size():
				var t: Trampolin = a[i]
				total += 1
				comprobar(t.position == b[i].position, "%s %d: trampolín determinista" % [f, s])
				comprobar(not Moviles.ocupado(m, t.zona()), "%s %d: trampolín sobre algo del mapa" % [f, s])
				comprobar(not t.zona().grow(399.0).has_point(m.inicio) and not t.zona().grow(399.0).has_point(m.meta), "%s %d: trampolín cerca de la salida o la meta" % [f, s])
				comprobar(t.position.y < m.caida_y - 150.0, "%s %d: trampolín dentro de la caída" % [f, s])
				for v: Ventilador in fans:
					comprobar(not v.zona().intersects(t.zona()), "%s %d: trampolín dentro de un ventilador" % [f, s])
				for j in i:
					comprobar(not a[j].zona().intersects(t.zona()), "%s %d: dos trampolines se pisan" % [f, s])
			for n in a + b + fans:
				n.free()
	comprobar(total > 10, "salen trampolines: %d" % total)


# En el nivel de verdad: el moco que entra cayendo sale disparado; el que sube, no.
func test_trampolin_rebota_al_que_cae() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	red.crear_partida(7794)
	var mapas_antes: Array = red.config.mapas
	red.config.mapas = ["azotea"]
	var nivel: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	Engine.get_main_loop().root.add_child(nivel)
	var t: Trampolin = null
	for hijo in nivel.get_node("Piezas").get_children():
		if hijo is Trampolin:
			t = hijo
	var j: Jugador = nivel.get_node_or_null("Jugadores/1")
	comprobar(t != null and j != null, "el nivel trae un trampolín y un moco")
	if t != null and j != null:
		j.congelado = false  # la postal de la ronda los tiene quietos
		j.velocity = Vector2(0, -200)
		nivel._al_tocar_trampolin(j, t)
		comprobar(j.velocity.y == -200.0, "subiendo no rebota")
		j.velocity = Vector2(0, 900)
		nivel._al_tocar_trampolin(j, t)
		comprobar(j.velocity.y == Trampolin.velocidad_rebote(900.0), "cayendo rebota")
	Engine.get_main_loop().root.remove_child(nivel)
	nivel.free()
	red.config.mapas = mapas_antes  # la config es global: que no les cambie el mapa a otros tests

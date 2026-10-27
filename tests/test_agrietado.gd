extends Caso

const FORMAS := ["horizontal", "bajada", "hibrido", "montaña", "torre", "pozo"]


func test_indices_deterministas_y_con_reglas() -> void:
	var techos := 0
	var rotos := 0
	for f in FORMAS:
		for s in 40:
			var m := Generador.generar(s, f)
			var idx := Agrietado.indices(s, m)
			comprobar(idx == Agrietado.indices(s, m), "%s %d: agrietados deterministas" % [f, s])
			for i in idx:
				comprobar(not (i + 1) in idx, "%s %d: dos agrietados seguidos (%d)" % [f, s, i])
				comprobar(i < m.camino.size() - 1, "%s %d: el último techo no se agrieta" % [f, s])
				for t: Dictionary in m.tramos:
					if i >= t.i0 and i < t.i1:
						comprobar(t.tipo in ["horizontal", "bajada"] and i > t.i0 and i < t.i1 - 1, "%s %d: agrietado %d en sitio vetado" % [f, s, i])
				var a: Vector2 = m.camino[i - 1]
				var b: Vector2 = m.camino[i]
				comprobar(not m.piezas.any(func(p: Dictionary) -> bool: return p.nombre.begins_with("Descanso") and p.pos.x > a.x and p.pos.x < b.x), "%s %d: el primero tras un descanso no se agrieta" % [f, s])
			if f == "horizontal":
				techos += m.camino.size()
				rotos += idx.size()
			var sin := Agrietado.indices(s, m, idx)  # los excluidos (techos que se apagan) no salen
			comprobar(sin.all(func(i: int) -> bool: return not i in idx), "%s %d: respeta los techos excluidos" % [f, s])
	var parte := float(rotos) / techos
	comprobar(parte > 0.1 and parte < 0.22, "entre el 10 y el 22 %% de los techos: %.1f %%" % (parte * 100.0))


# En el nivel de verdad: tiembla al colgarse, cae soltando el papel y vuelve.
func test_techo_agrietado_tiembla_cae_y_vuelve() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	red.crear_partida(7794)
	var mapas_antes: Array = red.config.mapas
	red.config.mapas = ["azotea"]
	var nivel: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	Engine.get_main_loop().root.add_child(nivel)
	var ag: Agrietado = null
	for hijo in nivel.get_node("Piezas").get_children():
		if hijo is Agrietado:
			ag = hijo
	var j: Jugador = nivel.get_node_or_null("Jugadores/1")
	comprobar(ag != null and j != null, "el nivel trae un techo agrietado y un moco")
	if ag != null and j != null:
		var cuerpo := ag.cuerpos[0]
		comprobar(cuerpo.is_in_group("enganchable") and cuerpo.get_node("Dibujo").get_child_count() > 3, "es enganchable y tiene grietas dibujadas")
		j.papel = PapelRope.new(ag._cajas[0].get_center(), 100.0, 3.0)
		ag._physics_process(0.016)
		comprobar(ag.estado == Agrietado.Estado.TIEMBLA, "tiembla al colgarse alguien")
		ag._physics_process(Agrietado.T_TIEMBLA - 0.1)
		comprobar(ag.estado == Agrietado.Estado.TIEMBLA and j.papel != null, "aún aguanta antes de 1,5 s")
		ag._physics_process(0.2)
		comprobar(ag.estado == Agrietado.Estado.CAIDO and j.papel == null and not j.papel_activo, "cae y suelta el papel")
		comprobar(not cuerpo.is_in_group("enganchable"), "caído no se puede enganchar")
		ag._physics_process(Agrietado.T_AUSENTE + 0.1)
		comprobar(ag.estado == Agrietado.Estado.QUIETO and cuerpo.is_in_group("enganchable"), "vuelve a funcionar")
	Engine.get_main_loop().root.remove_child(nivel)
	nivel.free()
	red.config.mapas = mapas_antes  # la config es global: que no les cambie el mapa a otros tests

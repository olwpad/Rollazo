extends Caso


func _jugador(nombre: String, pos: Vector2, padre: Node) -> Jugador:
	var j: Jugador = load("res://scenes/jugador.tscn").instantiate()
	j.name = nombre
	j.position = pos
	padre.add_child(j)
	return j


func _escenario() -> Node2D:
	var n := Node2D.new()
	Engine.get_main_loop().root.add_child(n)
	return n


func test_cinco_poderes_con_su_tiempo() -> void:
	comprobar(Poderes.TIPOS.size() == 5, "congelar, rapidez, pared, salto, puñetazo")
	for t in Poderes.TIPOS:
		comprobar(Poderes.DURACION.get(t, 0.0) > 0.0 and Poderes.NOMBRE.has(t) and Poderes.COLOR.has(t), "datos de " + t)


func test_el_mapa_trae_burbujas() -> void:
	for semilla in [1, 2, 3]:
		var m := Generador.generar(semilla)
		comprobar(m.burbujas.size() >= 3, "burbujas en la semilla %d" % semilla)
		comprobar(m.burbujas.all(func(b: Dictionary) -> bool: return b.tipo in Poderes.TIPOS), "tipos válidos")
	comprobar(Generador.generar(5).burbujas == Generador.generar(5).burbujas, "misma semilla, mismas burbujas en todos los PCs")


func test_el_poder_se_gasta() -> void:
	var n := _escenario()
	var j := _jugador("1", Vector2.ZERO, n)
	j.dar_poder("rapidez")
	comprobar(j.poder == "rapidez" and j.factor_velocidad() > 1.4, "más rápido")
	j.gastar_poder(Poderes.DURACION.rapidez + 0.1)
	comprobar(j.poder == "" and is_equal_approx(j.factor_velocidad(), 1.0), "se acaba solo")
	j.dar_poder("salto")
	comprobar(j.fuerza_de_salto() > j.fuerza_salto * 1.4, "salto alto")
	n.free()


func test_congelar_para_a_los_demas() -> void:
	var n := _escenario()
	var yo := _jugador("1", Vector2.ZERO, n)
	var otro := _jugador("2", Vector2(500, 0), n)
	yo.dar_poder("congelar")
	comprobar(otro.poder == "congelado" and yo.poder == "congelar", "el rival queda congelado")
	n.free()


func test_punetazo_lanza_al_que_esta_cerca() -> void:
	var n := _escenario()
	var yo := _jugador("1", Vector2.ZERO, n)
	var otro := _jugador("2", Vector2(40, 0), n)
	var lejos := _jugador("3", Vector2(400, 0), n)
	yo.dar_poder("punetazo")
	yo.golpear_cercanos()
	comprobar(otro.velocity.length() > 500.0 and otro.velocity.x > 0.0, "sale volando hacia fuera")
	comprobar(lejos.velocity.length() < 1.0, "al de lejos no le llega")
	var v := otro.velocity
	yo.golpear_cercanos()
	comprobar(otro.velocity == v, "no le pega cada frame")
	n.free()


func test_poderes_se_pueden_quitar() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	red.crear_partida(7793)
	comprobar(red.config.poderes, "por defecto hay poderes")
	red.poner_poderes(false)
	comprobar(not red.config.poderes, "el anfitrión los quita")
	red.salir()


func test_hud_del_poder() -> void:
	var hud: Node = load("res://scenes/hud.tscn").instantiate()
	Engine.get_main_loop().root.add_child(hud)
	hud.poder("rapidez", 3.2, 5.0)
	comprobar(hud.get_node("Poder").visible and hud.get_node("Poder/Texto").text == "RAPIDEZ · 4 S", "nombre y segundos")
	hud.poder("", 0.0, 1.0)
	comprobar(not hud.get_node("Poder").visible, "sin poder no se ve")
	hud.free()

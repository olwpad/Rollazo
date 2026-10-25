extends Caso


func test_puestos_en_orden() -> void:
	var c := Clasificacion.new()
	comprobar(c.registrar_llegada(5) == 1 and c.registrar_llegada(2) == 2, "orden de llegada")
	comprobar(c.registrar_llegada(5) == 1, "no se duplica")


func test_solo_el_primero_gana_la_ronda() -> void:
	var c := Clasificacion.new()
	var ids: Array[int] = [1, 2]
	c.registrar_llegada(1, 30.0)
	c.registrar_llegada(2, 35.0)
	c.cerrar_ronda(ids, 50.0)
	comprobar(c.victorias.get(1, 0) == 1 and c.victorias.get(2, 0) == 0, "una victoria para el 1.º")
	comprobar(is_equal_approx(c.tiempo_total[1], 30.0) and is_equal_approx(c.tiempo_total[2], 35.0), "suma tiempos de llegada")
	comprobar(c.llegadas.is_empty(), "la ronda siguiente empieza sin llegadas")


func test_quien_no_llega_suma_el_final_de_ronda() -> void:
	var c := Clasificacion.new()
	var ids: Array[int] = [1, 2]
	c.registrar_llegada(1, 30.0)
	c.cerrar_ronda(ids, 50.0)
	comprobar(is_equal_approx(c.tiempo_total[2], 50.0), "no llegar no sale gratis")


func test_orden_por_victorias_y_luego_tiempo() -> void:
	var c := Clasificacion.new()
	var ids: Array[int] = [1, 2, 3]
	c.registrar_llegada(2, 40.0); c.registrar_llegada(1, 41.0); c.cerrar_ronda(ids, 60.0)
	c.registrar_llegada(1, 20.0); c.registrar_llegada(2, 30.0); c.cerrar_ronda(ids, 60.0)
	c.registrar_llegada(3, 10.0); c.cerrar_ronda(ids, 60.0)
	# victorias 1/1/1; tiempos: 1 = 41+20+60 = 121, 2 = 40+30+60 = 130, 3 = 60+60+10 = 130
	comprobar(c.orden(ids)[0] == 1, "con empate a victorias gana el de menos tiempo")
	comprobar(c.gana_por_tiempo(ids), "avisa de que fue por tiempo")


func test_gana_por_victorias_sin_desempate() -> void:
	var c := Clasificacion.new()
	var ids: Array[int] = [1, 2]
	c.registrar_llegada(2, 90.0); c.cerrar_ronda(ids, 90.0)
	comprobar(c.orden(ids)[0] == 2, "más victorias va primero")
	comprobar(not c.gana_por_tiempo(ids), "no hubo desempate")


func test_todos_llegaron_ignora_desconectados() -> void:
	var c := Clasificacion.new()
	c.registrar_llegada(1)
	var solo_uno: Array[int] = [1]
	var con_otro: Array[int] = [1, 3]
	comprobar(c.todos_llegaron(solo_uno) and not c.todos_llegaron(con_otro), "solo cuenta los que siguen")

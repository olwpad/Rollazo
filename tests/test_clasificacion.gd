extends Caso


func test_puestos_en_orden() -> void:
	var c := Clasificacion.new()
	comprobar(c.registrar_llegada(5) == 1 and c.registrar_llegada(2) == 2, "orden de llegada")
	comprobar(c.registrar_llegada(5) == 1, "no se duplica")


func test_puntos_y_rondas() -> void:
	var c := Clasificacion.new()
	c.registrar_llegada(1)
	c.registrar_llegada(2)
	c.nueva_ronda()
	c.registrar_llegada(2)
	comprobar(c.puntos_totales[2] == 16 and c.puntos_totales[1] == 10, "10+6 y 10")


func test_todos_llegaron_ignora_desconectados() -> void:
	var c := Clasificacion.new()
	c.registrar_llegada(1)
	var solo_uno: Array[int] = [1]
	var con_otro: Array[int] = [1, 3]
	comprobar(c.todos_llegaron(solo_uno) and not c.todos_llegaron(con_otro), "solo cuenta los que siguen")


func test_quinto_no_puntua() -> void:
	var c := Clasificacion.new()
	for id in [1, 2, 3, 4, 5]:
		c.registrar_llegada(id)
	comprobar(c.puntos_de(5) == 0 and c.puntos_de(4) == 1, "fuera del podio de 4 no suma")

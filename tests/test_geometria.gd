extends Caso


func test_distancia_perpendicular() -> void:
	var d := Geometria.distancia_a_segmento(Vector2(0, 10), Vector2(-5, 0), Vector2(5, 0))
	comprobar(is_equal_approx(d, 10.0), "perpendicular al segmento: %f" % d)


func test_fuera_del_segmento_usa_el_extremo() -> void:
	var d := Geometria.distancia_a_segmento(Vector2(20, 0), Vector2(-5, 0), Vector2(5, 0))
	comprobar(is_equal_approx(d, 15.0), "al extremo más cercano: %f" % d)


func test_segmento_degenerado() -> void:
	var d := Geometria.distancia_a_segmento(Vector2(3, 4), Vector2.ZERO, Vector2.ZERO)
	comprobar(is_equal_approx(d, 5.0), "a == b es la distancia al punto: %f" % d)

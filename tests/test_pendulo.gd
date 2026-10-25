extends Caso


func test_fuera_del_radio_se_recoloca() -> void:
	var r := Pendulo.restringir(Vector2(0, 300), Vector2(0, 100), Vector2.ZERO, 200.0)
	comprobar(r[0].is_equal_approx(Vector2(0, 200)), "posición sobre el círculo")
	comprobar(r[1].is_equal_approx(Vector2.ZERO), "sin velocidad hacia fuera")
	comprobar(is_equal_approx(r[2], 100.0), "devuelve la velocidad radial quitada")


func test_conserva_velocidad_tangencial() -> void:
	var r := Pendulo.restringir(Vector2(0, 250), Vector2(150, 80), Vector2.ZERO, 200.0)
	comprobar(is_equal_approx(r[1].x, 150.0), "tangencial intacta")
	comprobar(is_equal_approx(r[1].y, 0.0), "radial quitada")


func test_dentro_del_radio_no_cambia() -> void:
	var r := Pendulo.restringir(Vector2(0, 100), Vector2(5, 5), Vector2.ZERO, 200.0)
	comprobar(r[0] == Vector2(0, 100) and r[1] == Vector2(5, 5) and r[2] == 0.0, "la cuerda no empuja")


func test_tension_limitada() -> void:
	comprobar(Pendulo.tension(0.0) == 0.0, "sin tirón")
	comprobar(is_equal_approx(Pendulo.tension(300.0), 0.5), "proporcional")
	comprobar(Pendulo.tension(99999.0) == 2.0, "máximo 2")

extends Caso


func test_choque_frontal_intercambia_y_amplifica() -> void:
	var r := Rebote.calcular(Vector2(400, 0), Vector2(-100, 0), Vector2(1, 0))
	comprobar(r[0].x < 0 and r[1].x > 0, "salen en direcciones opuestas")
	comprobar(is_equal_approx(r[1].x, 480.0), "el golpeado sale a 400*1.2")


func test_conserva_tangencial() -> void:
	var r := Rebote.calcular(Vector2(400, 50), Vector2(0, 0), Vector2(1, 0))
	comprobar(is_equal_approx(r[0].y, 50.0), "tangencial intacta")


func test_acciones_cortar_y_agarrar() -> void:
	comprobar(InputMap.has_action("cortar") and InputMap.has_action("agarrar"), "acciones cortar y agarrar")

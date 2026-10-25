extends Caso


func test_se_rompe_tras_aguante_sin_tension() -> void:
	var p := PapelRope.new(Vector2.ZERO, 200.0, 3.0)
	for i in 29:
		p.gastar(0.1, 0.0)
	comprobar(not p.roto, "aguanta 2.9 s")
	p.gastar(0.2, 0.0)
	comprobar(p.roto, "se rompe pasados 3 s")


func test_tension_rompe_antes() -> void:
	var p := PapelRope.new(Vector2.ZERO, 200.0, 3.0)
	for i in 16:  # 1.5 s exactos quedarían justo en el límite por redondeo
		p.gastar(0.1, 1.0)
	comprobar(p.roto, "con tensión 1 se rompe en ~1.5 s")


func test_largo_limitado() -> void:
	var p := PapelRope.new(Vector2.ZERO, 200.0)
	p.cambiar_largo(-1000.0)
	comprobar(p.largo == PapelRope.LARGO_MIN, "no baja de LARGO_MIN")
	p.cambiar_largo(5000.0)
	comprobar(p.largo == PapelRope.LARGO_MAX, "no pasa de LARGO_MAX")

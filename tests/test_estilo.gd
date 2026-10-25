extends Caso


func test_forma_del_moco_tiene_n_puntos() -> void:
	comprobar(MocoVisual.forma(24, 0.0, Vector2.ZERO).size() == 24, "24 puntos")


func test_moco_se_estira_en_la_direccion_del_movimiento() -> void:
	var p := MocoVisual.forma(32, 0.0, Vector2(1500, 0))
	var ancho := 0.0
	var alto := 0.0
	for v in p:
		ancho = maxf(ancho, absf(v.x))
		alto = maxf(alto, absf(v.y))
	comprobar(ancho > alto * 1.2, "más ancho que alto al ir rápido en horizontal (%.0f x %.0f)" % [ancho, alto])


func test_moco_quieto_es_casi_redondo() -> void:
	var p := MocoVisual.forma(32, 0.0, Vector2.ZERO)
	var ancho := 0.0
	var alto := 0.0
	for v in p:
		ancho = maxf(ancho, absf(v.x))
		alto = maxf(alto, absf(v.y))
	comprobar(absf(ancho - alto) < 6.0, "casi redondo en reposo")


func test_pelo_y_ropa_se_estiran_igual_que_el_cuerpo() -> void:
	var vel := Vector2(700, -250)
	var estirado := MocoVisual.forma(16, 0.3, vel)
	var quieto := MocoVisual.estiron(vel) * MocoVisual.forma(16, 0.3, Vector2.ZERO)
	for i in 16:
		comprobar(estirado[i].distance_to(quieto[i]) < 0.01, "punto %d igual" % i)


func test_escenas_con_estilo() -> void:
	var j: Node = load("res://scenes/jugador.tscn").instantiate()
	comprobar(j.get_node_or_null("Visual/Moco") is MocoVisual, "jugador con Visual/Moco")
	comprobar(j.get_node_or_null("Efectos/Salpicadura") is CPUParticles2D, "jugador con Efectos/Salpicadura")
	j.free()
	var r: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	comprobar(r.get_node_or_null("Ciudad") != null, "recorrido con fondo Ciudad")
	comprobar(r.get_node_or_null("Fondo") == null, "sin la pared de azulejos")
	r.free()


func test_sin_onomatopeyas() -> void:
	comprobar(not ResourceLoader.exists("res://scripts/onomatopeya.gd"), "onomatopeya.gd eliminado")


func test_acuarela_tres_capas_distintas() -> void:
	var cuadrado := PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(100, 50), Vector2(0, 50)])
	var capas := Acuarela.capas(cuadrado, 4)
	comprobar(capas.size() == 3, "3 capas")
	comprobar(capas[0] != capas[1] and capas[1] != capas[2], "cada capa con borde distinto")

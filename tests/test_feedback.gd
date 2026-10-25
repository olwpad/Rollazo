extends Caso


func test_pintar_colorea_moco_y_efectos() -> void:
	var j: Node = load("res://scenes/jugador.tscn").instantiate()
	var rosa: Color = Jugador.COLORES[1]
	j.pintar(rosa)
	comprobar(j.get_node("Visual/Moco").color == rosa, "moco rosa")
	comprobar(j.get_node("Efectos/Salpicadura").color == rosa and j.get_node("Efectos/Goteo").color == rosa, "gotas rosas")
	var estela: Color = j.get_node("Efectos/Estela").default_color
	comprobar(is_equal_approx(estela.r, rosa.r) and estela.a < 1.0, "estela rosa translúcida")
	j.free()


func _hud() -> Node:
	var hud: Node = load("res://scenes/hud.tscn").instantiate()
	Engine.get_main_loop().root.add_child(hud)
	return hud


func test_cuenta_atras_visible() -> void:
	var hud := _hud()
	hud.cuenta_atras(12.3)
	comprobar(hud.get_node("Cuenta").visible and hud.get_node("Cuenta").text == "13", "cuenta 13 s")
	hud.cuenta_atras(-1.0)
	comprobar(not hud.get_node("Cuenta").visible, "sin cuenta, oculta")
	hud.free()


func test_marcador_con_victorias_y_tiempo() -> void:
	var hud := _hud()
	hud.marcador([[Color.RED, "TÚ", 2, 102.0], [Color.BLUE, "JUGADOR 2", 0, 150.0]])
	var tabla: VBoxContainer = hud.get_node("Tabla")
	comprobar(tabla.get_child_count() == 2, "una fila por moco")
	var texto: String = tabla.get_child(0).get_child(1).text
	comprobar("TÚ" in texto and "2 VICTORIAS" in texto and "1:42" in texto, "nombre, victorias y tiempo (%s)" % texto)
	hud.free()


func test_postal_de_ronda() -> void:
	var hud := _hud()
	hud.postal("RONDA 2 DE 5 · LA AZOTEA", 123, [[Color.RED, 1]])
	comprobar(hud.get_node("Postal").visible and hud.get_node("Postal").titulo.begins_with("RONDA 2"), "sale la postal")
	hud.ocultar_postal()
	comprobar(not hud.get_node("Postal").visible, "y se va")
	hud.free()


func test_sin_mejor_en_online() -> void:
	var hud := _hud()
	hud.mostrar(5.0, INF, false)
	comprobar(not "MEJOR" in hud.get_node("Tiempo").text.to_upper(), "online no enseña el mejor")
	hud.free()


func test_ayuda_de_controles() -> void:
	var hud := _hud()
	var ayuda: Label = hud.get_node_or_null("Ayuda")
	comprobar(ayuda != null and "CLIC" in ayuda.text and "E" in ayuda.text, "controles explicados en pantalla")
	hud.free()


func test_mira_se_puede_quitar_y_se_recuerda() -> void:
	comprobar(InputMap.has_action("mira"), "tecla para la mira (T)")
	var Mira: GDScript = load("res://scripts/mira.gd")
	var antes: bool = Mira.activa()
	Mira.alternar()
	comprobar(Mira.activa() != antes, "T la quita o la pone")
	var cfg := ConfigFile.new()
	cfg.load(Mira.AJUSTES)
	comprobar(cfg.get_value("juego", "mira", true) == Mira.activa(), "se guarda para la próxima vez")
	Mira.alternar()  # dejarla como estaba

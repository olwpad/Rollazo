extends Caso


func _musica() -> Node:
	return Engine.get_main_loop().root.get_node_or_null("Musica")


func test_tocar_pone_la_cancion_en_bucle() -> void:
	var m := _musica()
	comprobar(m != null, "autoload Musica")
	if m == null:
		return
	m.tocar("carrera")
	comprobar(m.reproductor.stream != null and m.reproductor.stream.loop, "suena en bucle")
	var antes = m.reproductor.stream
	m.tocar("carrera")
	comprobar(m.reproductor.stream == antes, "pedir la misma no la reinicia")


func test_silenciar_alterna_y_se_guarda() -> void:
	var m := _musica()
	m.poner_volumen(100)  # punto de partida conocido: sonando al 100
	var avisos := []
	var anotar := func(callada: bool) -> void: avisos.append(callada)
	m.cambio_silencio.connect(anotar)
	m.alternar_silencio()
	comprobar(m.silenciada and avisos.has(true), "silencia y avisa al icono")
	comprobar(m.reproductor.volume_db <= -80.0, "silenciada no se oye")
	var cfg := ConfigFile.new()
	cfg.load(m.ruta)
	comprobar(cfg.get_value("sonido", "silenciada") == true, "guardado")
	m.alternar_silencio()
	comprobar(not m.silenciada and m.volumen == 100 and m.reproductor.volume_db == -8.0, "al quitarlo vuelve al volumen de antes (-8 dB de base)")
	m.cambio_silencio.disconnect(anotar)
	comprobar(m.ruta != "user://ajustes.cfg", "los tests no tocan los ajustes de verdad")


func test_volumen_se_guarda_y_se_limita() -> void:
	var m := _musica()
	m.poner_volumen(40)
	var cfg := ConfigFile.new()
	cfg.load(m.ruta)
	comprobar(cfg.get_value("sonido", "volumen") == 40, "guardado")
	comprobar(absf(m.reproductor.volume_db - (-8.0 + linear_to_db(0.4))) < 0.01, "40 %% = %.1f dB" % m.reproductor.volume_db)
	m.poner_volumen(250)
	comprobar(m.volumen == 100, "no pasa de 100")
	m.poner_volumen(-5)
	comprobar(m.volumen == 0 and m.callada() and not m.silenciada, "a 0 cuenta como callada (no pasa de 0)")
	m.poner_volumen(30, false)
	comprobar(not m.callada(), "subirlo desde 0 la quita")
	m.alternar_silencio()
	m.poner_volumen(60)
	comprobar(not m.silenciada, "mover el volumen también quita el silencio")
	m.poner_volumen(0)
	m.alternar_silencio()
	comprobar(not m.callada() and m.volumen > 0, "quitar el silencio con volumen 0 lo sube: si no, no se oiría")
	m.poner_volumen(100)


func test_icono_y_tecla_m_van_juntos() -> void:
	var m := _musica()
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	Engine.get_main_loop().root.add_child(menu)
	var nota: Button = menu.get_node("Nota")
	m.poner_volumen(100)
	var antes: bool = m.silenciada
	nota.pressed.emit()
	comprobar(m.silenciada != antes and (nota.accessibility_name == "Música apagada") == m.silenciada, "el icono silencia y su nombre accesible lo dice")
	var tecla := InputEventAction.new()
	tecla.action = "silenciar"
	tecla.pressed = true
	m._unhandled_input(tecla)
	comprobar(m.silenciada == antes and (nota.accessibility_name == "Música apagada") == antes, "la M lo devuelve y el icono se entera")
	m.poner_volumen(0)
	comprobar(m.callada() and nota.accessibility_name == "Música apagada", "volumen a 0: la nota sale tachada")
	m.poner_volumen(70)
	comprobar(not m.callada() and nota.accessibility_name == "Música" and nota.get_node("Volumen").accessibility_name.ends_with("70%"), "subirlo la destacha y el deslizador lo dice")
	var desliz: Control = nota.get_node("Volumen")
	var clic := InputEventMouseButton.new()
	clic.button_index = MOUSE_BUTTON_LEFT
	clic.pressed = true
	clic.position = Vector2(desliz.size.x / 2.0, 0)
	desliz._gui_input(clic)
	clic.pressed = false
	desliz._gui_input(clic)
	comprobar(m.volumen == 50, "clic en medio del deslizador = 50 (%d)" % m.volumen)
	m.poner_volumen(100)
	comprobar(nota.tooltip_text == "" and nota.get_node("Volumen").tooltip_text == "", "sin textos emergentes al pasar el ratón")
	comprobar(nota.focus_mode == Control.FOCUS_NONE and nota.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND, "se ve clicable y no roba el foco")
	menu.free()


func test_tecla_silenciar() -> void:
	comprobar(InputMap.has_action("silenciar"), "acción silenciar (M)")


func test_bus_maestro_se_oye_y_sin_efectos() -> void:
	comprobar(AudioServer.get_bus_volume_db(0) > -6.0, "volumen maestro audible (%.1f dB)" % AudioServer.get_bus_volume_db(0))
	comprobar(AudioServer.get_bus_effect_count(0) == 0, "sin efectos raros (distorsión) en el maestro")

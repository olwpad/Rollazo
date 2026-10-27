extends Caso
const Mira := preload("res://scripts/mira.gd")


func _menu() -> Node:
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	Engine.get_main_loop().root.add_child(menu)
	return menu


func _esc(menu: Node) -> void:
	var tecla := InputEventAction.new()
	tecla.action = "volver_menu"
	tecla.pressed = true
	menu._unhandled_input(tecla)


func _cfg() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(Ajustes.ruta)
	return cfg


func test_menu_con_cuatro_opciones() -> void:
	var menu := _menu()
	var nombres: Array = menu.get_node("Caja").get_children().filter(func(n: Node) -> bool: return n is Button).map(func(n: Node) -> String: return n.name)
	comprobar(nombres == ["Solo", "Multijugador", "TuMoco", "Opciones"], "practicar, multijugador, tu moco, opciones: %s" % str(nombres))
	comprobar(not menu.get_node("Caja").has_node("Crear") and not menu.get_node("Caja").has_node("Fila"), "ni crear ni el código en el inicio")
	comprobar(Ajustes.ruta != "user://ajustes.cfg", "los tests no tocan los ajustes de verdad")
	menu.free()


func test_panel_multijugador_se_abre_y_esc_lo_cierra() -> void:
	var menu := _menu()
	var multi: Control = menu.get_node("Multi")
	comprobar(not multi.visible, "empieza cerrado")
	menu.get_node("Caja/Multijugador").pressed.emit()
	comprobar(multi.visible and not menu.get_node("Caja").visible, "se abre y esconde la lista")
	comprobar(multi.get_node("Papel/Caja/Crear").text == "CREAR SALA" and multi.get_node("Papel/Caja/Fila/Codigo") != null \
			and multi.get_node("Papel/Caja/Fila/Unirse") != null, "crear, código y unirse")
	Red.jugadores_cambiaron.emit()
	comprobar(multi.visible and not menu.get_node("Caja").visible, "un aviso de la red no repinta el menú encima")
	_esc(menu)
	comprobar(not multi.visible and menu.get_node("Caja").visible and menu.get_node("Sala").visible, "Esc vuelve al menú")
	menu.free()


func test_error_de_conexion_sale_en_el_panel() -> void:
	var menu := _menu()
	menu.get_node("Caja/Multijugador").pressed.emit()
	Red.desconectado.emit("ESA SALA NO EXISTE")
	comprobar(menu.get_node("Multi/Papel/Caja/Estado").text == "ESA SALA NO EXISTE", "el error se ve en el panel")
	menu.free()


func test_opciones_se_guardan_y_se_aplican() -> void:
	var menu := _menu()
	var op := menu.get_node("Opciones")
	menu.get_node("Caja/Opciones").pressed.emit()
	comprobar(op.visible and not menu.get_node("Caja").visible, "Opciones se abre")
	var antes_completa := Ajustes.pantalla_completa
	var antes_ayuda := Ajustes.ayuda
	var antes_mira: bool = Mira.activa()
	op.get_node("Papel/Caja/Pantalla/Valor").pressed.emit()
	comprobar(Ajustes.pantalla_completa != antes_completa and _cfg().get_value("pantalla", "completa") == Ajustes.pantalla_completa, "pantalla completa se guarda")
	comprobar(op.get_node("Papel/Caja/Pantalla/Valor").text == ("SÍ" if Ajustes.pantalla_completa else "NO"), "y la pegatina lo dice")
	op.get_node("Papel/Caja/Pantalla/Valor").pressed.emit()
	op.get_node("Papel/Caja/Mira/Valor").pressed.emit()
	comprobar(Mira.activa() != antes_mira and _cfg().get_value("juego", "mira") == Mira.activa(), "la mira es la misma de la tecla T")
	op.get_node("Papel/Caja/Mira/Valor").pressed.emit()
	op.get_node("Papel/Caja/Ayuda/Valor").pressed.emit()
	comprobar(Ajustes.ayuda != antes_ayuda and _cfg().get_value("juego", "ayuda") == Ajustes.ayuda, "la ayuda se guarda")
	var hud: Node = load("res://scenes/hud.tscn").instantiate()
	Engine.get_main_loop().root.add_child(hud)
	comprobar(hud.get_node("Ayuda").visible == Ajustes.ayuda, "la carrera respeta la ayuda")
	hud.free()
	op.get_node("Papel/Caja/Ayuda/Valor").pressed.emit()
	_esc(menu)
	comprobar(not op.visible and menu.get_node("Caja").visible, "Esc cierra Opciones")
	menu.free()


func test_volumen_de_efectos_y_musica_compartido() -> void:
	var menu := _menu()
	var nota: Control = menu.get_node("Nota/Volumen")
	var musica: Control = menu.get_node("Opciones/Papel/Caja/Musica/Valor")
	var efectos: Control = menu.get_node("Opciones/Papel/Caja/Efectos/Valor")
	Musica.poner_volumen(35)
	comprobar(nota._volumen() == 35 and musica._volumen() == 35, "la nota y Opciones leen el mismo volumen de música")
	var clic := InputEventMouseButton.new()
	clic.button_index = MOUSE_BUTTON_LEFT
	clic.pressed = true
	clic.position = Vector2(musica.size.x * 0.8, 0)
	musica._gui_input(clic)
	clic.pressed = false
	musica._gui_input(clic)
	comprobar(nota._volumen() == Musica.volumen and Musica.volumen > 60 and _cfg().get_value("sonido", "volumen") == Musica.volumen, "moverlo en Opciones mueve la nota y se guarda")
	Musica.poner_volumen(100)
	Ajustes.poner_efectos(100)
	Sonidos.tocar("boton")
	comprobar(absf(Sonidos._planos[(Sonidos._siguiente + Sonidos.POOL - 1) % Sonidos.POOL].volume_db - Sonidos.BASE_DB) < 0.01, "efectos al 100 %: volumen base")
	Ajustes.poner_efectos(50)
	Sonidos.tocar("boton")
	var p: AudioStreamPlayer = Sonidos._planos[(Sonidos._siguiente + Sonidos.POOL - 1) % Sonidos.POOL]
	comprobar(absf(p.volume_db - (Sonidos.BASE_DB + linear_to_db(0.5))) < 0.01, "efectos al 50 %: más bajos")
	comprobar(_cfg().get_value("sonido", "efectos") == 50, "el volumen de efectos se guarda")
	Musica.poner_volumen(4)
	Sonidos.tocar("boton")
	p = Sonidos._planos[(Sonidos._siguiente + Sonidos.POOL - 1) % Sonidos.POOL]
	comprobar(absf(p.volume_db - (Sonidos.BASE_DB + linear_to_db(0.5))) < 0.01, "la música baja no arrastra a los efectos")
	clic.pressed = true
	clic.position = Vector2(efectos.size.x * 0.25, 0)
	efectos._gui_input(clic)
	clic.pressed = false
	efectos._gui_input(clic)
	comprobar(Ajustes.efectos > 15 and Ajustes.efectos < 35 and Musica.volumen == 4, "el deslizador de efectos solo toca los efectos")
	Ajustes.poner_efectos(100)
	Musica.poner_volumen(100)
	menu.free()

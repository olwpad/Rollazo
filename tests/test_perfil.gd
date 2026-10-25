extends Caso

# Las pruebas no tocan el perfil de verdad del jugador: cambian la ruta y lo dejan todo como estaba.
var _antes := []


func _perfil() -> Node:
	var p: Node = Engine.get_main_loop().root.get_node("Perfil")
	_antes = [p.ruta, p.aspecto.duplicate(), p.partidas, p.torneos, p.partidas_para]
	p.partidas_para = {"lana": 3, "skrillex": 5}  # candados de prueba
	p.ruta = "user://perfil_prueba.cfg"
	p.aspecto = p.POR_DEFECTO.duplicate()
	p.partidas = 0
	p.torneos = 0
	return p


func _devolver(p: Node) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p.ruta))
	p.ruta = _antes[0]
	p.aspecto = _antes[1]
	p.partidas = _antes[2]
	p.torneos = _antes[3]
	p.partidas_para = _antes[4]


func test_todo_libre_menos_lo_que_lleva_candado() -> void:
	var p: Node = Engine.get_main_loop().root.get_node("Perfil")
	for cosa in p.PELOS + p.SOMBREROS:
		comprobar(p.desbloqueado(cosa), cosa + " libre para todos")
	p = _perfil()
	comprobar(not p.desbloqueado("lana"), "lo que lleva candado empieza cerrado")
	comprobar(p.requisito("lana") == "SE GANA CON 3 PARTIDAS", "dice cuánto falta: " + p.requisito("lana"))
	comprobar(p.requisito("gorra") == "", "lo libre no pide nada")
	_devolver(p)


func test_jugar_partidas_desbloquea() -> void:
	var p := _perfil()
	p.anotar_torneo(false)
	p.anotar_torneo(true)
	comprobar(p.anotar_torneo(false) == ["lana"], "a la tercera partida, el gorro de lana (ganes o pierdas)")
	comprobar(p.partidas == 3 and p.torneos == 1, "cuenta partidas y torneos ganados")
	_devolver(p)


func test_solo_se_pone_lo_desbloqueado_y_se_guarda() -> void:
	var p := _perfil()
	comprobar(not p.poner("sombrero", "lana") and p.aspecto.sombrero == "nada", "con candado no se pone")
	comprobar(p.poner("sombrero", "gorra") and p.poner("pelo", "cresta") and p.poner("color", 5), "lo libre sí")
	p.aspecto = p.POR_DEFECTO.duplicate()
	p.cargar()
	comprobar(p.aspecto == {"color": 5, "pelo": "cresta", "sombrero": "gorra"}, "se guarda en disco: %s" % [p.aspecto])
	_devolver(p)


func test_aspecto_de_fuera_no_se_fia() -> void:
	var p: Node = Engine.get_main_loop().root.get_node("Perfil")
	comprobar(p.valido({"color": 2, "pelo": "cresta", "sombrero": "corona"}), "uno bueno")
	comprobar(not p.valido({"color": 99, "pelo": "cresta", "sombrero": "nada"}), "color que no existe")
	comprobar(not p.valido({"color": 1, "pelo": "tupé", "sombrero": "nada"}), "peinado que no existe")
	comprobar(not p.valido("hola"), "ni siquiera un diccionario")


func test_colores_sin_repetir_en_la_partida() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	var r: Dictionary = red.sin_repetir([1, 5, 9], {1: 2, 5: 2, 9: 0})
	comprobar(r[1] == 2, "el primero se queda su color")
	comprobar(r[5] != 2 and r[5] != 0, "el segundo que lo pidió coge otro libre: %d" % r[5])
	comprobar(r[9] == 0, "los demás, el suyo")


func test_el_moco_lleva_lo_que_eligió() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	var p := _perfil()
	p.poner("sombrero", "gorra")
	p.poner("color", 4)
	var nivel: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	Engine.get_main_loop().root.add_child(nivel)
	var moco: MocoVisual = nivel.get_node("Jugadores/1/Visual/Moco")
	comprobar(moco.sombrero == "gorra" and moco.color == p.COLORES[4], "sin red, mi moco con mi gorra y mi color")
	nivel.free()
	red.config = red.CONFIG_INICIAL.duplicate(true)
	_devolver(p)


func test_vestidor_con_flechas() -> void:
	var p := _perfil()
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	Engine.get_main_loop().root.add_child(menu)
	var v: Node = menu.get_node("Vestidor")
	comprobar(not v.visible, "empieza cerrado")
	menu.get_node("Caja/TuMoco").pressed.emit()
	comprobar(v.visible and not menu.get_node("Caja").visible, "TU MOCO abre el vestidor")
	v.get_node("Sombrero/Mas").pressed.emit()
	comprobar(p.aspecto.sombrero == "gorra" and v.get_node("Sombrero/Valor").text == "GORRA", "› pone la gorra y se guarda")
	v.get_node("Sombrero/Mas").pressed.emit()
	comprobar(v.moco.sombrero == "lana" and p.aspecto.sombrero == "gorra", "con candado se ve puesto pero no se guarda")
	comprobar(v.get_node("Sombrero/Requisito").text == "SE GANA CON 3 PARTIDAS", "y dice cómo ganarlo")
	v.get_node("Color/Menos").pressed.emit()
	comprobar(p.aspecto.color == p.COLORES.size() - 1 and v.get_node("Color/Valor").text == "CHICLE", "‹ da la vuelta a los colores")
	v.get_node("Listo").pressed.emit()
	comprobar(not v.visible and menu.get_node("Caja").visible, "LISTO vuelve al menú")
	comprobar(v.moco.sombrero == "gorra", "y se queda con lo último desbloqueado")
	comprobar(menu.get_node("Sala").huecos[0].moco.sombrero == "gorra", "y el moco TÚ de la azotea lleva la gorra")
	menu.free()
	_devolver(p)


func test_al_acabar_el_torneo_se_cuenta_y_se_avisa() -> void:
	var red: Node = Engine.get_main_loop().root.get_node("Red")
	var p := _perfil()
	var nivel: Node = load("res://scenes/recorrido_prueba.tscn").instantiate()
	Engine.get_main_loop().root.add_child(nivel)
	p.partidas = 2
	nivel.fin_torneo([[1, 3, 40.0]], false)  # gano yo (id 1)
	comprobar(p.partidas == 3 and p.torneos == 1, "cuenta la partida y el torneo ganado")
	var titular: String = nivel.get_node("HUD/Titular").text
	comprobar("GORRO DE LANA" in titular, "avisa de lo nuevo: " + titular)
	nivel.free()
	red.config = red.CONFIG_INICIAL.duplicate(true)
	_devolver(p)

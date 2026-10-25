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
	for cosa in ["calvo", "cresta", "skrillex", "nada", "gorra", "lana", "chistera", "corona"]:
		comprobar(p.desbloqueado(cosa) or p.partidas > 0, cosa + " libre para todos")
	for fila in [p.PELOS, p.SOMBREROS, p.CARAS, p.ROPAS]:
		comprobar(fila.size() > 1, "cada fila tiene donde elegir")
	comprobar(p.NOMBRES.skrillex == "MEDIO RAPADO", "sin nombres de famosos en el juego")
	for fila in [p.PELOS, p.SOMBREROS, p.CARAS, p.ROPAS]:
		for cosa in fila:
			comprobar(p.NOMBRES.has(cosa), cosa + " tiene nombre para el vestidor")
	var nuevo := Node.new()
	nuevo.set_script(load("res://scripts/perfil.gd"))  # uno recién estrenado, sin partidas
	for cosa in ["afro", "pasta", "sonrisa", "siete", "amarilla", "traje", "boina_roja", "tupe_rubio", "rizos", "cinta", "raya", "rulos", "cepillo", "rulos_cortos", "oca", "ciborg", "mascara_roja", "mascara_negra", "cafetera", "reloj"]:
		comprobar(not nuevo.desbloqueado(cosa), cosa + " (famoso) empieza con candado")
	comprobar(nuevo.requisito("estrella") == "GANA UN TORNEO", "las gafas de estrella se ganan ganando")
	nuevo.free()
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
	var viejo := ConfigFile.new()  # un perfil de antes de CARA y ROPA no se pierde
	viejo.set_value("moco", "aspecto", {"color": 2, "pelo": "cresta", "sombrero": "gorra"})
	viejo.save(p.ruta)
	p.cargar()
	comprobar(p.aspecto.pelo == "cresta" and p.aspecto.cara == "nada", "perfil viejo: se completa, no se borra")
	p.poner("color", 5)
	p.poner("sombrero", "gorra")
	comprobar(p.aspecto == {"color": 5, "pelo": "cresta", "sombrero": "gorra", "cara": "nada", "ropa": "nada"}, "se guarda en disco: %s" % [p.aspecto])
	_devolver(p)


func test_aspecto_de_fuera_no_se_fia() -> void:
	var p: Node = Engine.get_main_loop().root.get_node("Perfil")
	comprobar(p.valido({"color": 2, "pelo": "cresta", "sombrero": "corona", "cara": "barba", "ropa": "diez"}), "uno bueno")
	comprobar(not p.valido({"color": 2, "pelo": "cresta", "sombrero": "corona"}), "le falta cara y ropa")
	comprobar(not p.valido({"color": 99, "pelo": "cresta", "sombrero": "nada", "cara": "nada", "ropa": "nada"}), "color que no existe")
	comprobar(not p.valido({"color": 1, "pelo": "tupé", "sombrero": "nada", "cara": "nada", "ropa": "nada"}), "peinado que no existe")
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
	v.get_node("Ropa/Mas").pressed.emit()
	comprobar(v.moco.ropa == p.ROPAS[1] and v.get_node("Ropa/Valor").text == p.NOMBRES[p.ROPAS[1]], "la fila ROPA también va")
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


func test_famosos_predefinidos() -> void:
	var nuevo := Node.new()
	nuevo.set_script(load("res://scripts/perfil.gd"))  # recién estrenado, sin partidas
	for nombre in ["EL REY DEL ROCK", "EL CÓMICO MUDO", "EL 10 ZURDO"]:
		comprobar(nombre in nuevo.LOOKS and nuevo.requisito_look(nombre) == "", nombre + " libre desde el principio")
	comprobar(nuevo.LOOKS.size() >= 20, "un famoso por personaje: %d" % nuevo.LOOKS.size())
	comprobar(nuevo.requisito_look("EL MAGNATE") != "", "los demás con candado")
	comprobar(nuevo.poner_look("EL CÓMICO MUDO") and nuevo.aspecto.sombrero == "bombin" and nuevo.aspecto.cara == "bigotito" and nuevo.aspecto.pelo == "calvo", "un clic y va vestido entero")
	comprobar(not nuevo.poner_look("EL MAGNATE") and nuevo.aspecto.sombrero == "bombin", "con candado no se pone")
	comprobar(nuevo.look_puesto() == "EL CÓMICO MUDO", "sabe qué famoso llevas")
	for nombre in nuevo.LOOKS:
		comprobar(nuevo.valido(nuevo.look(nombre).merged({"color": 0})), nombre + " solo usa piezas que existen")
	nuevo.free()


func test_vestidor_fila_de_famosos() -> void:
	var p := _perfil()
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	Engine.get_main_loop().root.add_child(menu)
	var v: Node = menu.get_node("Vestidor")
	menu.get_node("Caja/TuMoco").pressed.emit()
	comprobar(v.get_node("Famoso/Valor").text == "NINGUNO", "sin famoso al empezar")
	v.get_node("Famoso/Mas").pressed.emit()
	comprobar(v.get_node("Famoso/Valor").text == p.LOOKS.keys()[0], "› pasa al primer famoso")
	comprobar(v.moco.pelo == p.look(p.LOOKS.keys()[0]).pelo and v.get_node("Pelo/Valor").text == p.NOMBRES[v.moco.pelo], "y viste al moco y mueve las demás filas")
	menu.free()
	_devolver(p)

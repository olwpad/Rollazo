extends Caso


func test_constantes_de_red() -> void:
	var red: GDScript = load("res://scripts/red.gd")
	comprobar(red != null and red.PUERTO == 7777, "puerto 7777")
	comprobar(red != null and red.MAX_JUGADORES == 4, "máximo 4 jugadores")


func test_red_es_autoload() -> void:
	comprobar(ProjectSettings.get_setting("autoload/Red", "") == "*res://scripts/red.gd", "autoload Red")


func test_menu_es_la_escena_principal() -> void:
	comprobar(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/menu.tscn", "main_scene = menu")

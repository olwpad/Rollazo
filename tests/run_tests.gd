# Ejecutor de tests: godot --headless --path . --script res://tests/run_tests.gd
# Carga cada tests/test_*.gd, llama a sus métodos test_* y sale con código 1 si algo falla.
extends SceneTree


func _init() -> void:
	var total := 0
	var fallidos := 0
	for archivo in DirAccess.get_files_at("res://tests"):
		if not (archivo.begins_with("test_") and archivo.ends_with(".gd")):
			continue
		var clase: GDScript = load("res://tests/" + archivo)
		for metodo in clase.get_script_method_list():
			var nombre: String = metodo["name"]
			if not nombre.begins_with("test_"):
				continue
			var caso: Caso = clase.new()
			caso.call(nombre)
			total += 1
			if caso.fallos.is_empty():
				print("  ok   ", archivo, " :: ", nombre)
			else:
				fallidos += 1
				print("  FALLO ", archivo, " :: ", nombre, " -> ", ", ".join(caso.fallos))
	print("%d tests, %d fallidos" % [total, fallidos])
	quit(1 if fallidos > 0 or total == 0 else 0)

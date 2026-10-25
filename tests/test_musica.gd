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


func test_tecla_silenciar() -> void:
	comprobar(InputMap.has_action("silenciar"), "acción silenciar (M)")

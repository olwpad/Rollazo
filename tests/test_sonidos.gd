extends Caso


func _s() -> Node:
	return Engine.get_main_loop().root.get_node_or_null("Sonidos")


func test_todos_los_sonidos_se_generan_y_no_saturan() -> void:
	var s := _s()
	comprobar(s != null, "autoload Sonidos")
	if s == null:
		return
	for nombre in s.RECETAS:
		var wav: AudioStreamWAV = s.streams.get(nombre)
		comprobar(wav != null and wav.data.size() > 200, "%s tiene datos" % nombre)
		if wav == null:
			continue
		var pico := 0
		for i in range(0, wav.data.size(), 2):
			pico = maxi(pico, absi(wav.data.decode_s16(i)))
		comprobar(pico > 1000 and pico <= int(0.6 * 32767) + 1, "%s: pico %d, audible y sin pasar de 0,6" % [nombre, pico])
		comprobar(wav.data.size() / 2.0 / wav.mix_rate < 1.0, "%s dura menos de 1 s" % nombre)


func test_tocar_suena_y_respeta_el_silencio() -> void:
	var s := _s()
	var m: Node = Engine.get_main_loop().root.get_node("Musica")
	m.poner_volumen(100, false)
	m.silenciada = false
	for p in s.get_children():
		p.stop()  # otros tests pueden haber dejado cosas sonando
	s.tocar("desconocido")
	comprobar(s.sonando() == 0, "nombre desconocido no rompe ni suena")
	s.tocar("boton")
	s.tocar("salpicar", Vector2(10, 10))
	comprobar(s.sonando() == 2, "suenan los dos (plano y 2D): %d" % s.sonando())
	for p in s.get_children():
		p.stop()
	m.silenciada = true
	s.tocar("meta")
	comprobar(s.sonando() == 0, "con Musica silenciada no suena")
	m.silenciada = false

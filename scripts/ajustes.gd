# Ajustes del jugador que no son la música: pantalla completa, volumen de efectos y ayuda de
# controles. Autoload como Musica. Aquí vive también la ruta del archivo (la mira y Musica la usan).
extends Node

signal efectos_cambiaron

var ruta := "user://ajustes.cfg"  # en Windows: %APPDATA%/Godot/app_userdata/Rollazo
var pantalla_completa := false
var efectos := 100  # 0..100, solo de los efectos (la música tiene el suyo)
var ayuda := true  # la ayuda de controles de las carreras


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # F11 también con la partida en pausa
	if get_tree().get_script() != null:  # tests y bots: no tocar los ajustes de verdad
		ruta = "user://ajustes_pruebas.cfg"
	var cfg := ConfigFile.new()
	cfg.load(ruta)
	pantalla_completa = cfg.get_value("pantalla", "completa", false)
	efectos = clampi(cfg.get_value("sonido", "efectos", 100), 0, 100)
	ayuda = cfg.get_value("juego", "ayuda", true)
	_aplicar_pantalla()


func poner_pantalla_completa(si: bool) -> void:
	pantalla_completa = si
	_aplicar_pantalla()
	guardar("pantalla", "completa", si)


# Mientras se arrastra no se escribe el archivo cada fotograma: guardar_ya = true al soltar.
func poner_efectos(valor: int, guardar_ya := true) -> void:
	efectos = clampi(valor, 0, 100)
	if guardar_ya:
		guardar("sonido", "efectos", efectos)
	efectos_cambiaron.emit()


func poner_ayuda(si: bool) -> void:
	ayuda = si
	guardar("juego", "ayuda", si)


# Conserva lo demás que haya en el archivo.
func guardar(seccion: String, clave: String, valor: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.load(ruta)
	cfg.set_value(seccion, clave, valor)
	cfg.save(ruta)


func _aplicar_pantalla() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if pantalla_completa else DisplayServer.WINDOW_MODE_WINDOWED)


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_F11:
		poner_pantalla_completa(not pantalla_completa)

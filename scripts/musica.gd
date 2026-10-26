# Música de fondo. Es un autoload (como un singleton en Java): vive por encima de las
# escenas, así la canción no se corta al pasar del menú a la carrera.
extends Node

signal cambio_silencio(callada: bool)  # el icono y el deslizador del menú se repintan con esto

const CANCIONES := {
	"menu": "res://assets/musica/menu.ogg",
	"carrera": "res://assets/musica/carrera.ogg",
}
const VOLUMEN := -8.0  # de fondo: que no tape los efectos ni la charla por Discord

var reproductor := AudioStreamPlayer.new()
var silenciada := false
var volumen := 100  # 0..100, aparte del silencio: al quitarlo vuelve a este
var ruta := "user://ajustes.cfg"  # el mismo archivo que la mira y la última IP
var _actual := ""


func _ready() -> void:
	if get_tree().get_script() != null:  # tests y bots: no tocar los ajustes de verdad
		ruta = "user://ajustes_pruebas.cfg"
	var cfg := ConfigFile.new()
	cfg.load(ruta)
	silenciada = cfg.get_value("sonido", "silenciada", false)
	volumen = clampi(cfg.get_value("sonido", "volumen", 100), 0, 100)
	_aplicar()
	add_child(reproductor)


# Sin sonido, ya sea por silencio o por tener el volumen a 0 (el icono sale tachado en los dos casos).
func callada() -> bool:
	return silenciada or volumen == 0


# La usan el icono del menú y la tecla M: así siempre dicen lo mismo.
func alternar_silencio() -> void:
	if callada():
		silenciada = false
		if volumen == 0:  # quitar el silencio con el volumen a 0 no se oiría: a la mitad
			volumen = 50
	else:
		silenciada = true
	_guardar()


# Mientras se arrastra no se escribe el archivo cada fotograma: guardar = true al soltar.
func poner_volumen(valor: int, guardar := true) -> void:
	volumen = clampi(valor, 0, 100)
	if volumen > 0:
		silenciada = false  # subir el volumen quita el silencio
	if guardar:
		_guardar()
	else:
		_aplicar()


func _guardar() -> void:
	var cfg := ConfigFile.new()
	cfg.load(ruta)  # conserva lo demás que haya guardado
	cfg.set_value("sonido", "silenciada", silenciada)
	cfg.set_value("sonido", "volumen", volumen)
	cfg.save(ruta)
	_aplicar()


# Silenciar baja el volumen en vez de pausar: así tocar() otra canción no tiene que acordarse del silencio.
func _aplicar() -> void:
	reproductor.volume_db = -80.0 if callada() else VOLUMEN + linear_to_db(volumen / 100.0)
	cambio_silencio.emit(callada())


func tocar(nombre: String) -> void:
	if nombre == _actual:
		return
	_actual = nombre
	var cancion: AudioStreamOggVorbis = load(CANCIONES[nombre])
	cancion.loop = true
	reproductor.stream = cancion
	reproductor.play()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("silenciar"):
		alternar_silencio()

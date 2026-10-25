# Música de fondo. Es un autoload (como un singleton en Java): vive por encima de las
# escenas, así la canción no se corta al pasar del menú a la carrera.
extends Node

const CANCIONES := {
	"menu": "res://assets/musica/menu.ogg",
	"carrera": "res://assets/musica/carrera.ogg",
}

var reproductor := AudioStreamPlayer.new()
var _actual := ""


func _ready() -> void:
	reproductor.volume_db = -8.0  # de fondo: que no tape los efectos ni la charla por Discord
	add_child(reproductor)


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
		reproductor.stream_paused = not reproductor.stream_paused

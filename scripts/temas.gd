# Los mapas: misma acuarela, distinta paleta y fondo. El trazado sale de la semilla (Generador);
# el tema solo cambia cómo se pinta, si hay aros de fuego y qué se mueve en el fondo.
class_name Temas
extends RefCounted

const LISTA := ["azotea", "noche", "cueva", "mar", "jungla"]

# cielo: arriba, medio, abajo. lejos/cerca: siluetas del fondo. suelo: descansos y salida.
# superficie: lo que hay abajo del todo ("" = el vacío de la calle).
const DATOS := {
	"azotea": {"nombre": "LA AZOTEA", "cielo": [Color("f7d6e0"), Color("c9d6f2"), Color("e9f3f1")], "luna": true,
		"lejos": Color("c3cfea"), "cerca": Color("9fb4d9"), "suelo": Color("7d74b8"), "ventanas": Color(1, 1, 1, 0.6),
		"fondo": "ciudad", "superficie": "", "aros": false},
	"noche": {"nombre": "VERBENA EN LOS TEJADOS", "cielo": [Color("4a3a66"), Color("8a6098"), Color("e58fae")], "luna": false,
		"lejos": Color("6a5590"), "cerca": Color("54457a"), "suelo": Color("3a2f55"), "ventanas": Color("f5d38a", 0.75),
		"fondo": "ciudad", "superficie": "", "aros": true},
	"cueva": {"nombre": "LA CUEVA DE LAVA", "cielo": [Color("4e3c58"), Color("6a4f6a"), Color("b0707a")], "luna": false,
		"lejos": Color("5e4868"), "cerca": Color("46354f"), "suelo": Color("3e2f48"), "ventanas": Color(0, 0, 0, 0),
		"fondo": "cueva", "superficie": "lava", "aros": true},
	"mar": {"nombre": "EL MUELLE", "cielo": [Color("f8d8e2"), Color("f3e6ea"), Color("d4eee4")], "luna": true,
		"lejos": Color("b7d8dc"), "cerca": Color("c9a88a"), "suelo": Color("c9a88a"), "ventanas": Color(0, 0, 0, 0),
		"fondo": "mar", "superficie": "olas", "aros": false},
	"jungla": {"nombre": "LA JUNGLA", "cielo": [Color("e4f2d8"), Color("d2e8cc"), Color("b8dcb0")], "luna": false,
		"lejos": Color("a6d0a8"), "cerca": Color("7ab48a"), "suelo": Color("6f9e7c"), "ventanas": Color(0, 0, 0, 0),
		"fondo": "jungla", "superficie": "", "aros": true},
}


# El mapa de cada ronda: recorre la lista elegida sin repetir, empezando por uno al azar
# (la semilla de la partida). Todos los PCs tienen la misma lista, semilla y ronda.
static func de_ronda(lista: Array, semilla: int, ronda: int) -> String:
	if lista.is_empty():
		return "azotea"
	return lista[posmod(semilla + ronda - 1, lista.size())]

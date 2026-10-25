# Mancha de acuarela: la misma forma pintada 3 veces, cada vez con el borde un poco distinto
# y semitransparente. Donde se solapan sale el borde más intenso, como el pigmento al secarse.
class_name Acuarela
extends RefCounted

const OPACIDAD_CAPA := 0.42

# Paleta pastel elegida por el autor.
const ROSA := Color("ef8fae")
const LAVANDA := Color("a99be0")
const MENTA := Color("6cc3b0")
const AZUL_EDIFICIO := Color("9fb4d9")
const AZUL_LEJOS := Color("c3cfea")
const AZOTEA := Color("7d74b8")
const CIRUELA := Color("3a3550")  # ojos y textos, en vez de negro


static func capas(poligono: PackedVector2Array, semilla: int) -> Array[PackedVector2Array]:
	var salida: Array[PackedVector2Array] = []
	for k in 3:
		salida.append(Tinta.irregular(poligono, semilla * 3 + k, 5.0 - k, 30.0))
	return salida


# Pinta la mancha dentro de un CanvasItem (para usar en _draw).
static func pintar(lienzo: CanvasItem, poligono: PackedVector2Array, color: Color, semilla: int) -> void:
	for capa in capas(poligono, semilla):
		lienzo.draw_colored_polygon(capa, Color(color, OPACIDAD_CAPA))

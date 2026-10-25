# Efectos de estilo cómic-anime del jugador: onomatopeyas y estela de velocidad.
extends Node2D

const ESTELA_PUNTOS := 10
const VELOCIDAD_ESTELA := 800.0

@onready var jugador: Jugador = get_parent()
@onready var estela: Line2D = $Estela


func _ready() -> void:
	top_level = true  # los efectos se quedan en el mundo aunque el jugador se mueva
	jugador.papel_lanzado.connect(func(): _soltar("¡FWIP!", Color.WHITE))
	jugador.papel_roto.connect(func(): _soltar("¡RASSS!", Color(1, 0.35, 0.3)))
	jugador.aterrizaje_fuerte.connect(func(): _soltar("¡PLOF!", Color(1, 0.85, 0.1)))


func _soltar(texto: String, color: Color) -> void:
	add_child(Onomatopeya.crear(texto, jugador.global_position, color))


# Líneas de velocidad estilo anime: una estela que solo aparece cuando vas rápido.
func _process(_delta: float) -> void:
	if jugador.velocity.length() > VELOCIDAD_ESTELA:
		estela.add_point(jugador.global_position, 0)
		if estela.get_point_count() > ESTELA_PUNTOS:
			estela.remove_point(estela.get_point_count() - 1)
	elif estela.get_point_count() > 0:
		estela.remove_point(estela.get_point_count() - 1)

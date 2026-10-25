# Dibuja el papel del jugador: lavanda cuando es nuevo, rosa intenso cuando va a romperse.
# (No blanco: sobre el cielo pastel no se vería.) Lee el estado sincronizado, así funciona
# igual en el anfitrión y en los demás PCs.
extends Line2D

@onready var jugador: Jugador = get_parent()


func _ready() -> void:
	top_level = true  # los puntos van en coordenadas del mundo, no del jugador


func _process(_delta: float) -> void:
	clear_points()
	if not jugador.papel_activo:
		return
	var ancla := jugador.papel_ancla
	if jugador.papel_aguante < 0.3:  # tiembla: aviso de que se va a romper
		ancla += Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
	add_point(jugador.global_position)
	add_point(ancla)
	default_color = Acuarela.LAVANDA.darkened(0.25).lerp(Acuarela.ROSA.darkened(0.2), 1.0 - jugador.papel_aguante)

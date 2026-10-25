# Cliente de la prueba de red: se une al anfitrión local y se queda 3 s.
extends SceneTree

var espera := 0.0
var unido := false


func _process(delta: float) -> bool:
	if not unido:  # el autoload entra en el árbol después de _initialize
		unido = true
		root.get_node("Red").unirse("127.0.0.1", 7791)
	espera += delta
	if espera > 3.0:
		quit(0)
	return false

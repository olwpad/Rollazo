# Base de todos los tests. Como una clase abstracta de JUnit:
# cada test_*.gd hereda de aquí y usa comprobar() en vez de assert,
# porque assert detiene el script sin decir qué test falló.
class_name Caso
extends RefCounted

var fallos: Array[String] = []


func comprobar(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos.append(mensaje)

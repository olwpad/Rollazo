# Puestos de una ronda y puntos acumulados de la partida. Solo datos, sin nodos (como un POJO).
class_name Clasificacion
extends RefCounted

const PUNTOS := [10, 6, 3, 1]

var llegadas: Array[int] = []  # ids en orden de llegada de esta ronda
var puntos_totales := {}  # id -> puntos, se mantiene entre rondas


# Devuelve el puesto (1 = primero). Llegar dos veces no cuenta doble.
func registrar_llegada(id: int) -> int:
	if not id in llegadas:
		llegadas.append(id)
		puntos_totales[id] = puntos_totales.get(id, 0) + puntos_de(id)
	return llegadas.find(id) + 1


func puntos_de(id: int) -> int:
	var i := llegadas.find(id)
	return PUNTOS[i] if i >= 0 and i < PUNTOS.size() else 0


func todos_llegaron(ids_en_juego: Array[int]) -> bool:
	return ids_en_juego.all(func(id: int) -> bool: return id in llegadas)


func nueva_ronda() -> void:
	llegadas.clear()

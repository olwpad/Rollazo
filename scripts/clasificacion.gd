# Llegadas de la ronda y marcador del torneo. Solo datos, sin nodos (como un POJO).
# Gana la ronda solo el primero; el tiempo total sirve para desempatar.
class_name Clasificacion
extends RefCounted

var llegadas: Array[int] = []  # ids en orden de llegada de esta ronda
var tiempos := {}  # id -> tiempo de llegada en esta ronda
var victorias := {}  # id -> rondas ganadas, se mantiene entre rondas
var tiempo_total := {}  # id -> segundos sumados de todas las rondas


# Devuelve el puesto (1 = primero). Llegar dos veces no cuenta doble.
func registrar_llegada(id: int, t := 0.0) -> int:
	if not id in llegadas:
		llegadas.append(id)
		tiempos[id] = t
	return llegadas.find(id) + 1


func todos_llegaron(ids_en_juego: Array[int]) -> bool:
	return ids_en_juego.all(func(id: int) -> bool: return id in llegadas)


# Suma la ronda al marcador. A quien no llegó se le cuenta t_fin: no llegar no sale gratis.
func cerrar_ronda(ids: Array[int], t_fin: float) -> void:
	if not llegadas.is_empty():
		victorias[llegadas[0]] = victorias.get(llegadas[0], 0) + 1
	for id in ids:
		tiempo_total[id] = tiempo_total.get(id, 0.0) + tiempos.get(id, t_fin)
	llegadas.clear()
	tiempos.clear()


# Más victorias primero; con las mismas, menos tiempo (como un Comparator con thenComparing).
func orden(ids: Array[int]) -> Array[int]:
	var lista: Array[int] = []
	lista.assign(ids)
	lista.sort_custom(func(a: int, b: int) -> bool:
		if victorias.get(a, 0) != victorias.get(b, 0):
			return victorias.get(a, 0) > victorias.get(b, 0)
		return tiempo_total.get(a, 0.0) < tiempo_total.get(b, 0.0))
	return lista


# El primero y el segundo tienen las mismas victorias: el primero va delante por tiempo.
func gana_por_tiempo(ids: Array[int]) -> bool:
	var o := orden(ids)
	return o.size() >= 2 and victorias.get(o[0], 0) == victorias.get(o[1], 0)

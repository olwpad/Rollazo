# Tu moco: color, peinado y sombrero, y lo que llevas desbloqueado jugando. Se guarda en este PC.
# Autoload "Perfil" (como un singleton en Java): lo usan el menú, la sala y la carrera.
extends Node

const COLORES := [Color("6cc3b0"), Color("ef8fae"), Color("a99be0"), Color("f5b38a"),
		Color("f5d38a"), Color("8ec5e8"), Color("c7d97a"), Color("e8a0d8")]
const NOMBRES_COLOR := ["MENTA", "ROSA", "LAVANDA", "MELOCOTÓN", "LIMÓN", "CIELO", "PISTACHO", "CHICLE"]
const PELOS := ["calvo", "cresta", "skrillex"]
const SOMBREROS := ["nada", "gorra", "lana", "chistera", "corona"]
const NOMBRES := {"calvo": "CALVO", "cresta": "CRESTA", "skrillex": "SKRILLEX", "nada": "NADA",
		"gorra": "GORRA", "lana": "GORRO DE LANA", "chistera": "CHISTERA", "corona": "CORONA"}
# Lo que no sale aquí es libre. De momento todo libre: los famosos con candado llegan aparte.
var partidas_para := {}
const POR_DEFECTO := {"color": 0, "pelo": "calvo", "sombrero": "nada"}

var ruta := "user://perfil.cfg"
var aspecto := POR_DEFECTO.duplicate()
var partidas := 0  # torneos terminados, ganes o pierdas: el que pierde también avanza
var torneos := 0  # torneos ganados


func _ready() -> void:
	if get_tree().get_script() != null:  # lanzado con --script (tests y bots): no tocar el perfil de verdad
		ruta = "user://perfil_pruebas.cfg"
	cargar()


func desbloqueado(cosa: String) -> bool:
	return partidas >= partidas_para.get(cosa, 0)


func requisito(cosa: String) -> String:
	if desbloqueado(cosa):
		return ""
	return "SE GANA CON %d PARTIDAS" % partidas_para[cosa]


# Al acabar un torneo. Devuelve lo que se acaba de desbloquear, para celebrarlo.
func anotar_torneo(gane: bool) -> Array:
	var antes := (PELOS + SOMBREROS).filter(desbloqueado)
	partidas += 1
	if gane:
		torneos += 1
	guardar()
	return (PELOS + SOMBREROS).filter(func(c: String) -> bool: return desbloqueado(c) and not c in antes)


# clave: "color" (índice), "pelo" o "sombrero". Lo que tiene candado no se pone.
func poner(clave: String, valor: Variant) -> bool:
	var prueba := aspecto.duplicate()
	prueba[clave] = valor
	if not valido(prueba) or (clave != "color" and not desbloqueado(valor)):
		return false
	aspecto = prueba
	guardar()
	return true


# Lo que llega por red no es de fiar: solo cosas que existen.
func valido(a: Variant) -> bool:
	return a is Dictionary and a.get("color") is int and a.color >= 0 and a.color < COLORES.size() \
			and a.get("pelo") in PELOS and a.get("sombrero") in SOMBREROS


func guardar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("moco", "aspecto", aspecto)
	cfg.set_value("moco", "partidas", partidas)
	cfg.set_value("moco", "torneos", torneos)
	cfg.save(ruta)


func cargar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(ruta) != OK:
		return
	var a: Variant = cfg.get_value("moco", "aspecto", POR_DEFECTO)
	aspecto = a if valido(a) else POR_DEFECTO.duplicate()  # un archivo roto no rompe el juego
	partidas = int(cfg.get_value("moco", "partidas", 0))
	torneos = int(cfg.get_value("moco", "torneos", 0))

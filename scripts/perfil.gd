# Tu moco: color, peinado y sombrero, y lo que llevas desbloqueado jugando. Se guarda en este PC.
# Autoload "Perfil" (como un singleton en Java): lo usan el menú, la sala y la carrera.
extends Node

const COLORES := [Color("6cc3b0"), Color("ef8fae"), Color("a99be0"), Color("f5b38a"),
		Color("f5d38a"), Color("8ec5e8"), Color("c7d97a"), Color("e8a0d8")]
const NOMBRES_COLOR := ["MENTA", "ROSA", "LAVANDA", "MELOCOTÓN", "LIMÓN", "CIELO", "PISTACHO", "CHICLE"]
# Los famosos son homenajes: se reconocen por el estilo, nunca con su nombre (ni marcas ni escudos).
const PELOS := ["calvo", "cresta", "skrillex", "tupe", "afro", "melena", "diva", "tupe_rubio", "engominado", "rizos", "cinta", "raya", "rulos", "cepillo", "rulos_cortos"]
const SOMBREROS := ["nada", "gorra", "lana", "chistera", "corona", "bombin", "vaquero", "boina", "boina_roja", "oca"]
const CARAS := ["nada", "bigotito", "rizado", "redondas", "estrella", "barba", "sonrisa", "pasta", "ciborg", "mascara_roja", "mascara_negra"]
const ROPAS := ["nada", "chandal", "corbata", "diez", "siete", "amarilla", "traje", "cafetera", "reloj"]
const NOMBRES := {"calvo": "CALVO", "cresta": "CRESTA", "skrillex": "MEDIO RAPADO", "tupe": "TUPÉ DE ROCKERO",
		"afro": "AFRO DISCO", "melena": "MELENA HEAVY", "diva": "MOÑO DE DIVA", "tupe_rubio": "TUPÉ RUBIO",
		"engominado": "ENGOMINADO", "rizos": "MELENA RUBIA RIZADA", "cinta": "RIZOS CON CINTA", "raya": "RAYA AL LADO",
		"nada": "NADA", "gorra": "GORRA", "lana": "GORRO DE LANA", "chistera": "CHISTERA", "corona": "CORONA",
		"bombin": "BOMBÍN", "vaquero": "SOMBRERO VAQUERO", "boina": "BOINA DE PINTOR", "boina_roja": "BOINA ROJA",
		"bigotito": "BIGOTITO", "rizado": "BIGOTE RIZADO", "redondas": "GAFAS REDONDAS", "estrella": "GAFAS DE ESTRELLA",
		"barba": "BARBA", "sonrisa": "SONRISA DE CRACK", "pasta": "GAFAS DE PASTA",
		"chandal": "CHÁNDAL TRICOLOR", "corbata": "CORBATA LARGA", "diez": "CAMISETA DEL 10", "siete": "CAMISETA DEL 7",
		"amarilla": "CAMISETA AMARILLA", "traje": "TRAJE DE DEBATE",
		"rulos": "RULOS NEGROS", "cepillo": "PELO CEPILLO", "rulos_cortos": "RULOS DE CANTERANO", "oca": "GORRO DE OCA",
		"ciborg": "GAFAS DE CÍBORG", "mascara_roja": "MÁSCARA DE HÉROE", "mascara_negra": "MÁSCARA NEGRA Y ROJA",
		"cafetera": "CAMISETA CAFETERA", "reloj": "CAMISETA CON RELOJ VERDE"}
# Candados: partidas jugadas (ganes o pierdas). Lo que no sale aquí es libre.
# Libres desde el principio: el rey del rock, el cómico mudo y el 10 zurdo (tupe, bombin, bigotito, barba, diez).
var partidas_para := {"afro": 4, "vaquero": 5, "melena": 6,
		"rizado": 7, "boina": 7, "diva": 8, "boina_roja": 9, "chandal": 9, "redondas": 10, "tupe_rubio": 11,
		"corbata": 11, "engominado": 13, "siete": 13, "rizos": 14,
		"cinta": 15, "sonrisa": 15, "amarilla": 15, "pasta": 16, "raya": 17, "traje": 17,
		"cafetera": 18, "rulos": 19, "cepillo": 20, "ciborg": 20, "oca": 21, "rulos_cortos": 22,
		"reloj": 23, "mascara_roja": 24, "mascara_negra": 25}
const TORNEOS_PARA := {"estrella": 1}  # las gafas de estrella, solo ganando
const POR_DEFECTO := {"color": 0, "pelo": "calvo", "sombrero": "nada", "cara": "nada", "ropa": "nada"}
const FILAS := {"pelo": PELOS, "sombrero": SOMBREROS, "cara": CARAS, "ropa": ROPAS}
# Famosos ya montados: un clic y el moco va vestido entero. Nombres genéricos, sin apodos reales.
const LOOKS := {
	"EL REY DEL ROCK": {"pelo": "tupe"}, "EL CÓMICO MUDO": {"sombrero": "bombin", "cara": "bigotito"},
	"EL 10 ZURDO": {"cara": "barba", "ropa": "diez"}, "EL DEL AFRO DISCO": {"pelo": "afro"},
	"EL HEAVY": {"pelo": "melena"}, "LA DIVA DEL SOUL": {"pelo": "diva"}, "LA ESTRELLA COUNTRY": {"sombrero": "vaquero"},
	"EL PINTOR GENIO": {"sombrero": "boina", "cara": "rizado"}, "EL MÚSICO PACIFISTA": {"pelo": "melena", "cara": "redondas"},
	"LA ESTRELLA DEL POP": {"cara": "estrella"}, "EL COMANDANTE": {"sombrero": "boina_roja", "ropa": "chandal"},
	"EL MAGNATE": {"pelo": "tupe_rubio", "ropa": "corbata"}, "EL 7 GOLEADOR": {"pelo": "engominado", "ropa": "siete"},
	"LA DIVA LATINA": {"pelo": "rizos"}, "EL MAGO DEL BALÓN": {"pelo": "cinta", "cara": "sonrisa", "ropa": "amarilla"},
	"EL DJ": {"pelo": "skrillex", "cara": "pasta"}, "EL DEBATIENTE": {"pelo": "raya", "ropa": "traje"},
	"EL 10 CAFETERO": {"pelo": "raya", "ropa": "cafetera"}, "EL 10 DE LOS RULOS": {"pelo": "rulos", "ropa": "diez"},
	"EL CÍBORG": {"pelo": "cepillo", "cara": "ciborg"}, "LA OCA": {"sombrero": "oca"},
	"EL HÉROE ENMASCARADO": {"cara": "mascara_roja"}, "EL HÉROE NOCTURNO": {"cara": "mascara_negra"},
	"EL NIÑO DEL RELOJ": {"pelo": "raya", "ropa": "reloj"}, "EL CANTERANO": {"pelo": "rulos_cortos"},
}

var ruta := "user://perfil.cfg"
var aspecto := POR_DEFECTO.duplicate()
var partidas := 0  # torneos terminados, ganes o pierdas: el que pierde también avanza
var torneos := 0  # torneos ganados


func _ready() -> void:
	if get_tree().get_script() != null:  # lanzado con --script (tests y bots): no tocar el perfil de verdad
		ruta = "user://perfil_pruebas.cfg"
	cargar()


func desbloqueado(cosa: String) -> bool:
	return partidas >= partidas_para.get(cosa, 0) and torneos >= TORNEOS_PARA.get(cosa, 0)


func requisito(cosa: String) -> String:
	if desbloqueado(cosa):
		return ""
	return "GANA UN TORNEO" if TORNEOS_PARA.has(cosa) else "SE GANA CON %d PARTIDAS" % partidas_para[cosa]


# Las piezas de un famoso (lo que no lleva, "calvo"/"nada").
func look(nombre: String) -> Dictionary:
	var a := POR_DEFECTO.duplicate()
	a.erase("color")
	return a.merged(LOOKS[nombre], true)


# Lo que pide la pieza más difícil del famoso ("" si está libre).
func requisito_look(nombre: String) -> String:
	var piezas := look(nombre).values().filter(func(c: String) -> bool: return not desbloqueado(c))
	piezas.sort_custom(func(x: String, y: String) -> bool: return TORNEOS_PARA.has(x) or partidas_para.get(x, 0) > partidas_para.get(y, 0))
	return requisito(piezas[0]) if piezas else ""


func poner_look(nombre: String) -> bool:
	if requisito_look(nombre) != "":
		return false
	aspecto.merge(look(nombre), true)  # el color se queda el tuyo
	guardar()
	return true


# Qué famoso llevas (o llevaría `a`), "" si ninguno.
func look_puesto(a: Dictionary = {}) -> String:
	if a.is_empty():
		a = aspecto
	for nombre in LOOKS:
		if look(nombre).keys().all(func(k: String) -> bool: return a[k] == look(nombre)[k]):
			return nombre
	return ""


# Al acabar un torneo. Devuelve lo que se acaba de desbloquear, para celebrarlo.
func anotar_torneo(gane: bool) -> Array:
	var todas := PELOS + SOMBREROS + CARAS + ROPAS
	var antes := todas.filter(desbloqueado)
	partidas += 1
	if gane:
		torneos += 1
	guardar()
	return todas.filter(func(c: String) -> bool: return desbloqueado(c) and not c in antes)


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
	if not (a is Dictionary and a.get("color") is int and a.color >= 0 and a.color < COLORES.size()):
		return false
	for fila in FILAS:
		if not a.get(fila) in FILAS[fila]:
			return false
	return true


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
	if a is Dictionary:  # un perfil de antes de CARA y ROPA se completa con lo de por defecto
		a = POR_DEFECTO.merged(a, true)
	aspecto = a if valido(a) else POR_DEFECTO.duplicate()  # un archivo roto no rompe el juego
	partidas = int(cfg.get_value("moco", "partidas", 0))
	torneos = int(cfg.get_value("moco", "torneos", 0))

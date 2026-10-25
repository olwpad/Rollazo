# Efectos de sonido sintetizados por código (nada de archivos de audio). Autoload como Musica:
# al arrancar genera cada sonido una vez y lo guarda; tocar() los reproduce con un pool pequeño.
extends Node

const RATE := 22050
const PICO := 0.6  # tope de amplitud: con varias notas superpuestas no satura
const BASE_DB := -4.0  # los efectos van un poco por encima de la música (-8 dB)
const SIN_VARIAR := ["cuenta", "meta", "control"]  # las melodías y los números no cambian de tono
const POOL := 8

# Cada nota: [inicio s, duración s, Hz inicial, Hz final, forma, amplitud]. Forma: "seno",
# "tri" o "ruido" (ruido con paso bajo; las frecuencias son entonces el corte, no un tono).
const RECETAS := {
	"lanzar": [[0.0, 0.12, 400.0, 900.0, "seno", 0.35]],
	"enganchar": [[0.0, 0.14, 320.0, 170.0, "seno", 0.5]],
	"soltar": [[0.0, 0.16, 600.0, 250.0, "tri", 0.35]],
	"salpicar": [[0.0, 0.25, 1500.0, 400.0, "ruido", 0.5], [0.0, 0.2, 260.0, 100.0, "seno", 0.3]],
	"sierra": [[0.0, 0.15, 700.0, 500.0, "tri", 0.25]],
	"poder": [[0.0, 0.1, 880.0, 1100.0, "seno", 0.35], [0.07, 0.16, 1320.0, 1400.0, "seno", 0.35]],
	"control": [[0.0, 0.2, 988.0, 988.0, "seno", 0.3], [0.09, 0.25, 1319.0, 1319.0, "seno", 0.3]],
	"meta": [[0.0, 0.25, 523.0, 523.0, "seno", 0.3], [0.12, 0.25, 659.0, 659.0, "seno", 0.3],
		[0.24, 0.25, 784.0, 784.0, "seno", 0.3], [0.36, 0.45, 1047.0, 1047.0, "tri", 0.3]],
	"cuenta": [[0.0, 0.1, 660.0, 660.0, "seno", 0.4]],
	"boton": [[0.0, 0.04, 900.0, 900.0, "seno", 0.25]],
}

var streams := {}  # nombre -> AudioStreamWAV
var _planos: Array[AudioStreamPlayer] = []
var _2d: Array[AudioStreamPlayer2D] = []
var _siguiente := 0


func _ready() -> void:
	for nombre in RECETAS:
		streams[nombre] = _sintetizar(RECETAS[nombre])
	for i in POOL:
		var p := AudioStreamPlayer.new()
		var p2 := AudioStreamPlayer2D.new()
		p2.max_distance = 1500.0
		add_child(p)
		add_child(p2)
		_planos.append(p)
		_2d.append(p2)
	get_tree().node_added.connect(_al_añadir_nodo)


# Todos los botones del juego hacen clic sin tocar cada escena.
func _al_añadir_nodo(nodo: Node) -> void:
	if nodo is BaseButton:
		nodo.pressed.connect(tocar.bind("boton"))


func _sintetizar(notas: Array) -> AudioStreamWAV:
	var total := 0.0
	for n in notas:
		total = maxf(total, n[0] + n[1])
	var muestras := PackedFloat32Array()
	muestras.resize(int(total * RATE) + 1)
	for n in notas:
		var ini := int(n[0] * RATE)
		var cuantas := int(n[1] * RATE)
		var fase := 0.0
		var filtro := 0.0
		var ruido := RandomNumberGenerator.new()
		ruido.seed = 7  # el mismo "splat" en cada arranque
		for i in cuantas:
			var u := float(i) / cuantas
			var hz := lerpf(n[2], n[3], u)
			fase += hz / RATE
			var v: float
			match n[4]:
				"seno": v = sin(TAU * fase)
				"tri": v = 4.0 * absf(fposmod(fase, 1.0) - 0.5) - 1.0
				_:
					filtro = lerpf(filtro, ruido.randf_range(-1.0, 1.0), clampf(TAU * hz / RATE, 0.0, 1.0))
					v = filtro * 2.0
			# ataque de 5 ms (sin clic) y caída suave
			var env := minf(i / (0.005 * RATE), 1.0) * pow(1.0 - u, 2.0)
			muestras[ini + i] += v * env * n[5]
	var bytes := PackedByteArray()
	bytes.resize(muestras.size() * 2)
	for i in muestras.size():
		bytes.encode_s16(i * 2, int(clampf(muestras[i], -PICO, PICO) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	return wav


# pos = null: suena igual en todas partes (interfaz); con posición se atenúa con la distancia.
func tocar(nombre: String, pos = null) -> void:
	if not streams.has(nombre) or Musica.callada():
		return
	var p
	if pos is Vector2:
		p = _2d[_siguiente]
		p.global_position = pos
	else:
		p = _planos[_siguiente]
	_siguiente = (_siguiente + 1) % POOL  # si todos suenan, pisa el más antiguo
	p.stream = streams[nombre]
	p.volume_db = BASE_DB + linear_to_db(Musica.volumen / 100.0)
	p.pitch_scale = 1.0 if nombre in SIN_VARIAR else randf_range(0.94, 1.06)
	p.play()


func sonando() -> int:
	var n := 0
	for p in _planos + _2d:
		if p.playing:
			n += 1
	return n

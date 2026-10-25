# Decoración del menú: un moco columpiándose de un techo al fondo, para que el menú
# ya parezca el juego. Es solo animación (seno), sin física.
extends Node2D

@export var largo := 230.0
@export var amplitud := 0.75  # radianes

var _t := 0.0
@onready var moco := MocoVisual.new()
@onready var papel := Line2D.new()


func _ready() -> void:
	papel.width = 5.0
	papel.default_color = Acuarela.LAVANDA.darkened(0.25)
	add_child(papel)
	moco.color = Color("f5d38a")  # amarillo: ninguno de los 4 de la azotea lo lleva, así no parece repetido
	moco.scale = Vector2(1.3, 1.3)
	add_child(moco)


func _process(delta: float) -> void:
	_t += delta
	var angulo := amplitud * sin(_t * 1.7)
	var antes := moco.position
	moco.position = Vector2(sin(angulo), cos(angulo)) * largo
	moco.velocidad = (moco.position - antes) / maxf(delta, 0.001)  # para que se estire al pasar
	papel.points = PackedVector2Array([Vector2.ZERO, moco.position])


func _draw() -> void:
	Acuarela.pintar(self, PackedVector2Array([Vector2(-110, -26), Vector2(110, -20), Vector2(112, 4), Vector2(-108, 0)]), Acuarela.ROSA, 5)

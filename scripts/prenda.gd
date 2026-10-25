# Prenda tendida: una liana corta que el viento mece poco. Se engancha por la prenda.
class_name Prenda
extends Liana

var cuerda_a := Vector2.ZERO  # extremos de la cuerda (global); cada prenda la dibuja entera
var cuerda_b := Vector2.ZERO
var color := Acuarela.ROSA


func _ready() -> void:
	largo = 46.0
	amplitud = 0.14
	periodo = 2.6
	super()
	(get_child(0) as CollisionShape2D).shape = RectangleShape2D.new()
	(get_child(0) as CollisionShape2D).shape.size = Vector2(40, 52)


func _draw() -> void:
	var a := to_local(cuerda_a)
	var b := to_local(cuerda_b)
	draw_line(a, b, Color("a99be0"), 3.0, true)
	draw_line(to_local(pivote), Vector2(0, -26), Color("a99be0"), 2.0)
	var cuerpo := PackedVector2Array([Vector2(-20, -26), Vector2(20, -26), Vector2(22, 26), Vector2(-22, 26)])
	Moviles.mancha(self, cuerpo, color, 61)

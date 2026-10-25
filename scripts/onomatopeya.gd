# Texto de cómic que salta en pantalla ("¡FWIP!", "¡RASSS!") y desaparece.
class_name Onomatopeya
extends Label

const FUENTE := preload("res://assets/fuentes/Bangers-Regular.ttf")


static func crear(p_texto: String, pos: Vector2, color := Color(1, 0.85, 0.1)) -> Onomatopeya:
	var o := Onomatopeya.new()
	o.text = p_texto
	o.add_theme_font_override("font", FUENTE)
	o.add_theme_font_size_override("font_size", 44)
	o.add_theme_color_override("font_color", color)
	o.add_theme_color_override("font_outline_color", Color.BLACK)
	o.add_theme_constant_override("outline_size", 14)
	o.position = pos + Vector2(randf_range(-30, 30), -70)
	o.rotation = randf_range(-0.35, 0.35)
	o.z_index = 50
	return o


func _ready() -> void:
	pivot_offset = size / 2.0
	scale = Vector2(0.3, 0.3)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.2, 1.2), 0.08)
	t.tween_property(self, "scale", Vector2.ONE, 0.08)
	t.tween_interval(0.35)
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(queue_free)

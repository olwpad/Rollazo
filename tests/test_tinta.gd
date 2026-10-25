extends Caso

const CUADRADO := [Vector2(0, 0), Vector2(100, 0), Vector2(100, 50), Vector2(0, 50)]


func test_mismo_fotograma_mismo_dibujo() -> void:
	var a := Tinta.temblar(PackedVector2Array(CUADRADO), 3, 5, 3.0)
	var b := Tinta.temblar(PackedVector2Array(CUADRADO), 3, 5, 3.0)
	comprobar(a == b, "determinista")


func test_otro_fotograma_otro_dibujo() -> void:
	var a := Tinta.temblar(PackedVector2Array(CUADRADO), 3, 5, 3.0)
	var b := Tinta.temblar(PackedVector2Array(CUADRADO), 3, 6, 3.0)
	comprobar(a != b, "la tinta hierve entre fotogramas")


func test_temblor_acotado() -> void:
	var a := Tinta.temblar(PackedVector2Array(CUADRADO), 9, 1, 3.0)
	for i in a.size():
		comprobar(a[i].distance_to(CUADRADO[i]) <= 3.0 * 1.5, "punto %d dentro de la amplitud" % i)


func test_fotograma_a_12_fps() -> void:
	comprobar(Tinta.fotograma(0) == Tinta.fotograma(80), "mismo fotograma dentro de 1/12 s")
	comprobar(Tinta.fotograma(0) != Tinta.fotograma(90), "cambia tras 1/12 s")


func test_trazo_irregular_subdivide() -> void:
	var t := Tinta.irregular(PackedVector2Array(CUADRADO), 1, 4.0, 40.0)
	comprobar(t.size() > 4, "añade puntos intermedios en los lados largos")

# Formas de nivel: plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** que cada mapa salga, según su semilla, como horizontal, torre, bajada, montaña o híbrido, con sierras, en solo y online.

**Architecture:** `Generador.generar` pasa a encadenar **tramos** (cada forma es una función que añade piezas a partir de un cursor y devuelve el cursor nuevo); la forma se elige con el mismo `rng` de la semilla. El diccionario del mapa gana campos (`forma`, `inicio`, `caida_y`, `limites`, `meta_tam`, `sierras`) y `recorrido.gd` deja de suponer que el mapa es horizontal. Las sierras son un `Area2D` con script propio; el contacto lo decide el anfitrión, como los aros.

**Tech Stack:** Godot 4.7.2, GDScript, tests propios (`tests/caso.gd`, `./run_tests.sh` con Git Bash).

**Spec:** `docs/superpowers/specs/2026-10-25-formas-de-nivel-design.md`

## Global Constraints

- Determinista por semilla: `Generador.generar(s)` devuelve lo mismo en los 4 PCs; ningún `randf()` global en el generador.
- Estilo acuarela pastel **sin contornos** (`Acuarela`, `Tinta`); nada de sprites genéricos. La sierra se dibuja con código.
- Antes del arte final de la sierra, boceto en el navegador y aprobación del usuario.
- Paredes de torre y montaña: `enganchable = false` (gris/lavanda oscuro del tema); salientes del camino: `enganchable = true`.
- Tocar una sierra = salpicadura y vuelta al último control (igual que `_al_tocar_aro`).
- Solo: al cruzar la meta, nada de volver a un control; tiempo en pantalla y mapa nuevo tras un momento; R repite el mismo mapa; el tema también cambia; "mejor" es por mapa.
- Comentarios en español, como el resto del código; un comentario solo para el porqué.
- `./run_tests.sh` termina con código 0 y sin "SCRIPT ERROR" al final de cada tarea.

## Review Focus

1. **Meta en una torre**: `Meta/Forma` mide 1200 de alto; en un mapa vertical no puede activarse a mitad del pozo. Se espera que la meta solo cuente al llegar arriba. → test en Tarea 5.
2. **Caer en un mapa que baja**: con la bajada, el suelo queda muy por debajo de y = 1200; la franja `Caida` tiene que estar por debajo del punto más bajo, no en 1200 fijo. → test en Tarea 1 y Tarea 5.
3. **Salida y 4 mocos**: si la bajada empieza arriba, `Inicio`/`SueloInicio` se mueven ahí y siguen cabiendo 4 mocos (90 px). → test en Tarea 5.
4. **Sierra junto a un control o un descanso**: reaparecer y tocar una sierra en bucle. Se espera que ninguna sierra quede a menos de 250 px de un control ni encima de un descanso. → test en Tarea 6.
5. **Pulsar R tras llegar en solo / llegar justo cuando cambia el mapa**: el mapa nuevo no debe arrancar encima del que repites. → test en Tarea 7.

---

### Task 1: Tramos en el generador (horizontal sin cambios de comportamiento)

**Files:**
- Modify: `scripts/generador.gd`
- Test: `tests/test_generador.gd`

**Interfaces:**
- Produces:
  - `static func generar(semilla: int, forma := "") -> Dictionary` — `forma` vacía = elegida por la semilla (en esta tarea siempre `"horizontal"`); los tests la fuerzan.
  - Campos nuevos del mapa: `forma: String`, `inicio: Vector2` (salida de los mocos; hoy `Vector2(200, 640)`), `caida_y: float` (centro de la franja que mata; hoy 1200), `limites: Rect2` (caja de todo el recorrido, de la salida a la meta, con todas las piezas dentro), `meta_tam: Vector2` (tamaño del área de meta; horizontal `Vector2(?, 1200)` como la escena).
  - `static func _tramo_horizontal(m: Dictionary, rng: RandomNumberGenerator, desde: Vector2, largo: float) -> Vector2` — el bucle actual, empezando en `desde` (borde del suelo anterior) y hasta recorrer `largo` px en x; devuelve el borde donde acaba.
  - Constante `FORMAS := ["horizontal", "torre", "bajada", "montaña", "hibrido"]`.

- [ ] **Step 1: tests**

```gdscript
func test_campos_nuevos_del_mapa() -> void:
	var m := Generador.generar(3, "horizontal")
	comprobar(m.forma == "horizontal", "forma")
	comprobar(m.inicio == Vector2(200, 640), "salida como hasta ahora")
	comprobar(m.caida_y >= 1200.0, "caída por debajo de todo")
	for p in m.piezas:
		comprobar(m.limites.grow(1.0).has_point(p.pos), "pieza %s dentro de los límites" % p.nombre)
	comprobar(m.limites.has_point(m.meta), "meta dentro")
```

Los tests horizontales que ya existen (`test_largo_con_controles_y_caida`, `test_siempre_alcanzable`, embudos, bloques, suelo de meta) pasan a llamar `Generador.generar(semilla, "horizontal")`.

- [ ] **Step 2:** `./run_tests.sh` → falla `test_campos_nuevos_del_mapa`.
- [ ] **Step 3:** extraer el bucle de `generar` a `_tramo_horizontal` y rellenar los campos nuevos. Las demás llamadas (`postal.gd`, `recorrido.gd`, `sim_red_cliente.gd`, `test_mapas.gd`, `test_poderes.gd`) siguen llamando `generar(semilla)` sin tocar.
- [ ] **Step 4:** `./run_tests.sh` → código 0.
- [ ] **Step 5:** commit `Generador: el recorrido se arma por tramos (de momento solo horizontal)`.

### Task 2: Tramo torre

**Files:** Modify `scripts/generador.gd`; Test `tests/test_generador.gd`

**Interfaces:**
- Consumes: `_tramo_*`, campos de la Tarea 1.
- Produces: `static func _tramo_torre(m, rng, desde: Vector2, alto: float) -> Vector2` — pozo entre dos paredes (`"Pared"`, no enganchables) con salientes enganchables (`"Techo"`) alternando izquierda/derecha, subiendo `alto` px; un descanso con control cada 3-4 salientes; devuelve el borde del último descanso arriba. Añade los salientes a `m.camino` y los bordes de descanso a `m.salidas_descanso`.

- [ ] **Step 1: tests**

```gdscript
func test_torre_sube_y_se_puede_escalar() -> void:
	for semilla in 40:
		var m := Generador.generar(semilla, "torre")
		comprobar(m.meta.y < m.inicio.y - 1500.0, "semilla %d: la meta queda muy arriba" % semilla)
		for i in range(1, m.camino.size()):
			var d: Vector2 = m.camino[i] - m.camino[i - 1]
			comprobar(d.length() <= PapelRope.LARGO_MAX - 40.0, "semilla %d: saliente %d a %.0f px" % [semilla, i, d.length()])
		for p in _piezas(m, "Pared"):
			comprobar(not p.enganchable, "las paredes no enganchan")
		comprobar(m.controles.size() >= 3, "semilla %d: controles a lo largo de la torre" % semilla)
```

- [ ] **Step 2:** ejecutar → falla. **Step 3:** implementar (medidas a elegir; la Tarea 8 las ajusta con el bot). **Step 4:** código 0. **Step 5:** commit `Generador: tramo de torre`.

### Task 3: Tramo bajada

**Files:** Modify `scripts/generador.gd`; Test `tests/test_generador.gd`

**Interfaces:**
- Produces: `static func _tramo_bajada(m, rng, desde: Vector2, largo: float) -> Vector2` — techos en escalera, cada uno más bajo que el anterior; `m.inicio` queda arriba (sobre un suelo de salida propio, pieza `"SueloSalida"` no enganchable) cuando la bajada es el primer tramo; descansos con control cada 3-4 techos. Deja huecos libres en el arco del columpio para las sierras de la Tarea 6 (`m.huecos_sierra: Array[Vector2]`).

- [ ] **Step 1: tests**

```gdscript
func test_bajada_baja_y_la_caida_queda_debajo() -> void:
	for semilla in 40:
		var m := Generador.generar(semilla, "bajada")
		comprobar(m.meta.y > m.inicio.y + 800.0, "semilla %d: la meta queda abajo" % semilla)
		for i in range(1, m.camino.size()):
			var d: Vector2 = m.camino[i] - m.camino[i - 1]
			comprobar(d.x > 0.0 and d.y > 0.0 and d.x <= 680.0, "semilla %d: escalón %d %s" % [semilla, i, d])
		comprobar(m.caida_y > m.limites.end.y, "semilla %d: la franja que mata está bajo todo" % semilla)
		comprobar(m.huecos_sierra.size() >= 2, "sitio para sierras")
```

- [ ] **Steps 2-5** como en la Tarea 2. Commit `Generador: tramo de bajada`.

### Task 4: Montaña, híbridos y elección por semilla

**Files:** Modify `scripts/generador.gd`; Test `tests/test_generador.gd`

**Interfaces:**
- Produces: `generar(semilla)` sin forma elige una de `FORMAS` con el `rng` de la semilla. `"montaña"` = torre corta + bajada; `"hibrido"` = 2 o 3 tramos al azar encadenados (al menos uno no horizontal). Un horizontal cuenta como forma posible.

- [ ] **Step 1: tests**

```gdscript
func test_salen_todas_las_formas_y_son_deterministas() -> void:
	var vistas := {}
	for semilla in 100:
		var m := Generador.generar(semilla)
		vistas[m.forma] = true
		comprobar(var_to_str(m) == var_to_str(Generador.generar(semilla)), "semilla %d igual en todos los PCs" % semilla)
	for f in Generador.FORMAS:
		comprobar(vistas.has(f), "sale alguna vez " + f)
```

Más: para `"montaña"` e `"hibrido"`, en 40 semillas, cada paso del camino ≤ 680 px y `caida_y > limites.end.y`.

- [ ] **Steps 2-5.** Commit `Generador: montaña, híbridos y forma elegida por la semilla`.

### Task 5: El recorrido deja de suponer horizontal

**Files:**
- Modify: `scripts/recorrido.gd` (`construir`, `_al_caer`, cámara del espectador ~línea 213, `_pintar_tema`)
- Modify: `scripts/fondo.gd` (cubrir `limites`, no solo hasta `hasta_x`), `scripts/postal.gd` (miniatura encuadrada en `limites`)
- Test: `tests/test_recorrido.gd`

**Interfaces:**
- Consumes: `inicio`, `caida_y`, `limites`, `meta_tam` del mapa.
- Produces: `func _mandar_a_mirar(cuerpo: Jugador) -> void` en `recorrido.gd` (lo que hoy hace el bloque online de `_al_caer`), llamada al caer a `Caida` **o** cuando un moco ya llegado baja más de 400 px por debajo de `meta.y` (comprobado en `_physics_process`, solo anfitrión).

- [ ] **Step 1: tests** (instanciando `recorrido_prueba.tscn` y llamando `construir` con semillas que den cada forma; buscar semillas con `Generador.generar(s).forma`)

```gdscript
func test_construir_se_adapta_a_la_forma() -> void:
	for forma in ["torre", "bajada"]:
		var s := _semilla_de(forma)
		var m := Generador.generar(s)
		var nivel := _nivel_construido(s)
		comprobar(nivel.get_node("Inicio").position == m.inicio, forma + ": salida movida")
		comprobar(nivel.get_node("Caida").position.y == m.caida_y, forma + ": caída bajo el mapa")
		comprobar(nivel.get_node("Meta/Forma").shape.size == m.meta_tam, forma + ": meta a medida (no 1200 de alto en una torre)")
		var suelo: Node2D = nivel.get_node("SueloInicio")
		comprobar(absf(suelo.position.y - m.inicio.y) < 120.0, forma + ": suelo de salida bajo los mocos")
		nivel.free()
```

`test_caben_cuatro_mocos_en_la_salida` se mantiene y se repite para la salida de una bajada.

- [ ] **Step 2:** falla. **Step 3:** implementar; la cámara del espectador "mapa entero" encuadra `limites` con el zoom que quepa. **Step 4:** código 0, y captura (sin `--headless`, 1280×720) de una torre y una bajada para mirarla. **Step 5:** commit `Recorrido: salida, caída, meta, fondo y cámara según la forma del mapa`.

### Task 6: Sierras

**Files:**
- Create: `scripts/sierra.gd` (`class_name Sierra extends Area2D`)
- Modify: `scripts/generador.gd` (campo `sierras`), `scripts/recorrido.gd` (instanciar y `_al_tocar_sierra`)
- Test: `tests/test_generador.gd`, `tests/test_mapas.gd`

**Interfaces:**
- Produces:
  - Mapa: `sierras: Array` de `{pos: Vector2, riel: Vector2, fase: float}` (`riel == Vector2.ZERO` = quieta; si no, va de `pos` a `pos + riel` y vuelve). Con su propio `rng` sembrado con `hash(Vector2i(semilla, 11))`, como `_aros`, para no cambiar el resto del mapa.
  - `Sierra`: `var riel: Vector2`, `var fase: float`, `func posicion_en(t: float) -> Vector2` (estática respecto a su origen: ida y vuelta en ~3 s), radio de colisión ~26 px. Se mueve con el `tiempo` de la ronda de cada PC; el contacto solo lo mira el anfitrión. `shortcut: la sierra en riel puede verse unas décimas desfasada en otros PCs, el anfitrión manda; si molesta, enviar el instante de arranque por rpc.`
  - `recorrido._al_tocar_sierra(cuerpo, sierra)`: salpicadura (efecto existente `"reaparecer"` u otro de `efectos.gd`) + `_volver_al_control(cuerpo)`; si el moco ya llegó (online), `_mandar_a_mirar`.

- [ ] **Step 0 (gate):** boceto de la sierra y del riel en el navegador (`.superpowers/brainstorm`), 2-3 variantes en acuarela; esperar la elección del usuario antes del Step 3.
- [ ] **Step 1: tests**

```gdscript
func test_sierras_justas() -> void:
	for semilla in 60:
		var m := Generador.generar(semilla)
		for s in m.sierras:
			for c: Vector2 in m.controles:
				comprobar(s.pos.distance_to(c) > 250.0 and (s.pos + s.riel).distance_to(c) > 250.0, "semilla %d: sierra pegada a un control" % semilla)
			comprobar(s.pos.distance_to(m.inicio) > 400.0, "semilla %d: sierra en la salida" % semilla)
	comprobar(Generador.generar(9).piezas == Generador.generar(9).piezas, "las sierras no cambian el resto del mapa")

func test_sierra_en_riel_va_y_vuelve() -> void:
	var s := Sierra.new()
	s.riel = Vector2(200, 0)
	comprobar(s.posicion_en(0.0).is_equal_approx(Vector2.ZERO), "empieza en su sitio")
	comprobar(s.posicion_en(1.5).x > 150.0, "a mitad llega al otro lado")
	comprobar(s.posicion_en(3.0).x < 50.0, "y vuelve")
	s.free()
```

Más presencia en bajada y montaña: en 40 semillas de `"bajada"` hay al menos una sierra por mapa.

- [ ] **Steps 2-5.** Commit `Sierras: quietas o en riel; tocarlas te devuelve al último control`.

### Task 7: Solo: mapa nuevo al llegar

**Files:** Modify `scripts/recorrido.gd` (`llegada`, `_unhandled_input` de R, `_al_caer`); Test `tests/test_recorrido.gd`

**Interfaces:**
- Produces: `const SEGUNDOS_MAPA_NUEVO := 3.0`; `func _mapa_nuevo_solo() -> void` = `ronda += 1`, `mejor = INF`, `construir(randi())`, `reiniciar()`. Sin red, al llegar: el moco se congela (`congelado = true`, no vuelve a ningún control si cae) y, pasados `SEGUNDOS_MAPA_NUEVO`, `_mapa_nuevo_solo()`; si antes pulsas R, se cancela el cambio y se repite el mismo mapa (mismo `semilla_actual`, `mejor` se conserva).

- [ ] **Step 1: tests** (nivel sin red; simular llegada llamando `llegada(1, 1, 12.0)`)

```gdscript
func test_solo_llegar_trae_mapa_nuevo() -> void:
	var nivel := _nivel_solo()
	var antes: int = nivel.semilla_actual
	nivel.llegada(1, 1, 12.0)
	comprobar(nivel.jugador_local().congelado, "tras la meta no te devuelve a un control")
	nivel._mapa_nuevo_solo()
	comprobar(nivel.semilla_actual != antes and nivel.mejor == INF and nivel.ronda == 2, "otro mapa, otro tema, mejor de cero")
	nivel.free()

func test_solo_r_tras_llegar_repite_el_mismo() -> void:
	var nivel := _nivel_solo()
	var antes: int = nivel.semilla_actual
	nivel.llegada(1, 1, 12.0)
	nivel.reiniciar()  # lo que hace la R
	comprobar(nivel.semilla_actual == antes and nivel.mejor == 12.0, "mismo mapa y se guarda el mejor")
	comprobar(not nivel.jugador_local().congelado, "vuelves a moverte")
	nivel.free()
```

(Que el temporizador de 3 s quede cancelado tras R: comprobarlo con una bandera o con el `SceneTreeTimer` guardado; el implementador elige.)

- [ ] **Steps 2-5.** Commit `Solo: al llegar a la meta, mapa nuevo con otra forma; R repite`.

### Task 8: El bot probador entra en el repo y se pasa por todas las formas

**Files:**
- Create: `tools/bot_mapas.gd` (desde `C:\Users\Usuario\AppData\Local\Temp\claude\C--Users-Usuario\8561f968-9bfb-4a6f-a711-2fed557ce261\scratchpad\playtest\bot.gd`), `tools/bot_mapas.sh` (desde `run.sh` del mismo sitio; ruta del script relativa al repo)
- Modify: `scripts/generador.gd` (solo medidas, si el bot lo pide)

**Interfaces:**
- Consumes: `Generador.generar(semilla, forma)`, `m.camino`, `m.sierras`, `m.limites`.
- Produces: `tools/bot_mapas.sh <salida.txt> <forma> <semillas...>` imprime una línea `BOT ... FIN|STUCK|FALL` por semilla y un resumen.

- [ ] **Step 1:** copiar bot y runner; el progreso pasa de `max_x` a "índice del siguiente techo de `m.camino`"; elegir gancho hacia el siguiente techo del camino (no solo `dx > 0`), recoger papel (`cambiar_largo`) para subir en la torre, soltarlo pronto en la bajada, y no lanzar si el arco cruza una sierra.
- [ ] **Step 2:** `tools/bot_mapas.sh out.txt <forma> 0..19` para cada forma. Objetivo: ≥ 18 de 20 terminan en cada forma (hoy 39/40 en horizontal).
- [ ] **Step 3:** si una forma no llega, ajustar medidas en el generador (separación de salientes, ancho del pozo, escalones) sin romper los tests de las Tareas 2-6; repetir Step 2.
- [ ] **Step 4:** `./run_tests.sh` → código 0.
- [ ] **Step 5:** commit `Bot probador de mapas en el repo, con torre, bajada y sierras`.

### Task 9: Prueba en partida y captura para el usuario

- [ ] **Step 1:** capturas reales (`--resolution 1280x720`, sin `--headless`) de una torre, una bajada, una montaña y un híbrido con 4 mocos, y una sierra en riel en movimiento; mirarlas.
- [ ] **Step 2:** `sim_torneo` (incluido en `run_tests.sh`) sigue OK con formas al azar.
- [ ] **Step 3:** enseñar las capturas al usuario antes de dar el bloque por cerrado.

# Fase 1: Prototipo del columpio con papel — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Objetivo:** un muñeco que lanza papel higiénico al techo, se columpia, sale disparado al soltar y cae si el papel se rasga, en un recorrido de prueba con meta y cronómetro.

**Arquitectura:** la lógica pura (aguante del papel y matemática del péndulo) vive en clases `RefCounted` sin nodos y con tests headless. El jugador es un `CharacterBody2D` que usa esas clases; el papel se dibuja con un `Line2D`. Más adelante, para el online, el anfitrión ejecutará esta misma lógica, así que la entrada se lee en un solo sitio (`_leer_input()`).

**Stack:** Godot 4.7.2 (winget `GodotEngine.GodotEngine`), GDScript, git. Sin addons: los tests son un script headless con `assert`.

**Spec:** `docs/superpowers/specs/2026-10-24-rollazo-design.md`

## Restricciones globales

- 2D de vista lateral, ratón y teclado.
- GDScript legible para alguien que viene de Java: tipos explícitos, sin trucos raros.
- Después de cada tarea, explicar al autor qué se hizo, con comparaciones con Java, y los pasos del editor uno a uno.
- Todos los números de física son **valores iniciales** que se ajustan jugando. Se agrupan con `@export` para poder cambiarlos desde el editor.
- La fase termina con una prueba en la que **el autor decide** si columpiarse ya es divertido.

## Puntos de revisión

1. Clic sin techo a tiro: no aparece cuerda, no hay error y se puede volver a intentar al instante.
2. Clic con el papel ya enganchado: se suelta el viejo y se lanza uno nuevo (no se acumulan dos).
3. Encoger el papel hasta el mínimo: el largo se detiene en `LARGO_MIN` y el muñeco no se mete dentro del techo.
4. Un impulso fuerte al soltar no atraviesa paredes, porque las colisiones van por `move_and_slide`.
5. Caer fuera del mapa reaparece en el punto de control y no deja la cuerda vieja dibujada.

---

### Tarea 1: Instalar Godot, crear el proyecto y el ejecutor de tests

**Archivos:**
- Crear: `project.godot`, `.gitignore`, `tests/run_tests.gd`, `tests/test_humo.gd`

**Interfaces:**
- Produce: `tests/run_tests.gd` (extiende `SceneTree`) recorre los `tests/test_*.gd`, llama a cada método `test_*` y termina con `quit(1)` si alguno falla. Cada test es un `RefCounted` que comprueba con `assert(cond, msg)`. Como `assert` solo funciona en debug, el ejecutor se lanza con `--headless`, que ya es debug.

- [ ] **Paso 1:** `winget install GodotEngine.GodotEngine`. Comprobar con `godot --version` → `4.7.2.stable...` (si `godot` no está en el PATH, usar la ruta que indique winget).
- [ ] **Paso 2:** `git init` en `C:\Users\Usuario\rollazo`. `.gitignore` con `.godot/` e `*.import`.
- [ ] **Paso 3:** `project.godot` con nombre "Rollazo", ventana de 1280x720, gravedad 2D por defecto y acciones de input: `lanzar` (clic izquierdo), `encoger` (W), `alargar` (S), `izquierda` (A), `derecha` (D).
- [ ] **Paso 4:** `tests/test_humo.gd` con `func test_humo(): assert(1 + 1 == 2)` y el ejecutor.
- [ ] **Paso 5:** `godot --headless --path . --script res://tests/run_tests.gd` → imprime `1 tests OK` y sale con código 0. Romper el test a propósito → sale con código ≠ 0. Restaurarlo.
- [ ] **Paso 6:** abrir el proyecto en el editor junto con el autor (guía paso a paso).
- [ ] **Paso 7:** commit `chore: proyecto Godot y ejecutor de tests`.

### Tarea 2: El papel que se rasga (`PapelRope`)

**Archivos:**
- Crear: `scripts/papel_rope.gd`, `tests/test_papel_rope.gd`

**Interfaces:**
- Produce: `class_name PapelRope extends RefCounted`
  - `var ancla: Vector2`, `var largo: float`, `var aguante: float` (de 0 a 1), `var roto: bool`
  - `const LARGO_MIN := 40.0`, `const LARGO_MAX := 420.0`
  - `func _init(ancla: Vector2, largo: float, segundos_aguante: float = 3.0)`
  - `func gastar(delta: float, tension: float) -> void`: resta `delta * (1 + tension) / segundos_aguante`, donde `tension` es 0 en reposo y crece con los tirones. Con `aguante <= 0` pone `roto = true`.
  - `func cambiar_largo(d: float) -> void`: suma `d` y limita el resultado entre `LARGO_MIN` y `LARGO_MAX`.

- [ ] **Paso 1: tests que fallan**
```gdscript
func test_se_rompe_tras_aguante_sin_tension():
    var p := PapelRope.new(Vector2.ZERO, 200.0, 3.0)
    for i in 29: p.gastar(0.1, 0.0)
    assert(not p.roto)
    p.gastar(0.2, 0.0)
    assert(p.roto)

func test_tension_rompe_antes():
    var p := PapelRope.new(Vector2.ZERO, 200.0, 3.0)
    for i in 16: p.gastar(0.1, 1.0)  # 1.5 s exactos quedarían justo en el límite por redondeo
    assert(p.roto)

func test_largo_limitado():
    var p := PapelRope.new(Vector2.ZERO, 200.0)
    p.cambiar_largo(-1000.0); assert(p.largo == PapelRope.LARGO_MIN)
    p.cambiar_largo(5000.0); assert(p.largo == PapelRope.LARGO_MAX)
```
- [ ] **Paso 2:** ejecutar los tests → FALLAN porque `PapelRope` no existe.
- [ ] **Paso 3:** implementar `scripts/papel_rope.gd`.
- [ ] **Paso 4:** ejecutar los tests → PASAN.
- [ ] **Paso 5:** commit `feat: papel con aguante que se rasga`.

### Tarea 3: Matemática del péndulo (`Pendulo`)

**Archivos:**
- Crear: `scripts/pendulo.gd`, `tests/test_pendulo.gd`

**Interfaces:**
- Produce: `class_name Pendulo extends RefCounted` con métodos estáticos:
  - `static func restringir(pos: Vector2, vel: Vector2, ancla: Vector2, largo: float) -> Array` devuelve `[pos_nueva, vel_nueva]`. Si `pos.distance_to(ancla) > largo`, coloca `pos` sobre el círculo de radio `largo` y quita a `vel` su componente radial hacia fuera (la tangencial se conserva). Si está dentro, lo devuelve sin cambios: la cuerda no empuja.
  - `static func tension(vel_radial_quitada: float) -> float` devuelve `clamp(vel_radial_quitada / 600.0, 0.0, 2.0)`.

- [ ] **Paso 1: tests que fallan**
```gdscript
func test_fuera_del_radio_se_recoloca():
    var r := Pendulo.restringir(Vector2(0, 300), Vector2(0, 100), Vector2.ZERO, 200.0)
    assert(r[0].is_equal_approx(Vector2(0, 200)))
    assert(r[1].is_equal_approx(Vector2.ZERO))

func test_conserva_velocidad_tangencial():
    var r := Pendulo.restringir(Vector2(0, 250), Vector2(150, 80), Vector2.ZERO, 200.0)
    assert(is_equal_approx(r[1].x, 150.0))
    assert(is_equal_approx(r[1].y, 0.0))

func test_dentro_del_radio_no_cambia():
    var r := Pendulo.restringir(Vector2(0, 100), Vector2(5, 5), Vector2.ZERO, 200.0)
    assert(r[0] == Vector2(0, 100) and r[1] == Vector2(5, 5))
```
- [ ] **Paso 2:** ejecutar → FALLAN.
- [ ] **Paso 3:** implementar `scripts/pendulo.gd`.
- [ ] **Paso 4:** ejecutar → PASAN.
- [ ] **Paso 5:** commit `feat: restricción de péndulo`.

### Tarea 4: El jugador que lanza, se columpia y sale disparado

**Archivos:**
- Crear: `scenes/jugador.tscn`, `scripts/jugador.gd`

**Interfaces:**
- Consume: `PapelRope`, `Pendulo.restringir`, `Pendulo.tension`.
- Produce: `class_name Jugador extends CharacterBody2D`
  - `signal papel_roto`
  - `var papel: PapelRope` (`null` si no está enganchado)
  - `func reaparecer(pos: Vector2) -> void`: mueve al jugador, pone la velocidad a 0 y suelta el papel.
  - `func _leer_input() -> Dictionary` devuelve `{lanzar: bool, soltar: bool, apunta: Vector2, eje_x: float, eje_largo: float}`. Es el único sitio donde se lee la entrada (en la fase 2 la mandarán los clientes).
- La escena tiene un `CollisionShape2D` de cápsula, un `Sprite2D`/`Polygon2D` provisional y un `RayCast2D` para apuntar.
- Valores `@export` iniciales: `gravedad = 1400`, `control_aire = 600`, `impulso_soltar = 1.15` (multiplica la velocidad al soltar), `velocidad_encoger = 300`.

- [ ] **Paso 1:** implementar `_physics_process`:
  1. leer la entrada;
  2. `lanzar` pulsado → raycast desde el jugador hacia `apunta` con alcance `LARGO_MAX`. Si choca con el grupo `"enganchable"`, crea `PapelRope.new(punto, distancia)`, sustituyendo el anterior si lo había. Si no choca, no hace nada;
  3. `lanzar` soltado → `velocity *= impulso_soltar` y `papel = null`;
  4. aplicar gravedad y control en el aire;
  5. `move_and_slide()`;
  6. con papel: `Pendulo.restringir`, `papel.gastar(delta, tension)`, `papel.cambiar_largo(eje_largo * velocidad_encoger * delta)`. Si `papel.roto`, emitir `papel_roto` y poner `papel = null`.
- [ ] **Paso 2:** escena temporal con un techo `StaticBody2D` del grupo `"enganchable"`. Darle a Play junto con el autor y comprobar: engancha, se columpia, sale disparado al soltar y cae cuando se rasga. Comprobar también los puntos de revisión 1 a 4.
- [ ] **Paso 3:** commit `feat: jugador con columpio de papel`.

### Tarea 5: Que el papel se vea y avise

**Archivos:**
- Crear: `scripts/papel_visual.gd` (en un `Line2D` hijo del jugador)
- Modificar: `scenes/jugador.tscn`

**Interfaces:**
- Consume: `Jugador.papel`, `Jugador.papel_roto`.
- Cada frame, el `Line2D` va del jugador a `papel.ancla`, o se vacía si `papel == null`. El color va del blanco (`aguante` 1) al rojo (0). Por debajo de 0.3 tiembla un poco. Al recibir `papel_roto` aparecen unos trocitos de papel (`CPUParticles2D`) y suena un "rasss" si hay un sonido gratuito a mano (opcional).
- El muñeco se ve blando: se inclina según su velocidad y se estira un poco al salir disparado (escala en el `Sprite2D`).

- [ ] **Paso 1:** implementarlo.
- [ ] **Paso 2:** Play con el autor y comprobar que se nota antes de que el papel se rompa.
- [ ] **Paso 3:** commit `feat: papel visible con aviso de rotura`.

### Tarea 6: Recorrido de prueba con meta, cronómetro y reaparición

**Archivos:**
- Crear: `scenes/recorrido_prueba.tscn`, `scripts/recorrido.gd`, `scenes/hud.tscn`, `scripts/hud.gd`
- Modificar: `project.godot` (escena principal = `recorrido_prueba.tscn`)

**Interfaces:**
- Consume: `Jugador.reaparecer(pos)`.
- `recorrido.gd`: tiene `Area2D` de puntos de control (guarda el último), un `Area2D` de "caída" bajo el mapa que llama a `reaparecer(ultimo_control)`, y un `Area2D` de meta que para el cronómetro y muestra el tiempo. Con R se reinicia todo al instante.
- `hud.gd`: muestra el cronómetro `00.00` y el mejor tiempo de la sesión.
- Recorrido de 30 a 60 segundos: techos a distintas alturas, huecos que obligan a encadenar 3 o 4 columpios y un tramo con atajo arriesgado (techo lejano que exige papel casi en `LARGO_MAX`).

- [ ] **Paso 1:** implementarlo y montar el recorrido.
- [ ] **Paso 2:** Play: completar el recorrido, caer y reaparecer (punto de revisión 5), y reiniciar con R.
- [ ] **Paso 3:** `godot --headless --path . --script res://tests/run_tests.gd` → todos los tests OK.
- [ ] **Paso 4:** commit `feat: recorrido de prueba con meta y cronómetro`.

### Tarea 7: Prueba del autor (puerta de la fase)

- [ ] **Paso 1:** el autor juega al menos 10 intentos. Se le pregunta: ¿quieres jugar otra?, ¿qué te frustra?, ¿el atajo merece la pena?
- [ ] **Paso 2:** ajustar los `@export` (gravedad, impulso, aguante, alcance) según lo que diga, y repetir.
- [ ] **Paso 3:** el autor dice "ya es divertido" → commit `chore: ajustes tras prueba` y se pasa al plan de la fase 2 (online). Si no lo dice, se sigue ajustando aquí.

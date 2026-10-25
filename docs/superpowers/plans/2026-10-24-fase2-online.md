# Fase 2: Online para 4 — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 4 mocos en la misma carrera online: un anfitrión y 3 amigos que se cortan el papel, se agarran, chocan y compiten por llegar primero.

**Architecture:** el multijugador integrado de Godot (ENet) con **el anfitrión como autoridad**. Solo el anfitrión simula la física. Los clientes envían su entrada con un RPC cada frame y reciben posiciones y estado del papel con `MultiplayerSynchronizer`. Los efectos se replican con un RPC. Sin red, `OfflineMultiplayerPeer` hace que `multiplayer.is_server()` sea true y el id local 1, así que el modo de un jugador y las simulaciones actuales siguen funcionando sin cambios.

**Tech Stack:** Godot 4.7.2, GDScript, ENetMultiplayerPeer, MultiplayerSpawner/MultiplayerSynchronizer, Tailscale para jugar por internet.

**Spec:** `docs/superpowers/specs/2026-10-24-rollazo-design.md`

## Restricciones globales

- 4 jugadores es el caso normal y el máximo (`Red.MAX_JUGADORES = 4`).
- El anfitrión decide la física y los demás le envían sus controles. El código de red queda separado (`scripts/red.gd` y los RPC del Jugador) para poder añadir predicción en el cliente más adelante.
- Estilo: moco gotero, ciudad de neón y **efectos sin texto**. Cada jugador es un moco de un color pastel: menta, rosa, lavanda y melocotón.
- Puerto `7777`. Conexión por IP; para internet, la IP de Tailscale.
- Las simulaciones y tests actuales tienen que seguir en verde: el modo sin red se comporta igual que en la fase 1.
- Explicar al autor cada tarea comparando con Java.

## Puntos de revisión

1. Un 5.º jugador intenta unirse: se le rechaza y los 4 que juegan no notan nada. → Tarea 1 (manual en la tarea 8, porque ENet no permite comprobar el límite sin abrir 4 clientes).
2. Un cliente se desconecta a mitad de carrera: su moco desaparece y la carrera puede terminar con los que quedan. → Tareas 2 y 7.
3. El anfitrión cierra: los clientes vuelven al menú con el mensaje "El anfitrión se ha ido". → Tarea 1.
4. Dos jugadores se cortan el papel en el mismo frame: los dos papeles desaparecen y no hay error. → Tarea 5.
5. Si reaparece el que lleva a otro agarrado, o el agarrado, el agarre se suelta. → Tarea 6.

---

### Task 1: Red (crear partida y unirse) y menú

**Archivos:**
- Crear: `scripts/red.gd` (autoload `Red`), `scenes/menu.tscn`, `scripts/menu.gd`, `tests/test_red.gd`, `tests/sim_red_anfitrion.gd`, `tests/sim_red_cliente.gd`
- Modificar: `project.godot` (autoload `Red` y main_scene = `menu.tscn`), `run_tests.sh`

**Interfaces:**
- Produce `Red` (autoload, `extends Node`):
  - `const PUERTO := 7777`, `const MAX_JUGADORES := 4`
  - `signal jugadores_cambiaron`, `signal desconectado(motivo: String)`
  - `var ids: Array[int]`: ids conectados, incluido el anfitrión (1). Solo es fiable en el anfitrión.
  - `func crear_partida(puerto: int = PUERTO) -> Error` crea `ENetMultiplayerPeer.create_server(puerto, MAX_JUGADORES - 1)` y deja `ids = [1]`.
  - `func unirse(ip: String, puerto: int = PUERTO) -> Error`
  - `func salir() -> void` vuelve a `OfflineMultiplayerPeer` y limpia `ids`.
  - Si el anfitrión se cae (`server_disconnected`), emite `desconectado("El anfitrión se ha ido")` y llama a `salir()`.
- Produce el menú: `LineEdit` IP (por defecto `127.0.0.1`), botones **Crear**, **Unirse** y **Empezar** (este solo lo ve el anfitrión), y un `Label` con el estado ("Jugadores: 2/4"). Empezar llama a `Red.empezar_carrera()`: un `@rpc("authority", "call_local", "reliable")` que cambia todos a `res://scenes/recorrido_prueba.tscn`.

- [ ] **Paso 1: tests que fallan.** En `test_red.gd`: `test_sin_red_es_anfitrion_offline` comprueba que `Red` existe como autoload y que, sin conectar, `multiplayer.get_unique_id() == 1`. En `test_crear_partida`: `Red.crear_partida(7790) == OK` y `Red.ids == [1]`, y después `Red.salir()`. Simulación entre dos procesos: `sim_red_anfitrion.gd` crea la partida en 7791 y espera un cliente (máximo 10 s), y `sim_red_cliente.gd` se une a `127.0.0.1:7791`. El anfitrión imprime `sim_red: OK` si `Red.ids.size() == 2`. `run_tests.sh` lanza al anfitrión en segundo plano y al cliente después, y espera el código de salida del anfitrión.
- [ ] **Paso 2:** `./run_tests.sh` → FALLA (no compila / `sim_red` FALLO).
- [ ] **Paso 3:** implementar `red.gd`, el menú y el autoload.
- [ ] **Paso 4:** `./run_tests.sh` → todo OK, incluida la línea `sim_red: OK`.
- [ ] **Paso 5:** commit `feat: red (crear/unirse) y menú`.

### Task 2: Un moco por jugador, sincronizado

**Archivos:**
- Modificar: `scenes/jugador.tscn` (añadir `MultiplayerSynchronizer`), `scripts/jugador.gd`, `scripts/moco_visual.gd`, `scripts/papel_visual.gd`, `scenes/recorrido_prueba.tscn` (quitar el Jugador fijo y añadir `Jugadores` + `MultiplayerSpawner`), `scripts/recorrido.gd`, los tests `sim_*.gd` que usen `nivel.get_node("Jugador")`
- Crear: `tests/test_multijugador.gd`

**Interfaces:**
- `Jugador`:
  - `const COLORES := [Color("6cc3b0"), Color("ef8fae"), Color("a99be0"), Color("f5b38a")]` (menta, rosa, lavanda, melocotón)
  - `var id_dueno: int` (sale de `name.to_int()`; 1 si el nombre no es numérico)
  - Estado sincronizado, que es lo único que leen los visuales en los clientes: `papel_activo: bool`, `papel_ancla: Vector2`, `papel_aguante: float`. El anfitrión lo actualiza al final de `_physics_process`. El `MultiplayerSynchronizer` replica `position`, `velocity`, `papel_activo`, `papel_ancla` y `papel_aguante`.
- `MocoVisual`: `var color: Color`, que lo fija el jugador según `COLORES[indice]`.
- `recorrido.gd`:
  - `func crear_jugador(id: int, indice: int) -> Jugador`: la función del spawner. Pone `name = str(id)`, la posición `Inicio + Vector2(indice * 50, 0)` y el color de su índice, y añade una `Camera2D` solo si `id == multiplayer.get_unique_id()`.
  - En el anfitrión: crea un jugador por cada `Red.ids` (offline: `[1]`) y borra el de un id que se desconecta.
  - `func jugadores() -> Array[Jugador]`
- Los sims cambian `get_node("Jugador")` por `get_node("Jugadores/1")`.

- [ ] **Paso 1: tests que fallan.** `test_multijugador.gd::test_colores_distintos` comprueba que `Jugador.COLORES` tiene 4 colores distintos. Ampliar `sim_red_anfitrion.gd`: tras conectarse el cliente, carga el recorrido y comprueba que existen `Jugadores/1` y `Jugadores/<id_cliente>`. Ampliar `sim_red_cliente.gd`: comprueba que ve 2 hijos en `Jugadores` y que tiene una sola `Camera2D`, la del suyo. Desconexión (punto de revisión 2): el cliente sale y el anfitrión comprueba que `Jugadores/<id_cliente>` desaparece antes de 2 s.
- [ ] **Paso 2:** `./run_tests.sh` → FALLA.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** `./run_tests.sh` → OK, también los 4 sims de la fase 1 actualizados.
- [ ] **Paso 5:** commit `feat: un moco por jugador sincronizado`.

### Task 3: Entrada remota (los clientes controlan su moco)

**Archivos:**
- Modificar: `scripts/jugador.gd`, `scripts/efectos.gd`, `tests/sim_red_*.gd`

**Interfaces:**
- `Jugador`:
  - `@rpc("any_peer", "call_remote", "unreliable_ordered") func recibir_input(e: Dictionary) -> void`: solo lo acepta el anfitrión, y solo si `multiplayer.get_remote_sender_id() == id_dueno`. Los eventos de un frame (`lanzar`, `saltar`, `cortar`, `agarrar`) se **acumulan con OR** hasta que `_physics_process` los consume, para no perder un clic entre dos paquetes. Los ejes y `apunta` se sobrescriben.
  - `_leer_input()`: si `id_dueno == multiplayer.get_unique_id()`, lee el teclado y el ratón como ahora. Si no, devuelve la entrada remota pendiente y la limpia.
  - `_physics_process`: el cliente dueño envía `recibir_input.rpc_id(1, e)` y **retorna sin simular**. Solo el anfitrión simula.
  - `@rpc("authority", "call_local", "unreliable") func efecto(tipo: String, pos: Vector2) -> void` emite `signal efecto_red(tipo: String, pos: Vector2)`. `tipo` es uno de `"salpicar"`, `"temblar"` o `"romper"`.
- `efectos.gd`: escucha `efecto_red` en lugar de las señales de física, para que los efectos salgan en todas las pantallas. El temblor solo se aplica si el jugador es el local.

- [ ] **Paso 1: test que falla.** `sim_red_cliente.gd` mantiene `Input.action_press("derecha")` 1 s, y el anfitrión comprueba que `Jugadores/<id_cliente>` se movió más de 100 px a la derecha. Además, el cliente ve en su pantalla el moco movido más de 100 px (sincronización).
- [ ] **Paso 2:** `./run_tests.sh` → FALLA (el moco remoto no se mueve).
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** `./run_tests.sh` → OK.
- [ ] **Paso 5:** commit `feat: los clientes controlan su moco`.

### Task 4: Choques entre mocos

**Archivos:**
- Crear: `scripts/rebote.gd`, `tests/test_rebote.gd`, `tests/sim_choque.gd`
- Modificar: `scripts/jugador.gd`, `scenes/jugador.tscn` (capa de colisión 2 y máscara 1+2), `project.godot` (acción `agarrar` = E y `cortar` = clic derecho, para las tareas 5 y 6)

**Interfaces:**
- `class_name Rebote extends RefCounted`, `static func calcular(v1: Vector2, v2: Vector2, normal: Vector2, rebote: float = 1.2) -> Array` devuelve `[v1_nueva, v2_nueva]`: intercambia las componentes de velocidad sobre la normal multiplicadas por `rebote` y conserva las tangenciales.
- `Jugador`: `const VELOCIDAD_CHOQUE := 300.0`. Tras `move_and_slide`, si choca con otro `Jugador` con una velocidad relativa mayor, aplica `Rebote.calcular` a los dos y llama a `efecto.rpc("salpicar", punto)` y `efecto.rpc("temblar", punto)`.

- [ ] **Paso 1: tests que fallan.**
```gdscript
func test_choque_frontal_intercambia_y_amplifica():
    var r := Rebote.calcular(Vector2(400, 0), Vector2(-100, 0), Vector2(1, 0))
    comprobar(r[0].x < 0 and r[1].x > 0, "salen en direcciones opuestas")
    comprobar(is_equal_approx(r[1].x, 480.0), "el golpeado sale a 400*1.2")
func test_conserva_tangencial():
    var r := Rebote.calcular(Vector2(400, 50), Vector2(0, 0), Vector2(1, 0))
    comprobar(is_equal_approx(r[0].y, 50.0), "tangencial intacta")
```
`sim_choque.gd`: dos jugadores (ids 1 y 2) en `prueba_columpio` a 200 px; el 1 lanzado a 600 px/s contra el 2. Tras 30 frames, el 2 se movió más de 60 px y el 1 rebotó.
- [ ] **Paso 2:** ejecutar → FALLA.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** ejecutar → OK.
- [ ] **Paso 5:** commit `feat: choques entre mocos`.

### Task 5: Cortar el papel de otro

**Archivos:**
- Crear: `scripts/geometria.gd`, `tests/test_geometria.gd`, `tests/sim_cortar.gd`
- Modificar: `scripts/jugador.gd`

**Interfaces:**
- `class_name Geometria extends RefCounted`, `static func distancia_a_segmento(p: Vector2, a: Vector2, b: Vector2) -> float`.
- `Jugador`: `const RADIO_CORTE := 50.0`. Con la entrada `cortar`, el anfitrión recorre los demás jugadores y, si uno tiene `papel != null` y `distancia_a_segmento(mi_pos, su_pos, su_ancla) < RADIO_CORTE`, le pone `papel = null` y emite el efecto `"romper"`. Para eso existe `func cortar_papel() -> void` en el jugador afectado.

- [ ] **Paso 1: tests que fallan.** `distancia_a_segmento(Vector2(0,10), Vector2(-5,0), Vector2(5,0)) ≈ 10`; fuera del segmento devuelve la distancia al extremo más cercano (`(20,0)` frente a `(-5,0)-(5,0)` da 15); con un segmento degenerado (`a == b`) devuelve la distancia al punto. `sim_cortar.gd`: el 2 colgado de un techo y el 1 junto a su papel pulsa cortar; el 2 queda con `papel == null`. Mismo frame (punto de revisión 4): los dos colgados y cerca, los dos pulsan cortar a la vez; los dos papeles quedan a null y no hay errores en la salida.
- [ ] **Paso 2:** ejecutar → FALLA.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** ejecutar → OK.
- [ ] **Paso 5:** commit `feat: cortar el papel de otro`.

### Task 6: Agarrarse a otro

**Archivos:**
- Crear: `tests/sim_agarrar.gd`
- Modificar: `scripts/jugador.gd`, `scripts/papel_visual.gd` (dibuja un hilo de moco corto hacia el agarrado)

**Interfaces:**
- `Jugador`:
  - `var agarrado_a: Jugador = null`, `var carga := 0`
  - `const DIST_AGARRE := 60.0`, `const LARGO_AGARRE := 45.0`, `const PESO_POR_CARGA := 0.5`
  - Con la entrada `agarrar`: si `agarrado_a` es null, se agarra al jugador más cercano a menos de `DIST_AGARRE` y suma 1 a su `carga`; si ya está agarrado, se suelta. También se suelta al saltar.
  - Mientras está agarrado: `Pendulo.restringir(pos, vel, agarrado_a.global_position, LARGO_AGARRE)`.
  - La gravedad de cada jugador se multiplica por `(1 + PESO_POR_CARGA * carga)`.
  - `func soltar_agarre() -> void` resta la carga del otro. `reaparecer()` suelta el agarre propio **y** el de quien esté agarrado a este jugador (punto de revisión 5).
- Sincronizar `agarre_activo: bool` y `agarre_pos: Vector2` para el dibujo.

- [ ] **Paso 1: test que falla.** `sim_agarrar.gd`: el 1 colgado y el 2 a 40 px pulsa agarrar. Comprobaciones: `j2.agarrado_a == j1` y `j1.carga == 1`. Al mover el 1, el 2 lo sigue a menos de 60 px. El 1 cae más rápido que solo (la `velocity.y` tras 10 frames sin papel es mayor que la de una referencia sin carga). `j1.reaparecer(...)` deja `j2.agarrado_a == null` y `j1.carga == 0`.
- [ ] **Paso 2:** ejecutar → FALLA.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** ejecutar → OK.
- [ ] **Paso 5:** commit `feat: agarrarse a otro moco`.

### Task 7: Carrera con posiciones y rondas

**Archivos:**
- Crear: `scripts/clasificacion.gd`, `tests/test_clasificacion.gd`
- Modificar: `scripts/recorrido.gd`, `scripts/hud.gd`, `scenes/hud.tscn`, `tests/sim_recorrido.gd`

**Interfaces:**
- `class_name Clasificacion extends RefCounted`:
  - `const PUNTOS := [10, 6, 3, 1]`
  - `func registrar_llegada(id: int) -> int` devuelve el puesto, empezando en 1. Si el id ya llegó, devuelve su puesto sin duplicarlo.
  - `func todos_llegaron(ids_en_juego: Array[int]) -> bool`
  - `func puntos_de(id: int) -> int`
  - `var puntos_totales: Dictionary` (de id a puntos), que se mantiene entre rondas
  - `func nueva_ronda() -> void`
- `recorrido.gd` (en el anfitrión): la meta registra la llegada de cada Jugador. La ronda acaba cuando `todos_llegaron(Red.ids actuales)` o 20 s después del primero. Entonces se muestran los resultados 5 s con `mostrar_resultados.rpc(...)` y empieza otra ronda (todos reaparecen en el inicio). El reinicio con R queda **solo para el modo sin red**.
- HUD: el puesto propio al llegar ("1.º", "2.º"...) y una tabla de resultados con colores de moco y puntos totales. Sin onomatopeyas.

- [ ] **Paso 1: tests que fallan.**
```gdscript
func test_puestos_en_orden():
    var c := Clasificacion.new()
    comprobar(c.registrar_llegada(5) == 1 and c.registrar_llegada(2) == 2, "orden de llegada")
    comprobar(c.registrar_llegada(5) == 1, "no se duplica")
func test_puntos_y_rondas():
    var c := Clasificacion.new()
    c.registrar_llegada(1); c.registrar_llegada(2)
    c.nueva_ronda(); c.registrar_llegada(2)
    comprobar(c.puntos_totales[2] == 16 and c.puntos_totales[1] == 10, "10+6 y 10")
func test_todos_llegaron_ignora_desconectados():
    var c := Clasificacion.new()
    c.registrar_llegada(1)
    comprobar(c.todos_llegaron([1]) and not c.todos_llegaron([1, 3]), "solo cuenta los que siguen")
```
Actualizar `sim_recorrido.gd` (sin red): al llegar a la meta, el HUD muestra "1.º" y R sigue reiniciando.
- [ ] **Paso 2:** ejecutar → FALLA.
- [ ] **Paso 3:** implementar.
- [ ] **Paso 4:** ejecutar → OK.
- [ ] **Paso 5:** commit `feat: carrera con posiciones y rondas`.

### Task 8: Jugar con los amigos (puerta de la fase)

**Archivos:**
- Crear: `docs/jugar-online.md`, `export_presets.cfg` (preset "Windows Desktop" hacia `build/Rollazo.exe`)
- Modificar: `.gitignore` (`build/`)

- [ ] **Paso 1:** instalar las plantillas de exportación de Godot 4.7.2 (en el editor, *Editor → Gestionar plantillas de exportación*, paso a paso con el autor) y exportar `build/Rollazo.exe`. Comprobar que el `.exe` arranca y muestra el menú.
- [ ] **Paso 2:** `docs/jugar-online.md`, para el autor y sus amigos, en pasos cortos: instalar Tailscale, unirse a la misma red, que el anfitrión pulse Crear y comparta su IP `100.x.y.z`, y que los demás la peguen en Unirse.
- [ ] **Paso 3:** prueba en local con 4 instancias en el mismo PC (anfitrión y 3 clientes en `127.0.0.1`), cortando, agarrando y chocando. Comprobación manual del punto de revisión 1: abrir una 5.ª instancia y que **no** entre. Punto de revisión 3: cerrar el anfitrión y que los clientes vuelvan al menú con el mensaje.
- [ ] **Paso 4:** partida real con los 3 amigos. Preguntas: ¿os reísteis?, ¿hubo retraso en el columpio?, ¿qué fue lo más divertido o frustrante? Si hay retraso, se planifica la predicción en el cliente (la red está separada para eso).
- [ ] **Paso 5:** commit `chore: exportación y guía para jugar online`.

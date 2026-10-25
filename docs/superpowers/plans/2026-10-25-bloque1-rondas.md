# Bloque 1 (rondas, marcador, espectador, configuración): plan

> Ejecución: Native (executing-plans), como en la fase 2.

**Spec:** `docs/superpowers/specs/2026-10-25-bloque1-rondas-design.md`

## Global Constraints
- Godot 4.7.2, GDScript tipado, comentarios en español comparando con Java donde ayude.
- Estética: acuarela pastel, sin contornos, Bangers, paleta de `Acuarela` y `Jugador.COLORES`.
- El anfitrión decide todo (rpc "authority"); lo que manda un cliente se valida.
- Tests: `./run_tests.sh` debe quedar en verde (unitarios + simulaciones).

## Review Focus
1. Un jugador se desconecta a mitad del torneo: el marcador y el fin de ronda no deben romperse.
2. El espectador al empezar la ronda siguiente vuelve a ser visible, a moverse y a tener su cámara.
3. Un cliente manda `marcar_listo` con basura: se ignora.
4. Cambiar la configuración borra los listos (nadie empieza con opciones que no vio).
5. Torneo terminado: volver a la sala sin desconectar y poder empezar otro.

### Task 1: Clasificacion por victorias
- Modify `scripts/clasificacion.gd`: `registrar_llegada(id, t := 0.0) -> int`,
  `cerrar_ronda(ids: Array[int], t_fin: float)`, `orden(ids) -> Array[int]`,
  `gana_por_tiempo(ids) -> bool`; datos `victorias`, `tiempo_total`. Quitar PUNTOS.
- Test `tests/test_clasificacion.gd`: solo el 1.º suma victoria; el que no llega suma t_fin;
  orden por victorias y luego tiempo; gana_por_tiempo.

### Task 2: Config y listos en Red
- `Red.config := {"rondas": 5}`, `Red.RONDAS := [3, 5, 7, 10]`, `Red.listos := {}`,
  `poner_rondas(n)` (anfitrión), `marcar_listo(si: bool)` rpc any_peer, `todos_listos() -> bool`,
  señal `config_cambiada`. Al conectar alguien, el anfitrión le manda config y listos.
- Test `tests/test_red.gd`: por defecto 5; todos_listos; poner_rondas borra listos.

### Task 3: Menú "LA PARTIDA" + Postal
- Create `scripts/postal.gd` (`class_name Postal extends Control`): papel crema girado, miniatura
  pintada de `Generador.generar(semilla)`, título; filas opcionales [color, victorias].
- Menu: online, sección Partida con rondas ‹ n › (solo anfitrión), postal de LA AZOTEA, botón LISTO
  (clientes); Empezar solo con todos listos. Sala: ✓ bajo los listos.
- Test `tests/test_red.gd`: el cliente no ve los botones de rondas; sala muestra ✓.

### Task 4: Rondas, postal, marcador, fin de torneo, espectador
- Recorrido: `ronda`, `nombres`, `llegados`, `espectadores`; postal 2,5 s con los mocos quietos
  (`Jugador.congelado`); Tab muestra `hud.marcador(filas)`; `_terminar_ronda` con cerrar_ronda y
  fin de torneo (`fin_torneo` rpc → `volver_a_sala` rpc sin desconectar); caída tras meta →
  `espectador` rpc, cámara de espectador con clic izquierdo.
- Tests: test_feedback (marcador con filas), test_clasificacion; sims de red ajustadas a la postal.

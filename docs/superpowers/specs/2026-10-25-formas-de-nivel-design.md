# Formas de nivel: torre, bajada, montaña e híbridos, con sierras

Sale de una partida en solitario (2026-10-25): el usuario siente que todos los mapas son "el
mismo pasillo horizontal" aunque cambie el tema. Quiere que los niveles se diferencien por su
**estructura**, no solo por el color. El podio con copa y ramo queda para un bloque posterior.

## Por qué

Hoy `Generador.generar(semilla)` siempre produce lo mismo en forma: de izquierda a derecha,
techos a 520-640 px uno del otro y a 250-380 de altura, descansos cada 3-4 techos, meta al
final (x ≥ 7600). Los temas (azotea, noche, cueva, muelle, jungla) solo cambian el dibujo. Tras
unas cuantas rondas todo se siente igual. El éxito es que dos rondas seguidas del mismo tema se
sientan como niveles distintos.

## Diseños elegidos por el usuario (boceto `.superpowers/brainstorm/.../formas-nivel.html`)

Le gustaron las cuatro formas y pidió que también haya **híbridos**:

- **A · Horizontal**: como ahora.
- **B · Torre**: un pozo estrecho entre dos paredes; te columpias de un lado a otro para
  **subir**. Si fallas, caes un buen trozo (no al vacío: a lo que haya debajo).
- **C · Bajada**: empiezas arriba y bajas en escalera; el truco es frenar. Hay sierras.
- **D · Montaña**: un muro en medio; se sube por un lado, se pasa por arriba y se baja por el
  otro entre sierras.
- **Híbridos**: un mismo recorrido encadena tramos de distinta forma (p. ej. horizontal →
  torre → bajada).

## Qué hace

1. **La forma sale al azar de la semilla.** Cada vez que se genera un mapa, el generador elige
   la forma (A, B, C, D o un híbrido) a partir de la semilla. Los temas no cambian: el mismo
   tema de cueva puede salir como torre un día y como bajada otro. Igual en solo y online: la
   semilla sigue siendo lo único que viaja por la red, y los 4 PCs construyen el mismo mapa.
2. **Sierras.** Sierras circulares que giran; algunas quietas y otras que se mueven de un lado a
   otro por un riel. Tocarla: el moco salpica y **vuelve al último punto de control**, igual que
   al caer. Lo decide el anfitrión, como la caída y los aros (ver `_al_tocar_aro`). Aparecen en
   cualquier forma, con más presencia en bajada y montaña.
3. **Solo: al llegar a la meta.** Hoy, practicando solo, si cruzas la meta y luego te caes,
   vuelves al último control. Cambia a: al cruzar la meta ya no te devuelve a ningún control;
   sale tu tiempo y, tras un momento, empieza solo un **mapa nuevo con otra forma al azar**.
   La **R** sigue repitiendo el mismo mapa (para mejorar tu tiempo).
4. **Siempre se puede pasar.** Ninguna forma puede generar un tramo imposible. Igual que ahora,
   la regla es que cada techo del camino quede al alcance del anterior y desde cada descanso se
   alcance el siguiente; para las formas verticales la regla se adapta a subir y bajar.

## No es objetivo

- Niveles hechos a mano o una lista de niveles que se desbloquean (el usuario prefirió que la
  variedad salga del azar dentro de cada mapa).
- Temas nuevos, portales, más poderes, el podio (bloques aparte).
- Cambiar los controles del moco o la física del papel.

## Lo que lo haría un fracaso aunque funcione

- Un mapa imposible o con un tramo que el bot no puede pasar (ya pasó con los embudos; por eso
  existe el bot probador).
- Una sierra que mata sin verse venir (aparece en pantalla de repente, sin sitio para
  reaccionar) o que te devuelve a un control muy lejano.
- Que la cámara no deje ver hacia dónde hay que ir en un tramo vertical.
- Que las formas nuevas se vean "de IA" o rompan la acuarela pastel sin contornos.

## Restricciones del proyecto

- Godot 4.7.2, GDScript, 2D. Estilo acuarela pastel sin contornos (`Acuarela`, `Tinta`); las
  sierras se dibujan con código como los mocos, nada de sprites genéricos. El usuario ve
  bocetos en el navegador antes de cambios de arte: la sierra necesita su boceto.
- Determinista por semilla (`RandomNumberGenerator` con `seed`): mismo mapa en los 4 PCs.
  Las sierras que se mueven deben estar en la misma posición en todos los PCs (p. ej. calculada
  con el reloj de la ronda, no con un azar por PC).
- Lo que hay fijo en `recorrido_prueba.tscn` y asume horizontal: `Inicio` y `SueloInicio`
  (salida abajo a la izquierda), `Caida` (franja en y = 1200 que mata), la cámara del espectador
  "mapa entero" (`recorrido.gd` ~línea 213, encuadra de x=0 a la meta), `Fondo`/`Superficie`
  (`fondo.gd`, cubren en x hasta `hasta_x`), la miniatura de la postal (`postal.gd` pinta el
  mapa de la semilla). Todo eso tiene que funcionar con mapas que crecen hacia arriba o abajo.
- Tests (`./run_tests.sh`): `test_generador.gd` comprueba hoy reglas horizontales (meta.x ≥
  7500, saltos con d.x > 0, y entre 240 y 420). Hay que adaptarlas por forma, no borrarlas.
  El bot probador de mapas (scratchpad `playtest/run.sh`, terminaba 39 de 40 semillas) debe
  seguir terminando casi todas las semillas en todas las formas.

## Decisiones tomadas por Claude (el usuario las aceptó o delegó)

- Sierra: gira; quietas o en riel; al tocarla, salpicadura y vuelta al último control
  (propuesto por Claude, aceptado por el usuario).
- Final en solo: tiempo en pantalla y mapa nuevo tras un momento; R repite (propuesto por
  Claude, aceptado).
- Mapa nuevo en solo: también cambia el tema (sigue la rotación de mapas), y el "mejor tiempo"
  es por mapa: se conserva con R y se reinicia al pasar a un mapa nuevo (decisión de Claude).
- El bot probador de mapas entra en el repo (`tests/` o `tools/`) y se adapta a las formas
  verticales y a las sierras, como fase propia del plan: hoy vive en un scratchpad temporal y
  solo sabe ir hacia la derecha (decisión de Claude).
- Las sierras que se mueven usan un instante de inicio que manda el anfitrión, para estar en el
  mismo sitio en los 4 PCs (decisión de Claude).
- Tras cruzar la meta online, pasar a espectador no puede depender solo de caer a la franja
  `Caida`: en una torre se cae sobre un saliente. Basta con caer por debajo de la meta o tocar
  una sierra (decisión de Claude; detalle para quien construya).

## Lo que queda para quien lo construya

- Cómo se reparte la probabilidad entre formas e híbridos, y el largo de cada tramo.
- Medidas de la torre (ancho del pozo, separación vertical de techos) mientras el bot la pase.
- Dónde se colocan descansos y controles en tramos verticales.
- Cómo se adapta la cámara del jugador (si hace falta mirar más hacia arriba o abajo) y la del
  espectador.
- El dibujo exacto de la sierra y del riel (con boceto previo para el usuario).

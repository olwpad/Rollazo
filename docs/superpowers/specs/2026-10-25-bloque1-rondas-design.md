# Bloque 1: espectador, rondas, marcador y configuración de partida

Sale de la primera partida online con amigos (2026-10-25). Es el primer bloque de la lista
grande de mejoras; los demás (pausa, poderes, mapas, peinados, opciones, podio) van después,
cada uno con sus bocetos.

## Por qué

En la partida se notó que: quien ya había llegado volvía a la carrera si se caía; no se sabía
cuándo empezaba una ronda nueva; los puntos 10/6/3/1 no decían quién iba ganando de verdad, y
la partida no terminaba nunca. Este bloque convierte las rondas sueltas en un **torneo** con
principio, marcador y final.

## Diseños elegidos por el usuario (bocetos en `.superpowers/brainstorm/.../bloque1-rondas.html`)

- Transición: **C · la postal** (postal pintada del mapa con "RONDA N · NOMBRE" y las victorias).
- Marcador: **A · la tabla** (mantener Tab: color, nombre, victorias, tiempo total).
- Configuración: **B · postales de mapas** (postales que se marcan, rondas con ‹ 5 ›).

## Qué hace

1. **Espectador.** Si un moco que ya cruzó la meta cae al vacío, no reaparece: desaparece de la
   carrera y su dueño ve "¡LLEGASTE A LA META! · MODO ESPECTADOR". La cámara sigue al primer moco
   que aún juega; con clic izquierdo pasa al siguiente y, tras el último, al mapa entero. Dura
   hasta que acaba la ronda. Quien llega a la meta y no se cae sigue jugando (puede molestar).
2. **Puntuación por victorias.** Gana la ronda solo el primero en llegar (+1 victoria). Cada
   ronda suma a cada uno su tiempo de llegada; a quien no llega, el tiempo en que acabó la
   ronda. Orden: más victorias y, si empatan, menos tiempo total. Se quita el 10/6/3/1.
3. **Marcador.** Mantener **Tab** durante la carrera (online) muestra la tabla. La misma tabla
   sale 5 s entre rondas, en lugar de la lista de puntos actual.
4. **Transición.** Al empezar cada ronda (también la 1.ª) cae la postal durante ~2,5 s con
   "RONDA N DE M · LA AZOTEA", una miniatura pintada del mapa real de esa ronda y las victorias.
   Mientras está, los mocos están quietos y el reloj parado.
5. **Fin del torneo.** Tras la última ronda: "GANA <nombre>" + la tabla durante ~8 s y, si el
   primero ganó por tiempo, "EMPATE EN VICTORIAS · GANA POR TIEMPO". Luego todos vuelven a la
   sala **sin desconectarse**, listos para otro torneo. (El podio con flores es el bloque 8.)
6. **Configuración.** Online, el lado izquierdo del menú pasa a ser "LA PARTIDA": rondas
   (3, 5, 7, 10; por defecto 5) y las postales de mapas. Solo el anfitrión cambia algo; los demás
   lo ven igual y pulsan **LISTO**. En la sala aparece ✓ bajo cada moco listo. El anfitrión
   puede empezar cuando todos están listos. Si cambia la configuración, los listos se borran.

## Decisiones tomadas por Claude (el usuario las delegó)

- Pausa con 4 jugadores: basta con que acepte otro (bloque de pausa, no este).
- La cámara del espectador cambia con clic izquierdo, porque Tab ya es el marcador.
- La configuración se queda en el menú, al lado de la sala, y no en otra pantalla: así se ven
  a la vez los ✓ de listos y las opciones. Usa el estilo de postales elegido.
- Solo existe un mapa (la azotea), así que hay una sola postal. Las de noche, cueva, mar y
  jungla, y los interruptores de poderes y aros de fuego, aparecen cuando existan esas cosas.
  Mostrarlos antes sería prometer opciones que no hacen nada.
- Practicar solo no cambia: sin rondas ni torneo, con R para repetir.
- Al volver a la sala tras un torneo se vuelven a aceptar conexiones, para que entre alguien nuevo.

## Fuera de este bloque

Pausa, poderes, mapas nuevos, aros de fuego, peinados, opciones y volumen, menú responsivo y podio.

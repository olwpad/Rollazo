# Rollazo: documento de diseño

Fecha: 2026-10-24
Estado: aprobado por el autor (2026-10-24)

## 1. Qué es y por qué

Un "friend slop" online: un juego caótico y absurdo para jugar con amigos, con física blanda al estilo Party Animals. Lo especial es su minijuego central: **una carrera colgándote de un rollo de papel higiénico**, como Spider-Man pero ridículo, por una casa gigante vista desde el tamaño de un muñequito.

El autor es programador Java y no conoce Godot. El objetivo inmediato es **jugarlo con su grupo habitual de 4 amigos**, cada uno desde su casa, e ir puliéndolo. Steam queda como posibilidad para más adelante, sin compromiso.

Lo que tiene que transmitir, en palabras del autor: **intrépido, divertido y que enganche desde el primer momento**.

## 2. Objetivos

- Entras y en segundos ya te estás riendo. Nada de tutoriales largos.
- Controles fáciles de aprender y difíciles de dominar.
- El caos entre los 4 jugadores es la fuente principal de risa.
- Partidas cortas y reinicio instantáneo para que siempre apetezca "otra".

## 3. Lo que NO es (por ahora)

- No es 3D en la versión 1.
- No tiene matchmaking con desconocidos, cuentas ni tienda.
- No tiene skins, varios mapas ni modo armas en la versión 1 (ver fases).

**Sería un fracaso aunque funcione técnicamente si:** columpiarse no se siente bien por sí solo, el online se nota con tirones o lag que arruinan el caos, o una partida se decide en los primeros 10 segundos y los demás se aburren.

## 4. Decisiones tomadas

### Del autor
- Online, cada jugador en su casa. 4 jugadores es el caso normal.
- Colección de minijuegos absurdos con física blanda. El primero es la carrera con papel higiénico.
- Gana el que llega primero a la meta.
- Hay obstáculos en el recorrido.
- Le gustan las propuestas de la sección 5 tal como están.
- Más adelante: varios mapas, skins y un modo armas en el que os peleáis colgados del papel.

- Lo quiere **ligero, de la forma más sencilla posible**, pero adictivo y jugable. Pone como referencia a Party Machine.
- **Forma de trabajar:** Claude escribe el código y lo explica mientras avanza; el autor mira, pregunta, prueba y colabora. No tiene experiencia haciendo juegos, pero sí programando en Java.

### Mías (el autor puede cambiarlas)
- **Motor:** Godot 4 (versión estable más reciente). Todavía no está instalado en la máquina.
- **Lenguaje:** GDScript. Es el que tiene más tutoriales y ejemplos, y alguien que viene de Java lo aprende rápido. C# es la alternativa si el autor lo prefiere.
- **Vista:** 2D de lado, porque es la opción más sencilla, como pidió el autor. Es mucho más barato que 3D en física y en online, y el columpio se lee mejor así.
- **Retraso de red:** los amigos viven en la misma ciudad, a unos 10 km (dato del autor), así que el ping debería ser bajo. En la v1 se usa el modelo simple, en el que el anfitrión decide toda la física. Si en la fase 4 el columpio aun así se nota con retraso, se añade predicción en el cliente para el propio jugador. El código de red debe quedar separado para que ese cambio sea posible.
- **Nombre provisional:** "Rollazo".
- **Red:** el multijugador integrado de Godot (ENet). Un jugador hace de anfitrión y los demás se conectan a él. **El anfitrión decide la física** y los demás le envían sus controles. Para conectar por internet sin abrir puertos del router, en la v1 se usa una red privada tipo Tailscale o ZeroTier. Steam (GodotSteam) se considera solo si se publica.
- **Desarrollo en local:** varias instancias del juego en el mismo PC para probar el online antes de jugarlo con los amigos.

## 5. Diseño del juego

### Mundo
Una casa gigante: baño, cocina, salón. Los jugadores son muñequitos con física de trapo.

### Controles (ratón y teclado)
- Apuntar con el ratón y hacer clic para lanzar el papel, que se pega al techo o a una superficie.
- Mientras sigue enganchado, te columpias. Si sueltas en el momento justo, sales disparado con el impulso.
- Teclas para encoger o alargar el papel y para un pequeño empujón en el aire. Que hagan falta o no lo decide el constructor jugando.

### El papel que se rasga (la mecánica central)
- El papel tiene "aguante". Se gasta si lo mantienes mucho tiempo o si das un tirón brusco.
- Cuando se agota, se rompe y caes.
- La idea es que cuanto más arriesgas, más rápido vas.
- Tiene que verse antes de que pase: el papel se estira o cambia de color.

### Interacción entre jugadores
- **Cortar** el papel de otro jugador.
- **Agarrarse a las piernas** de otro: te lleva, pero le pesas.
- **Choques en el aire:** los dos salís rebotando como muñecos de trapo.

### Obstáculos (primer mapa: el baño)
- Ventilador de techo que enreda el papel.
- Váter que tira de la cadena y absorbe a quien pase cerca.
- Suelo mojado que resbala.
- Un gato gigante que da zarpazos (puede dejarse para el segundo mapa).

### Estructura de partida
- Una ronda tiene 3 recorridos de 1 a 2 minutos cada uno, y se suman puntos según la posición de llegada.
- **Ayuda al que va último** (por ejemplo, un papel más resistente) para que nadie quede descolgado.
- Si alguien se cae o se queda atascado, reaparece rápido en un punto de control.
- Al terminar la ronda, se muestra una **repetición del fallo más ridículo**.

## 5a. Cambio de estilo (elegido por el autor en bocetos, 2026-10-24) — sustituye partes de 5b

- **Personaje:** un **moco gotero**. Es viscoso, gotea al moverse y tiene los ojos desiguales. No tiene forma humana. Se rechazaron los personajes humanos de Kenney.
- **Mapas:** **ciudad nocturna de neón al estilo Spider-Verse**: azoteas, carteles y un cielo rosa y morado con colores desplazados y puntitos de cómic. Os columpiáis con papel higiénico entre edificios. **Sustituye a la casa gigante** como tema del primer mapa.
- **Efectos:** **solo efectos físicos**: salpicadura de moco, confeti de papel y temblor de pantalla. **Sin onomatopeyas ni texto.** Se rechazó la pared de azulejos y las onomatopeyas.

## 5b. Estilo visual: "cómic-anime" (aprobado por el autor, 2026-10-24)

Inspirado, sin copiar, en obras que le gustan al autor: Spider-Man/Spider-Verse, Black Clover, Ao Ashi, Steins;Gate y Rocket League.
- **Cómic (Spider-Verse):** contornos negros gruesos, colores planos y vivos, puntitos de imprenta (halftone) y onomatopeyas en pantalla ("¡FWIP!" al lanzar, "¡RASSS!" al romperse, "¡PLOF!" al estamparse).
- **Anime (Black Clover, Ao Ashi):** líneas de velocidad cuando vas rápido, pantallazo de impacto al chocar entre jugadores y un aura para el que va primero.
- **Rocket League:** cuenta atrás épica, explosión al cruzar la meta, repetición y personalización (rollos con estampados).
- **Para más adelante:** rollos especiales con poderes (idea de los grimorios) y un salto temporal de una vez por carrera o un fantasma de tu mejor intento (Steins;Gate).
- **Recursos:** packs gratuitos con licencia que permita uso comercial (preferiblemente CC0, como Kenney), más efectos programados.
- **Controles añadidos:** Espacio salta desde el suelo.

## 6. Fases

1. **Prototipo para un jugador:** un muñeco, el papel que se engancha y se rasga, y un recorrido de prueba. Esta fase solo busca que **columpiarse sea divertido por sí solo**. No se avanza hasta conseguirlo, y **lo decide el autor jugándolo** (mi decisión: al final de la fase hay una prueba con él).
2. **Online para 4:** el anfitrión y 3 jugadores conectados, la carrera con meta y posiciones, cortar el papel, agarrarse y chocar.
3. **El baño completo:** los obstáculos, los 3 recorridos, los puntos de la ronda, la ayuda al último y el menú mínimo (crear partida o unirse por IP).
4. **Prueba con los amigos** y ajustes según lo que pase.
5. **Repetición del fallo más ridículo.**
6. Más adelante, en este orden salvo que el autor diga otra cosa: más mapas (cocina, salón), skins y modo armas.

Las fases 5 y 6 se pueden diseñar más a fondo cuando lleguen.

### Ideas del autor para después de la fase 2 (2026-10-24)
Obstáculos (incluidas **sierras**), **portales** y **poderes**. Se diseñan después de probar el online con los amigos.

## 7. Lo que queda en manos del constructor

- Cómo se simula el papel (cadena de segmentos con uniones o una restricción de distancia), siempre que se sienta bien y funcione en red.
- Qué tan completo es el muñeco de trapo en la v1. Lo único obligatorio es que se vea blando y gracioso.
- Los números de física, el aguante del papel y la puntuación, que se ajustan jugando.
- El arte provisional: formas simples o recursos gratuitos bastan hasta la fase 4.
- La estructura de carpetas y escenas.

## 8. Notas para el autor (viene de Java)

- Cada fase debe terminar con algo que se pueda jugar y enseñar a los amigos.
- El código tiene que ser legible para alguien que está aprendiendo Godot, sin trucos raros.
- En cada paso, explicar qué se hizo y por qué, usando comparaciones con Java cuando ayuden (por ejemplo, un nodo se parece a un objeto y una escena a una clase reutilizable).
- Los pasos que el autor tenga que hacer en el editor de Godot (instalarlo, abrir el proyecto, darle a Play) se explican uno a uno.

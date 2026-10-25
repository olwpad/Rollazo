# Jugar a Rollazo online con los amigos

Rollazo funciona como una red de área local: un PC hace de **anfitrión** y los demás se
conectan a él. Como no estamos en la misma casa, usamos **Tailscale**, que crea una red privada
entre nuestros PCs por internet (gratis, sin abrir puertos del router).

## Una sola vez (cada uno)

1. Descarga Tailscale en https://tailscale.com/download e instálalo.
2. Entra con tu cuenta de Google, Microsoft o GitHub.
3. El anfitrión invita a los demás a su red: en https://login.tailscale.com/admin/users,
   botón **Invite users**, y les manda el enlace. Cada amigo lo abre y acepta.
4. Copia `Rollazo.exe` en tu PC (te lo pasa el anfitrión). Windows puede avisar de que es una
   app desconocida: **Más información → Ejecutar de todas formas**.
5. La primera vez que el anfitrión pulse **Crear partida**, Windows pregunta por el firewall:
   marca **Redes privadas** y acepta.

## Cada partida

**Anfitrión**

1. Abre Tailscale (icono junto al reloj) y copia tu IP: empieza por `100.` (por ejemplo `100.101.7.42`).
2. Pásala por el grupo de WhatsApp.
3. Abre Rollazo y pulsa **Crear partida**.
4. Cuando estéis todos, pulsa **¡Empezar carrera!**

**Amigos**

1. Comprueba que Tailscale está conectado (icono sin tachar).
2. Abre Rollazo, pega la IP del anfitrión en la casilla y pulsa **Unirse**.

## Controles

| Acción | Tecla |
|---|---|
| Lanzar papel / columpiarse | clic izquierdo (mantener) |
| Soltar con impulso | soltar el clic |
| Encoger / alargar papel | W / S |
| Moverse | A / D |
| Saltar | Espacio |
| Cortar el papel de otro | clic derecho (cerca de su papel) |
| Agarrarse a otro / soltarse | E |
| Volver al menú | Esc |
| Silenciar la música | M |

Máximo 4 jugadores. Cada ronda: puntos 10, 6, 3 y 1 por orden de llegada; cuando llega el
primero, los demás tienen 20 segundos.

## Si algo falla

- **No conecta:** que los dos tengáis Tailscale encendido y la IP sea la `100.x` del anfitrión
  (no la de tu wifi). Prueba `ping 100.x.y.z` en una terminal.
- **"No se pudo conectar" con Tailscale bien:** puede que ya haya 4 jugadores, o que la carrera ya haya empezado (espera a la siguiente partida).
- **El anfitrión cierra el juego:** todos vuelven al menú. Que vuelva a crear y os unís otra vez.

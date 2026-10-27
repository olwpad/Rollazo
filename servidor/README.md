# rollazo-salas

Servidor de salas de Rollazo (Cloudflare Worker + Durable Object). Solo presenta a los jugadores
(señalización WebRTC); la partida va directa de PC a PC.

- `npm install`
- `npm run dev`: servidor local en `ws://127.0.0.1:8787` (el juego lo usa con `ROLLAZO_SALAS=ws://127.0.0.1:8787`).
- `npm test`: arranca `wrangler dev` y prueba el protocolo (no va en `run_tests.sh`: necesita node).
- Publicar (lo hace el dueño): `npx wrangler login` y luego `npx wrangler deploy`; después, poner la
  URL `wss://rollazo-salas.<tu-subdominio>.workers.dev` en `SERVIDOR_SALAS` de `scripts/red.gd`.

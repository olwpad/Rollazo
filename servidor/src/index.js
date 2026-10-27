// Servidor de salas de Rollazo: solo presenta a los jugadores entre sí (señalización WebRTC).
// La partida va directa de PC a PC; aquí no pasa ningún dato del juego.
import { Sala } from "./sala.js";
export { Sala };

// Sin I, L ni O: se confunden con 1 y 0 al dictar el código.
const ALFABETO = "ABCDEFGHJKMNPQRSTUVWXYZ";

function codigoAleatorio() {
  const r = crypto.getRandomValues(new Uint32Array(4));
  return Array.from(r, (n) => ALFABETO[n % ALFABETO.length]).join("");
}

export default {
  async fetch(peticion, env) {
    const ruta = new URL(peticion.url).pathname;
    if (ruta === "/") return new Response("rollazo-salas ok");
    if (peticion.headers.get("Upgrade") !== "websocket") return new Response("Se espera un WebSocket", { status: 426 });

    if (ruta === "/sala/nueva") {
      // Si el código ya tiene anfitrión, la sala responde 409 y probamos con otro.
      for (let i = 0; i < 5; i++) {
        const codigo = codigoAleatorio();
        const r = await env.SALA.get(env.SALA.idFromName(codigo)).fetch(entrada(peticion, "anfitrion", codigo));
        if (r.status !== 409) return r;
      }
      return new Response("Sin códigos libres", { status: 503 });
    }

    const m = ruta.match(/^\/sala\/([A-Za-z]{4})$/);
    if (!m) return new Response("No encontrado", { status: 404 });
    const codigo = m[1].toUpperCase();
    return env.SALA.get(env.SALA.idFromName(codigo)).fetch(entrada(peticion, "cliente", codigo));
  },
};

// Misma petición con el rol y el código en cabeceras (la sala no sabe su propio nombre).
function entrada(peticion, rol, codigo) {
  const p = new Request(peticion);
  p.headers.set("x-rol", rol);
  p.headers.set("x-codigo", codigo);
  return p;
}

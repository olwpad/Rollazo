// Una sala = un Durable Object (uno por código). Usa la API de hibernación: los sockets y su
// identidad (serializeAttachment) sobreviven aunque el objeto se duerma, así que no hay estado en memoria.
import { DurableObject } from "cloudflare:workers";

const MAX_JUGADORES = 6; // anfitrión + 5
const RETRANSMITIDOS = ["oferta", "respuesta", "candidato"];

export class Sala extends DurableObject {
  // Sockets vivos con su {id, codigo}; el anfitrión siempre es el id 1.
  conectados() {
    return this.ctx.getWebSockets().map((ws) => ({ ws, ...ws.deserializeAttachment() })).filter((c) => c.id > 0); // id 0 = rechazado
  }

  async fetch(peticion) {
    const par = new WebSocketPair();
    const [cliente, servidor] = Object.values(par);
    const rol = peticion.headers.get("x-rol");
    const codigo = peticion.headers.get("x-codigo");
    const dentro = this.conectados();
    const anfitrion = dentro.find((c) => c.id === 1);

    if (rol === "anfitrion") {
      if (anfitrion) return new Response("Código en uso", { status: 409 });
      this.ctx.acceptWebSocket(servidor);
      servidor.serializeAttachment({ id: 1, codigo });
      servidor.send(JSON.stringify({ tipo: "sala", codigo, id: 1 }));
      return new Response(null, { status: 101, webSocket: cliente });
    }

    // Un cliente: hay que aceptar el socket aunque sea para decirle el error.
    this.ctx.acceptWebSocket(servidor);
    const rechazo = !anfitrion ? "no_existe" : dentro.length >= MAX_JUGADORES ? "llena" : null;
    if (rechazo) {
      servidor.serializeAttachment({ id: 0, codigo }); // id 0: no cuenta como jugador
      servidor.send(JSON.stringify({ tipo: "error", motivo: rechazo }));
      servidor.close(1000, rechazo);
      return new Response(null, { status: 101, webSocket: cliente });
    }
    const id = this.idLibre(dentro);
    servidor.serializeAttachment({ id, codigo });
    servidor.send(JSON.stringify({ tipo: "sala", codigo, id }));
    anfitrion.ws.send(JSON.stringify({ tipo: "entra", id }));
    return new Response(null, { status: 101, webSocket: cliente });
  }

  idLibre(dentro) {
    for (;;) {
      const id = 2 + Math.floor(Math.random() * 2147483646); // 2..2147483647
      if (!dentro.some((c) => c.id === id)) return id;
    }
  }

  webSocketMessage(ws, mensaje) {
    const yo = ws.deserializeAttachment();
    if (!yo || typeof mensaje !== "string") return;
    let m;
    try { m = JSON.parse(mensaje); } catch { return; }
    if (!m || !RETRANSMITIDOS.includes(m.tipo)) return;
    const destino = this.conectados().find((c) => c.id === m.a);
    if (!destino) return; // destino desconocido: se ignora
    const { a, ...resto } = m;
    destino.ws.send(JSON.stringify({ ...resto, de: yo.id }));
  }

  webSocketClose(ws) {
    this.alIrse(ws);
  }

  webSocketError(ws) {
    this.alIrse(ws);
  }

  alIrse(ws) {
    const yo = ws.deserializeAttachment();
    if (!yo || yo.id === 0) return;
    const resto = this.conectados().filter((c) => c.ws !== ws);
    if (yo.id === 1) { // cae el anfitrión: la sala desaparece y el código queda libre
      for (const c of resto) {
        try { c.ws.send(JSON.stringify({ tipo: "cerrada" })); c.ws.close(1000, "cerrada"); } catch {}
      }
    } else {
      resto.find((c) => c.id === 1)?.ws.send(JSON.stringify({ tipo: "sale", id: yo.id }));
    }
  }
}

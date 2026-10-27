// Prueba de integración: levanta `wrangler dev` en local y habla con él por WebSocket.
import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { spawn } from "node:child_process";

const PUERTO = 8799;
const URL_BASE = `ws://127.0.0.1:${PUERTO}`;
let wrangler;

before(async () => {
  wrangler = spawn("npx", ["wrangler", "dev", "--port", String(PUERTO)], { shell: true, stdio: "ignore" });
  for (let i = 0; i < 120; i++) { // hasta ~60 s
    try { if ((await fetch(`http://127.0.0.1:${PUERTO}/`)).ok) return; } catch {}
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error("wrangler dev no arrancó");
});

after(() => {
  // En Windows shell:true deja un árbol de procesos: taskkill /T lo cierra entero.
  if (process.platform === "win32") spawn("taskkill", ["/pid", String(wrangler.pid), "/T", "/F"]);
  else wrangler.kill();
});

// Abre un socket y guarda los mensajes; `siguiente()` espera el próximo.
function abrir(ruta) {
  const ws = new WebSocket(URL_BASE + ruta);
  const cola = [];
  let aviso = null;
  ws.onmessage = (e) => { cola.push(JSON.parse(e.data)); aviso?.(); };
  
  const siguiente = async () => {
    while (!cola.length) await new Promise((r, rej) => { aviso = r; setTimeout(() => rej(new Error("sin mensaje")), 5000); });
    return cola.shift();
  };
  return { ws, siguiente };
}

async function crear() {
  const h = abrir("/sala/nueva");
  const m = await h.siguiente();
  return { h, m };
}

test("salud", async () => {
  assert.equal(await (await fetch(`http://127.0.0.1:${PUERTO}/`)).text(), "rollazo-salas ok");
});

test("crear da un código de 4 letras y id 1", async () => {
  const { h, m } = await crear();
  assert.equal(m.tipo, "sala");
  assert.match(m.codigo, /^[ABCDEFGHJKMNPQRSTUVWXYZ]{4}$/);
  assert.equal(m.id, 1);
  h.ws.close();
});

test("unirse, retransmitir y salir", async () => {
  const { h, m } = await crear();
  const c = abrir("/sala/" + m.codigo.toLowerCase()); // sin distinguir mayúsculas
  const mc = await c.siguiente();
  assert.equal(mc.tipo, "sala");
  assert.equal(mc.codigo, m.codigo);
  assert.ok(mc.id >= 2);
  assert.deepEqual(await h.siguiente(), { tipo: "entra", id: mc.id });

  h.ws.send(JSON.stringify({ tipo: "oferta", a: mc.id, sdp: "x" }));
  assert.deepEqual(await c.siguiente(), { tipo: "oferta", sdp: "x", de: 1 });
  c.ws.send(JSON.stringify({ tipo: "respuesta", a: 1, sdp: "y" }));
  assert.deepEqual(await h.siguiente(), { tipo: "respuesta", sdp: "y", de: mc.id });
  c.ws.send(JSON.stringify({ tipo: "candidato", a: 99999, c: "z" })); // destino desconocido: nada

  c.ws.close();
  assert.deepEqual(await h.siguiente(), { tipo: "sale", id: mc.id });
  h.ws.close();
});

test("código inexistente: no_existe", async () => {
  const c = abrir("/sala/ZZZZ");
  assert.deepEqual(await c.siguiente(), { tipo: "error", motivo: "no_existe" });
});

test("quinto jugador: llena; cae el anfitrión: cerrada", async () => {
  const { h, m } = await crear();
  const clientes = [];
  for (let i = 0; i < 3; i++) {
    const c = abrir("/sala/" + m.codigo);
    assert.equal((await c.siguiente()).tipo, "sala");
    clientes.push(c);
  }
  const quinto = abrir("/sala/" + m.codigo);
  assert.deepEqual(await quinto.siguiente(), { tipo: "error", motivo: "llena" });

  h.ws.close();
  for (const c of clientes) {
    assert.deepEqual(await c.siguiente(), { tipo: "cerrada" });
  }
  const otra = abrir("/sala/" + m.codigo); // el código vuelve a estar libre
  assert.deepEqual(await otra.siguiente(), { tipo: "error", motivo: "no_existe" });
});

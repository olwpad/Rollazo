#!/bin/bash
# Prueba de salas con c贸digo: levanta el servidor local (necesita node + npm install en servidor/)
# y conecta dos Godot por WebRTC en este PC. No va en run_tests.sh.
G="${GODOT:-$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
export ROLLAZO_SALAS=ws://127.0.0.1:8787
LOG="$(mktemp)"
export ROLLAZO_CODIGO_ARCHIVO="$(mktemp -u)"  # aqu铆 el anfitri贸n deja el c贸digo para el cliente

npm --prefix "$RAIZ/servidor" run dev > "$LOG" 2>&1 &
SERV=$!
parar() {
  # npm lanza wrangler y workerd como hijos: taskkill /T mata el 醨bol entero (en Windows).
  WINPID=$(cat /proc/$SERV/winpid 2>/dev/null)
  if [ -n "$WINPID" ]; then taskkill //PID "$WINPID" //T //F >/dev/null 2>&1; else kill $SERV 2>/dev/null; fi
}
trap parar EXIT

for i in $(seq 1 120); do  # hasta 60 s a que el puerto responda
  curl -s http://127.0.0.1:8787/ >/dev/null && break
  sleep 0.5
done
curl -s http://127.0.0.1:8787/ >/dev/null || { echo "FALLO: el servidor no arranc贸"; cat "$LOG"; exit 1; }

cd "$RAIZ"
SALIDA="$(mktemp)"
"$G" --headless --path . --script res://tests/sim_salas_anfitrion.gd > "$SALIDA" 2>&1 &
ANF=$!
"$G" --headless --path . --script res://tests/sim_salas_cliente.gd 2>&1 | tee -a "$SALIDA" | grep "sim_salas"
RC=${PIPESTATUS[0]}
wait $ANF; R=$?
grep "sim_salas:" "$SALIDA"
if [ $R -eq 0 ] && [ $RC -eq 0 ]; then echo "OK"; else echo "FALLO"; grep -E "ERROR|WARNING: .*(webrtc|WebRTC)" "$SALIDA" | head; exit 1; fi

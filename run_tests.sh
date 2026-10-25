#!/bin/bash
# Importa el proyecto (registra los class_name) y ejecuta todos los tests.
G="${GODOT:-$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
cd "$(dirname "$0")"
"$G" --headless --path . --import >/dev/null 2>&1
SALIDA=$("$G" --headless --path . --script res://tests/run_tests.gd 2>&1); RC=$?
echo "$SALIDA"
[ $RC -eq 0 ] || exit 1
# Un test que revienta con error de script no marca fallo por sí solo: lo cazamos aquí.
if echo "$SALIDA" | grep -q "SCRIPT ERROR"; then echo "FALLO: hubo errores de script en los tests"; exit 1; fi
"$G" --headless --path . --script res://tests/sim_columpio.gd || exit 1
"$G" --headless --path . --script res://tests/sim_recorrido.gd || exit 1
"$G" --headless --path . --script res://tests/sim_clics.gd || exit 1
"$G" --headless --path . --script res://tests/sim_salto.gd || exit 1
"$G" --headless --path . --script res://tests/sim_choque.gd || exit 1
"$G" --headless --path . --script res://tests/sim_cortar.gd || exit 1
"$G" --headless --path . --script res://tests/sim_agarrar.gd || exit 1
"$G" --headless --path . --script res://tests/sim_aro.gd || exit 1
"$G" --headless --path . --script res://tests/sim_sierra.gd || exit 1
"$G" --headless --path . --script res://tests/sim_caida.gd || exit 1
# Prueba de red con dos procesos: anfitrión en segundo plano y cliente.
LOG="$(mktemp)"
"$G" --headless --path . --script res://tests/sim_red_anfitrion.gd > "$LOG" 2>&1 &
ANF=$!
sleep 1
"$G" --headless --path . --script res://tests/sim_red_cliente.gd 2>&1 | grep "sim_red_cliente"
RC=${PIPESTATUS[0]}
wait $ANF; R=$?
grep "sim_red:" "$LOG"
[ $R -eq 0 ] && [ $RC -eq 0 ] || exit 1
# Bots de un torneo entero de 3 rondas: listos, pausa compartida, metas y vuelta a la sala.
"$G" --headless --path . --script res://tests/sim_torneo_anfitrion.gd > "$LOG" 2>&1 &
ANF=$!
sleep 1
CLI=$("$G" --headless --path . --script res://tests/sim_torneo_cliente.gd 2>&1); RC=$?
wait $ANF; R=$?
echo "$CLI" | grep "sim_torneo_cliente"
grep "sim_torneo:" "$LOG"
if cat "$LOG" <(echo "$CLI") | grep -q "SCRIPT ERROR"; then echo "FALLO: errores de script en el torneo"; exit 1; fi
[ $R -eq 0 ] && [ $RC -eq 0 ] || exit 1

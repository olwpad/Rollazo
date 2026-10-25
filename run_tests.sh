#!/bin/sh
# Importa el proyecto (registra los class_name) y ejecuta todos los tests.
G="${GODOT:-$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
cd "$(dirname "$0")"
"$G" --headless --path . --import >/dev/null 2>&1
"$G" --headless --path . --script res://tests/run_tests.gd || exit 1
"$G" --headless --path . --script res://tests/sim_columpio.gd || exit 1
"$G" --headless --path . --script res://tests/sim_recorrido.gd || exit 1
"$G" --headless --path . --script res://tests/sim_clics.gd || exit 1
"$G" --headless --path . --script res://tests/sim_salto.gd || exit 1
# Prueba de red con dos procesos: anfitrión en segundo plano y cliente.
LOG="$(mktemp)"
"$G" --headless --path . --script res://tests/sim_red_anfitrion.gd > "$LOG" 2>&1 &
ANF=$!
sleep 1
"$G" --headless --path . --script res://tests/sim_red_cliente.gd > /dev/null 2>&1
wait $ANF; R=$?
grep "sim_red" "$LOG"
[ $R -eq 0 ] || exit 1

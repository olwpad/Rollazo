#!/bin/bash
# Pasa el bot probador por varias semillas de una forma.
# Uso: tools/bot_mapas.sh <salida.txt> <forma|-> <semillas...>   (env: CAP segundos por mapa, PAR mapas a la vez)
REPO="$(cd "$(dirname "$0")/.." && pwd)"
G="${GODOT:-$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
out=$1; forma=$2; shift 2
tmp="$(mktemp -d)"
uno() {  # una semilla a su propio fichero: así se pueden correr varias a la vez
	timeout 150 "$G" --headless --fixed-fps 60 --path "$REPO" --script res://tools/bot_mapas.gd -- "$1" "$forma" 1 "${CAP:-100}" 2>&1 \
		| grep -E "^(SEED|BOT|  )|SCRIPT ERROR|Parse" | grep -v "at: " > "$tmp/$1.txt"
	grep -q "^BOT" "$tmp/$1.txt" || echo "BOT 1 TIMEOUT seed=$1 forma=$forma" >> "$tmp/$1.txt"
}
export -f uno; export G REPO forma tmp
printf "%s\n" "$@" | xargs -P "${PAR:-4}" -I{} bash -c 'uno {}'
: > "$out"
for s in "$@"; do cat "$tmp/$s.txt" >> "$out"; done
rm -rf "$tmp"
grep -E "^BOT|ERROR" "$out"
echo "$forma: FIN $(grep -c "^BOT.* FIN " "$out") de $# · falls $(grep -c "^  FALL" "$out") · sierras $(grep -c "^  SAW" "$out") · stuck $(grep -c "^  STUCK" "$out")"

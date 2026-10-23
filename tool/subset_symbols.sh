#!/bin/sh
# Rebuilds assets/fonts/MaterialSymbolsRounded.ttf with only the glyphs in tool/symbols.txt.
# The variable axes (FILL, wght, GRAD, opsz) are kept so icons can switch to filled.
# Usage: tool/subset_symbols.sh <MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf> <.codepoints>
# Requires fonttools (pip install fonttools). After adding a name, also add it to lib/symbols.dart.
set -e
font="$1"; codepoints="$2"
unicodes=$(grep -v '^$' "$(dirname "$0")/symbols.txt" | while read -r name; do
  code=$(grep "^$name " "$codepoints" | cut -d' ' -f2)
  [ -n "$code" ] || { echo "Unknown symbol: $name" >&2; exit 1; }
  printf 'U+%s,' "$code"
done)
pyftsubset "$font" --unicodes="${unicodes%,}" --layout-features='' --no-hinting \
  --output-file="$(dirname "$0")/../assets/fonts/MaterialSymbolsRounded.ttf"

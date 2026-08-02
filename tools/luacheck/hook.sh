#!/bin/sh
# Syntax-check a Lua file the moment it is edited, so a broken `end` is caught
# here instead of at the next server boot.
#
# Exits 2 with the parser error on stderr so the editor surfaces it and the
# mistake gets fixed before anything else happens. Stays quiet when the file
# isn't Lua, or when the checker's dependencies were never installed.
set -e

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

FILE=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input", {}).get("file_path", ""))' 2>/dev/null || true)

case "$FILE" in
	*.lua) ;;
	*) exit 0 ;;
esac

[ -f "$FILE" ] || exit 0
[ -d "$DIR/node_modules/luaparse" ] || exit 0
command -v bun >/dev/null 2>&1 || exit 0

OUTPUT=$(bun "$DIR/check.js" "$FILE" 2>&1) || {
	echo "$OUTPUT" >&2
	exit 2
}

exit 0

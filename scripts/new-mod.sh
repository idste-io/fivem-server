#!/bin/bash
# Create a new mod from the example-mod template
# Usage: bash scripts/new-mod.sh my-mod-name
# Then add `ensure my-mod-name` to server.cfg and push.

set -euo pipefail

NAME="${1:-}"
if [ -z "$NAME" ]; then
  echo "Usage: bash scripts/new-mod.sh <mod-name>"
  exit 1
fi

DEST="resources/[custom]/$NAME"
TEMPLATE="resources/[custom]/example-mod"

if [ -d "$DEST" ]; then
  echo "Error: $DEST already exists"
  exit 1
fi

cp -r "$TEMPLATE" "$DEST"
sed -i "s/example-mod/$NAME/g" "$DEST/fxmanifest.lua"
echo "Created $DEST"
echo ""
echo "Next steps:"
echo "  1. Edit the files in $DEST/"
echo "  2. Add 'ensure $NAME' to server.cfg"
echo "  3. git add . && git commit -m 'core-vault: add mod $NAME'"
echo "  4. git push"
echo "  5. ssh root@187.124.93.157 \"bash /opt/fivem-server/scripts/update.sh\""

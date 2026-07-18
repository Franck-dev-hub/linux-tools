#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_ROOT="${SCRIPT_DIR}/scripts"
TARGET_DIR="${HOME}/.local/share/scripts"

mkdir -p "$TARGET_DIR"

while IFS= read -r -d '' file; do
    name="$(basename "$file")"
    cp "$file" "${TARGET_DIR}/${name}"
    echo "Copied: ${name} -> ${file}"
done < <(find "$SCRIPTS_ROOT" -mindepth 2 -type f \( -name "*.sh" -o -name "*.py" \) -print0)

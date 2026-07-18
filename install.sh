#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.local/share/scripts"

mkdir -p "$TARGET_DIR"

while IFS= read -r -d '' file; do
    name="$(basename "$file")"
    cp "$file" "${TARGET_DIR}/${name}"
    echo "Copied: ${name} -> ${file}"
done < <(find "$SCRIPT_DIR" -mindepth 2 -type f \( -name "*.sh" -o -name "*.py" \) -not -path "*/.git/*" -print0)

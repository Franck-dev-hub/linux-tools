#!/bin/bash

#######################################
# List required version constraints of a dependency across all
# published versions of a Packagist package.
# Globals:
#   None
# Arguments:
#   $1 - Package name (default: sylius/sylius)
#   $2 - Dependency name to inspect (default: guzzlehttp/psr7)
# Outputs:
#   "<package version> -> <dependency constraint>" for each version
#   that requires the dependency
#######################################

set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: dependency_versions.sh [package] [dependency]

Input:
  package     Packagist package name (default: sylius/sylius)
  dependency  Dependency name to inspect (default: guzzlehttp/psr7)

Output:
  One line per package version that requires the dependency:
  <package version> -> <dependency constraint>
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

package="${1:-sylius/sylius}"
dependency="${2:-guzzlehttp/psr7}"

curl -s "https://repo.packagist.org/p2/${package}.json" | python3 -c "
import json, sys

package = '${package}'
dependency = '${dependency}'

d = json.load(sys.stdin)
for p in d['packages'][package]:
    req = p.get('require', {})
    if dependency in req:
        print(p['version'], '->', req[dependency])
"

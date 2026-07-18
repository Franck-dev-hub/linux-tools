#!/usr/bin/env python3

#######################################
# CVE triage for a Composer project
# Globals:
#   None
# Arguments:
#   None
# Output:
#   OK / NOK / Ignored / ERR | CVE | package | patch target | sylius patch
#######################################

import json
import re
import subprocess
import sys

RED, GREEN, YELLOW, RST = "\033[31m", "\033[32m", "\033[33m", "\033[0m"

# CVE -> Sylius version that ships the fix (manual entry).
# Format : "CVE-2026-48998": "1.13",
SYLIUS_MAP = {
}

def run_audit():
    try:
        r = subprocess.run(
            ["composer", "audit", "--locked", "--format=json"],
            capture_output=True, text=True,
        )
    except FileNotFoundError:
        sys.exit("composer not found : is it installed and on PATH ?")
    if not r.stdout.strip():
        detail = r.stderr.strip() or "wrong folder, or composer < 2.4 ?"
        sys.exit(f"composer audit found nothing : {detail}")
    return json.loads(r.stdout)

def as_dict(section):
    return section if isinstance(section, dict) else {}

def vkey(v):
    return tuple(int(n) for n in re.findall(r"\d+", v or "")) or (0,)

def load_installed():
    try:
        with open("composer.lock") as f:
            lock = json.load(f)
    except (FileNotFoundError, ValueError):
        return {}
    pkgs = (lock.get("packages") or []) + (lock.get("packages-dev") or [])
    return {p["name"]: p.get("version", "") for p in pkgs}

def fix_targets(affected):
    return re.findall(r"<\s*([0-9][\w.\-]*)", affected or "")

def branch_target(targets, inst):
    if not targets:
        return None
    above = [t for t in targets if vkey(t) > vkey(inst)] if inst else []
    return min(above, key=vkey) if above else min(targets, key=vkey)

def sylius_from_reason(reason):
    m = re.search(r"Sylius\s*v?\^?([\d][\d.]*)", reason or "")
    return m.group(1) if m else "?"

def check_patch(pkg, target):
    try:
        r = subprocess.run(["composer", "why-not", pkg, target],
                           capture_output=True, text=True)
    except FileNotFoundError:
        return "ERR", []
    if r.returncode not in (0, 1) or (not r.stdout.strip() and r.stderr.strip()):
        return "ERR", []
    if "requires" not in r.stdout:
        return "OK", []
    blockers = []
    for line in r.stdout.splitlines():
        if "requires" in line:
            name = line.split()[0]
            if name and name != pkg and name not in blockers:
                blockers.append(name)
    return "NOK", blockers

def remediation(cve, state, blockers):
    mapped = SYLIUS_MAP.get(cve)
    if mapped:
        return f"Sylius >={mapped}"
    if state == "OK":
        return "composer update"
    if blockers:
        return "blocked by " + ", ".join(blockers)
    return "needs triage"

def main():
    data      = run_audit()
    active    = as_dict(data.get("advisories") or {})
    ignored   = as_dict(data.get("ignored-advisories") or {})
    installed = load_installed()

    if not active and not ignored:
        print(f"{GREEN}--- No advisory ---{RST}")
        return 0

    has_nok = False

    for pkg, advs in active.items():
        inst = installed.get(pkg, "")
        for adv in advs:
            cve      = adv.get("cve") or adv.get("advisoryId", "?")
            affected = adv.get("affectedVersions", "?")
            targets  = fix_targets(affected)

            if not targets:
                print(f"{YELLOW}Ignored{RST} | {cve} | {pkg} | {affected}")
                continue

            target        = branch_target(targets, inst)
            state, blocks = check_patch(pkg, target)
            if state == "NOK":
                has_nok = True
            color         = {"OK": GREEN, "NOK": RED, "ERR": YELLOW}[state]
            status        = f"{color}{state:<3}{RST}"
            remed         = remediation(cve, state, blocks)

            print(f"  {status}   | {cve} | {pkg} | {affected} | {remed}")

    for pkg, advs in ignored.items():
        for adv in advs:
            cve      = adv.get("cve") or adv.get("advisoryId", "?")
            affected = adv.get("affectedVersions", "?")
            reason   = adv.get("ignoreReason") or "no reason provided"
            sylius   = sylius_from_reason(reason)
            print(f"{YELLOW}Ignored{RST} | {cve} | {pkg} | {affected} | Sylius {sylius} | ({reason})")

    return 1 if has_nok else 0

if __name__ == "__main__":
    sys.exit(main())

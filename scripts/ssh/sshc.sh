#!/usr/bin/env bash
#######################################
# Lists the SSH hosts of the user config in an fzf menu, then connects to the chosen one.
# The comment line right above a Host block is shown as its description.
# Globals:
#   HOME (read, to find ~/.ssh/config and ~/.ssh/config.d)
# Arguments:
#   $1 - Optional filter; connects directly when only one host matches
# Outputs:
#   The menu on the terminal, then the ssh session
# Returns:
#   1 when no host is found, 0 when the menu is closed, else the ssh exit code
#######################################
set -euo pipefail
shopt -s nullglob

configs=()
[[ -f "$HOME/.ssh/config" ]] && configs+=("$HOME/.ssh/config")
configs+=("$HOME/.ssh/config.d"/*.conf)

if (( ${#configs[@]} == 0 )); then
    echo "Aucun fichier de config SSH trouvé." >&2
    exit 1
fi

hosts=$(
    awk '
        /^[[:space:]]*#/ { sub(/^[[:space:]]*# ?/, ""); desc = $0; next }
        /^[[:space:]]*$/ { next }
        tolower($1) == "host" {
            for (i = 2; i <= NF; i++)
                # Patterns and negations cannot be connected to
                if ($i !~ /[*?!]/) print $i "\t" desc
        }
        # A comment only describes the Host line right below it
        { desc = "" }
    ' "${configs[@]}" \
    | sort -f -u -t $'\t' -k1,1
)

if [[ -z "$hosts" ]]; then
    echo "Aucun host trouvé." >&2
    exit 1
fi

# Padding is done here because column would count the colour codes as width
menu=$(
    awk -F '\t' '
        { name[NR] = $1; desc[NR] = $2; if (length($1) > width) width = length($1) }
        END {
            for (i = 1; i <= NR; i++)
                printf "\033[1;36m%-" width "s\033[0m  \033[90m%s\033[0m\n", name[i], desc[i]
        }
    ' <<< "$hosts"
)

# Hidden for screen sharing; a file holds the ctrl-r toggle as fzf keeps no state
state_dir=$(mktemp -d)
trap 'rm -rf "$state_dir"' EXIT
visible="'$state_dir/visible'"
details='ssh -G {1} 2>/dev/null | grep -E "^(user|hostname|port|identityfile|proxyjump) "'
details+=" | { [ -e $visible ] && cat || sed -E 's/^hostname .*/hostname ••••••/'; }"

selection=$(
    fzf --ansi \
        --query="${1:-}" \
        --select-1 \
        --prompt='SSH > ' \
        --height=70% \
        --layout=reverse-list \
        --border=rounded \
        --border-label=' SSH ' \
        --color='pointer:#667eea' \
        --header="ctrl-r : afficher / masquer l'adresse" \
        --preview="$details" \
        --bind="ctrl-r:execute-silent~[ -e $visible ] && rm $visible || touch $visible~+refresh-preview" \
        --preview-window='right,45%,border-left' \
        <<< "$menu"
) || exit 0

ssh "${selection%% *}"

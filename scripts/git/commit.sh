#!/bin/bash
#######################################
# Tool to make commits
# Globals:
#   TERM (read, to detect fallback mode)
# Arguments:
#   None
# Outputs:
#   Case no ticket
#     git commit -m "[Type] Message"
#   Case ticket
#     git commit -m "[Type] #ticket-id Message"
#######################################
set -euo pipefail

WARN_LEN=60
MAX_LEN=70

# Detects whether we can safely draw an interactive arrow menu.
is_interactive_tty() {
  [[ -t 0 && -t 2 && "${TERM:-dumb}" != "dumb" ]]
}

# Arrow-key menu, with fallback to classic numbered `select`
choose_type() {
  local options=("Feature" "Chore" "Fix" "Hotfix" "Refactor" "Doc" "Test" "Style" "Release")

  if ! is_interactive_tty; then
    local i reply
    for i in "${!options[@]}"; do
      printf '%d) %s\n' "$((i + 1))" "${options[$i]}" >&2
    done
    while true; do
      read -r -p "Select commit type (default: Feature): " reply
      if [ -z "$reply" ]; then
        echo "Feature"
        return
      fi
      if [[ "$reply" =~ ^[0-9]+$ ]] && [ "$reply" -ge 1 ] && [ "$reply" -le "${#options[@]}" ]; then
        echo "${options[$((reply - 1))]}"
        return
      fi
      echo "Invalid option $reply" >&2
    done
  fi

  local selected=0
  local n=${#options[@]}
  local key rest i

  tput civis >&2 2>/dev/null || true
  trap 'tput cnorm >&2 2>/dev/null || true' RETURN

  while true; do
    printf '\r\033[K' >&2
    for i in "${!options[@]}"; do
      if [ "$i" -eq "$selected" ]; then
        printf '\033[32m%s\033[0m  ' "${options[$i]}" >&2
      else
        printf '%s  ' "${options[$i]}" >&2
      fi
    done

    IFS= read -rsn1 key
    case "$key" in
      $'\x1b')
        read -rsn2 -t 0.01 rest || true
        case "$rest" in
          '[A'|'[D') selected=$(((selected - 1 + n) % n)) ;;
          '[B'|'[C') selected=$(((selected + 1) % n)) ;;
        esac
        ;;
      "")
        break
        ;;
    esac
  done

  tput cnorm >&2 2>/dev/null || true

  # freeze the full line, keeping only the chosen type highlighted
  printf '\r\033[K' >&2
  for i in "${!options[@]}"; do
    if [ "$i" -eq "$selected" ]; then
      printf '\033[32m%s\033[0m  ' "${options[$i]}" >&2
    else
      printf '%s  ' "${options[$i]}" >&2
    fi
  done
  printf '\n' >&2

  echo "${options[$selected]}"
}

# Live-colored message input, with left/right cursor navigation.
# Fallback to plain `read` when not on an interactive tty.
read_message_colored() {
  local prefix_len="${1:-0}"
  local prompt="Enter commit message: "
  local message="" char rest extra len color pos=0 trailing

  if ! is_interactive_tty; then
    read -r -p "$prompt" message >&2
    printf '%s' "$message"
    return
  fi

  len=$prefix_len
  if [ "$len" -le "$WARN_LEN" ]; then
    color='\033[32m'
  elif [ "$len" -le "$MAX_LEN" ]; then
    color='\033[33m'
  else
    color='\033[31m'
  fi
  printf '\r\033[K%b(%3d)\033[0m %s' "$color" "$len" "$prompt" >&2

  while IFS= read -rsn1 char; do
    if [[ -z "$char" ]]; then
      break
    elif [[ "$char" == $'\x7f' ]]; then
      if [ "$pos" -gt 0 ]; then
        message="${message:0:pos-1}${message:pos}"
        pos=$((pos - 1))
      fi
    elif [[ "$char" == $'\x1b' ]]; then
      read -rsn2 -t 0.01 rest || true
      case "$rest" in
        '[D') [ "$pos" -gt 0 ] && pos=$((pos - 1)) ;;
        '[C') [ "$pos" -lt "${#message}" ] && pos=$((pos + 1)) ;;
        '[H') pos=0 ;;
        '[F') pos=${#message} ;;
        '[3')
          read -rsn1 -t 0.01 extra || true
          [ "$pos" -lt "${#message}" ] && message="${message:0:pos}${message:pos+1}"
          ;;
        '['[0-9])
          read -rsn1 -t 0.01 extra || true
          ;;
      esac
    else
      message="${message:0:pos}${char}${message:pos}"
      pos=$((pos + 1))
    fi

    len=$((prefix_len + ${#message}))
    if [ "$len" -le "$WARN_LEN" ]; then
      color='\033[32m'
    elif [ "$len" -le "$MAX_LEN" ]; then
      color='\033[33m'
    else
      color='\033[31m'
    fi

    printf '\r\033[K%b(%3d)\033[0m %s%b%s\033[0m' \
      "$color" "$len" "$prompt" "$color" "$message" >&2

    trailing=$((${#message} - pos))
    [ "$trailing" -gt 0 ] && printf '\033[%dD' "$trailing" >&2
  done
  printf '\n' >&2
  printf '%s' "$message"
}

main() {
  local type ticket message prefix prefix_len full_message len color

  type=$(choose_type)

  read -r -p "Ticket id (default: none): " ticket >&2

  if [ -n "$ticket" ]; then
    prefix="[$type] #$ticket "
  else
    prefix="[$type] "
  fi
  prefix_len=${#prefix}

  while true; do
    message=$(read_message_colored "$prefix_len")
    if [ -n "$message" ]; then
      break
    fi
    echo "Message cannot be empty" >&2
  done

  if [ -n "$ticket" ]; then
    full_message="[$type] #$ticket $message"
  else
    full_message="[$type] $message"
  fi

  len=${#full_message}
  if [ "$len" -le "$WARN_LEN" ]; then
    color='\033[32m'
  elif [ "$len" -le "$MAX_LEN" ]; then
    color='\033[33m'
  else
    color='\033[31m'
  fi

  printf '\n%b%s\033[0m\n' "$color" "$full_message" >&2
  printf 'Press Enter to commit, any other key to cancel: ' >&2
  IFS= read -rsn1 confirm
  printf '\n' >&2

  if [ -n "$confirm" ]; then
    echo "Aborted." >&2
    exit 1
  fi

  git commit -m "$full_message"
}

main "$@"

#!/bin/bash

#######################################
# Create a file with all directory path
# Globals:
#   None
# Arguments:
#   File path
# Outputs:
#   An empty file with parent folders
#######################################

mkfile() {
  for file in "$@"; do
    mkdir -p "$(dirname "$file")" && touch "$file"
  done
}

mkfile "$@"

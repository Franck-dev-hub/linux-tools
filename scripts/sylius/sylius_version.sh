#!/bin/bash

#######################################
# Create a file with all directory path
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   PHP Version
#   Symfony Version
#   Sylius version
#######################################

# Grep usage of a sylius package
grep-sylius-packages() {
  local package=$1

  echo "----------------------------------------"
  echo "Package" $(composer show "$package" | grep versions)

  echo "----------------------------------------"
  local files
  files=$(grep -r "$package" src/ --include="*.php" -l)

  if [ -z "$files" ]; then
    echo "No package usage found"
    echo "----------------------------------------"
  else
    echo "Where package is used (files)"
    echo "$files"

    echo "----------------------------------------"
    echo "Get all code related (use statements)"
    local uses
    uses=$(grep -r "use Sylius" src/ --include="*.php" | grep -i "$package")

    if [ -z "$uses" ]; then
      echo "No use statement found"
      echo "----------------------------------------"
    else
      echo "$uses"
    fi
  fi
}


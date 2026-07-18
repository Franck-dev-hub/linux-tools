#!/bin/bash
#
# Manage AppImage installation

#######################################
# Create .desktop file
# Globals:
#   None
# Arguments:
#   $1: App name
#   $2: Absolute path to AppImage exec
# Outputs:
#   <app_name>.desktop file
#######################################
desktop_shortcut() {
  local app_name="$1"
  local exec_path="$2"
  local shortcut_dir="$HOME/.local/share/applications"
  local app_type=""
  local app_category=""
  local user_response=""

  # Create application folder if doesn't exist
  mkdir -p "$shortcut_dir"

  # Questions to the user
  # Type
  while true; do
    echo -e "\e[0;36mIs it an executable app ?\e[m y/n (Default: yes)"
    read -r user_response

    case "${user_response,,}" in
      ""|y|yes)
        app_type="Application"
        break
        ;;
      n|no)
        app_type="Link"
        break
        ;;
      *)
        echo -e "\e[0;32mInvalid input\e[m. Please enter 'y' or 'n'"
        echo ""
        ;;
    esac
  done

  # Category
  echo -e "\e[0;36mEnter the app category\e[m (Utility, Development, Game ...)"
  read -r app_category

  # Populate file
  cat <<EOF > "$shortcut_dir/$app_name.desktop"
[Desktop Entry]
Type=$app_type
Name=$app_name
Exec=$exec_path
Icon=$exec_path/$app_name.ico
Terminal=false
Categories=$app_category
EOF

  echo -e "\e[0;32m$app_name installed with success !"
}

#######################################
# Main function
# Globals:
#   None
# Arguments:
#   $1: AppImage's path
# Outputs:
#   File moved to $HOME/.local/share/<app_name>
#######################################
main() {
  # Handle empty call
  if [ -z "$1" ]; then
    echo -e "\e[0;31mError :\e[m Please provide the path of the AppImage"
    exit 1
  fi

  # Handle file not found
  if [ ! -f "$1" ]; then
    echo -e "\e[0;31mError :\e[m File "$1" not found"
    exit 1
  fi

  # Extract application name
  local app_name
  app_name=$(basename "$1" .AppImage)

  # Make app executable
  chmod +x "$1"

  # Define destination folder and final path
  local dest_folder="$HOME/.local/share/$app_name"
  local final_exec_path="$dest_folder/$(basename "$1")"

  # Create new folder's app
  mkdir -p "$dest_folder"

  # Move AppImage into the folder
  mv "$1" "$final_exec_path"

  # Create .desktop
  desktop_shortcut "$app_name" "$final_exec_path"
}

main "$@"

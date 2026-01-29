#!/usr/bin/env bash

## name: dotfile-symlinker.sh
## author: Dat (and AI)
## description: Switch between themes, apply symlinks, and install GTK themes/icons smartly.
## usage: bash dotfile-switcher.sh

########################################
BASE_DOTFILES_DIR="$HOME/Documents/dotfiles"
LOGFILE="$HOME/Templates/dotfiles-sync.log"
########################################

set -euo pipefail

# Create log directory and redirect output to logfile
mkdir -p "$(dirname "$LOGFILE")"
exec > >(tee -a "$LOGFILE") 2>&1

# Function to clean old symlinks
clean_old_links() {
    echo "--- Cleaning up old symlinks ---"
    # Scan for links in HOME and .config
    mapfile -t links < <(find "$HOME" "$HOME/.config" -maxdepth 1 -type l 2>/dev/null)

    for link in "${links[@]}"; do
        [[ -e "$link" ]] || continue
        target=$(readlink -f "$link" 2>/dev/null) || continue

        # Remove link if it points to our dotfiles directory
        if [[ "$target" == "$BASE_DOTFILES_DIR"* ]]; then
            echo "[#] Removing old link: $link"
            rm -f "$link"
        fi
    done
}

# Smart ZIP extraction function
extract_and_move() {
    local zipfile="$1"
    local dest_dir="$2"
    local type_name="$3" # "Theme" or "Icon"

    # Detect the first folder name inside the ZIP
    local root_folder_in_zip
    root_folder_in_zip=$(unzip -Z1 "$zipfile" | head -n1 | cut -d/ -f1)

    # If this folder already exists in destination, skip extraction
    if [[ -d "${dest_dir}/${root_folder_in_zip}" ]]; then
        echo "[-] $type_name already exists, skipping: $root_folder_in_zip"
        return 0
    fi

    echo "[✓] New $type_name detected, installing: $(basename "$zipfile")"

    # Extract to a temporary directory
    local tmp_dir
    tmp_dir=$(mktemp -d)
    unzip -o -LL -q "$zipfile" -d "$tmp_dir"
    chmod -R u+rwX "$tmp_dir"

    # Move to destination
    shopt -s dotglob nullglob
    for item in "$tmp_dir"/*; do
        [ -e "$item" ] || continue
        item_name=$(basename "$item")
        echo "    Moving: $item_name"
        rm -rf "${dest_dir}/${item_name}" 
        mv "$item" "$dest_dir/"
    done
    shopt -u dotglob nullglob
    rm -rf "$tmp_dir"
}

# Directory check
if [[ ! -d "$BASE_DOTFILES_DIR" ]]; then
    echo "[!] Error: $BASE_DOTFILES_DIR directory not found!"
    exit 1
fi

echo "##### Available Themes #####"
cd "$BASE_DOTFILES_DIR"
# List only directories
options=(*/)
PS3="Please select a theme (number): "
select SELECTED_DIR in "${options[@]}"; do
    if [[ -n "$SELECTED_DIR" ]]; then
        DOTFILES="${BASE_DOTFILES_DIR}/${SELECTED_DIR%/}"
        echo "Selected Theme: $(basename "$DOTFILES")"
        break
    else
        echo "[!] Invalid selection."
    fi
done

read -p "Old links will be removed and the new theme will be applied. Proceed? (y/n): " confirm
[[ "$confirm" != [yY]* ]] && echo "Aborted by user." && exit 1

clean_old_links

# Link .config files
CONFIG_DIR="$DOTFILES/config"
if [[ -d "$CONFIG_DIR" ]]; then
    echo "##### Linking .config files #####"
    mkdir -p "$HOME/.config"
    for ITEM in "$CONFIG_DIR"/*; do
        [ -e "$ITEM" ] || continue
        NAME=$(basename "$ITEM")
        DEST="$HOME/.config/$NAME"

        if [[ -e "$DEST" && ! -L "$DEST" ]]; then
            echo "[!] Warning: Real file/folder exists at $DEST, skipping to avoid overwrite."
            continue
        fi

        ln -sf "$ITEM" "$DEST"
        echo "[✓] Linked: .config/$NAME"
    done
fi

# Link home directory dotfiles
echo "##### Linking home dotfiles #####"
for ITEM in "$DOTFILES"/*; do
    NAME=$(basename "$ITEM")
    # Skip special folders and the script itself
    [[ "$NAME" == "config" || "$NAME" == "themes" || "$NAME" == "icons" || "$NAME" == ".git" ]] && continue
    [[ "$NAME" == "$(basename "$0")" ]] && continue

    DEST="$HOME/.$NAME"
    # Handle cases where files already start with a dot
    if [[ "$NAME" == .* ]]; then DEST="$HOME/$NAME"; fi

    if [[ -e "$DEST" && ! -L "$DEST" ]]; then
        echo "[!] Warning: Real file exists at $DEST, skipping."
        continue
    fi

    ln -sf "$ITEM" "$DEST"
    echo "[✓] Linked: $DEST"
done

# Handle GTK Themes and Icons
THEMES_DEST="$HOME/.themes"
ICONS_DEST="$HOME/.icons"
mkdir -p "$THEMES_DEST" "$ICONS_DEST"

# Themes
if [[ -d "$DOTFILES/themes" ]]; then
    for zip in "$DOTFILES/themes"/*.zip; do
        [[ -f "$zip" ]] && extract_and_move "$zip" "$THEMES_DEST" "Theme"
    done
fi

# Icons
if [[ -d "$DOTFILES/icons" ]]; then
    for zip in "$DOTFILES/icons"/*.zip; do
        [[ -f "$zip" ]] && extract_and_move "$zip" "$ICONS_DEST" "Icon"
    done
fi

echo -e "\n[DONE] Theme applied successfully!"

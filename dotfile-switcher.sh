#!/usr/bin/env bash

## name: dotfile-switcher.sh
## author: Dat (and AI)
## description: Switch between different dotfile themes: clean old symlinks, apply new ones, and install GTK themes/icons from ZIP files.
## usage: bash dotfile-switcher.sh

########################################
BASE_DOTFILES_DIR="$HOME/Documents/dotfiles"
LOGFILE="$HOME/Templates/dotfiles-sync.log"
########################################

set -euo pipefail
exec > >(tee -a "$LOGFILE") 2>&1

# Clean old symlinks
clean_old_links() {
    echo "--- Cleaning up old dotfile symlinks ---"

    mapfile -t links < <(find "$HOME" "$HOME/.config" -maxdepth 1 -type l 2>/dev/null)

    for link in "${links[@]}"; do
        [[ -e "$link" ]] || continue
        target=$(readlink -f "$link" 2>/dev/null) || continue

        if [[ "$target" == "$BASE_DOTFILES_DIR"* ]]; then
            echo "[#] Removing old link: $link"
            rm -f "$link"
        fi
    done
}

# Theme Selection
echo "##### Available Themes #####"
cd "$BASE_DOTFILES_DIR"
PS3="Please select a theme (number): "
select SELECTED_DIR in */; do
    if [[ -n "$SELECTED_DIR" ]]; then
        DOTFILES="${BASE_DOTFILES_DIR}/${SELECTED_DIR%/}"
        echo "Selected Theme: $(basename "$DOTFILES")"
        break
    else
        echo "[!] Invalid selection. Please try again."
    fi
done

# Confirmation
read -p "This will remove old symlinks and apply the new theme (including GTK themes/icons). Proceed? (y/n): " confirm
[[ "$confirm" != [yY]* ]] && echo "Aborted by user." && exit 1

# Clean old symlinks
clean_old_links

# Link new .config files
CONFIG_DIR="$DOTFILES/config"
if [[ -d "$CONFIG_DIR" ]]; then
    echo "--- Linking new .config files ---"
    for ITEM in "$CONFIG_DIR"/*; do
        [ -e "$ITEM" ] || continue
        NAME=$(basename "$ITEM")
        DEST="$HOME/.config/$NAME"

        if [[ -e "$DEST" && ! -L "$DEST" ]]; then
            echo "[!] Warning: Real folder/file exists at $DEST, skipping to avoid overwrite."
            continue
        fi

        ln -sf "$ITEM" "$DEST"
        echo "[✓] Linked: .config/$NAME"
    done
fi

# Link new home dotfiles
echo "--- Linking new home dotfiles ---"
for ITEM in "$DOTFILES"/*; do
    NAME=$(basename "$ITEM")
    # Skip config, themes, icons folders and the script itself
    [[ "$NAME" == "config" || "$NAME" == "themes" || "$NAME" == "icons" ]] && continue
    [[ "$NAME" == "$(basename "$0")" ]] && continue

    DEST="$HOME/.$NAME"
    if [[ "$NAME" == .* ]]; then
        DEST="$HOME/$NAME"
    fi

    if [[ -e "$DEST" && ! -L "$DEST" ]]; then
        echo "[!] Warning: Real file exists at $DEST, skipping to avoid overwrite."
        continue
    fi

    ln -sf "$ITEM" "$DEST"
    echo "[✓] Linked: $DEST"
done

# GTK Themes and Icons: Extract and move contents
echo "--- Handling GTK themes and icons ---"

THEMES_SRC="$DOTFILES/themes"
ICONS_SRC="$DOTFILES/icons"

THEMES_DEST="$HOME/.themes"
ICONS_DEST="$HOME/.icons"

mkdir -p "$THEMES_DEST" "$ICONS_DEST"

# Temporary extraction directory (auto-cleaned on exit)
TMP_EXTRACT=$(mktemp -d)
trap 'rm -rf "$TMP_EXTRACT"' EXIT

extract_and_move() {
    local zipfile="$1"
    local dest_dir="$2"
    local type_name="$3"  # "theme" or "icon"

    echo "[✓] Processing $(basename "$zipfile") → $dest_dir"

    # Extract quietly, force lowercase filenames, overwrite existing
    unzip -o -LL -q "$zipfile" -d "$TMP_EXTRACT"

    # Fix permissions to ensure everything is movable
    chmod -R u+rwX "$TMP_EXTRACT"

    # Move all extracted top-level items
    shopt -s dotglob nullglob
    for item in "$TMP_EXTRACT"/*; do
        [ -e "$item" ] || continue
        item_name=$(basename "$item")
        echo "   Moving $type_name: $item_name"
        rm -rf "${dest_dir}/${item_name}"  # Remove old version if exists
        mv "$item" "$dest_dir/"
    done
    shopt -u dotglob nullglob

    # Clear temp directory for next ZIP
    rm -rf "$TMP_EXTRACT"/*
}

# Handle themes
if [[ -d "$THEMES_SRC" ]]; then
    echo "Installing GTK themes from $THEMES_SRC ..."
    found_zip=false
    for zipfile in "$THEMES_SRC"/*.zip; do
        [[ -f "$zipfile" ]] || continue
        found_zip=true
        extract_and_move "$zipfile" "$THEMES_DEST" "theme"
    done
    $found_zip || echo "No theme ZIP files found in $THEMES_SRC."
else
    echo "No 'themes' directory found in selected theme."
fi

# Handle icons
if [[ -d "$ICONS_SRC" ]]; then
    echo "Installing icon packs from $ICONS_SRC ..."
    found_zip=false
    for zipfile in "$ICONS_SRC"/*.zip; do
        [[ -f "$zipfile" ]] || continue
        found_zip=true
        extract_and_move "$zipfile" "$ICONS_DEST" "icon"
    done
    $found_zip || echo "No icon ZIP files found in $ICONS_SRC."
else
    echo "No 'icons' directory found in selected theme."
fi

echo "Completed! All dotfiles, GTK themes, and icons have been applied successfully."

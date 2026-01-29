#!/usr/bin/env bash

## name: xfce-theme-change.sh
## author: Dat
## description: Xfce GTK theme, icon theme, cursor theme changer. Also changes background and neovim colorscheme.
## usage: bash xfce_theme_change.sh [number]


# GTK Themes -> /usr/share/themes/
GTKTHEME[1]="Gruvbox-Dark-Medium"
GTKTHEME[2]="Nordic"
GTKTHEME[3]="Graphite-Dark"

# Window Manager Options -> /usr/share/themes/
XFWM4THEME[1]="Default"
XFWM4THEME[2]="Default"
XFWM4THEME[3]="Graphite-Dark"

# Icon Packs --> /usr/share/icons/
XFWM4ICONS[1]="Gruvbox-Plus-Dark"
XFWM4ICONS[2]="Zafiro-Nord-Black"
XFWM4ICONS[3]="Clarity"

# Cursor Themes --> /usr/share/icons/
CURSORTHEME[1]="Future-cyan-cursors"
CURSORTHEME[2]="Nordzy-cursors"
CURSORTHEME[3]="Future-dark-cursors"

# Backgrounds -> /usr/share/backgrounds/
MONITOR_PATH=$(xfconf-query -c xfce4-desktop -l | grep last-image | head -n1)
WALLPAPER[1]="/usr/share/backgrounds/Wp/gruvbox/gruvbox_astronaut2.png"
WALLPAPER[2]="/usr/share/backgrounds/Wp/nord/nord-paintedcity.jpg"
WALLPAPER[3]="/usr/share/backgrounds/Wp/"

# Neovim Colorschemes
NVIM_COLOR[1]="gruvbox"
NVIM_COLOR[2]="nord"
NVIM_COLOR[3]="gruvbox-material"

# Make the XFCE changes
xfconf-query -c xsettings -p /Net/ThemeName -s ${GTKTHEME[$1]}
xfconf-query -c xfwm4 -p /general/theme -s ${XFWM4THEME[$1]}
xfconf-query -c xsettings -p /Net/IconThemeName -s ${XFWM4ICONS[$1]}
xfconf-query -c xsettings -p /Gtk/CursorThemeName -s ${CURSORTHEME[$1]}
xfconf-query -c xfce4-desktop -p "$MONITOR_PATH" -s "${WALLPAPER[$1]}"
xfce4-panel -r

#Change Neovim theme
NVIM_INIT="$HOME/.config/nvim/init.vim"
if grep -q "^colorscheme " "$NVIM_INIT"; then
    sed -i "s/^colorscheme .*/colorscheme ${NVIM_COLOR[$1]}/" "$NVIM_INIT"
else
    echo "colorscheme ${NVIM_COLOR[$1]}" >> "$NVIM_INIT"
fi

exit 0

#!/usr/bin/env bash

## name: arch-install-update.sh
## author: Dat (and AI)
## description: Arch Linux package synchronization and system update script
## usage: bash arch-install-packages.sh

set -e

# Install reflector if not already present (required for mirror update)
sudo pacman -S --needed --noconfirm reflector

# Update mirrorlist with faster and more reliable mirrors (Turkey + nearby European countries)
echo "Updating Mirrorlist..."
sudo reflector \
    --country 'Turkey,Germany,Bulgaria,Romania,Greece,France' \
    --age 12 \
    --protocol https \
    --latest 15 \
    --sort rate \
    --save /etc/pacman.d/mirrorlist

echo "Synchronizing package databases and upgrading the system..."

# Install yay from AUR if not already present
if ! command -v yay &> /dev/null; then
    echo "yay not found → installing from AUR..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
    echo "yay installed successfully!"
else
    echo "yay is already installed."
fi

# Package list
declare -a PACKAGES=(
    # System Essentials
    # Core system functionality, kernel, and boot management.
    "acpid"              # ACPI power management daemon
    "base"               # Minimal package set for base Arch system
    "base-devel"         # Essential development tools (make, gcc, etc.)
    "efibootmgr"         # EFI boot manager
    "git"                # Distributed version control
    "grub"               # GRUB bootloader
    "linux"              # Default Linux kernel
    "linux-firmware"     # Firmware files for hardware
    "linux-headers"      # Kernel headers (needed for DKMS, etc.)
    "reflector"          # Updates mirrorlist for faster downloads
    "sudo"               # Allow privilege escalation
    "yay"                # AUR helper
    "curl"               # Transferring data with URLs
    "bleachbit"          # System cleaner
    "xorg-xhost"         # This is for running bleachbit with root

    # Filesystem & Utils
    # Btrfs, filesystem tools, disk/system monitoring, and core utilities.
    "btrfs-progs"        # Tools for Btrfs filesystem
    "dosfstools"         # Tools for FAT filesystems
    "snapper"            # A tool for managing BTRFS and LVM snapshots
    "btrfs-assistant"    # BTRFS subvolumes and Snapper snapshot manager (AUR)
    "grub-btrfs"         # Btrfs snapshot support in GRUB (AUR)
    "snap-pac"           # Pacman hooks that use snapper to create pre/post btrfs snapshots (AUR)
    "inotify-tools"      # Filesystem events monitoring component
    "zram-generator"     # Compressed swap in RAM
    "man-db"             # Man pages database
    "fastfetch"          # Modern neofetch alternative
    "htop"               # Interactive process viewer
    "rsync"              # Fast incremental file transfer
    "xdg-user-dirs"      # Creates standard user directories
    "less"               # Pager program
    "jq"                 # JSON processor
    "python-mutagen"     # Python audio metadata library
    "caligula"           # Disk burning tool
    "tldr"               # Tealdeer tldr manual for apps

    # Hardware & Drivers
    # Networking, audio, Bluetooth, and graphics drivers.
    "networkmanager"     # Network connection manager
    "network-manager-applet" # NetworkManager tray applet
    "iptables-nft"       # nftables-based iptables
    "bluez"              # Bluetooth protocol stack
    "bluez-utils"        # Bluetooth tools
    "blueman"            # Bluetooth manager (GUI)
    "pipewire"           # Modern audio/video server
    "pipewire-alsa"      # Pipewire ALSA compatibility
    "pipewire-jack"      # Pipewire JACK replacement
    "pipewire-pulse"     # Pipewire PulseAudio replacement
    "pipewire-v4l2"      # Pipewire V4L2 support
    "pipewire-zeroconf"  # Pipewire Zeroconf support
    "pavucontrol"        # Audio mixer
    "sof-firmware"       # Intel Sound Open Firmware
    "brightnessctl"      # Control backlight brightness
    "intel-ucode"        # Intel CPU microcode updates
    "nvidia-open-dkms"   # NVIDIA open-source kernel modules
    "nvidia-settings"    # NVIDIA X Server Settings
    "cuda"               # Nvidia cuda support

    # Desktop Environment
    # Hyprland WM, SDDM, Wayland helpers, and theming tools.
    "hyprland"           # Dynamic Wayland compositor
    "hyprcursor"         # Hyprland cursor theme engine
    "hypridle"           # Hyprland idle daemon
    "hyprlock"           # Screen locker for Hyprland
    "hyprpaper"          # Wallpaper utility for Hyprland
    "hyprpolkitagent"    # Polkit agent for Hyprland
    "sddm"               # Simple Desktop Display Manager
    "kitty"              # GPU-accelerated terminal
    "waybar"             # Customizable Wayland bar
    "wofi"               # Wayland application launcher
    "qt5-wayland"        # Wayland Qt5 support
    "qt6-wayland"        # Wayland Qt6 support
    "wl-clipboard"       # Wayland clipboard
    "kvantum"            # Qt styling engine
    "kvantum-qt5"        # Kvantum for Qt5
    "qt5ct"              # Qt5 configuration tool
    "qt6ct"              # Qt6 configuration tool
    "nwg-look"           # GTK theme manager
    "hyprshot"           # Screenshotter tool for hyprland
    "ydotool"            # command line keyboard automation tool

    # Core Applications
    # Web, communication, media playback, and file management.
    "firefox"            # Mozilla Firefox browser
    "chromium"           # Chromium web browser
    "thunar"             # File manager for Xfce
    "thunar-archive-plugin" # Archive integration for Thunar
    "xarchiver"          # Archive manager (GUI)
    "unzip"              # ZIP decompressor
    "zip"                # ZIP archiver
    "udiskie"            # Removable device automounter
    "gvfs-mtp"           # MTP support for GVFS
    "localsend"          # Local file sharing app
    "qbittorrent"        # BitTorrent client
    "vlc"                # Media player
    "vlc-plugins-all"    # All VLC plugins
    "ffmpeg"             # Multimedia framework
    "metadata-cleaner"   # Metadata searcyh and clean GUI

    # Development & Office
    # Coding and productivity tools.
    "neovim"             # Vim fork focused on extensibility
    "vim"                # Vi improved text editor
    "visual-studio-code-bin" # VScode IDE
    "netbeans"           # Java IDE
    "libreoffice-fresh"  # LibreOffice office suite

    # Gaming & Entertainment
    # Gaming platform, emulation, and other entertainment apps.
    "steam"              # Gaming platform
    "wine"               # Windows compatibility layer
    "an-anime-game-launcher-bin" # Genshin impact starter
    "prismlauncher"      # Minecraft launcher
    "retroarch"          # Frontend for emulators
    "retroarch-assets-ozone" # RetroArch Ozone assets
    "retroarch-assets-xmb" # RetroArch XMB assets
    "libretro-mgba"      # mGBA libretro core 	
    "calibre"            # E-book library management
    "yt-dlp-git"         # YouTube downloader
    "mousai"             # Song identification tool
    "pokeget"            # Pokémon CLI utility
    "komikku"            # Comic,Manga,Mahnwa,Manhua Reader/Downloader

    # Fonts & Icons
    # Typefaces for visual consistency.
    "noto-fonts"         # Noto font family
    "noto-fonts-emoji"   # Noto emoji fonts
    "ttf-nerd-fonts-symbols" # Nerd Fonts symbols
    "ttf-nerd-fonts-symbols-mono" # Monospace Nerd Fonts symbols
    "woff2-font-awesome" # Font Awesome web fonts
)

# Extract only package names while preserving comments in the list above
PACKAGE_NAMES=()
for item in "${PACKAGES[@]}"; do
    pkg=$(echo "$item" | awk '{print $1}' | grep -v '^$')
    [[ -n "$pkg" ]] && PACKAGE_NAMES+=("$pkg")
done

echo "Installing/updating defined packages..."
yay -Syyu --needed "${PACKAGE_NAMES[@]}"

# Check and remove orphan packages (with timeout to prevent hanging)
echo "Checking for orphan packages..."
ORPHANS=$(timeout 300 pacman -Qtdq || echo "")

if [[ -n "$ORPHANS" ]]; then
    echo "Unused orphan packages found: $ORPHANS"
    read -p "Remove them? (y/N): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] && sudo pacman -Rns $ORPHANS --noconfirm && echo "Orphans removed."
else
    echo "No orphan packages found."
fi

# Check for explicitly installed packages not defined in the script
echo "Checking for extra packages not defined in the script..."
INSTALLED_EXPLICIT=$(pacman -Qqe)
TO_REMOVE=()

for pkg in $INSTALLED_EXPLICIT; do
    [[ " ${PACKAGE_NAMES[@]} " =~ " $pkg " ]] || TO_REMOVE+=("$pkg")
done

if [[ ${#TO_REMOVE[@]} -gt 0 ]]; then
    echo "The following packages are installed but not in the script list:"
    printf '%s\n' "${TO_REMOVE[@]}"
    read -p "Remove them? (y/N): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] && sudo pacman -Rns "${TO_REMOVE[@]}" --noconfirm && echo "Extra packages removed."
else
    echo "Your system is fully in sync with the script. No extra packages found."
fi

# Clean package cache (keep only the latest version)
echo "Cleaning pacman cache..."
sudo pacman -Sc --noconfirm

echo "Process completed!"

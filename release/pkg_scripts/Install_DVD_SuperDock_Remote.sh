#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
# Install the keyboard-class SuperDock receiver preset without the OSD mapper.
# Optional argument: mounted MiSTer SD root (defaults to /media/fat).
set -eu

die() { echo "ERROR: $*" >&2; exit 1; }
[ "$#" -le 1 ] || die "Usage: $0 [MiSTer SD root]"
sd_root=${1:-/media/fat}
[ -d "$sd_root" ] || die "SD root does not exist: $sd_root"
sd_root=$(CDPATH= cd -- "$sd_root" && pwd)
inputs=$sd_root/config/inputs
name=DVD-Player_input_1c4f_0002_v3.map
target=$inputs/$name

echo "DVD Player: SuperDock remote (1c4f:0002)"
echo "Exit DVD Player before installing; reload the core afterwards."
mkdir -p "$inputs"
[ ! -L "$target" ] || die "Refusing to replace a symbolic link: $target"
if [ -e "$target" ] && [ ! -f "$target" ]; then
    die "Not a regular map file: $target"
fi
tmp=$(mktemp "$inputs/.dvd-remote.XXXXXX")
trap 'rm -f "$tmp"' EXIT
trap 'exit 1' HUP INT TERM

# Exactly 32 little-endian uint32 slots. All codes fit in the low byte.
# D-pad: Right, Left, Down, Up. J1: Confirm, Back, Play/Pause, DVD Menu,
# Previous Chapter, Next Chapter, Subtitle, Audio Next. Remaining slots unused.
for code in 106 105 108 103 28 45 60 87 0 0 67 0 \
            0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; do
    octal=$(printf '%03o' "$code")
    printf '%b' "\\0$octal\\0000\\0000\\0000"
done > "$tmp"
[ "$(wc -c < "$tmp" | tr -d ' ')" = 128 ] || die "Generated map is not 128 bytes"

if [ -f "$target" ] && cmp -s "$tmp" "$target"; then
    echo "Remote preset already installed."
else
    if [ -f "$target" ]; then
        backup_root=$sd_root/DVD/backup/superdock-remote
        mkdir -p "$backup_root"
        backup=$(mktemp -d "$backup_root/map.XXXXXX")
        cp -p "$target" "$backup/$name"
        cmp -s "$target" "$backup/$name" || die "Backup verification failed"
        echo "Previous mapping backed up to: $backup/$name"
    fi
    chmod 644 "$tmp"
    mv -f "$tmp" "$target"
    echo "Installed: $target"
fi

for advanced in "$inputs"/DVD-Player_advanced_input_1c4f_0002*.map; do
    [ -e "$advanced" ] || continue
    echo "Existing advanced remap may override this preset: $advanced"
    echo "It was left untouched. See the remote setup guide for recovery."
done
echo "OK=Confirm; Cancel=Back (hold ~3s to stop); 1=Play/Pause; 2=Subtitle; 3=DVD Menu."
echo "Remote Menu/F12 remains the MiSTer OSD button. Reload DVD Player now."

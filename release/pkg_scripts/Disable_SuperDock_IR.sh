#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
# Disable only the SuperDock keyboard-class IR receiver, until re-enumeration.
# Run in the background from /media/fat/linux/user-startup.sh.
# Optional: enable (undo now), --once (do not wait for USB enumeration).
set -eu

state=0
attempts=30
for arg in "$@"; do
    case "$arg" in
        enable) state=1 ;;
        disable) state=0 ;;
        --once) attempts=1 ;;
        *) echo "Usage: $0 [disable|enable] [--once]" >&2; exit 2 ;;
    esac
done

# Override only for host tests with a synthetic sysfs directory.
usb_root=${SUPERDOCK_USB_SYSFS:-/sys/bus/usb/devices}
while [ "$attempts" -gt 0 ]; do
    found=0
    for d in "$usb_root"/*; do
        [ "$(cat "$d/idVendor" 2>/dev/null)" = 1c4f ] || continue
        [ "$(cat "$d/idProduct" 2>/dev/null)" = 0002 ] || continue
        case "$(cat "$d/product" 2>/dev/null)" in
            *pico_ir_keyboard*) ;;
            *) continue ;;
        esac
        if [ ! -f "$d/authorized" ]; then
            echo "IR receiver has no USB authorization control: $d" >&2
            exit 1
        fi
        if [ "$(cat "$d/authorized")" != "$state" ]; then
            printf '%s\n' "$state" > "$d/authorized"
        fi
        [ "$(cat "$d/authorized")" = "$state" ] || {
            echo "Failed to set IR receiver authorization: $d" >&2
            exit 1
        }
        found=1
        echo "SuperDock IR receiver authorized=$state: $d"
    done
    [ "$found" = 0 ] || exit 0
    attempts=$((attempts - 1))
    [ "$attempts" = 0 ] || sleep 1
done
echo "SuperDock IR receiver not found; no devices changed." >&2
exit 1

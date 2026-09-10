# Disable SuperDock IR at boot

Copy `release/pkg_scripts/Disable_SuperDock_IR.sh` to
`/media/fat/Scripts/Disable_SuperDock_IR.sh` on MiSTer.

Back up `/media/fat/linux/user-startup.sh`, then add this line after its shebang
and before any `exit` or `exec` command. Keep all existing startup commands:

```sh
sh /media/fat/Scripts/Disable_SuperDock_IR.sh >/tmp/superdock-ir.log 2>&1 &
```

If `user-startup.sh` does not exist, copy the existing
`/media/fat/linux/_user-startup.sh` template to that name first. If neither file
exists, create `user-startup.sh` with `#!/bin/sh` as its first line. Use Unix LF
line endings. Over SSH, ensure it is executable:

```sh
chmod +x /media/fat/linux/user-startup.sh
```

Reboot, or exit DVD playback and run the new script from MiSTer's Scripts menu
to disable the receiver immediately. Check `/tmp/superdock-ir.log` after reboot:
`authorized=0` confirms it found and disabled the receiver. No matching device
is reported explicitly, rather than treated as success.

The script matches VID `1c4f`, PID `0002`, and a product name containing
`pico_ir_keyboard`, then sets that USB device's `authorized` attribute to zero.
It waits up to approximately 30 seconds for enumeration, in the background,
then exits. It does not disable the whole hub, modify controller maps, or change
the DVD player. It disables all input from that receiver across MiSTer cores,
including arrows and F12. Other remotes using the same receiver are disabled too.

This is a boot-time action, not a persistent hotplug monitor: unplugging and
reconnecting the receiver/dock can re-enable it until the script is run again.

To undo permanently, remove the added startup line and reboot. To undo for the
current session, after the boot helper has finished:

```sh
sh /media/fat/Scripts/Disable_SuperDock_IR.sh enable
```

IR receivers do not negotiate priority with one another. This prevents unwanted
MiSTer input; it does not prove that the SuperDock caused RetroTINK response lag
or guarantee that disabling its USB interface resolves that lag.

Host verification uses a synthetic USB sysfs tree to check the exact device
match, repeated runs, enable/disable, and preservation of other devices. This
script has not been verified on the user's SuperDock.

References:

- [MiSTer boot-script documentation](https://mister-devel.github.io/MkDocs_MiSTer/advanced/network/)
- [Linux USB device authorization](https://docs.kernel.org/usb/authorization.html)

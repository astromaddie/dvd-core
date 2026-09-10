# SuperDock remote setup

The `1c4f:0002` receiver (`TinyUSB pico_ir_keyboard`) reports keyboard events.
The reported OSD mapping failure leaves Confirm unset; the remote's OK button
sends Enter (28). This preset installs the reported working map directly.
It is a device-specific workaround, not a change to the general OSD mapper.

## Install

1. Copy `release/pkg_scripts/Install_DVD_SuperDock_Remote.sh` into the MiSTer
   SD card's `Scripts` directory (the downloadable add-on already has this layout).
2. Exit DVD Player, then run **Install DVD SuperDock Remote** from Scripts.
3. Reload DVD Player. The installer prints the backup path if a map was replaced.

Alternatively, on a computer with the SD card mounted, run:

```sh
sh Install_DVD_SuperDock_Remote.sh /path/to/mounted/SD
```

This writes `config/inputs/DVD-Player_input_1c4f_0002_v3.map`: exactly 128 bytes,
32 little-endian uint32 values. An identical existing map is a no-op. A different
existing map is backed up and verified before replacement. No binaries or other
devices' maps are changed. It can be used with the audio-queue experiment.

| Remote button | Linux keycode | DVD function | Map slot |
| --- | ---: | --- | ---: |
| Right | 106 | Right | 0 |
| Left | 105 | Left | 1 |
| Down | 108 | Down | 2 |
| Up | 103 | Up | 3 |
| OK | 28 | Confirm | 4 |
| Cancel | 45 | Back; hold about 3 seconds to stop | 5 |
| 1 | 60 | Play/Pause | 6 |
| 3 | 87 | DVD Menu | 7 |
| 2 | 67 | Subtitle | 10 |

Remote Menu sends F12 (88), reserved for the MiSTer OSD; use **3** for DVD menus.
Previous/Next Chapter and Audio Next remain unbound. The reported receiver
firmware does not emit events for the dedicated transport buttons, so a map
cannot make those buttons work. No receiver firmware modification is included.

## Existing remaps and recovery

Avoid the OSD advanced button/key remap for this setup: mapping F12 to a direction
can make the OSD inaccessible. The installer warns about receiver-specific
advanced maps but does not remove them. If affected, exit to the MiSTer menu or
power down and mount the SD on a computer. Back up and move the offending
`DVD-Player_advanced_input_1c4f_0002*.map` out of `config/inputs`, then reload.
Do not delete other devices' advanced maps.

If `controller_unique_mapping` is enabled for this receiver, MiSTer uses a
device-specific suffix in its filename. This installer targets the standard
VID/PID map only; it does not overwrite those uniquely named maps. Match the
actual filename for your receiver before using this preset with that setting.

To undo, exit DVD Player and restore the backup to its original map path. If no
map existed before installation, remove only the installed receiver map. Reload
the core. For keycode capture, the reported MiSTer input grab (`EVIOCGRAB`) means
you must exit the running core first.

## Validation

Host tests check all 32 slots, the size/byte order, repeated installation,
backup fidelity, preservation of unrelated/advanced maps, and symlink refusal.
The mapping follows `CONF_STR` J1 in `fpga/DVD.sv`. MiSTer filename/slot storage
was checked against Main_MiSTer `input.cpp` at the pinned commit
`0a8fb44ccec6d69c8b7f158abd5fe8065ab2bf4f`.
Receiver behavior and successful playback navigation are user-supplied findings;
this installer has not yet been run on MiSTer hardware.

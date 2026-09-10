# Subtitle presentation experiment

This candidate targets choppy movie playback when subtitles are enabled in the
buffered FPGA YUV420 path. It retains the 128-packet audio queue experiment.
Hardware playback validation is pending; a successful cross-build does not prove
that this fixes the reported stutter.

## Evidence and proposed change

In the supplied on/off log, one approximately 21-second subtitles-off interval
had one stale-frame drop; the next approximately three-second on interval had
14; the following approximately 93-second off interval had five. During choppy
playback the decoded-video queue remained populated, unlike the original audio
queue starvation. This supports investigating subtitle presentation overhead,
but does not by itself isolate its exact cost.

Previously the presenter waited for the FPGA to acknowledge the preceding
display request, then copied the next video frame to cached scratch RAM and
composed its subtitles, then copied the result to the free display buffer.
This candidate performs the scratch preparation before that wait for timed
movie frames, allowing it to overlap the outstanding display request. It still
waits for the ACK and reads the actual display-buffer status before choosing or
writing the destination. Decoder frames remain unmodified. Menu, UI redraw,
and still-frame paths retain preparation after the wait. Navigation generation
checks discard obsolete prepared frames; an on/off change during the wait
causes preparation to be repeated using the current setting.

Uniform movie subtitle palettes also use a small cache: four luma blend tables
and 256 alpha-weighted chroma combinations for the four 2-bit codes in a 2x2
block. Palette or alpha changes rebuild the cache. Changing video backgrounds
are blended afresh on every frame. Clipped/partial chroma blocks and spatial
CHG_COLCON palette changes retain the original scalar calculation. Integer
rounding and authored Y/Cr/Cb values are preserved.

## Validation performed locally

Run the native differential test from the repository root:

```sh
cc -O2 -Wall -Wextra -Werror -fsanitize=address,undefined \
  player/tools/test_subtitle_blend_cache.c -o /tmp/test-subtitle-cache
/tmp/test-subtitle-cache
```

It compares the cached blend against the previous scalar arithmetic for 210
palette/alpha states, all 256 pixel-code blocks and all 256 background values
in each plane (13,762,560 block/background comparisons), plus luma, cache
invalidation, odd bitmap stride, and edge fallback checks. It does not exercise
DVD navigation, full SPU decoding, or FPGA timing.

The standalone player is cross-built with the existing Cortex-A9 ARM hard-float,
NEON/VFPv3 flags and static FFmpeg libraries. The test package records its ELF,
library/symbol-version checks and checksums. No RBF or shared-library changes
are required. Include `subtitle_blend_cache.h` beside the player source when
rebuilding from a source bundle.

## MiSTer comparison

Exit playback and back up `/media/fat/DVD/bin/dvd_av_threaded_test`. Replace it
with the candidate binary and keep the existing libraries, core and settings.
The package includes the previous 128-packet player as the control/rollback;
the 32-packet player would reintroduce the earlier audio-queue variable.

Replay the same subtitle-heavy chapter in both builds, ideally for at least
60 seconds each with subtitles on, then repeat the on/off toggle. Check subtitle
colors, outlines and fades, audio sync, chapter jumps, pause/resume, and menu
highlights. Save each complete `player.log` separately, recording the hardware,
disc/ISO, PAL/NTSC and installed binary checksum. PAL, NTSC, physical media,
ISO, and authored spatial palette changes need hardware coverage.

Compare rendered FPS, stale drops, queue depths and audio underruns. The new
`SUBTITLE PRESENT` samples report total preparation before ACK, scratch-copy,
compose, final display-copy and ACK-wait times. Total preparation includes
visibility checks, locking, allocation and cache setup, which the narrower
compose measurement omits. `yuv_copy_us` remains the final DDR copy only;
use total frame/mailbox cycle and stale drops to judge improvement. Observed
mailbox-to-ACK time may now include preparation before the ACK is polled and
must not be read as a pure hardware latency measurement.

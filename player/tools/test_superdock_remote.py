#!/usr/bin/env python3
"""Exercise the actual shell installer against a disposable SD root."""
import pathlib
import struct
import subprocess
import tempfile
import unittest

SCRIPT = pathlib.Path(__file__).resolve().parents[2] / 'release/pkg_scripts/Install_DVD_SuperDock_Remote.sh'
NAME = 'DVD-Player_input_1c4f_0002_v3.map'


class RemoteInstallTest(unittest.TestCase):
    def test_install_backup_and_preservation(self):
        with tempfile.TemporaryDirectory(prefix='dvd-remote-test-') as directory:
            root = pathlib.Path(directory) / 'SD card'
            inputs = root / 'config/inputs'
            inputs.mkdir(parents=True)
            target = inputs / NAME
            previous = bytes(range(128))
            target.write_bytes(previous)
            advanced = inputs / 'DVD-Player_advanced_input_1c4f_0002_v1.map'
            other = inputs / 'DVD-Player_input_1234_5678_v3.map'
            advanced.write_bytes(b'advanced mapping')
            other.write_bytes(b'other controller')
            result = subprocess.run(['sh', str(SCRIPT), str(root)], check=True, capture_output=True, text=True)
            self.assertIn('advanced remap', result.stdout)
            values = [0] * 32
            values[:8] = [106, 105, 108, 103, 28, 45, 60, 87]
            values[10] = 67
            self.assertEqual(target.read_bytes(), struct.pack('<32I', *values))
            backups = list((root / 'DVD/backup').rglob(NAME))
            self.assertEqual(len(backups), 1)
            self.assertEqual(backups[0].read_bytes(), previous)
            subprocess.run(['sh', str(SCRIPT), str(root)], check=True, capture_output=True)
            self.assertEqual(list((root / 'DVD/backup').rglob(NAME)), backups)
            self.assertEqual(advanced.read_bytes(), b'advanced mapping')
            self.assertEqual(other.read_bytes(), b'other controller')
            self.assertFalse(list(inputs.glob('.dvd-remote.*')))

    def test_fresh_install_and_symlink_refusal(self):
        with tempfile.TemporaryDirectory(prefix='dvd-remote-test-') as directory:
            root = pathlib.Path(directory)
            subprocess.run(['sh', str(SCRIPT), str(root)], check=True, capture_output=True)
            target = root / 'config/inputs' / NAME
            self.assertEqual(len(target.read_bytes()), 128)
            self.assertFalse((root / 'DVD/backup').exists())
            target.unlink()
            victim = root / 'other.map'
            victim.write_bytes(b'preserve')
            target.symlink_to(victim)
            result = subprocess.run(['sh', str(SCRIPT), str(root)], capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(victim.read_bytes(), b'preserve')


if __name__ == '__main__':
    unittest.main()

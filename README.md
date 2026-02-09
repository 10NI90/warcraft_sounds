# Warcraft Peon Sounds for Claude Code

Add Warcraft Peon voice lines as sound effects to your Claude Code hooks.

| Event | Sound | Quote |
|-------|-------|-------|
| Session Start | PeonReady1 | *"Ready to work!"* |
| Prompt Submit | PeonYes3 | *"Yes, me lord!"* |
| Notification | PeonWhat3 | *"What?"* |
| Task Complete | PeonBuildingComplete1 | *"Job's done!"* |

## Prerequisites

- **macOS**: `ffmpeg` (to convert .ogg to .wav for `afplay`)
  ```sh
  brew install ffmpeg
  ```
- **Linux**: `paplay` (PulseAudio) or `aplay` (ALSA) — usually pre-installed
- **Optional**: `jq` for merging into existing settings (recommended if you already have a `~/.claude/settings.json`)
  ```sh
  # macOS
  brew install jq
  # Linux
  sudo apt install jq
  ```

## Install

```sh
git clone https://github.com/YOUR_USERNAME/warcraft_sounds.git
cd warcraft_sounds
./install.sh
```

The script will:
1. Copy sound files to `~/.claude/hooks/`
2. Convert `.ogg` to `.wav` on macOS (using ffmpeg)
3. Add hook entries to `~/.claude/settings.json`

Restart Claude Code after installing.

## Uninstall

```sh
./uninstall.sh
```

Removes the sound files and hook entries from your settings.

## Customization

Want different sounds for different events? Edit the `HOOK_SOUNDS` mapping in [install.sh](install.sh) and drop your `.ogg` files into the [hooks/](hooks/) directory, then re-run the installer.

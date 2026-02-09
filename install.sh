#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# Parallel arrays for hook event -> sound file mapping (bash 3.2 compatible)
HOOK_EVENTS=("SessionStart" "UserPromptSubmit" "Notification" "Stop")
HOOK_SOUNDS=("PeonReady1"   "PeonYes3"         "PeonWhat3"    "PeonBuildingComplete1")

echo "=== Warcraft Peon Sounds for Claude Code ==="
echo ""

# Detect OS and set up audio player
OS="$(uname -s)"
case "$OS" in
  Darwin)
    PLAYER="afplay"
    SOUND_EXT="wav"
    echo "Detected macOS - will use afplay with .wav files"
    ;;
  Linux)
    SOUND_EXT="ogg"
    if command -v paplay &>/dev/null; then
      PLAYER="paplay"
      echo "Detected Linux - will use paplay with .ogg files"
    elif command -v aplay &>/dev/null; then
      PLAYER="aplay"
      SOUND_EXT="wav"
      echo "Detected Linux - will use aplay with .wav files"
    else
      echo "Error: No supported audio player found (paplay or aplay)."
      echo "Install PulseAudio: sudo apt install pulseaudio-utils"
      exit 1
    fi
    ;;
  *)
    echo "Error: Unsupported OS: $OS"
    exit 1
    ;;
esac

# Check if conversion is needed (ogg -> wav)
NEEDS_CONVERT=false
if [ "$SOUND_EXT" = "wav" ]; then
  NEEDS_CONVERT=true
  if ! command -v ffmpeg &>/dev/null; then
    echo ""
    echo "Error: ffmpeg is required to convert .ogg sound files to .wav"
    echo ""
    if [ "$OS" = "Darwin" ]; then
      echo "  Install with:  brew install ffmpeg"
    else
      echo "  Install with:  sudo apt install ffmpeg"
    fi
    echo ""
    echo "Then re-run this script."
    exit 1
  fi
fi

# Create hooks directory
mkdir -p "$HOOKS_DIR"

# Copy and convert sound files
echo ""
echo "Installing sound files to $HOOKS_DIR/ ..."
for name in "${HOOK_SOUNDS[@]}"; do
  src="$SCRIPT_DIR/hooks/${name}.ogg"
  if [ ! -f "$src" ]; then
    echo "  Warning: $src not found, skipping"
    continue
  fi

  if [ "$NEEDS_CONVERT" = true ]; then
    dst="$HOOKS_DIR/${name}.wav"
    if [ -f "$dst" ]; then
      echo "  $name.wav (already exists, skipping)"
    else
      ffmpeg -i "$src" -loglevel error "$dst"
      echo "  $name.ogg -> $name.wav"
    fi
  else
    dst="$HOOKS_DIR/${name}.ogg"
    cp "$src" "$dst"
    echo "  $name.ogg"
  fi
done

# Build the hooks JSON
echo ""
echo "Configuring Claude Code hooks..."

HOOKS_JSON="{"
for i in "${!HOOK_EVENTS[@]}"; do
  event="${HOOK_EVENTS[$i]}"
  sound="${HOOK_SOUNDS[$i]}"
  sound_path="$HOOKS_DIR/${sound}.${SOUND_EXT}"

  if [ "$i" -gt 0 ]; then
    HOOKS_JSON+=","
  fi

  HOOKS_JSON+="\"$event\":[{\"hooks\":[{\"type\":\"command\",\"command\":\"$PLAYER $sound_path\"}]}]"
done
HOOKS_JSON+="}"

# Merge into existing settings.json or create new one
if [ -f "$SETTINGS_FILE" ]; then
  # Check if jq is available for proper JSON merging
  if command -v jq &>/dev/null; then
    # Merge hooks into existing settings
    EXISTING=$(cat "$SETTINGS_FILE")
    MERGED=$(echo "$EXISTING" | jq --argjson newhooks "$HOOKS_JSON" '.hooks = (.hooks // {}) + $newhooks')
    echo "$MERGED" > "$SETTINGS_FILE"
    echo "  Merged hooks into existing $SETTINGS_FILE"
  else
    echo ""
    echo "Warning: jq is not installed. Cannot safely merge into existing settings."
    echo ""
    echo "Your existing $SETTINGS_FILE was NOT modified."
    echo ""
    echo "Option 1: Install jq and re-run this script"
    if [ "$OS" = "Darwin" ]; then
      echo "  brew install jq"
    else
      echo "  sudo apt install jq"
    fi
    echo ""
    echo "Option 2: Manually add the following hooks to $SETTINGS_FILE:"
    echo ""
    echo "  \"hooks\": {"
    for i in "${!HOOK_EVENTS[@]}"; do
      event="${HOOK_EVENTS[$i]}"
      sound="${HOOK_SOUNDS[$i]}"
      sound_path="$HOOKS_DIR/${sound}.${SOUND_EXT}"
      echo "    \"$event\": [{\"hooks\": [{\"type\": \"command\", \"command\": \"$PLAYER $sound_path\"}]}],"
    done
    echo "  }"
    exit 1
  fi
else
  # Create new settings file
  if command -v jq &>/dev/null; then
    echo "{\"hooks\": $HOOKS_JSON}" | jq '.' > "$SETTINGS_FILE"
  else
    # Format manually without jq
    total=${#HOOK_EVENTS[@]}
    {
      echo "{"
      echo "  \"hooks\": {"
      for i in "${!HOOK_EVENTS[@]}"; do
        event="${HOOK_EVENTS[$i]}"
        sound="${HOOK_SOUNDS[$i]}"
        sound_path="$HOOKS_DIR/${sound}.${SOUND_EXT}"
        comma=","
        if [ "$((i + 1))" -eq "$total" ]; then comma=""; fi
        echo "    \"$event\": [{ \"hooks\": [{ \"type\": \"command\", \"command\": \"$PLAYER $sound_path\" }] }]$comma"
      done
      echo "  }"
      echo "}"
    } > "$SETTINGS_FILE"
  fi
  echo "  Created $SETTINGS_FILE"
fi

echo ""
echo "Done! Warcraft Peon sounds are now installed."
echo ""
echo "Sound mappings:"
echo "  SessionStart       -> PeonReady1        (\"Ready to work!\")"
echo "  UserPromptSubmit   -> PeonYes3          (\"Yes, me lord!\")"
echo "  Notification       -> PeonWhat3         (\"What?\")"
echo "  Stop               -> PeonBuildingComplete1 (\"Job's done!\")"
echo ""
echo "Restart Claude Code to activate the hooks."

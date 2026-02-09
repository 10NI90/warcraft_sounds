#!/usr/bin/env bash
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

SOUND_FILES=(
  "PeonReady1"
  "PeonYes3"
  "PeonWhat3"
  "PeonBuildingComplete1"
)

HOOK_EVENTS=(
  "SessionStart"
  "UserPromptSubmit"
  "Notification"
  "Stop"
)

echo "=== Uninstall Warcraft Peon Sounds ==="
echo ""

# Remove sound files
echo "Removing sound files..."
for name in "${SOUND_FILES[@]}"; do
  for ext in wav ogg; do
    f="$HOOKS_DIR/${name}.${ext}"
    if [ -f "$f" ]; then
      rm "$f"
      echo "  Removed $f"
    fi
  done
done

# Remove hooks from settings.json
if [ -f "$SETTINGS_FILE" ] && command -v jq &>/dev/null; then
  echo ""
  echo "Removing hooks from settings..."
  for event in "${HOOK_EVENTS[@]}"; do
    UPDATED=$(jq "del(.hooks.\"$event\")" "$SETTINGS_FILE")
    echo "$UPDATED" > "$SETTINGS_FILE"
    echo "  Removed $event hook"
  done
  # Clean up empty hooks object
  HOOKS_COUNT=$(jq '.hooks | length' "$SETTINGS_FILE")
  if [ "$HOOKS_COUNT" -eq 0 ]; then
    UPDATED=$(jq 'del(.hooks)' "$SETTINGS_FILE")
    echo "$UPDATED" > "$SETTINGS_FILE"
  fi
  echo "  Updated $SETTINGS_FILE"
elif [ -f "$SETTINGS_FILE" ]; then
  echo ""
  echo "Warning: jq is not installed. Please manually remove the hook entries"
  echo "for SessionStart, UserPromptSubmit, Notification, and Stop from:"
  echo "  $SETTINGS_FILE"
fi

echo ""
echo "Done! Warcraft Peon sounds have been removed."
echo "Restart Claude Code to apply changes."

#!/bin/bash
# Sync skills from this repo to local agents skills directory

set -e

SKILLS_DIR="$HOME/.config/agents/skills"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Syncing skills to $SKILLS_DIR..."

for skill in git-workflow pr-create pr-review; do
    if [ -d "$REPO_DIR/$skill" ]; then
        echo "  → $skill"
        mkdir -p "$SKILLS_DIR/$skill"
        cp "$REPO_DIR/$skill/SKILL.md" "$SKILLS_DIR/$skill/"
    fi
done

echo "Done! Skills synced successfully."

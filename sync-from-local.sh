#!/bin/bash
# Sync skills from local agents skills directory to this repo

set -e

SKILLS_DIR="$HOME/.config/agents/skills"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Syncing skills from $SKILLS_DIR..."

for skill in git-workflow pr-create pr-review; do
    if [ -d "$SKILLS_DIR/$skill" ]; then
        echo "  → $skill"
        mkdir -p "$REPO_DIR/$skill"
        cp "$SKILLS_DIR/$skill/SKILL.md" "$REPO_DIR/$skill/"
    fi
done

echo "Done! Skills synced from ~/.config/agents/skills/"
echo "Don't forget to commit and push the changes!"

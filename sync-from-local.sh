#!/bin/bash
# Sync skills from local agents skills directory to this repo

set -e

SKILLS_DIR="$HOME/.config/agents/skills"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Syncing skills from $SKILLS_DIR..."

# Auto-discover skill directories by finding all SKILL.md files
while IFS= read -r skill_file; do
    skill_dir=$(dirname "$skill_file")
    skill=$(basename "$skill_dir")
    
    # Skip if it's the root directory
    if [ "$skill" = "." ]; then
        continue
    fi
    
    echo "  → $skill"
    mkdir -p "$REPO_DIR/$skill"
    cp "$SKILLS_DIR/$skill/SKILL.md" "$REPO_DIR/$skill/"
done < <(find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -name "SKILL.md" 2>/dev/null || true)

echo "Done! Skills synced from ~/.config/agents/skills/"
echo "Don't forget to commit and push the changes!"

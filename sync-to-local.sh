#!/bin/bash
# Sync skills from this repo to local agents skills directory

set -e

SKILLS_DIR="$HOME/.config/agents/skills"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Syncing skills to $SKILLS_DIR..."

# Auto-discover skill directories by finding all SKILL.md files
# Exclude tests and .github directories
while IFS= read -r skill_file; do
    skill_dir=$(dirname "$skill_file")
    skill=$(basename "$skill_dir")
    
    # Skip if it's the root directory or a special directory
    if [ "$skill" = "." ] || [ "$skill" = "tests" ] || [ "$skill" = ".github" ]; then
        continue
    fi
    
    echo "  → $skill"
    mkdir -p "$SKILLS_DIR/$skill"
    cp "$REPO_DIR/$skill/SKILL.md" "$SKILLS_DIR/$skill/"
done < <(find "$REPO_DIR" -mindepth 2 -maxdepth 2 -name "SKILL.md" | grep -v "/tests/" | grep -v "/.github/")

echo "Done! Skills synced to ~/.config/agents/skills/"

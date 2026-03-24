# Contributing

## Sync Workflow

This repository is kept in sync with the local skills directory at `~/.config/agents/skills/`.

### Local → Repo (Push to GitHub)

When you've updated skills locally and want to push to GitHub:

```bash
cd /path/to/kimi-skills
./sync-from-local.sh
git add -A
git commit -m "sync: update skills from local"
git push origin master
```

### Repo → Local (Pull from GitHub)

When you've pulled updates from GitHub and want to apply to local:

```bash
cd /path/to/kimi-skills
./sync-to-local.sh
```

Or manually:

```bash
cp -r git-workflow pr-create pr-review ~/.config/agents/skills/
```

## Adding New Skills

1. Create a new directory: `mkdir new-skill`
2. Add `SKILL.md` with frontmatter:
   ```yaml
   ---
   name: new-skill
   description: Brief description of what this skill does
   ---
   ```
3. Update `README.md` with the new skill
4. Sync to local: `./sync-to-local.sh`
5. Commit and push

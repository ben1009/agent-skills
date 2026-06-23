# Agent Skills

A collection of reusable skills for AI agents.

## Skills Included

| Skill | Description |
|-------|-------------|
| `git-workflow` | Git best practices and workflows for clean commit history and effective collaboration |
| `pr-create` | Create a pull request from local changes with proper checks and optional comment watching |
| `pr-review` | Handle pull request review comments with user control over all fixes |
| `rust-skills` | Comprehensive Rust coding guidelines with rules for ownership, error handling, async, performance, testing, and style |

## Usage

These skills are designed to be used with AI agents (Claude, GPT, Gemini, Kimi, etc.). Place them in your agents skills directory:

When working in a Rust repository, read `rust-skills/SKILL.md` before changing Rust code.

```
~/.config/agents/skills/
├── git-workflow/
│   └── SKILL.md
├── pr-create/
│   └── SKILL.md
├── pr-review/
│   └── SKILL.md
└── rust-skills/
    └── SKILL.md
```

## Syncing

To sync these skills with your local installation:

```bash
# From this repo
./sync-to-local.sh

# Or manually copy
cp -r git-workflow pr-create pr-review rust-skills ~/.config/agents/skills/
```

## License

Apache 2.0 - see [LICENSE](LICENSE)

## Testing

Run the test suite to verify sync logic:

```bash
./tests/test_sync.sh
```

Tests are automatically run on every push via GitHub Actions.

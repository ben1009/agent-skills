# Agent Skills - Project Guide

## Project Overview

This repository contains a collection of **reusable skills for AI agents** (Claude, GPT, Gemini, Kimi, etc.). Skills are modular extensions that provide specialized knowledge, workflow patterns, and tool integrations to enhance AI agent capabilities.

### What are Skills?

Skills are self-contained directories with a `SKILL.md` file that contains:
- **Specialized knowledge**: Domain-specific expertise (e.g., Git workflows, PR creation)
- **Workflow patterns**: Best practices for common tasks
- **Tool integrations**: Pre-configured tool chains for specific operations
- **Reference material**: Documentation, templates, and examples

### Current Skills

| Skill | Description |
|-------|-------------|
| `git-workflow` | Git best practices and workflows for clean commit history and effective collaboration |
| `pr-create` | Create a pull request from local changes with proper checks and optional comment watching |
| `pr-review` | Handle pull request review comments with user control over all fixes |

## Technology Stack

This is a **documentation-only project** with the following components:

- **Documentation Format**: Markdown with YAML frontmatter
- **Automation**: Bash scripts for file synchronization
- **CI/CD**: GitHub Actions workflows
- **Target Platform**: AI agent skill systems (e.g., Kimi CLI, Claude Code)

### No Build Process Required

This project does not require compilation, dependency installation, or a build step. Changes are made directly to Markdown files.

## Project Structure

```
agent-skills/
├── git-workflow/           # Git workflow skill
│   └── SKILL.md           # Skill documentation with YAML frontmatter
├── pr-create/             # PR creation skill
│   └── SKILL.md
├── pr-review/             # PR review skill
│   └── SKILL.md
├── tests/                 # Test suite
│   └── test_sync.sh       # Bash tests for sync scripts
├── .github/workflows/     # CI/CD configurations
│   ├── test.yml          # Run tests on push/PR
│   └── sync-from-local.yml  # Manual sync workflow
├── sync-to-local.sh       # Sync repo → local skills dir
├── sync-from-local.sh     # Sync local skills dir → repo
├── README.md             # Human-facing documentation
├── CONTRIBUTING.md       # Contribution guidelines
├── LICENSE               # Apache 2.0 license
└── AGENTS.md            # This file (AI agent guide)
```

## Skill File Format

Each skill **MUST** follow this structure:

```markdown
---
name: skill-name
description: Brief description of what this skill does. Include usage triggers.
---

# Skill Title

## Section 1
Content...

## Section 2
Content...
```

### Required YAML Frontmatter

- `name`: Unique identifier for the skill (kebab-case)
- `description`: Brief description that helps AI agents know when to use this skill

### Writing Guidelines

1. **Start with critical rules** if the skill has "NEVER DO THIS" type warnings
2. **Use clear sections** with hierarchical headings
3. **Include code examples** in fenced code blocks with language specified
4. **Add usage triggers** in the description to help agents identify when to use the skill
5. **Cross-reference related skills** using tables or inline references

## Development Workflow

### Adding a New Skill

1. Create a new directory: `mkdir new-skill`
2. Add `SKILL.md` with proper YAML frontmatter (see format above)
3. Update `README.md` to include the new skill in the table
4. Update both sync scripts to include the new skill name:
   - `sync-to-local.sh`: Add to the `for skill in ...` loop
   - `sync-from-local.sh`: Add to the `for skill in ...` loop
   - `tests/test_sync.sh`: Add to skill lists in test setup
5. Test the sync: `./tests/test_sync.sh`
6. Sync to local: `./sync-to-local.sh`
7. Commit and push

### Modifying an Existing Skill

1. Edit the `SKILL.md` file in the skill directory
2. Run tests: `./tests/test_sync.sh`
3. Sync to local to test with your AI agent: `./sync-to-local.sh`
4. Commit and push

### Syncing Between Repo and Local

The repository is designed to sync with the local agents skills directory at `~/.config/agents/skills/`.

**Local → Repo (Push to GitHub):**
```bash
./sync-from-local.sh
git add -A
git commit -m "sync: update skills from local"
git push origin master
```

**Repo → Local (Test changes):**
```bash
./sync-to-local.sh
```

## Testing Instructions

### Running Tests

```bash
./tests/test_sync.sh
```

The test suite verifies:
- Sync scripts correctly copy files in both directions
- Missing directories are created automatically
- File contents are properly transferred

### CI/CD

Tests are automatically run on every push and pull request via GitHub Actions (`.github/workflows/test.yml`).

The CI pipeline:
1. Runs the sync test suite
2. Verifies scripts are executable
3. Verifies all skill files exist

## Code Style Guidelines

### Markdown Style

- Use ATX-style headers (`# Header`) not Setext-style
- Use fenced code blocks with language specification
- Use `-` for unordered lists (not `*` or `+`)
- Use `1.` for ordered lists
- Wrap lines at ~100 characters for readability
- Use emphasis (`**bold**`, `*italic*`) for important points

### Bash Script Style

- Use `set -e` for error handling
- Quote variables: `"$VAR"` not `$VAR`
- Use `$(...)` for command substitution (not backticks)
- Add comments for non-obvious operations
- Use `#!/bin/bash` shebang

### Commit Message Format

Follow conventional commits:
```
<type>: <short summary>

<body - optional but recommended>
```

**Types:**
- `feat:` New skill or major feature
- `fix:` Bug fix or correction
- `docs:` Documentation only changes
- `style:` Formatting changes
- `refactor:` Code reorganization
- `test:` Test-related changes
- `chore:` Build/config/tooling changes
- `sync:` Sync from local directory

## Security Considerations

1. **No secrets in skills**: Never include API keys, tokens, or credentials in skill files
2. **Safe commands only**: Skills should not suggest destructive operations without user confirmation
3. **User confirmation for critical actions**: Skills that perform writes (like PR creation) must always ask for user confirmation
4. **Review before sync**: When syncing from local, review changes before committing to ensure no sensitive data was added

## License

Apache License 2.0 - See [LICENSE](LICENSE) for details.

## Quick Reference

| Task | Command |
|------|---------|
| Run tests | `./tests/test_sync.sh` |
| Sync repo → local | `./sync-to-local.sh` |
| Sync local → repo | `./sync-from-local.sh` |
| Add new skill | Create dir + SKILL.md + update scripts + update README.md |

---
name: pr-create
description: Create a pull request from local changes. Handles workspace preparation, local checks, commit, push, PR creation, and optional comment watching. Defers comment handling and merge to the pr-review skill.
---

# PR Create Skill

Create a pull request from your local changes with proper checks and optional comment watching.

## ⚠️ CRITICAL RULES - NEVER VIOLATE

### 1. NEVER Push to Protected Branches (main/master)

**Always create feature branch first.** Never run:
```bash
# ❌ FORBIDDEN - Never do this
git push origin master
git push origin main
```

### 2. NEVER Merge PR Without User Confirmation

**Always ask user before merging**, even if all checks pass.

Correct workflow:
```bash
gh pr checks --watch      # Wait for checks
# Ask: "All checks passed. Should I merge this PR?"
gh pr merge               # Only after user says yes
```

### 3. ALWAYS Use English in PR Title and Description

**PR title and body must be in English**, regardless of the user's input language.

```bash
# ❌ WRONG - Non-English PR title
gh pr create --title "修复: 按钮样式" --body "..."

# ✅ CORRECT - English PR title  
gh pr create --title "fix: button style" --body "..."
```

**Even if user asks in Chinese/Japanese/Other language**, translate to English for PR.

## Usage

```bash
# Basic usage
"fire a pr"
"create pr"
"prepare pr"

# With auto-watch for comments
"fire a pr and watch for comments"
"create pr --watch"
```

## Workflow

### Phase 1: Prepare Workspace

```bash
# Stash current changes if needed
git stash push -m "WIP: pr-create"

# Switch to master and update
git checkout master
git pull origin master

# Create and switch to new feature branch
git checkout -b feat/descriptive-name

# Apply stashed changes
git stash pop
```

### Phase 2: Run Local Checks ⭐ REQUIRED

**All checks MUST pass before creating PR:**

```bash
./dev check
# OR
cargo fmt --check
cargo clippy --workspace --all-features --all-targets -- -D warnings
cargo test
```

**If checks fail:**
- Fix the issues
- Re-run checks
- Only proceed when all checks pass

### Phase 3: Commit & Push

```bash
# Stage changes
git add <files>

# Commit with conventional message (see git-workflow skill for format)
git commit -m "feat: descriptive summary

Optional longer description explaining:
- What changed
- Why it changed
- Any breaking changes"

# Push and set upstream
git push -u origin <branch-name>
```

**Commit conventions:** Reference `git-workflow` skill for:
- Commit message format
- Single vs multiple commits
- Commit types (feat:, fix:, docs:, etc.)

### Phase 4: Create PR

Using GitHub CLI (preferred):

```bash
gh pr create \
  --title "type: concise description" \
  --body "## Summary

Brief explanation of changes.

## Changes
- Item 1
- Item 2

## Verification
- [x] Local checks pass
- [x] Tests pass"
```

**If gh CLI fails** (network/GraphQL errors):

```bash
# Retry once - gh commands are idempotent for PR creation
gh pr create --title "..." --body "..."

# Or use REST API:
curl -s -X POST \
  -H "Authorization: token $(gh auth token)" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/pulls \
  -d '{
    "title": "PR title",
    "head": "branch-name",
    "base": "master",
    "body": "PR description"
  }'
```

### Phase 5: Done

The PR has been created. The next steps (review, checks, merge) are handled by the `pr-review` skill.

### Phase 6: Optional Auto-Watch ⭐

If user requested watching for comments:

```bash
# Poll for new comments every 30 seconds
# Stop when comments found or user interrupts
```

**When comments detected:**
- Notify user: "New review comments available"
- **Do NOT handle comments in this skill** - Use 'pr-review' skill instead
- Suggest: "Run 'pr-review' skill to handle these comments"

## Error Handling

| Issue | Solution |
|-------|----------|
| Check failures | Fix issues, re-run checks, then proceed |
| Push rejected | `git pull origin <branch>` first, then push |
| PR already exists | Update existing PR with new commits |
| Network timeout | Retry with exponential backoff |
| Accidentally pushed to master | Revert immediately: `git revert HEAD --no-edit && git push origin master` |

## What NOT To Do

| ❌ Forbidden | Why |
|-------------|-----|
| `git push origin master/main` | Bypasses PR workflow and code review |
| Auto-merge without asking | User must approve all merges |
| Commit directly to protected branch | Always use feature branch |

## Quick Reference: Protected Branch Workflow

```bash
# ✅ CORRECT: Feature branch workflow (create phase)
git checkout main
git pull origin main
git checkout -b feat/my-change
git add -A
git commit -m "feat: my change"
git push -u origin feat/my-change
gh pr create --title "feat: my change"

# Next: Use pr-review skill for review, checks, and merge
```

## Integration with Other Skills

| Need | Use Skill |
|------|-----------|
| Git commit format | `git-workflow` |
| Force push guidelines | `git-workflow` |
| Review comments, CI checks, merge | `pr-review` |
| Split/amend commits | `git-workflow` |

## Example Session

```
User: "fire a pr and watch"
→ Check for local changes
→ Stash if needed
→ Checkout master → Pull
→ Create branch → Apply stash
→ ./dev check
→ [If fails] Fix issues → Re-check
→ Commit → Push → Create PR
→ [If --watch] Start watching for comments
→ "PR #42 created. Watching for comments..."
[Later] "New comments detected. Run 'pr-review' to handle them."
```

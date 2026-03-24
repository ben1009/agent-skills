---
name: pr-review
description: Handle pull request review comments. Fetches, presents, and helps fix review comments with user confirmation. Never auto-fixes without approval.
---

# PR Review Skill

Handle review comments on a pull request with user control over all fixes.

**⚠️ IMPORTANT: This skill NEVER auto-fixes. Always asks user before making changes.**

## Usage

```bash
# Read and summarize comments
"read the comments"
"show pr comments"
"check reviews"

# Fix comments (after user confirmation)
"fix review comments"
"address pr feedback"
```

## Workflow

### Step 1: Fetch Comments

```bash
# Method 1: Try gh CLI first
gh pr view <number> --comments

# Method 2: If GraphQL errors, use REST API
curl -s \
  -H "Authorization: token $(gh auth token)" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/pulls/<number>/comments

# Method 3: Get issue comments too (general discussion)
curl -s \
  -H "Authorization: token $(gh auth token)" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/issues/<number>/comments
```

### Step 2: Present to User

Summarize findings by severity:

```
Found N review comments:

🔴 Critical (1):
- File: src/x.js, Line 42
- Bot: gemini-code-assist
- Issue: Function X missing, causes runtime error

🟡 Medium (1):
- File: src/y.js, Line 88  
- Bot: chatgpt-codex-connector
- Issue: Variable naming inconsistent

🟢 Low (1):
- File: docs/README.md
- Bot: typo-bot
- Issue: Typo in documentation
```

### Step 3: Ask Before Fixing ⭐ REQUIRED

**Must ask explicitly:**

> "Would you like me to address these review comments?"
> 
> Options:
> - [ ] Fix all issues automatically
> - [ ] Fix only critical issues
> - [ ] Show me the code first
> - [ ] I'll handle it myself

**Never auto-fix without explicit user confirmation.**

### Step 4: Apply Fixes (If Confirmed)

For each confirmed fix:

```bash
# Make the fix
git add <file>
git commit -m "fix: address review comment - specific fix description"
git push origin <branch>
```

**Commit message format:**
- Use `fix:` prefix for review comment fixes
- Be specific about what was fixed
- Reference comment author if relevant

Example:
```
fix: address review comments - use Path instead of PathBuf

- Fix clippy warning about &PathBuf vs &Path
- Improves API ergonomics
```

## Patterns

### Multiple Review Rounds

```
Round 1: Initial PR created
  ↓
Bot comments received
  ↓
Ask user → User confirms fixes
  ↓
Apply fixes, commit, push
  ↓
Round 2: New comments or follow-up
  ↓
Ask user again → Address or discuss
```

### Human Reviewer + Bots

When both human and bot comments exist:
1. **Prioritize human review comments** - These are more important
2. Group bot comments by severity
3. Ask user which to address
4. Suggest: "Address human comments first, then evaluate bot suggestions"

## Error Handling

| Issue | Solution |
|-------|----------|
| `gh` CLI GraphQL errors | Use REST API fallback |
| Stash pop conflicts | Ask user to resolve manually |
| Push rejected (non-fast-forward) | `git pull origin <branch>` first, then push |
| Network timeout | Retry with exponential backoff |

## Integration with Other Skills

| Need | Use Skill |
|------|-----------|
| Commit message format | `git-workflow` |
| Force push guidelines | `git-workflow` |
| Create PR | `pr-create` |
| Split/amend commits | `git-workflow` |

## Example Session

```
User: "read the comments"
→ Fetch comments via API
→ Summarize by severity
→ Present to user

User: "fix all"
→ "Which ones?"
→ User selects: Fix all critical
→ Apply fixes
→ Commit → Push
→ "Fixes pushed. PR updated."
```

## Anti-Patterns

❌ **Never do this:**
```bash
# Auto-fix without asking
gh pr view --comments | fix-all.sh
```

✅ **Always do this:**
```bash
# Present → Ask → Fix
gh pr view --comments
# "Would you like me to fix these?"
# [User confirms]
# Then apply fixes
```

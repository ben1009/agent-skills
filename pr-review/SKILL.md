---
name: pr-review
description: Handle pull request review workflow - comments, CI checks, and merge. Fetches review comments, checks CI status, and manages merge with user confirmation.
---

# PR Review Skill

Handle the complete PR review workflow: review comments, CI checks, and merge.

**⚠️ IMPORTANT: This skill NEVER auto-fixes or auto-merges. Always asks user before making changes.**

## Usage

```bash
# Read and summarize review comments
"read the comments"
"show pr comments"
"check reviews"

# Check CI status
"check pr status"
"are checks passing?"

# Complete review workflow
"review pr"          # Check comments + CI status

# Fix comments (after user confirmation)
"fix review comments"
"address pr feedback"

# Update PR description after fixes
"update pr description"
"edit pr body"

# Merge (after user confirmation)
"merge pr"
"is this ready to merge?"
```

## Workflow

### Step 1: Fetch Review Comments

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

### Step 2: Check CI Status

```bash
# Check current status
gh pr checks <number>

# Watch checks in real-time
gh pr checks <number> --watch

# View PR overview with status
gh pr view <number>
```

### Step 3: Present Summary

Summarize findings by category:

```
PR #17 Review Summary:

📝 Review Comments: 6 found
🔴 Critical (1):
   - File: src/x.rs, Line 42
   - Issue: Function X missing

🟡 Medium (2):
   - File: src/y.rs, Line 88
   - Issue: Variable naming inconsistent

✅ CI Checks: PASSING
   - All 5 checks passed

📊 Status: Ready for review fixes
```

### Step 4: Address Review Comments ⭐ USER DECISION

**Ask user before fixing:**

> "Found 6 review comments (1 critical, 2 medium, 3 low). CI checks are passing.
> Would you like me to address these comments?"
> 
> Select:
> 1. Fix all issues automatically
> 2. Fix only critical issues
> 3. Show me the code first
> 4. Ignore - I'll handle it myself

**If confirmed, apply fixes:**

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

**Reply to review comments after fixing:**

After pushing fixes, you should reply to each review comment to indicate the issue has been addressed:

```bash
# Get comment IDs
gh pr view <number> --comments

# Reply to a comment (preferred - creates a reply thread)
curl -s -X POST \
  -H "Authorization: token $(gh auth token)" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/pulls/<number>/comments/<comment_id>/replies \
  -d '{"body": "Fixed"}'
```

**Important:** 
- Use the `/replies` endpoint to create a proper reply thread
- Do NOT edit the original comment body (that's the reviewer's comment)
- Simple replies like "Fixed" or "✅ Fixed" are sufficient
- **Resolving comments: CANNOT be done via CLI/API** - The PR author must manually click "Resolve conversation" in the GitHub UI (GitHub doesn't expose this action in their API)

**Example workflow:**
```
1. Fix the code issue
2. git add -A && git commit -m "fix: address review comment"
3. git push origin <branch>
4. Reply "Fixed" to each review comment via API
5. User manually resolves conversations in GitHub UI
```

### Step 4b: Update PR Description (Optional)

After addressing review comments, consider updating the PR description to reflect:
- Changes made during review
- Fixes applied (with before/after summary)
- New tests added
- Breaking changes introduced

**Ask user:**
> "I've addressed the review comments and pushed fixes. Would you like me to update the PR description to reflect these changes?"

**To update:**
```bash
# Edit PR description
gh pr edit <number> --body-file updated_description.md

# Or inline (for small updates)
gh pr edit <number> --body "Updated description..."
```

**If `gh pr edit` fails:**
If you encounter GraphQL errors, use the REST API as a fallback:
```bash
curl -s -X PATCH \
  -H "Authorization: token $(gh auth token)" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/pulls/<number> \
  -d '{"body": "new body content"}'
```

**When to update:**
| Scenario | Action |
|----------|--------|
| Significant architectural changes | Update to reflect new approach |
| Added tests per review request | Add "Testing" section |
| Fixed bugs mentioned in review | Add "Bug Fixes" summary table |
| Breaking changes introduced | Update "Breaking Changes" section |
| Minor style fixes | Optional - may skip |

### Step 5: Merge PR ⭐ USER CONFIRMATION REQUIRED

**⚠️ NEVER auto-merge. Always ask user first.**

**Prerequisites for merge:**
1. All review comments addressed (or intentionally skipped)
2. All CI checks passing
3. No merge conflicts

**Ask explicitly:**

> "All review comments have been addressed and CI checks are passing.
> Should I merge this PR?"
> 
> Select:
> 1. Yes, merge with squash
> 2. Yes, merge with merge commit
> 3. Yes, rebase and merge
> 4. No, I'll merge manually

**After user confirms:**

```bash
# Check final status
gh pr checks <number>

# Merge (default: squash)
gh pr merge <number> --squash --delete-branch

# Or with merge commit
gh pr merge <number> --merge --delete-branch

# Or rebase
gh pr merge <number> --rebase --delete-branch
```

## Patterns

### Multiple Review Rounds

```
Round 1: Initial PR created
  ↓
Bot/human comments received
  ↓
User: "review pr"
  ↓
Present summary → User confirms fixes
  ↓
Apply fixes, commit, push
  ↓
[Optional] Update PR description to reflect changes
  ↓
Round 2: New comments or follow-up
  ↓
User: "review pr" again
  ↓
Check new comments + CI status
  ↓
User confirms merge
  ↓
Merge PR
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
| Checks failing | Report failures, ask if user wants to fix or wait |
| Merge conflicts | Ask user to resolve manually |

## Integration with Other Skills

| Need | Use Skill |
|------|-----------|
| Commit message format | `git-workflow` |
| Force push guidelines | `git-workflow` |
| Create PR | `pr-create` |
| Split/amend commits | `git-workflow` |

## Example Session

```
User: "review pr"
→ Fetch comments via API
→ Check CI status
→ Summarize by severity
→ Present to user

User: "fix all"
→ "Select: 1-Fix all, 2-Critical only, 3-Show code, 4-Ignore"
→ User selects: 2
→ Apply critical fixes only
→ Commit → Push
→ "Fixes pushed. PR updated."

User: "update pr description"
→ "Would you like me to update the PR description to reflect the fixes?"
→ User selects: Yes
→ Update description with fixes summary
→ "PR description updated."

User: "is it ready to merge?"
→ Check comments (all resolved?) ✓
→ Check CI status (passing?) ✓
→ "All checks pass. Select merge option:"
→ User selects: 1 (merge with squash)
→ gh pr merge --squash --delete-branch
→ "PR #17 merged successfully!"
```

## Anti-Patterns

❌ **Never do this:**
```bash
# Auto-fix without asking
gh pr view --comments | fix-all.sh

# Auto-update PR description without asking
gh pr edit <number> --body "..."

# Auto-merge without asking
gh pr merge --squash
```

✅ **Always do this:**
```bash
# Present → Ask → Fix
gh pr view --comments
# "Select: 1-Fix all, 2-Critical only, 3-Show code, 4-Ignore"
# User selects: 2
# Then apply fixes

# Ask before updating description
# "Update PR description to reflect changes?"
# User confirms → Then update

# Check → Ask → Merge
gh pr checks
# "Select: 1-Squash, 2-Merge commit, 3-Rebase, 4-Cancel"
# User selects: 1
# Then merge
```

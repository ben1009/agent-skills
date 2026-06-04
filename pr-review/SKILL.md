---
name: pr-review
description: Handle pull request review workflow - comments, CI checks, and merge. Fetches review comments, checks CI status, and manages merge with user confirmation.
---

# PR Review Skill

Handle the complete PR review workflow: review comments, CI checks, and merge.

**⚠️ IMPORTANT: This skill NEVER auto-fixes or auto-merges. Always asks user before making changes.**

**🚫 HARD RULE 1: NEVER resolve a review conversation thread without first posting a reply comment.**
This applies to bot comments, human comments, and all review threads. Always reply explaining what was fixed before resolving.

**🚫 HARD RULE 2: NEVER merge a PR while any review comment or conversation thread remains unresolved.**
All comments must be replied to and resolved before merge. If a comment is intentionally skipped, explicitly mark it resolved with a reply explaining why.

**🚫 HARD RULE 3: ALWAYS use `--repo OWNER/REPO` with every `gh` CLI command.**
`gh` may default to the wrong remote (upstream vs origin/fork). Always specify the target repo explicitly.

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

**All `gh` commands MUST use `--repo OWNER/REPO` to target the correct repository.**

### Step 1: Fetch Review Comments

```bash
# Method 1: Try gh CLI first
gh pr view <number> --comments --repo OWNER/REPO

# Method 2: If GraphQL errors, use REST API (always use per_page=100 to avoid missing comments)
curl -s \
  -H "Authorization: token $(gh auth token)" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/OWNER/REPO/pulls/<number>/comments?per_page=100"

# Method 3: Get issue comments too (general discussion)
curl -s \
  -H "Authorization: token $(gh auth token)" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/issues/<number>/comments
```

### Step 2: Check CI Status

```bash
# Check current status
gh pr checks <number> --repo OWNER/REPO

# Watch checks in real-time
gh pr checks <number> --watch --repo OWNER/REPO

# View PR overview with status
gh pr view <number> --repo OWNER/REPO
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

**Reply to review comments after fixing (MANDATORY):**

After pushing fixes, you MUST reply to each review comment before resolving the conversation. Never resolve without replying first.

```bash
# Get comment IDs and latest commit SHA
gh pr view <number> --comments --repo OWNER/REPO
LATEST_SHA=$(gh pr view <number> --json headRefOid -q '.headRefOid' --repo OWNER/REPO)

# Method 1: Reply using in_reply_to (preferred - creates proper review thread reply)
curl -s -X POST \
  -H "Authorization: token $(gh auth token)" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/pulls/<number>/comments \
  -d '{
    "body": "Fixed. Replaced incr+expire with atomic SET NX EX to prevent permanent lockout if expire never runs.",
    "in_reply_to": COMMENT_ID,
    "commit_id": "'"$LATEST_SHA"'",
    "path": "file-path.html",
    "line": LINE_NUMBER,
    "side": "RIGHT"
  }'

# Method 2: Fallback - add general PR comment if Method 1 fails
curl -s -X POST \
  -H "Authorization: token $(gh auth token)" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/issues/<number>/comments \
  -d '{"body": "@reviewer Addressed your feedback — see commit abc123 for details."}'
```

**Important:** 
- Use `in_reply_to` field to create a proper reply in the review thread
- The reply will appear at the code line in the PR review interface
- Method 2 creates a general PR comment (not a review reply) - only use as fallback
- **Replies must explain what was changed or why a change was NOT made.**
  - Good: `Fixed. Added tie-breaker to row_number() for stable ranking.`
  - Good: `Fixed. Removed redundant unique constraint from url column.`
  - Good: `Not fixed. Supabase JS v2 does not support arrays here; reverted with a comment explaining why.`
  - Bad: `Fixed` (too vague)
- **Resolving comments: ONLY after posting a reply** (see below)

**Resolving review threads via GraphQL:**

GitHub's REST API doesn't support resolving, but the GraphQL API does via the `resolveReviewThread` mutation:

```bash
# First, get the thread ID
curl -s -X POST \
  -H "Authorization: token $(gh auth token)" \
  -H "Content-Type: application/json" \
  https://api.github.com/graphql \
  -d '{"query": "query { repository(owner: \"OWNER\", name: \"REPO\") { pullRequest(number: N) { reviewThreads(first: 10) { nodes { id isResolved comments(first: 1) { nodes { body } } } } } } }"}'

# Then resolve the thread
curl -s -X POST \
  -H "Authorization: token $(gh auth token)" \
  -H "Content-Type: application/json" \
  https://api.github.com/graphql \
  -d '{"query": "mutation { resolveReviewThread(input: {threadId: \"THREAD_ID\"}) { clientMutationId } }"}'
```

Note: Each review comment creates a "thread". You resolve the thread, not individual comments.

**Example workflow:**
```
1. Fix the code issue
2. git add -A && git commit -m "fix: address review comment"
3. git push origin <branch>
4. Reply to each review comment via API explaining what was fixed or why no fix is needed
5. Resolve review threads via GraphQL API
6. Post a comment asking reviewers / bots to re-review
```

### Step 4b: Update PR Description (Required)

After addressing review comments, consider updating the PR description to reflect:
- Changes made during review
- Fixes applied (with before/after summary)
- New tests added
- Breaking changes introduced

**After addressing review comments, update the PR description to reflect:**
- Changes made during review
- Fixes applied (with before/after summary)
- New tests added
- Breaking changes introduced

**To update:**
```bash
# Edit PR description
gh pr edit <number> --body-file updated_description.md --repo OWNER/REPO

# Or inline (for small updates)
gh pr edit <number> --body "Updated description..." --repo OWNER/REPO
```

### Step 4c: Resolve Conversations and Request Re-review (Required)

After all fixes are pushed and replies are posted, you MUST resolve every review thread before asking for a re-review.

**Get unresolved thread IDs:**
```bash
curl -s -X POST \
  -H "Authorization: token $(gh auth token)" \
  -H "Content-Type: application/json" \
  https://api.github.com/graphql \
  -d '{"query": "query { repository(owner: \"OWNER\", name: \"REPO\") { pullRequest(number: <number>) { reviewThreads(first: 100) { nodes { id isResolved } } } } }"}' | \
  jq -r '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | .id'
```

**Resolve each thread via GraphQL:**
```bash
# Fetch all thread IDs
curl -s -X POST \
  -H "Authorization: token $(gh auth token)" \
  -H "Content-Type: application/json" \
  https://api.github.com/graphql \
  -d '{"query": "query { repository(owner: \"OWNER\", name: \"REPO\") { pullRequest(number: <number>) { reviewThreads(first: 100) { nodes { id isResolved } } } } }"}'

# Resolve each unresolved thread
curl -s -X POST \
  -H "Authorization: token $(gh auth token)" \
  -H "Content-Type: application/json" \
  https://api.github.com/graphql \
  -d '{"query": "mutation { resolveReviewThread(input: {threadId: \"THREAD_ID\"}) { clientMutationId } }"}'
```

### Step 4d: Ping Reviewers to Re-review (Required)

After resolving all threads, you MUST explicitly ping the reviewers so they know the PR is ready for another look. Do not assume they will notice the pushes automatically.

**Post a general PR comment @-mentioning every reviewer (human + bot):**
```bash
gh pr comment <number> --repo OWNER/REPO --body "All review comments have been addressed and resolved. Please re-review.

@gemini-code-assist @coderabbitai"
```

**How to find reviewer handles:**
```bash
# List all review authors
curl -s -X POST \
  -H "Authorization: token $(gh auth token)" \
  -H "Content-Type: application/json" \
  https://api.github.com/graphql \
  -d '{"query": "query { repository(owner: \"OWNER\", name: \"REPO\") { pullRequest(number: <number>) { reviews(first: 100) { nodes { author { login } } } } } }"}' | \
  jq -r '.data.repository.pullRequest.reviews.nodes[].author.login' | sort -u
```

**Hard rules:**
- Never ask for re-review while any conversation thread remains unresolved.
- Always @-mention the reviewer; a silent push is invisible to bots.
- Include bot accounts (e.g. `@gemini-code-assist`, `@coderabbitai`) so they re-trigger their checks.

## GitHub Native Enforcement

GitHub branch protection can enforce these rules automatically:

| Rule | GitHub Setting | Path |
|------|---------------|------|
| Require resolved conversations before merge | **Require conversation resolution before merging** | Settings → Branches → Branch protection rule |
| Require PR reviews | **Require a pull request review before merging** | Settings → Branches → Branch protection rule |
| Require passing checks | **Require status checks to pass** | Settings → Branches → Branch protection rule |

Enable **"Require conversation resolution before merging"** on the target branch (e.g. `main`) to block merges with unresolved review threads at the platform level.

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
gh pr checks <number> --repo OWNER/REPO

# Merge (default: squash)
gh pr merge <number> --squash --delete-branch --repo OWNER/REPO

# Or with merge commit
gh pr merge <number> --merge --delete-branch --repo OWNER/REPO

# Or rebase
gh pr merge <number> --rebase --delete-branch --repo OWNER/REPO
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
Reply "Fixed" to each review comment via API
  ↓
[Required] Update PR description to reflect changes
  ↓
[Required] Resolve review threads via GraphQL API
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

### Stopping Condition for Review Loop

After fixes are pushed and reviewers are pinged, **stop and wait** for their response. Do not proactively run another review round.

**The loop ends when:**
- Reviewer replies with approval / LGTM / "looks good"
- A new review round produces **zero new comments** (only resolved threads from previous round)
- CI passes and all threads are resolved

**Do NOT continue looping if:**
- You already fixed all comments and pinged reviewers
- No new comments appear after the re-review request
- The only remaining "reviews" are your own reply comments

### Human Reviewer + Bots

When both human and bot comments exist:
1. **Prioritize human review comments** - These are more important
2. Group bot comments by severity
3. Ask user which to address
4. Suggest: "Address human comments first, then evaluate bot suggestions"
5. **Reply to ALL addressed comments** before resolving — bot comments get the same treatment as human comments

## General Review Comments (Non-Line-Specific)

Sometimes reviewers (especially bots or via certain integrations) **cannot create individual line-level review comments** and instead post all feedback as a single general PR comment or issue comment. This loses GitHub's built-in per-thread tracking, so you must handle it manually.

### How to Identify
- The comment appears under the general "Conversation" tab, not the "Files changed" tab
- No file path or line number is attached to the comment
- Multiple unrelated issues are bundled into one comment

### Handling Workflow

**Step 1: Parse and map the feedback yourself**

Break the general comment into individual action items and map each to specific files/lines:

```
| Feedback Point | File | Line | Severity |
|---|---|---|---|
| Script execution order bug | src/x.js | 42 | Critical |
| Brittle CSS selector | src/y.css | 88 | Medium |
```

**Step 2: Address each point in code**

Fix them the same way you would fix line-level review comments — commit per logical fix.

**Step 3: Post a structured reply**

Reply to the general comment with explicit references to each fix:

```
Thanks for the review. Addressed all N points:

1. **Script execution order**: Wrapped in DOMContentLoaded listener
   → commit `abc1234`

2. **Brittle CSS selector**: Simplified to generic `.speaking`
   → commit `abc1234`

3. **Test logic error**: Removed || short-circuit
   → commit `def5678`
```

**Step 4: Track completion manually**

Since there's no "resolve conversation" button for general comments, update the PR description or post a follow-up comment marking everything done.

### Key Differences from Line-Level Comments

| Aspect | Line-Level Comment | General Comment |
|--------|-------------------|-----------------|
| GitHub tracking | Built-in resolve/threads | None — track manually |
| Reply location | Inline on code | General PR comment |
| Precision | Exact file + line | Must infer mapping |
| API for reply | `in_reply_to` + thread ID | Standard issue comment API |

## Error Handling

| Issue | Solution |
|-------|----------|
| `gh` CLI GraphQL errors | Use REST API fallback |
| `gh` targets wrong remote (upstream vs origin) | Use `--repo OWNER/REPO` flag, e.g. `gh pr comment 76 --repo ben1009/mini-lsm` |
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
→ Reply "Fixed" to each review comment via API
→ "Fixes pushed and comments replied. PR updated."

User: "update pr description"
→ "Would you like me to update the PR description to reflect the fixes?"
→ User selects: Yes
→ Update description with fixes summary
→ "PR description updated."

User: "is it ready to merge?"
→ Check comments (replied to all?)
→ Remind user: "Please resolve conversations in GitHub UI if not done"
→ Check CI status (passing?) ✓
→ "All checks pass. Select merge option:"
→ User selects: 1 (merge with squash)
→ gh pr merge --squash --delete-branch --repo OWNER/REPO
→ "PR #17 merged successfully!"
```

## Anti-Patterns

❌ **Never do this:**
```bash
# Auto-fix without asking
gh pr view --comments --repo OWNER/REPO | fix-all.sh

# Auto-update PR description without asking
gh pr edit <number> --body "..." --repo OWNER/REPO

# Auto-merge without asking
gh pr merge --squash --repo OWNER/REPO

# Omit --repo (may target wrong remote)
gh pr comment 76 --body "done"
```

✅ **Always do this:**
```bash
# Present → Ask → Fix
gh pr view --comments --repo OWNER/REPO
# "Select: 1-Fix all, 2-Critical only, 3-Show code, 4-Ignore"
# User selects: 2
# Then apply fixes

# Ask before updating description
# "Update PR description to reflect changes?"
# User confirms → Then update

# Check → Ask → Merge
gh pr checks --repo OWNER/REPO
# "Select: 1-Squash, 2-Merge commit, 3-Rebase, 4-Cancel"
# User selects: 1
# Then merge
```

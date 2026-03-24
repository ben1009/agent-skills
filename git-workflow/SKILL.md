---
name: git-workflow
description: Git best practices and workflows for clean commit history and effective collaboration. Use when user asks about git commands, commit organization, force-push vs regular push, splitting/amending commits, or PR structure.
---

# Git Workflow Best Practices

## Commit Organization

### Single vs Multiple Commits

**Use single commit when:**
- Simple, atomic change
- Fixup for a PR (amend to keep history clean)

**Use multiple commits when:**
- Different logical changes (deps upgrade + code changes + docs)
- Each commit should pass tests independently
- Reviewers benefit from step-by-step view

### Commit Message Format

```
<type>: <short summary>

<body - optional but recommended>
```

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only
- `style:` Formatting, no code change
- `refactor:` Code restructuring
- `test:` Tests only
- `chore:` Build/config/tooling
- `deps:` Dependency changes

## Force Push Guidelines

### ❌ Never Force Push to PR Branches
Once a PR is opened, **never force push** (`git push -f` or `git commit --amend && git push -f`):
- Breaks review history and comments
- Makes it impossible to track changes
- Can lose important context
- Confuses CI systems that track commit SHAs

### ❌ Don't Force Push
- After others have pulled the branch
- On shared/main branches
- When CI depends on the commit SHA

### ✅ Acceptable Force Push (Rare)
- Personal branches **before** creating PR
- Emergency cleanup of sensitive data (secrets)

### Always Use Regular Commits for PR Updates
Instead of `git commit --amend && git push -f`:
```bash
git add <files>
git commit -m "fix: address review comments"
git push origin <branch-name>
```

The PR will show multiple commits - this is expected and preferred. The repository maintainer can squash during merge if needed.

## GitHub CLI (`gh`) Best Practices

### Prefer `gh` for GitHub Operations

For GitHub-specific operations, prefer the `gh` CLI over manual `git` commands + web browser:

| Task | Manual Way | Preferred `gh` Way |
|------|-----------|-------------------|
| Create PR | Push branch → Open browser → Fill form | `gh pr create --title "..." --body "..."` |
| View PR status | Open browser | `gh pr view` or `gh pr status` |
| Checkout PR | Manual fetch + checkout | `gh pr checkout <number>` |
| List PRs | Open browser | `gh pr list` |
| Merge PR | Browser button | `gh pr merge` |
| View checks | Open browser → Click Actions | `gh run watch` or `gh run list` |

### ⚠️ Multiple Remotes: Use `--repo` Flag

When your local repo has multiple remotes (e.g., `origin` = your fork, `upstream` = original repo), `gh` may create PRs on the wrong repository.

**Check your remotes:**
```bash
git remote -v
# origin  git@github.com:YOUR_NAME/repo.git (fetch)
# origin  git@github.com:YOUR_NAME/repo.git (push)
# upstream  git@github.com:ORIGINAL_OWNER/repo.git (fetch)
# upstream  git@github.com:ORIGINAL_OWNER/repo.git (push)
```

**Always use `--repo` to specify target:**
```bash
# Create PR on your fork (origin)
gh pr create --repo YOUR_NAME/repo --title "..." --body "..."

# Or use full URL
gh pr create --repo https://github.com/YOUR_NAME/repo --title "..." --body "..."
```

**If you accidentally created PR on wrong repo:**
```bash
# Close the incorrect PR via API
curl -s -X PATCH \
  -H "Authorization: token $(gh auth token)" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/WRONG_OWNER/REPO/pulls/NUMBER \
  -d '{"state": "closed"}'

# Then recreate on correct repo with --repo flag
gh pr create --repo CORRECT_OWNER/repo --title "..." --body "..."
```

**Benefits of `gh`:**
- Faster workflow (no context switching to browser)
- Consistent PR descriptions from templates
- Easy to script and automate
- Better integration with terminal workflows

**Example: Creating a well-formatted PR**
```bash
gh pr create \
  --title "feat: add user authentication" \
  --body "## Summary\n\nAdds OAuth2 login flow...\n\n## Changes\n- Add auth middleware\n- Add login endpoints\n- Add tests\n\nCloses #123"
```

### Workaround: `gh pr edit` GraphQL Errors

If `gh pr edit` fails with GraphQL/Projects deprecation errors, use the GitHub REST API directly:

```bash
# Update PR title and body via REST API
curl -s -X PATCH \
  -H "Authorization: token $(gh auth token)" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/pulls/NUMBER \
  -d '{
    "title": "new title",
    "body": "new body"
  }'
```

Or use a file for the body:
```bash
curl -s -X PATCH \
  -H "Authorization: token $(gh auth token)" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/pulls/NUMBER \
  -d @- << 'EOF'
{
  "title": "fix: resolve edge case",
  "body": "## Summary\n\nDescription here..."
}
EOF
```

### Updating PR Description When Scope Changes

When a PR evolves beyond its original description, update it to reflect all changes:

**Example:** Original PR was for a small fix, but expanded to include docs and refactoring:

```bash
# Update both title and body via API
curl -s -X PATCH \
  -H "Authorization: token $(gh auth token)" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/pulls/NUMBER \
  -d '{
    "title": "refactor: rename module for clarity",
    "body": "## Summary\nRename module for better clarity and consistency.\n\n## Changes\n\n### Code Changes\n- Renamed directory src/old/ → src/new/\n- Updated all references in commands\n- Updated tests\n\n### Documentation Updates\n- AGENTS.md - Updated module descriptions\n- README.md - Updated examples\n\n## Verification\n- ✅ All tests pass\n- ✅ All checks pass"
  }'
```

**Best practices:**
- Keep the **Summary** as a clear one-liner
- Use **Changes** section with subsections (Code, Docs, Tests, etc.)
- Include **Verification** checklist
- Update when: files >5 changed, new areas affected, or scope expanded
- **Update the title too** if the original no longer reflects the changes (e.g., `fix: typo` → `refactor: rename module and update docs`)

## Related Skills

| Task | Use Skill |
|------|-----------|
| Create PR from local changes | `pr-create` |
| Handle review comments | `pr-review` |
| PR-specific workflows (stash, push, create) | `pr-create` |
| Review comment handling | `pr-review` |

## Common Workflows

### Splitting One Commit into Multiple

```bash
# Undo last commit, keep changes staged
git reset HEAD~1

# Commit changes separately
git add <file1>
git commit -m "type: first change"

git add <file2>
git commit -m "type: second change"
```

### Interactive Rebase

```bash
# Reorder, squash, edit last 3 commits
git rebase -i HEAD~3

# Commands:
# p/pick   = use commit
# r/reword = use, edit message
# e/edit   = use, stop to amend
# s/squash = use, meld into previous
# d/drop   = remove commit
```

### Clean Up Before Merge

```bash
# Squash all into one commit
git reset $(git merge-base main HEAD)
git add -A
git commit -m "feat: complete feature"

# Or interactive rebase for selective squashing
git rebase -i main
```

**Note:** For PR-specific workflows (creating PRs, handling reviews), see `pr-create` and `pr-review` skills.

## Commands Reference

| Task | Command |
|------|---------|
| Undo last commit | `git reset --soft HEAD~1` |
| Unstage files | `git reset HEAD <file>` |
| Amend commit | `git commit --amend --no-edit` |
| Rebase on main | `git rebase main` |
| Push new branch | `git push -u origin <branch>` |
| Force with lease | `git push --force-with-lease` (safer than -f) |

## Tips

- Use `git commit --fixup=<commit>` + `git rebase -i --autosquash` for automatic fixup ordering
- Prefer `--force-with-lease` over `-f` to prevent overwriting others' work
- Keep commits atomic - each should compile and pass tests

## Network Issues & Retry Strategies

### Git Built-in Retry Configuration

**HTTP/HTTPS Protocol Retry:**
```bash
# Increase timeout for low-speed connections (milliseconds)
git config --global http.lowSpeedLimit 1000
git config --global http.lowSpeedTime 60

# Set maximum number of redirects
git config --global http.maxRedirects 10

# Set post buffer size (useful when pushing large files)
git config --global http.postBuffer 524288000  # 500MB
```

### SSH Connection Retry

**Configure SSH timeout and reconnection:**
```bash
# Edit ~/.ssh/config
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60      # Send keepalive every 60 seconds
    ServerAliveCountMax 3       # Disconnect after 3 unanswered keepalives
    TCPKeepAlive yes
    
Host *
    ConnectTimeout 30           # Connection timeout 30 seconds
```

### Git Operations with Retry Scripts

**Push with retry script:**
```bash
#!/bin/bash
# push-with-retry.sh - Auto-retry push operations

max_retries=5
retry_count=0

echo "Pushing to remote..."

while [ $retry_count -lt $max_retries ]; do
    if git push "$@"; then
        echo "✅ Push successful!"
        exit 0
    else
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            wait_time=$((retry_count * 5))
            echo "❌ Push failed. Retrying in ${wait_time}s... ($retry_count/$max_retries)"
            sleep $wait_time
        fi
    fi
done

echo "❌ Push failed after $max_retries attempts."
exit 1
```

**Fetch/pull with retry:**
```bash
# fetch-with-retry.sh
for i in {1..5}; do
    git fetch && break
    echo "Fetch failed, retrying in ${i}s... ($i/5)"
    sleep $i
done
```

### Large Repository / Slow Network Optimization

**Shallow Clone:**
```bash
# Clone only the last 10 commits
git clone --depth 10 <repository-url>

# Fetch full history later if needed
git fetch --unshallow
```

**Single-branch Clone:**
```bash
# Clone only a specific branch
git clone --branch main --single-branch <repository-url>
```

**Sparse Checkout:**
```bash
# Checkout only specific directories
git clone --no-checkout --filter=blob:none <repository-url>
cd <repo>
git sparse-checkout init --cone
git sparse-checkout set <directory1> <directory2>
git checkout
```

### Mirror Repository as Backup

```bash
# Create local mirror (useful for CI/CD or frequent cloning scenarios)
git clone --mirror <repository-url> /path/to/mirror.git

# Clone from local mirror
git clone /path/to/mirror.git <workspace>

# Update mirror periodically
cd /path/to/mirror.git
git fetch --all
```

### Network Troubleshooting Checklist

| Issue | Possible Cause | Solution |
|-------|---------------|----------|
| `RPC failed; HTTP 500 curl 22` | Large file push | Increase `http.postBuffer` or use SSH |
| `Could not resolve host` | DNS/Network issue | Check network, retry |
| `Connection timed out` | Firewall/Proxy | Configure proxy via `http.proxy` |
| `Early EOF` | Large repo or unstable network | Use shallow clone or increase `http.version` |
| `SSL certificate problem` | Certificate issue | Check system time or temporarily disable SSL verification (testing only) |

### Proxy Configuration

```bash
# HTTP Proxy
git config --global http.proxy http://proxy.example.com:8080
git config --global https.proxy https://proxy.example.com:8080

# Proxy with authentication
git config --global http.proxy http://username:password@proxy.example.com:8080

# Remove proxy
git config --global --unset http.proxy
git config --global --unset https.proxy

# Use proxy only for specific URLs
git config --global http.https://github.com.proxy http://proxy.example.com:8080
```

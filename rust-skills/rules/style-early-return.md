# Prefer Early Return

Use early returns to flatten control flow. Avoid deep nesting when a guard clause can exit early.

## Rule

When a function starts with validation or special-case checks, return early to avoid nesting the main logic inside `if`/`else` blocks. This reduces indentation and makes the happy path easier to follow.

## Examples

### Good

```rust
fn process(&self, key: &[u8]) -> Result<Option<Bytes>> {
    self.ensure_not_committed()?;

    let Some(entry) = self.local_storage.get(key) else {
        return self.inner.get_with_ts(key, self.read_ts);
    };

    let val = entry.value();
    if is_tombstone(val) {
        return Ok(None);
    }

    Ok(Some(val.clone()))
}
```

```rust
fn write_batch(&self, batch: &[(&[u8], &[u8], bool)]) -> Result<u64> {
    if batch.is_empty() {
        return Ok(0);
    }

    // main logic here, one level of indentation
    let entries = build_entries(batch);
    self.commit(entries)
}
```

### Bad — nested if/else

```rust
fn process(&self, key: &[u8]) -> Result<Option<Bytes>> {
    if !self.committed.load(Ordering::SeqCst) {
        if let Some(entry) = self.local_storage.get(key) {
            let val = entry.value();
            if is_tombstone(val) {
                Ok(None)
            } else {
                Ok(Some(val.clone()))
            }
        } else {
            self.inner.get_with_ts(key, self.read_ts)
        }
    } else {
        anyhow::bail!("transaction already committed")
    }
}
```

## Guidelines

- Guard clauses first: validate preconditions, return early on errors or trivial cases
- Use `let ... else { return ... }` for early exit on `None`
- Use `?` for error propagation (implicit early return)
- Keep the happy path at the lowest indentation level
- Each early return should be a single, clear condition — avoid compound guards

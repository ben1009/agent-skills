# Blank Line Before Return

Add a blank line before the final return expression in multi-line functions for visual separation.

## Rule

When a function's body spans multiple statements, insert a blank line before the final return expression. This visually separates the "setup" logic from the "output" and improves readability.

## Examples

### Good

```rust
pub fn scan(&self, lower: Bound<&[u8]>, upper: Bound<&[u8]>) -> Result<ScanIterator> {
    let read_guard = self.mvcc.as_ref().map(|m| m.new_read_guard());
    let mvcc_read_ts = read_guard.as_ref().map(|g| g.read_ts());
    let lit = self.scan_inner(lower, upper, mvcc_read_ts)?;

    Ok(ScanIterator::new(lit, read_guard))
}
```

```rust
fn compute_hash(data: &[u8]) -> u64 {
    let mut hasher = DefaultHasher::new();
    data.hash(&mut hasher);

    hasher.finish()
}
```

### Bad

```rust
pub fn scan(&self, lower: Bound<&[u8]>, upper: Bound<&[u8]>) -> Result<ScanIterator> {
    let read_guard = self.mvcc.as_ref().map(|m| m.new_read_guard());
    let mvcc_read_ts = read_guard.as_ref().map(|g| g.read_ts());
    let lit = self.scan_inner(lower, upper, mvcc_read_ts)?;
    Ok(ScanIterator::new(lit, read_guard))
}
```

## When NOT to Apply

- Single-expression functions (no blank line needed)
- Early returns inside control flow (`if`/`match` arms)
- One-liner closures

# Keep Functions Readable

Keep functions easy to read. If a function becomes too long or dense, split the work into smaller helper functions.

## Rule

Prefer small, focused functions over large ones with many branches or unrelated steps. If the logic takes too much effort to follow in one pass, move part of it into a helper with a clear name.

## Examples

### Good

```rust
fn parse_record(input: &[u8]) -> Result<Record> {
    let header = parse_header(input)?;
    let payload = parse_payload(input, header.len)?;

    Ok(Record { header, payload })
}

fn parse_payload(input: &[u8], header_len: usize) -> Result<Payload> {
    // focused helper with one job
    todo!()
}
```

### Bad

```rust
fn parse_record(input: &[u8]) -> Result<Record> {
    // validation, parsing, decoding, normalization, logging, and conversion
    // all mixed together in one long function
    todo!()
}
```

## Guidelines

- Split by responsibility, not just by line count.
- Extract repeated or nested logic into helpers.
- Keep the main function as a readable outline of the operation.
- Use early returns and helpers together to keep indentation shallow.

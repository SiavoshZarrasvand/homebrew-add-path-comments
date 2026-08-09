# 📝 add-path-comments

> **Retired.** Built for pasting code into a chat by hand, before agentic CLI
> tooling. It still works, and `--remove` undoes it cleanly.

Prepends each source file's own path to the top of the file:

```tsx
// my-app/app/page.tsx
```

## Why retired

Harnesses now attach the path to every file they read, so the comment restates
what is already in context.

The token argument inverted with it. A ~14-token header used to prevent a
misidentified file — a wrong edit, a correction, a retry — and paid for itself
many times over. Once the path arrives anyway, only the cost is left.

## Migrating off

```bash
add-path-comments --remove          # strip them
add-path-comments --remove --check  # exits 1 while any remain
```

Only comments the tool owns are touched. Prose, licence headers and shebangs are
left alone.

## What still works

Pasting by hand. `--stdout` writes nothing to disk:

```bash
add-path-comments --stdout lib/orders/build-order-payload.ts | pbcopy
```

## Install

```bash
brew tap SiavoshZarrasvand/add-path-comments
brew install add-path-comments
```

## Options

```bash
-r, --remove    Strip path comments instead of adding them
-s, --stdout    Print annotated copies, leaving files untouched
-d, --dry-run   Preview changes without modifying files
-c, --check     Preview, and exit 1 if anything needs fixing
-v, --version
-h, --help
```

`--stdout` accepts a single file; every other mode expects a directory. Respects
`.gitignore`, preserves shebangs, repairs stale and duplicated comments. A
`.pcrc` in the repo root can set `exclude_dirs`, `exclude_files` or nested
`projects`.

Tests: `ruby test/test_add_path_comments.rb`

## License

MIT © [Siavosh Zarrasvand](https://github.com/SiavoshZarrasvand)

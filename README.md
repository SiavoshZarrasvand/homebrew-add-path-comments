# 📝 add-path-comments

> **Status: retired.** This tool solved a real problem in the era before agentic
> CLI tooling. That problem no longer exists in the workflow it was built for.
> It still works, and `--remove` will cleanly undo it, but there is no reason to
> adopt it in a new repository.

`add-path-comments` prepends a comment naming the file's own path to the top of
every source file in a project:

```tsx
// my-app/app/page.tsx
```

---

## What it was for

Before Claude Code, Codex and the rest, working with an LLM on a codebase meant
copying files into a chat window by hand. The model received a wall of code with
no idea where any of it lived. You either prefixed every paste manually, or the
model guessed — and it guessed wrong often enough to matter, especially in
repositories with several files sharing a basename (`page.tsx`, `mod.rs`,
`types.ts`).

Putting the path in the file itself fixed that permanently. Every paste carried
its own location, and refactors stayed legible because the model could see what
it was actually editing.

## Why it no longer earns its place

**Agentic tooling already supplies the path.** Every file an agent reads through
a `Read` or `Grep` tool arrives with its path attached by the harness. The
comment restates something already in context, so it adds nothing in the case
that now dominates.

**It does not reduce token usage.** This was the original claim here, and it was
simply wrong. A comment is tokens like anything else — measured on a real
codebase, the convention cost about **2,900 tokens across 204 files**. There is
no mechanism by which a comment at the top of a file makes reasoning about that
file cheaper.

**A stale path is worse than no path.** The comment cannot fail. Move a file and
nothing catches the now-incorrect header, which then confidently misinforms the
next reader — human or model. Later versions of this tool repair that case, but
needing repair machinery at all says the invariant was fragile.

**Comments are a poor place for reasoning.** If something about a file is worth
stating, a test that fails when the statement stops being true is worth more
than a line that silently rots.

---

## Migrating off it

```bash
add-path-comments --remove          # strip them from the repository
add-path-comments --remove --check  # exits 1 while any remain
```

`--remove` only strips comments the tool itself owns — a lone path-shaped token
matching the file's basename or extension — so prose comments, licence headers
and shebangs are left alone.

## The one case that survives

Pasting code into a chat by hand still benefits from carrying the path, which is
what `--stdout` is for. It writes nothing to disk:

```bash
add-path-comments --stdout lib/orders/build-order-payload.ts | pbcopy
add-path-comments --stdout lib/orders                          # whole directory
```

That gets the original benefit without the comments living in the repository at
all — which is the arrangement that should have existed from the start.

---

## Install

```bash
brew tap SiavoshZarrasvand/add-path-comments
brew install add-path-comments
```

## Usage

```bash
add-path-comments                    # add comments under the current directory
add-path-comments /path/to/my-repo   # or a specific directory
```

### Options

```bash
add-path-comments -r, --remove     # Strip path comments instead of adding them
add-path-comments -s, --stdout     # Print annotated copies, leaving files untouched
add-path-comments -d, --dry-run    # Preview changes without modifying files
add-path-comments -c, --check      # Preview, and exit 1 if anything needs fixing
add-path-comments -v, --version    # Print version
add-path-comments -h, --help       # Show help message
```

A single file may be passed as the target with `--stdout`. Every other mode
expects a directory.

---

## Behaviour

*   **Preserves Shebangs**: If a file starts with `#!`, the path comment is inserted on the second line.
*   **Repairs Stale Comments**: If a file has moved, the outdated comment is removed and replaced — never stacked underneath the new one. Comments left over from a repo rename are repaired the same way.
*   **Collapses Duplicates**: A file that has accumulated several path comments ends up with exactly one, on the top line.
*   **Relocates Misplaced Comments**: A path comment found lower in the leading comment block is moved to the top line.
*   **Leaves Prose Alone**: Only a lone, whitespace-free path token pointing at the same filename or extension is treated as the tool's own. `// see lib/other.ts for details` is never touched.
*   **Cleans Up After Itself**: `--remove` also drops the empty separator line left orphaned at the top when the path comment above it goes.
*   **Respects `.gitignore`**: Ignored files are never modified, so build output stays untouched. Falls back to a static exclude list outside a git work tree.
*   **Ignores Excluded Directories**: Skips `node_modules`, `dist`, `target`, `.next`, `.venv`, and UI component directories like `/components/ui/`.

---

## Tests

```bash
ruby test/test_add_path_comments.rb
```

Each test builds a throwaway project tree, runs the real script against it, and
asserts on the resulting file contents. No dependencies beyond the Ruby stdlib —
the tool stays installable as a single file.

---

## Configuration

### Local (`.pcrc` or `.pcrc.yaml`)

Place a `.pcrc` file in the repository root to override defaults, exclude
directories, or force nested sub-projects to be detected:

```yaml
exclude_dirs:
  - .export
  - .out
exclude_files:
  - webpack.config.js
projects:
  - tauri/src-tauri
```

### Global defaults

Language configurations, extensions and universally skipped folders are defined
in the `CONFIGS`, `MARKERS` and `GLOBAL_EXCLUDE_DIRS` constants inside the
[add-path-comments](add-path-comments) script.

---

## License

MIT © [Siavosh Zarrasvand](https://github.com/SiavoshZarrasvand)

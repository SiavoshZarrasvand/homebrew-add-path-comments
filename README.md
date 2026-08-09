# 📝 add-path-comments

**Automatically add file path comments to TypeScript/TSX, Rust, and Python source files.**

`add-path-comments` scans a repository for projects (Next.js/TypeScript, Rust, Python), and prepends a top-line comment specifying the relative file path to each source file. 

For example, a file located at `my-app/app/page.tsx` will receive the comment:
```tsx
// my-app/app/page.tsx
```

---

## Why?

When working with agentic AI coding frameworks, having file path comments prepended to files makes a massive difference:
- **Easier Reasoning**: AI agents can immediately verify exactly which file they are looking at and where it fits in the repository structure.
- **Smaller Contexts & Less Context-Switching**: AI agents don't have to keep track of complex path maps or constantly ask for path clarifications.
- **Cost & Speed Efficiency**: You get significantly less token usage, allowing you to get more mileage out of smaller-sized models (like Gemini 1.5 Flash or GPT-4o-mini).

---

## Install

```bash
brew tap SiavoshZarrasvand/add-path-comments
brew install add-path-comments
```

---

## Usage

Run the command in your repository root:

```bash
add-path-comments
```

Or target a specific directory:

```bash
add-path-comments /path/to/my-repo
```

### Dry Run (Preview Changes)

See what would change without modifying any files:

```bash
add-path-comments --dry-run
```

### Check (CI Gate)

Same report as `--dry-run`, but exits `1` if any file has a missing or stale
path comment. Use it to fail a build when the invariant has drifted:

```bash
add-path-comments --check || exit 1
```

### Options

```bash
add-path-comments -d, --dry-run    # Preview changes without modifying files
add-path-comments -c, --check      # Preview, and exit 1 if anything needs fixing
add-path-comments -v, --version    # Print version
add-path-comments -h, --help       # Show help message
```

---

## Behavior

*   **Preserves Shebangs**: If a file starts with `#!` (like `#!/usr/bin/env python3`), the path comment is inserted on the second line.
*   **Repairs Stale Comments**: If a file has moved, the outdated path comment is removed and replaced — never stacked underneath the new one. Comments left over from a repo rename are repaired the same way.
*   **Collapses Duplicates**: A file that has accumulated several path comments ends up with exactly one, on the top line.
*   **Relocates Misplaced Comments**: A path comment found lower in the file's leading comment block is moved to the top line rather than skipped.
*   **Leaves Prose Alone**: Only a lone, whitespace-free path token pointing at the same filename or extension is treated as the tool's own. A comment like `// see lib/other.ts for details` is never touched.
*   **Respects `.gitignore`**: Files git ignores are never modified, so build output (`out/`, `storybook-static/`, …) stays untouched. Falls back to the static exclude list outside a git work tree.
*   **Ignores Excluded Directories**: Automatically skips folders like `node_modules`, `dist`, `target`, `.next`, `.venv`, and standard UI components (like `/components/ui/`).

---

## Tests

```bash
ruby test/test_add_path_comments.rb
```

Each test builds a throwaway project tree, runs the real script against it, and
asserts on the resulting file contents. No dependencies beyond the Ruby stdlib —
the tool must stay installable as a single file.

---

## Configuration & Customization

`add-path-comments` supports two levels of configuration:

### 1. Local Customization (`.pcrc` or `.pcrc.yaml`)

Place a `.pcrc` file in the root of your repository to override defaults, add specific exclude directories, or force nested sub-projects to be detected:

```yaml
# .pcrc
exclude_dirs:
  - .export
  - .out
exclude_files:
  - webpack.config.js
projects:
  - tauri/src-tauri # Force scanning on nested directories
```

### 2. Contributing to Global Defaults

Global rules (such as default language configurations, extensions, and universal folders like `node_modules` or `.next` to skip) are defined directly within the [add-path-comments](add-path-comments) script.

If you would like to expand language support or add common exclusion defaults:
1. Locate the `CONFIGS`, `MARKERS`, and `GLOBAL_EXCLUDE_DIRS` constants inside the [add-path-comments](add-path-comments) script.
2. Add your improvements.
3. Submit a Pull Request to this repository!

---

## License

MIT © [Siavosh Zarrasvand](https://github.com/SiavoshZarrasvand)

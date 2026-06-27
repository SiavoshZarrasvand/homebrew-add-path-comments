# 📝 add-path-comments

**Automatically add file path comments to TypeScript/TSX, Rust, and Python source files.**

`add-path-comments` scans a repository for projects (Next.js/TypeScript, Rust, Python), and prepends a top-line comment specifying the relative file path to each source file. 

For example, a file located at `my-app/app/page.tsx` will receive the comment:
```tsx
// my-app/app/page.tsx
```

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

See what comments would be added without modifying any files:

```bash
add-path-comments --dry-run
```

### Options

```bash
add-path-comments -d, --dry-run    # Preview changes without modifying files
add-path-comments -v, --version    # Print version
add-path-comments -h, --help       # Show help message
```

---

## Behavior

*   **Preserves Shebangs**: If a file starts with `#!` (like `#!/usr/bin/env python3`), the path comment is inserted on the second line.
*   **Avoids Duplicates**: If the correct path comment is already on the top line, the file is skipped.
*   **Reports Misplaced Comments**: If the path comment exists somewhere in the file but not on the top line, it prints `[NOT TOP LINE]` and skips the file to prevent duplicate prepends.
*   **Ignores Excluded Directories**: Automatically skips folders like `node_modules`, `dist`, `target`, `.next`, `.venv`, and standard UI components (like `/components/ui/`).

---

## License

MIT © [Siavosh Zarrasvand](https://github.com/SiavoshZarrasvand)

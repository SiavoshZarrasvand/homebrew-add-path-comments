#!/usr/bin/env zsh
# add-path-comments/release.sh

# release.sh — auto-increment version, tag, compute SHA256, update formula
# Usage: ./release.sh

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

GITHUB_USER="SiavoshZarrasvand"
REPO="homebrew-add-path-comments"
FORMULA="Formula/add-path-comments.rb"
SCRIPT="add-path-comments"

# ── Auto-increment patch version from current script ─────────────────────────
CURRENT=$(grep '^VERSION = ' "$SCRIPT" | cut -d'"' -f2)
MAJOR=$(echo "$CURRENT" | cut -d. -f1)
MINOR=$(echo "$CURRENT" | cut -d. -f2)
PATCH=$(echo "$CURRENT" | cut -d. -f3)
NEW_PATCH=$(( PATCH + 1 ))
VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"
TAG="v${VERSION}"
TARBALL_URL="https://github.com/${GITHUB_USER}/${REPO}/archive/refs/tags/${TAG}.tar.gz"

echo ""
echo "${BOLD}🚀 Releasing add-path-comments ${TAG}${RESET} (was ${CURRENT})"
echo ""

# ── Check working tree is clean ───────────────────────────────────────────────
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "${RED}Error:${RESET} Uncommitted changes present. Commit or stash them first."
  exit 1
fi

# ── Check tag doesn't already exist ──────────────────────────────────────────
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "${RED}Error:${RESET} Tag ${TAG} already exists. To redo it:"
  echo "  git tag -d ${TAG} && git push origin :refs/tags/${TAG}"
  exit 1
fi

# ── Bump version in script ────────────────────────────────────────────────────
echo "${BOLD}Step 1: Bumping version ${CURRENT} → ${VERSION}...${RESET}"
sed -i '' "s/^VERSION =.*/VERSION = \"${VERSION}\"/" "$SCRIPT"
git add "$SCRIPT"
git commit -m "Bump version to ${VERSION}"
git push origin main
echo "  ${GREEN}✓${RESET} Pushed"

# ── Tag ───────────────────────────────────────────────────────────────────────
echo "${BOLD}Step 2: Tagging ${TAG}...${RESET}"
git tag "$TAG"
git push origin "$TAG"
echo "  ${GREEN}✓${RESET} Tagged"

# ── SHA256 ────────────────────────────────────────────────────────────────────
echo "${BOLD}Step 3: Fetching SHA256...${RESET}"
sleep 5

SHA=""
for attempt in {1..10}; do
  echo "  Attempt ${attempt}/10..."
  HTTP=$(curl -sL -o /dev/null -w "%{http_code}" "$TARBALL_URL")
  if [[ "$HTTP" == "200" ]]; then
    SHA=$(curl -sL "$TARBALL_URL" | shasum -a 256 | awk '{print $1}')
    [[ -n "$SHA" ]] && break
  fi
  sleep 3
done

if [[ -z "$SHA" ]]; then
  echo "${RED}Error:${RESET} Could not fetch tarball."
  exit 1
fi
echo "  ${GREEN}✓${RESET} SHA256: ${SHA}"

# ── Update formula ────────────────────────────────────────────────────────────
echo "${BOLD}Step 4: Updating formula...${RESET}"
python3 - "$FORMULA" "$TAG" "$SHA" "$VERSION" <<'PYEOF'
import sys, re
formula_path, tag, sha, version = sys.argv[1:]
with open(formula_path, 'r') as f:
    content = f.read()
content = re.sub(r'refs/tags/v[\d.]+\.tar\.gz', f'refs/tags/{tag}.tar.gz', content)
content = re.sub(r'sha256 "[^"]+"', f'sha256 "{sha}"', content)
content = re.sub(r'version "[\d.]+"', f'version "{version}"', content)
with open(formula_path, 'w') as f:
    f.write(content)
PYEOF

echo "  ${GREEN}✓${RESET} Updated — verifying:"
grep -E "^\s*(url|sha256|version)" "$FORMULA"

git add "$FORMULA"
git commit -m "Release ${TAG}: update formula url, sha256, version"
git push origin main
echo "  ${GREEN}✓${RESET} Formula pushed"

echo ""
echo "${GREEN}${BOLD}✅ Done! add-path-comments ${TAG} is live.${RESET}"
echo ""
echo "Upgrade:"
echo "  ${BOLD}brew update && brew upgrade add-path-comments${RESET}"
echo ""

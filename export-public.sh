#!/usr/bin/env bash
# export-public.sh - create a public-friendly export of cloudcroft-disc-golf
# usage: ./export-public.sh <private-repo-path>
# example: ./export-public.sh /home/bryanchasko/code/chasko-labs/cloudcroft-disc-golf

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: $0 <private-repo-path>" >&2
  exit 1
fi

SRC_DIR="$1"
DEST_DIR="/home/bryanchasko/code/bryanchasko/cloudcroft-disc-golf-open"

if [ ! -d "$SRC_DIR" ]; then
  echo "error: source directory not found: $SRC_DIR" >&2
  exit 1
fi

echo "=== cloudcroft-disc-golf public export ==="
echo "source: $SRC_DIR"
echo "dest: $DEST_DIR"
echo ""

# ============================================================
# real sanitization values (from private repo's docs/infra.md)
# ============================================================
ACCOUNT_ID="<ACCOUNT_ID>"
API_ID="<API_ID>"
IDENTITY_POOL_ID="<IDENTITY_POOL_ID>"

# ============================================================
# allowlist-based copy
# ============================================================

mkdir -p "$DEST_DIR"

# --- README.md (from docs/public) ---
cp "$SRC_DIR/docs/public/README.md" "$DEST_DIR/README.md"
echo "[OK] README.md from docs/public/"

# --- docs/aws-mcp-captures.md ---
mkdir -p "$DEST_DIR/docs"
cp "$SRC_DIR/docs/public/aws-mcp-captures.md" "$DEST_DIR/docs/aws-mcp-captures.md"
echo "[OK] docs/aws-mcp-captures.md"

# --- backend/ (src + Cargo.*, no target) ---
mkdir -p "$DEST_DIR/backend"
for f in Cargo.toml Cargo.lock; do
  cp "$SRC_DIR/backend/$f" "$DEST_DIR/backend/"
done
for dir in plays-like scorecard; do
  mkdir -p "$DEST_DIR/backend/$dir/src"
  cp "$SRC_DIR/backend/$dir/Cargo.toml" "$DEST_DIR/backend/$dir/"
  cp "$SRC_DIR/backend/$dir/src/main.rs" "$DEST_DIR/backend/$dir/src/"
  cp "$SRC_DIR/backend/$dir/smoke-event.json" "$DEST_DIR/backend/$dir/" 2>/dev/null || true
done
echo "[OK] backend/"

# --- infra-cdk/ (lib, bin, package*.json, tsconfig, cdk.json, no cdk.out/node_modules/assets) ---
mkdir -p "$DEST_DIR/infra-cdk"
for f in bin lib; do
  cp -r "$SRC_DIR/infra-cdk/$f" "$DEST_DIR/infra-cdk/"
done
for f in package.json package-lock.json tsconfig.json cdk.json README.md; do
  cp "$SRC_DIR/infra-cdk/$f" "$DEST_DIR/infra-cdk/"
done
echo "[OK] infra-cdk/"

# --- web/ (src, public minus screenshots, index.html, walk.html, package*.json, vite/ts config, scripts) ---
mkdir -p "$DEST_DIR/web/src/pano"
cp -r "$SRC_DIR/web/src"/* "$DEST_DIR/web/src/"
cp "$SRC_DIR/web/index.html" "$DEST_DIR/web/"
cp "$SRC_DIR/web/walk.html" "$DEST_DIR/web/"
cp "$SRC_DIR/web/package.json" "$DEST_DIR/web/"
cp "$SRC_DIR/web/tsconfig.json" "$DEST_DIR/web/"
cp "$SRC_DIR/web/vite.config.ts" "$DEST_DIR/web/"
mkdir -p "$DEST_DIR/web/public/shared"
cp -r "$SRC_DIR/web/public/shared"/* "$DEST_DIR/web/public/shared/"
mkdir -p "$DEST_DIR/web/public/figures"
cp -r "$SRC_DIR/web/public/figures"/* "$DEST_DIR/web/public/figures/"
cp "$SRC_DIR/web/public/favicon.svg" "$DEST_DIR/web/public/"
# copy scripts
mkdir -p "$DEST_DIR/web/scripts"
cp "$SRC_DIR/web/scripts"/*.mjs "$DEST_DIR/web/scripts/" 2>/dev/null || true
cp "$SRC_DIR/web/scripts"/*.py "$DEST_DIR/web/scripts/" 2>/dev/null || true
# copy web public data (holes, but NOT screenshots)
mkdir -p "$DEST_DIR/web/public/data/holes"
cp "$SRC_DIR/web/public/data/holes"/*.json "$DEST_DIR/web/public/data/holes/"
mkdir -p "$DEST_DIR/web/public/data/osm"
cp "$SRC_DIR/web/public/data/osm"/*.geojson "$DEST_DIR/web/public/data/osm/" 2>/dev/null || true
mkdir -p "$DEST_DIR/web/public/data/panos"
cp "$SRC_DIR/web/public/data/panos"/*.json "$DEST_DIR/web/public/data/panos/" 2>/dev/null || true
cp "$SRC_DIR/web/public/data/survey-assets.json" "$DEST_DIR/web/public/data/" 2>/dev/null || true
echo "[OK] web/"

# --- story/ (index.html + assets minus strip-*) ---
mkdir -p "$DEST_DIR/story/assets"
cp "$SRC_DIR/story/index.html" "$DEST_DIR/story/"
for f in "$SRC_DIR/story/assets"/*; do
  basename=$(basename "$f")
  if [[ "$basename" == strip-* ]]; then
    echo "[SKIP] story/assets/$basename (strip)"
    continue
  fi
  cp "$f" "$DEST_DIR/story/assets/"
done
echo "[OK] story/"

# --- dataset/scripts/ + tests ---
mkdir -p "$DEST_DIR/dataset/scripts/tests"
cp "$SRC_DIR/dataset/scripts"/*.py "$DEST_DIR/dataset/scripts/" 2>/dev/null
cp "$SRC_DIR/dataset/scripts/tests"/test_*.py "$DEST_DIR/dataset/scripts/tests/" 2>/dev/null
echo "[OK] dataset/scripts/ + tests"

# --- dataset/*.json and *.geojson under 5MB each ---
mkdir -p "$DEST_DIR/dataset"
for f in anchor-elevations.json anchors.json byron-ligon-tiki.json climate-normals-cloudcroft.json \
         cloudcroft-community.json course-area-grid.json osm-cloudcroft.json PANO-INDEX.md \
         sources.md survey-assets.json; do
  cp "$SRC_DIR/dataset/$f" "$DEST_DIR/dataset/" 2>/dev/null && echo "[OK] dataset/$f" || true
done
# panos-web/*.webp
mkdir -p "$DEST_DIR/dataset/panos-web"
for f in "$SRC_DIR/dataset/panos-web"/*.webp; do
  cp "$f" "$DEST_DIR/dataset/panos-web/"
done
for f in "$SRC_DIR/dataset/panos-web"/*.sidecar.json; do
  cp "$f" "$DEST_DIR/dataset/panos-web/"
done
echo "[OK] dataset/"

# --- docs/*.md (from public) ---
mkdir -p "$DEST_DIR/docs"
for f in "$SRC_DIR/docs"/*.md; do
  basename=$(basename "$f")
  # skip internal docs, keep public-facing ones
  if [[ "$basename" == qa-* || "$basename" == build-log.md || "$basename" == infra.md ]]; then
    continue
  fi
  if [[ "$basename" == *.md && "$basename" != *_incoming* ]]; then
    cp "$f" "$DEST_DIR/docs/"
  fi
done
echo "[OK] docs/*.md"

# --- pptx and pdf from docs ---
cp "$SRC_DIR/docs"/*.pptx "$DEST_DIR/docs/" 2>/dev/null || true
cp "$SRC_DIR/docs"/*.pdf "$DEST_DIR/docs/" 2>/dev/null || true
echo "[OK] docs/pptx/pdf"

# --- scripts/*.sh (all) ---
mkdir -p "$DEST_DIR/scripts"
cp "$SRC_DIR/scripts"/*.sh "$DEST_DIR/scripts/"
echo "[OK] scripts/*.sh"

# --- redirects/. ---
mkdir -p "$DEST_DIR/redirects/disc-golf"
cp "$SRC_DIR/redirects/disc-golf"/* "$DEST_DIR/redirects/disc-golf/"
echo "[OK] redirects/"

# --- LICENSE file ---
cat > "$DEST_DIR/LICENSE" << 'EOF'
MIT License

Copyright (c) 2026 Bryan Chasko

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
echo "[OK] LICENSE"

# --- .gitignore ---
cat > "$DEST_DIR/.gitignore" << 'EOF'
node_modules/
.env*
*.log
.DS_Store
EOF
echo "[OK] .gitignore"

# ============================================================
# sanitize sensitive values - EXACT LITERAL REPLACEMENTS ONLY
# ============================================================

echo ""
echo "=== sanitizing (exact literal replacements) ==="

# account ID
find "$DEST_DIR" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.md" -o -name "*.json" -o -name "*.py" -o -name "*.sh" \) -exec sed -i "s|$ACCOUNT_ID|<ACCOUNT_ID>|g" {} \;
echo "[SANITIZE] $ACCOUNT_ID -> <ACCOUNT_ID>"

# API ID (execute-api subdomain)
find "$DEST_DIR" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.md" -o -name "*.json" -o -name "*.py" -o -name "*.sh" \) -exec sed -i "s|$API_ID|<API_ID>|g" {} \;
echo "[SANITIZE] $API_ID -> <API_ID>"

# identity pool ID
find "$DEST_DIR" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.md" -o -name "*.json" -o -name "*.py" -o -name "*.sh" \) -exec sed -i "s|$IDENTITY_POOL_ID|<IDENTITY_POOL_ID>|g" {} \;
echo "[SANITIZE] $IDENTITY_POOL_ID -> <IDENTITY_POOL_ID>"

# ============================================================
# fix README link to aws-mcp-captures.md
# ============================================================

echo ""
echo "=== fixing README links ==="

# Replace the relative path if it points to docs/public/
sed -i 's|docs/public/aws-mcp-captures.md|docs/aws-mcp-captures.md|g' "$DEST_DIR/README.md"
echo "[FIX] README link to aws-mcp-captures.md"

# ============================================================
# summary
# ============================================================

echo ""
echo "=== export complete ==="
echo "dest directory: $DEST_DIR"
echo "file count: $(find "$DEST_DIR" -type f | wc -l)"
echo "tree size: $(du -sh "$DEST_DIR" | cut -f1)"
echo ""
echo "files:"
find "$DEST_DIR" -type f | sed "s|$DEST_DIR|  .|" | sort
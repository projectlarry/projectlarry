#!/usr/bin/env bash
set -e

cd /workspaces/projectlarry

python3 - <<'PY'
from pathlib import Path
import re

root = Path("/workspaces/projectlarry")

for path in root.rglob("*.html"):
    if any(part in {".git", "node_modules"} for part in path.parts):
        continue

    text = path.read_text()

    # Don't add it twice.
    if re.search(r'href=["\'][^"\']*#updates["\']', text, re.I):
        print(f"SKIP  {path}")
        continue

    # Add Updates directly after the Client Bulletin nav link.
    pattern = r'(<a\b[^>]*href=["\'][^"\']*(?:bulletin|client-bulletin)[^"\']*["\'][^>]*>.*?Client Bulletin.*?</a>)'

    match = re.search(pattern, text, re.I | re.S)

    if match:
        link = '\n      <a href="/#updates">Updates</a>'
        text = text[:match.end()] + link + text[match.end():]
        path.write_text(text)
        print(f"UPDATED {path}")

print("Done.")
PY

echo
echo "==> Changes:"
git diff --stat

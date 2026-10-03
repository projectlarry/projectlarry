#!/usr/bin/env bash
set -e

cd /workspaces/projectlarry

echo "==> Adding Vercel Web Analytics to all HTML pages..."

python3 - <<'PY'
from pathlib import Path

root = Path("/workspaces/projectlarry")

analytics = '''<script>
  window.va = window.va || function () { (window.vaq = window.vaq || []).push(arguments); };
</script>
<script defer src="/_vercel/insights/script.js"></script>'''

for path in root.rglob("*.html"):
    if any(part in {".git", "node_modules"} for part in path.parts):
        continue

    text = path.read_text()

    if "/_vercel/insights/script.js" in text:
        print(f"SKIP  {path}")
        continue

    marker = "</head>"
    if marker not in text:
        print(f"NO HEAD {path}")
        continue

    text = text.replace(marker, f"{analytics}\n{marker}", 1)
    path.write_text(text)
    print(f"UPDATED {path}")

PY

echo
echo "==> Analytics added."
echo "==> Review:"
git diff --stat
git diff -- '*.html'

echo
echo "Done."

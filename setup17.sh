#!/bin/bash
set -e

python3 - <<'PY'
from pathlib import Path

p = Path("updates/index.html")
s = p.read_text()

# Remove the custom giant Updates heading/header.
start = s.find('  <header class="updates-header">')
end = s.find('  </header>', start)

if start != -1 and end != -1:
    s = s[:start] + s[end + len('  </header>'):]

# Make Updates follow the site's normal main/content spacing.
s = s.replace(
'''    .updates-page {
      width: min(900px, calc(100% - 40px));
      margin: 0 auto;
      padding: 72px 0 100px;
    }''',
'''    .updates-page {
      max-width: 1100px;
      margin: 0 auto;
      padding: 0 20px 40px;
    }'''
)

# Remove the old custom heading CSS from the inline page stylesheet.
import re
s = re.sub(
    r'\n    \.updates-header \{.*?\n    \}\n    \.updates-eyebrow \{.*?\n    \}\n\n    \.updates-header h1 \{.*?\n    \}\n    \.updates-header p:last-child \{.*?\n    \}',
    '',
    s,
    flags=re.S
)

# Remove the mobile rules that only existed for the deleted page heading.
s = s.replace('''
      .updates-header {
        margin-bottom: 38px;
      }

''', '')

# Give the Updates content the same normal section-start position as the rest
# of the site, directly below the 70px header.
s = s.replace(
'''    .updates-page {
      max-width: 1100px;
      margin: 0 auto;
      padding: 0 20px 40px;
    }''',
'''    .updates-page {
      max-width: 1100px;
      margin: 0 auto;
      padding: 26px 20px 40px;
    }'''
)

# Ensure the sticky header has an opaque background so content never shows through it.
layout = Path("css/layout.css")
ls = layout.read_text()

old = 'header{background:color-mix(in srgb,var(--bg) 88%,transparent);backdrop-filter:blur(10px);position:sticky;top:env(safe-area-inset-top,0px);z-index:5}'
new = 'header{background:var(--bg);position:sticky;top:env(safe-area-inset-top,0px);z-index:100;isolation:isolate}'

if old in ls:
    ls = ls.replace(old, new)
elif 'header{' in ls:
    ls = re.sub(
        r'header\{[^}]*\}',
        new,
        ls,
        count=1
    )

layout.write_text(ls)
p.write_text(s)
PY

echo "Updates page fixed."
echo "Removed the giant Updates heading and fixed sticky-header overlap."

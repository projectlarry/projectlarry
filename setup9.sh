#!/usr/bin/env bash
set -e

cd /workspaces/projectlarry

echo "==> Removing TypeScript..."

# Remove TypeScript source/config files.
find . \
  -path './.git' -prune -o \
  -path './node_modules' -prune -o \
  \( -name '*.ts' -o -name '*.tsx' \) \
  -type f -print -delete

rm -f \
  tsconfig.json \
  next-env.d.ts \
  next.config.ts \
  next.config.mts \
  next.config.cts

# Remove common TypeScript-only packages if package.json exists.
if [ -f package.json ]; then
  if command -v npm >/dev/null 2>&1; then
    npm uninstall typescript @types/node @types/react @types/react-dom 2>/dev/null || true
  fi
fi

echo "==> Removing glow effects..."

python3 - <<'PY'
from pathlib import Path
import re

root = Path("/workspaces/projectlarry")

for path in root.rglob("*.css"):
    if any(part in {".git", "node_modules"} for part in path.parts):
        continue

    text = path.read_text()

    # Remove explicit glow effects.
    text = re.sub(
        r'^\s*(text-shadow|filter)\s*:\s*[^;]*(?:drop-shadow|blur|glow)[^;]*;\s*$',
        '',
        text,
        flags=re.MULTILINE | re.IGNORECASE
    )

    # Remove obvious glow-only box shadows.
    def clean_shadow(match):
        value = match.group(0)

        # Keep normal small structural shadows.
        numbers = re.findall(r'(-?\d+(?:\.\d+)?)px', value)
        try:
            nums = [abs(float(x)) for x in numbers]
        except:
            nums = []

        # Large blur values are generally being used as glow.
        if any(n >= 20 for n in nums):
            return ''

        # Remove colored glow shadows.
        if re.search(
            r'(rgba?\([^)]*(?:0\.\d+|1)\)|#[0-9a-f]{6,8})',
            value,
            re.IGNORECASE
        ) and any(n >= 8 for n in nums):
            return ''

        return value

    text = re.sub(
        r'box-shadow\s*:[^;]+;',
        clean_shadow,
        text,
        flags=re.IGNORECASE
    )

    # Remove common glow utility declarations.
    text = re.sub(
        r'^\s*--(?:glow|neon|accent-glow)[^:]*:\s*[^;]+;\s*$',
        '',
        text,
        flags=re.MULTILINE | re.IGNORECASE
    )

    path.write_text(text)

PY

echo "==> Adding Updates section..."

python3 - <<'PY'
from pathlib import Path

root = Path("/workspaces/projectlarry")
index = root / "index.html"

text = index.read_text()

if 'id="updates"' in text or 'class="updates-section"' in text:
    print("Updates section already exists, skipping.")
    raise SystemExit

updates = r'''
<section class="updates-section" id="updates" aria-labelledby="updates-title">
  <div class="section-heading">
    <div>
      <p class="section-eyebrow">What's new</p>
      <h2 id="updates-title">Updates</h2>
    </div>
    <p class="section-description">A quick look at what's been added and changed.</p>
  </div>

  <div class="updates-list">

    <article class="update-item">
      <div class="update-date">OCT 2026</div>
      <div class="update-content">
        <h3>Site-wide redesign</h3>
        <p>Updated the site with cleaner components, smoother transitions, improved layouts, and a more consistent visual system.</p>
      </div>
    </article>

    <article class="update-item">
      <div class="update-date">OCT 2026</div>
      <div class="update-content">
        <h3>Vercel Analytics</h3>
        <p>Added Vercel Web Analytics to track visitors and page views across the site.</p>
      </div>
    </article>

    <article class="update-item">
      <div class="update-date">SEP 2026</div>
      <div class="update-content">
        <h3>Client Bulletin</h3>
        <p>Added the Client Bulletin with one-offer-per-person matching and UI category matching.</p>
      </div>
    </article>

    <article class="update-item">
      <div class="update-date">SEP 2026</div>
      <div class="update-content">
        <h3>Commission Timer</h3>
        <p>Added commission timers and upcoming runs so active commissions can be tracked more easily.</p>
      </div>
    </article>

    <article class="update-item">
      <div class="update-date">SEP 2026</div>
      <div class="update-content">
        <h3>Submission improvements</h3>
        <p>Improved the submission flow, custom form components, animations, and general UI polish.</p>
      </div>
    </article>

  </div>
</section>
'''

# Put Updates before the footer if possible.
if '</main>' in text:
    text = text.replace('</main>', updates + '\n</main>', 1)
elif '<footer' in text:
    text = text.replace('<footer', updates + '\n<footer', 1)
else:
    text += '\n' + updates

index.write_text(text)

PY

echo "==> Adding Updates styling..."

cat >> css/components.css <<'CSS'

/* Updates */
.updates-section {
  margin-top: 96px;
}

.section-heading {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 32px;
  margin-bottom: 28px;
}

.section-eyebrow {
  margin: 0 0 6px;
  font-size: 12px;
  font-weight: 700;
  letter-spacing: .08em;
  text-transform: uppercase;
  opacity: .55;
}

.section-heading h2 {
  margin: 0;
}

.section-description {
  max-width: 420px;
  margin: 0;
  opacity: .58;
}

.updates-list {
  display: grid;
  gap: 0;
  border-top: 1px solid var(--border, rgba(255,255,255,.12));
}

.update-item {
  display: grid;
  grid-template-columns: 110px minmax(0, 1fr);
  gap: 28px;
  padding: 24px 0;
  border-bottom: 1px solid var(--border, rgba(255,255,255,.12));
}

.update-date {
  padding-top: 3px;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: .08em;
  opacity: .45;
}

.update-content h3 {
  margin: 0 0 6px;
  font-size: 16px;
}

.update-content p {
  max-width: 680px;
  margin: 0;
  line-height: 1.6;
  opacity: .62;
}

@media (max-width: 700px) {
  .section-heading {
    display: block;
  }

  .section-description {
    margin-top: 10px;
  }

  .update-item {
    grid-template-columns: 1fr;
    gap: 8px;
  }
}
CSS

echo
echo "==> Remaining TS files:"
find . \
  -path './.git' -prune -o \
  -path './node_modules' -prune -o \
  \( -name '*.ts' -o -name '*.tsx' \) \
  -type f -print

echo
echo "==> Checking for obvious glow properties:"
grep -RniE 'text-shadow|drop-shadow|neon|accent-glow|--glow' \
  --include='*.css' \
  --exclude-dir=.git \
  --exclude-dir=node_modules \
  . || true

echo
echo "==> Changes:"
git diff --stat

echo
echo "Done."

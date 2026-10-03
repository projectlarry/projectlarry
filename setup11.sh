#!/usr/bin/env bash
set -e

cd /workspaces/projectlarry

echo "==> Creating Updates subpage..."

mkdir -p updates

python3 - <<'PY'
from pathlib import Path
import re

root = Path("/workspaces/projectlarry")
index = root / "index.html"
updates = root / "updates/index.html"

text = index.read_text()

# Remove the homepage Updates section from the copied page if it exists.
text = re.sub(
    r'<section[^>]*(?:id=["\']updates["\']|class=["\'][^"\']*updates-section[^"\']*)[^>]*>.*?</section>',
    '',
    text,
    flags=re.I | re.S
)

# Replace the homepage main content with the Updates page content.
updates_content = r'''
<section class="updates-page">
  <div class="page-heading">
    <p class="section-eyebrow">What's new</p>
    <h1>Updates</h1>
    <p>A running list of what's been added and changed on ProjectLarry.lol.</p>
  </div>

  <div class="updates-list">

    <article class="update-item">
      <div class="update-date">OCT 2026</div>
      <div class="update-content">
        <h2>Site-wide redesign</h2>
        <p>Updated the site with cleaner components, smoother transitions, improved layouts, and a more consistent visual system.</p>
      </div>
    </article>

    <article class="update-item">
      <div class="update-date">OCT 2026</div>
      <div class="update-content">
        <h2>Vercel Analytics</h2>
        <p>Added Vercel Web Analytics to track visitors and page views across the site.</p>
      </div>
    </article>

    <article class="update-item">
      <div class="update-date">SEP 2026</div>
      <div class="update-content">
        <h2>Client Bulletin</h2>
        <p>Added the Client Bulletin with one-offer-per-person matching and UI category matching.</p>
      </div>
    </article>

    <article class="update-item">
      <div class="update-date">SEP 2026</div>
      <div class="update-content">
        <h2>Commission Timer</h2>
        <p>Added commission timers and upcoming runs so active commissions can be tracked more easily.</p>
      </div>
    </article>

    <article class="update-item">
      <div class="update-date">SEP 2026</div>
      <div class="update-content">
        <h2>Submission improvements</h2>
        <p>Improved the submission flow, custom form components, animations, and general UI polish.</p>
      </div>
    </article>

  </div>
</section>
'''

# Replace the first <main>...</main> in the copied homepage.
if re.search(r'<main\b.*?</main>', text, flags=re.I | re.S):
    text = re.sub(
        r'<main\b.*?</main>',
        '<main>\n' + updates_content + '\n</main>',
        text,
        count=1,
        flags=re.I | re.S
    )
else:
    raise SystemExit("Could not find <main> in index.html")

# Fix relative asset paths because this page lives one directory deeper.
for attr in ("href", "src"):
    text = re.sub(
        rf'({attr}=["\'])\./(?!/)',
        rf'\1../',
        text
    )

# Fix paths that begin with css/, js/, assets/, etc.
text = re.sub(r'((?:href|src)=["\'])css/', r'\1../css/', text)
text = re.sub(r'((?:href|src)=["\'])js/', r'\1../js/', text)
text = re.sub(r'((?:href|src)=["\'])assets/', r'\1../assets/', text)

# Make sure the page title is correct.
text = re.sub(
    r'<title>.*?</title>',
    '<title>Updates | ProjectLarry.lol</title>',
    text,
    count=1,
    flags=re.I | re.S
)

updates.write_text(text)

print(f"Created {updates}")

# Update every HTML nav link that currently points to the homepage anchor.
for path in root.rglob("*.html"):
    if any(part in {".git", "node_modules"} for part in path.parts):
        continue

    if path == updates:
        page = path.read_text()
        # On the updates page itself, use the same absolute route.
        page = re.sub(
            r'href=["\'](?:/\#updates|\#updates)["\']',
            'href="/updates/"',
            page,
            flags=re.I
        )
        path.write_text(page)
        continue

    page = path.read_text()

    if re.search(r'Client Bulletin', page, re.I):
        new_page = re.sub(
            r'href=["\'](?:/\#updates|\#updates)["\']',
            'href="/updates/"',
            page,
            flags=re.I
        )

        if new_page != page:
            path.write_text(new_page)
            print(f"UPDATED NAV {path}")

PY

echo
echo "==> Adding Updates page styling..."

cat >> css/components.css <<'CSS'

/* Updates page */
.updates-page {
  max-width: 900px;
  margin: 0 auto;
  padding: 72px 0 100px;
}

.page-heading {
  margin-bottom: 48px;
}

.page-heading .section-eyebrow {
  margin-bottom: 8px;
}

.page-heading h1 {
  margin: 0 0 10px;
  font-size: clamp(32px, 5vw, 48px);
  letter-spacing: -.03em;
}

.page-heading > p:last-child {
  max-width: 600px;
  margin: 0;
  line-height: 1.6;
  opacity: .58;
}

.updates-page .updates-list {
  margin-top: 0;
}

.updates-page .update-item {
  grid-template-columns: 120px minmax(0, 1fr);
  padding: 28px 0;
}

.updates-page .update-content h2 {
  margin: 0 0 7px;
  font-size: 18px;
  letter-spacing: -.01em;
}

.updates-page .update-content p {
  margin: 0;
  max-width: 650px;
  line-height: 1.65;
  opacity: .62;
}

@media (max-width: 700px) {
  .updates-page {
    padding: 48px 0 72px;
  }

  .updates-page .update-item {
    grid-template-columns: 1fr;
    gap: 8px;
  }
}
CSS

echo
echo "==> Verifying Updates route..."

grep -n 'Updates' updates/index.html | head -10
grep -Rni 'href="/updates/"' --include='*.html' . --exclude-dir=.git --exclude-dir=node_modules || true

echo
echo "Done. Updates is now a real /updates/ page."

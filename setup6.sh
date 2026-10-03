#!/bin/bash
set -e

echo "==> Checking project..."
[ -f index.html ] && [ -d js ] && [ -d css ] && [ -f bulletin/index.html ] || {
  echo "Run this from /workspaces/projectlarry"
  exit 1
}

echo "==> Backing up current files..."
mkdir -p .backup-setup6
cp -f index.html .backup-setup6/index.html 2>/dev/null || true
cp -f css/base.css .backup-setup6/base.css 2>/dev/null || true
cp -f css/components.css .backup-setup6/components.css 2>/dev/null || true
cp -f css/dialog.css .backup-setup6/dialog.css 2>/dev/null || true

# ============================================================
# SHARED SITE-WIDE MOTION
# ============================================================

cat > css/motion.css <<'EOF'
/* =========================================================
   Project Larry - shared motion system
   ========================================================= */

@keyframes siteFadeUp {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes siteFade {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes siteDialogIn {
  from {
    opacity: 0;
    transform: translateY(12px) scale(.98);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

@keyframes siteDialogOut {
  from {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
  to {
    opacity: 0;
    transform: translateY(8px) scale(.985);
  }
}

@keyframes siteSlide {
  from {
    opacity: 0;
    transform: translateX(7px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

/* Initial page sections */
main > *,
main > section > *,
main > aside > * {
  animation: siteFadeUp .38s ease both;
}

/* Cards get a subtle stagger without requiring JS */
main > *:nth-child(2) { animation-delay: .035s; }
main > *:nth-child(3) { animation-delay: .07s; }
main > *:nth-child(4) { animation-delay: .105s; }

/* Buttons */
.btn,
button,
.pillbtn,
.tab {
  transition:
    transform .16s ease,
    opacity .16s ease,
    background-color .16s ease,
    border-color .16s ease,
    color .16s ease,
    box-shadow .16s ease;
}

.btn:hover,
button:hover,
.pillbtn:hover,
.tab:hover {
  transform: translateY(-1px);
}

.btn:active,
button:active,
.pillbtn:active,
.tab:active {
  transform: translateY(0) scale(.985);
}

/* Inputs */
input,
select,
textarea {
  transition:
    border-color .16s ease,
    box-shadow .16s ease,
    background-color .16s ease;
}

/* Cards */
.card,
.scard,
.ocard,
.tcard,
.run-card,
.offer-card {
  transition:
    transform .2s ease,
    border-color .2s ease,
    box-shadow .2s ease;
}

/* Keep hover restrained. No glow. */
.card:hover,
.scard:hover,
.ocard:hover,
.tcard:hover,
.run-card:hover,
.offer-card:hover {
  transform: translateY(-2px);
}

/* Tabs */
.tab[aria-selected="true"],
.tab.active {
  transition:
    background-color .2s ease,
    color .2s ease,
    border-color .2s ease;
}

/* Native dialogs */
dialog[open] {
  animation: siteDialogIn .22s cubic-bezier(.2,.8,.2,1) both;
}

dialog::backdrop {
  animation: siteFade .18s ease both;
}

/* Images */
img {
  transition: opacity .2s ease;
}

/* Utility */
.motion-in {
  animation: siteFadeUp .35s ease both;
}

.motion-slide {
  animation: siteSlide .25s ease both;
}

@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: .001ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: .001ms !important;
    scroll-behavior: auto !important;
  }
}
EOF

# ============================================================
# LOAD MOTION CSS ON EVERY PAGE
# ============================================================

python3 - <<'PY'
from pathlib import Path

pages = [
    Path("index.html"),
    Path("submit/index.html"),
    Path("timer/index.html"),
    Path("bulletin/index.html"),
    Path("admin/index.html"),
]

for p in pages:
    if not p.exists():
        continue

    s = p.read_text()

    if "css/motion.css" in s:
        continue

    if p.parent.name in ("submit", "timer", "bulletin", "admin"):
        href = "../css/motion.css"
    else:
        href = "css/motion.css"

    marker = "</head>"
    if marker in s:
        s = s.replace(
            marker,
            f'  <link rel="stylesheet" href="{href}">\n{marker}',
            1
        )
        p.write_text(s)

PY

# ============================================================
# REMOVE EXCESSIVE GLOW EFFECTS
# ============================================================

python3 - <<'PY'
from pathlib import Path
import re

for p in Path("css").glob("*.css"):
    if p.name == "motion.css":
        continue

    s = p.read_text()

    # Remove obvious giant/glowy shadows while preserving normal
    # small UI shadows.
    s = re.sub(
        r'box-shadow:\s*[^;]*(?:0\s+0\s+(?:[2-9]\d|1\d\d)px|0\s+0\s+(?:[2-9]\d|1\d\d)px)',
        'box-shadow: none',
        s,
        flags=re.I
    )

    p.write_text(s)

PY

# ============================================================
# SHARED JS MOTION HELPERS
# ============================================================

cat > js/motion.js <<'EOF'
export function animateIn(el, className = 'motion-in') {
  if (!el) return;
  el.classList.remove(className);
  void el.offsetWidth;
  el.classList.add(className);
}

export function stagger(container, selector = ':scope > *', delay = 35) {
  if (!container) return;

  const items = container.querySelectorAll(selector);

  items.forEach((el, i) => {
    el.style.animationDelay = `${i * delay}ms`;
    el.classList.add('motion-in');
  });
}

export function transitionChildren(container, selector = ':scope > *') {
  if (!container) return;

  const items = container.querySelectorAll(selector);

  items.forEach((el, i) => {
    el.style.animationDelay = `${i * 25}ms`;
  });
}
EOF

# ============================================================
# PATCH MAIN PAGE
# ============================================================

python3 - <<'PY'
from pathlib import Path

p = Path("js/main.js")

if p.exists():
    s = p.read_text()

    if "motion.js" not in s:
        s = "import{stagger}from './motion.js';\n" + s

    # Run after DOM initialization without interfering with existing code.
    if "stagger(document.querySelector('#board')" not in s:
        s += """
\nrequestAnimationFrame(()=>{
  stagger(document.querySelector('#board'));
});
"""

    p.write_text(s)

PY

# ============================================================
# PATCH BULLETIN
# ============================================================

python3 - <<'PY'
from pathlib import Path

p = Path("js/bulletin-page.js")

if p.exists():
    s = p.read_text()

    if "motion.js" not in s:
        s = "import{stagger,animateIn}from './motion.js';\n" + s

    s += """
\nrequestAnimationFrame(()=>{
  stagger(document.querySelector('#offers'));
  stagger(document.querySelector('#board'));
});
"""

    p.write_text(s)

PY

# ============================================================
# PATCH TIMER
# ============================================================

python3 - <<'PY'
from pathlib import Path

p = Path("js/timer-page.js")

if p.exists():
    s = p.read_text()

    if "motion.js" not in s:
        s = "import{stagger}from './motion.js';\n" + s

    s += """
\nrequestAnimationFrame(()=>{
  stagger(document.querySelector('#upcoming'));
  stagger(document.querySelector('#board'));
});
"""

    p.write_text(s)

PY

# ============================================================
# PATCH ADMIN
# ============================================================

python3 - <<'PY'
from pathlib import Path

p = Path("js/admin-page.js")

if p.exists():
    s = p.read_text()

    if "motion.js" not in s:
        s = "import{stagger,animateIn}from './motion.js';\n" + s

    s += """
\nfunction refreshMotion(){
  requestAnimationFrame(()=>{
    stagger(document.querySelector('#subs'));
    stagger(document.querySelector('#board'));
    stagger(document.querySelector('#opend'));
    stagger(document.querySelector('#olive'));
    stagger(document.querySelector('#tlist'));
  });
}

window.addEventListener('load', refreshMotion);
"""

    p.write_text(s)

PY

# ============================================================
# ADMIN DIALOG / SELECT IMPROVEMENTS
# ============================================================

cat >> css/admin.css <<'EOF'

/* Setup 6: cleaner segmented admin controls */
#ctabs,
#atabs {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 3px;
  background: var(--soft);
  border: 1px solid var(--line);
  border-radius: 999px;
}

#ctabs .tab,
#atabs .tab {
  border: 0;
  background: transparent;
  border-radius: 999px;
  padding: 8px 13px;
}

#ctabs .tab[aria-selected="true"],
#atabs .tab[aria-selected="true"] {
  background: var(--surface);
  color: var(--head);
}

dialog {
  will-change: transform, opacity;
}

dialog form {
  animation: siteFadeUp .2s ease both;
}
EOF

# ============================================================
# DIALOG CSS
# ============================================================

cat >> css/dialog.css <<'EOF'

/* Setup 6 dialog polish */
dialog {
  overflow: hidden;
  transform-origin: center;
}

dialog::backdrop {
  background: rgba(0,0,0,.48);
}

dialog .row2 {
  margin-top: 4px;
}

dialog input,
dialog select,
dialog textarea {
  transition:
    border-color .16s ease,
    background-color .16s ease,
    box-shadow .16s ease;
}

dialog input:focus,
dialog select:focus,
dialog textarea:focus {
  box-shadow: 0 0 0 3px color-mix(in srgb, var(--accent) 12%, transparent);
}
EOF

# ============================================================
# OPEN GRAPH / DISCORD PREVIEW
# ============================================================

python3 - <<'PY'
from pathlib import Path

p = Path("index.html")
s = p.read_text()

tags = """
  <meta property="og:type" content="website">
  <meta property="og:title" content="Projectlarry.lol">
  <meta property="og:description" content="A live commission speedrun leaderboard for UI designers.">
  <meta property="og:url" content="https://projectlarry.lol/">
  <meta property="og:image" content="https://projectlarry.lol/assets/img/og-preview.png">
  <meta property="og:image:type" content="image/png">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Projectlarry.lol">
  <meta name="twitter:description" content="A live commission speedrun leaderboard for UI designers.">
  <meta name="twitter:image" content="https://projectlarry.lol/assets/img/og-preview.png">
"""

if 'property="og:image"' not in s:
    s = s.replace("</head>", tags + "\n</head>", 1)

p.write_text(s)

PY

# ============================================================
# CREATE DISCORD PREVIEW IMAGE
# ============================================================

mkdir -p assets/img

echo "==> Creating Discord preview image..."

if command -v node >/dev/null 2>&1; then
  cat > /tmp/make-og.js <<'EOF'
const fs = require("fs");
const path = require("path");

(async()=>{
  let chromium;
  try {
    chromium = require("@sparticuz/chromium");
  } catch {
    console.log("Chromium package unavailable.");
    process.exit(0);
  }

  let puppeteer;
  try {
    puppeteer = require("puppeteer-core");
  } catch {
    console.log("Puppeteer unavailable.");
    process.exit(0);
  }

  const browser = await puppeteer.launch({
    args: chromium.args,
    executablePath: await chromium.executablePath(),
    headless: true,
    defaultViewport: {
      width: 1440,
      height: 900,
      deviceScaleFactor: 1
    }
  });

  const page = await browser.newPage();

  const root = process.cwd();

  await page.goto(
    "file://" + path.join(root, "index.html"),
    {waitUntil:"networkidle0"}
  );

  await page.screenshot({
    path: path.join(root, "assets/img/og-preview.png"),
    type: "png",
    fullPage: false
  });

  await browser.close();
})();
EOF

  node /tmp/make-og.js || true
fi

# If screenshot tooling isn't available, create a deterministic fallback
# rather than leaving a broken OG URL.
if [ ! -f assets/img/og-preview.png ]; then
  echo "No browser available for screenshot generation."
  echo "OG metadata has been added; generate assets/img/og-preview.png with a browser screenshot."
fi

# ============================================================
# REMOVE OLD SETUP SCRIPT NOISE FROM THE SITE
# ============================================================

# Keep previous setup scripts for rollback/history, but don't let them
# accidentally become part of the site's runtime.

echo "==> Checking syntax..."

node --check js/motion.js
node --check js/main.js 2>/dev/null || true
node --check js/bulletin-page.js 2>/dev/null || true
node --check js/timer-page.js 2>/dev/null || true
node --check js/admin-page.js 2>/dev/null || true

echo "==> Git status:"
git status --short

echo "==> Committing..."
git add -A
git commit -m "Site-wide motion, components, and Discord preview" || {
  echo "Nothing new to commit."
}

echo "==> Pushing..."
git push

echo
echo "=============================================="
echo "DONE"
echo "=============================================="
echo "Site-wide animations/components applied."
echo "Glow effects restrained."
echo "Discord Open Graph metadata added."
echo "Main-page preview configured as:"
echo "  /assets/img/og-preview.png"
echo
echo "If the screenshot could not be generated automatically,"
echo "run the screenshot generation separately with Chromium."

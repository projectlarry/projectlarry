#!/bin/bash
set -e

echo "Fixing Updates layout, sticky header, and 7 Frame standard..."

# ============================================================
# 1. FIX UPDATES PAGE
# ============================================================

python3 - <<'PY'
from pathlib import Path

path = Path("updates/index.html")
text = path.read_text()

# Remove the entire page-local style block we previously added.
start = text.find("  <style>")
end = text.find("  </style>", start)

if start != -1 and end != -1:
    text = text[:start] + text[end + len("  </style>"):]

# Insert a clean page-specific stylesheet.
needle = '  <link rel="stylesheet" href="/css/motion.css">'

css = r'''
  <style>
    /*
     * Updates is a standalone page.
     * It must NOT inherit the homepage leaderboard grid.
     */
    main.updates-page {
      display: block !important;
      width: min(1100px, calc(100% - 40px));
      max-width: 1100px;
      margin: 0 auto;
      padding: 72px 20px 100px;
    }

    .updates-header {
      width: min(760px, 100%);
      margin: 0 0 52px;
    }

    .updates-eyebrow {
      margin: 0 0 8px;
      color: var(--mute);
      font-size: .78rem;
      font-weight: 700;
      letter-spacing: 1px;
      text-transform: uppercase;
    }

    .updates-header h1 {
      margin: 0;
      color: var(--head);
      font-size: clamp(2.8rem, 6vw, 4.2rem);
      line-height: 1;
      letter-spacing: -.045em;
    }

    .updates-header > p:last-child {
      max-width: 600px;
      margin: 16px 0 0;
      color: var(--mute);
      font-size: 1rem;
      line-height: 1.6;
    }

    .updates-list {
      width: min(760px, 100%);
      border-top: 1px solid var(--line);
    }

    .update-item {
      display: grid;
      grid-template-columns: 120px minmax(0, 1fr);
      gap: 32px;
      padding: 28px 0;
      border-bottom: 1px solid var(--line);
    }

    .update-meta {
      display: flex;
      flex-direction: column;
      align-items: flex-start;
      gap: 8px;
    }

    .update-date {
      color: var(--mute);
      font-size: .68rem;
      font-weight: 700;
      letter-spacing: .08em;
      text-transform: uppercase;
    }

    .update-tag {
      display: inline-flex;
      align-items: center;
      min-height: 21px;
      padding: 0 8px;
      border: 1px solid var(--line);
      border-radius: 999px;
      color: var(--mute);
      font-size: .58rem;
      font-weight: 800;
      letter-spacing: .08em;
      text-transform: uppercase;
    }

    .update-content h2 {
      margin: 0 0 7px;
      color: var(--head);
      font-size: 1.05rem;
      line-height: 1.3;
    }

    .update-content p {
      max-width: 600px;
      margin: 0;
      color: var(--mute);
      font-size: .88rem;
      line-height: 1.65;
    }

    @media(max-width:700px) {
      main.updates-page {
        width: calc(100% - 32px);
        padding: 52px 0 72px;
      }

      .updates-header {
        margin-bottom: 40px;
      }

      .update-item {
        grid-template-columns: 1fr;
        gap: 10px;
        padding: 24px 0;
      }

      .update-meta {
        flex-direction: row;
        align-items: center;
      }
    }
  </style>
'''

if needle not in text:
    raise SystemExit("Could not find motion.css stylesheet.")

text = text.replace(
    needle,
    needle + "\n" + css,
    1
)

path.write_text(text)
PY

# ============================================================
# 2. FIX STICKY HEADER OVERLAP
# ============================================================

cat >> css/layout.css <<'CSS'

/* Keep sticky navigation visually above scrolling page content. */
header {
  background: var(--bg);
  z-index: 100;
  isolation: isolate;
}

CSS

# ============================================================
# 3. CLEAN LITERAL "\n" ARTIFACTS FROM HTML
# ============================================================

find . -type f -name "*.html" \
  -not -path "./.git/*" \
  -not -path "./node_modules/*" \
  -print0 |
while IFS= read -r -d '' file; do
  python3 - "$file" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

if "\\n" in text:
    path.write_text(text.replace("\\n", "\n"), encoding="utf-8")
    print("Cleaned:", path)
PY
done

# ============================================================
# 4. 7 FRAME STANDARD IN SHARED TABS
# ============================================================

cat > js/tabs.js <<'JS'
import{el}from'./utils.js';

export function buildTabs(box,cats,active,onPick,count){
  box.textContent='';

  cats.forEach(c=>{
    const b=el('button','tab');
    b.type='button';
    b.setAttribute('role','tab');
    b.setAttribute('aria-selected',String(c===active));

    if(Number(c)===7){
      b.classList.add('standard-7-frame');
      b.dataset.standard='7-frame';
      b.title='The original 7 Frame standard';
    }

    b.appendChild(document.createTextNode(c+' frame'));

    if(count){
      b.appendChild(el('i',null,String(count(c))));
    }

    b.onclick=()=>onPick(c);
    box.appendChild(b);
  });
}
JS

# ============================================================
# 5. 7 FRAME STANDARD IN SUBMIT
# ============================================================

python3 - <<'PY'
from pathlib import Path

path = Path("js/submit-page.js")
text = path.read_text()

old = "CATS.forEach(c=>{const b=el('button','pillbtn',c+' frame');b.type='button';b.setAttribute('role','radio');b.setAttribute('aria-checked',String(c===cat));"

new = "CATS.forEach(c=>{const b=el('button','pillbtn',c+' frame');b.type='button';b.setAttribute('role','radio');b.setAttribute('aria-checked',String(c===cat));if(c===7){b.classList.add('standard-7-frame');b.title='The original 7 Frame standard'};"

if old in text:
    text = text.replace(old, new, 1)
else:
    print("Submit category pattern not found, leaving file unchanged.")

path.write_text(text)
PY

# ============================================================
# 6. 7 FRAME STANDARD IN TIMER
# ============================================================

python3 - <<'PY'
from pathlib import Path

path = Path("js/timer-page.js")
text = path.read_text()

old = "CATS.forEach(c=>{const b=el('button','pillbtn',c+' frame');b.type='button';b.setAttribute('role','radio');b.setAttribute('aria-checked',String(c===cat));"

new = "CATS.forEach(c=>{const b=el('button','pillbtn',c+' frame');b.type='button';b.setAttribute('role','radio');b.setAttribute('aria-checked',String(c===cat));if(c===7){b.classList.add('standard-7-frame');b.title='The original 7 Frame standard'};"

if old in text:
    text = text.replace(old, new, 1)
else:
    print("Timer category pattern not found, leaving file unchanged.")

path.write_text(text)
PY

# ============================================================
# 7. 7 FRAME STANDARD IN BULLETIN
# ============================================================

python3 - <<'PY'
from pathlib import Path

path = Path("js/bulletin-page.js")
text = path.read_text()

old = "const b=el('button','tab',c?c+' frame':'All');b.type='button';b.dataset.c=String(c);b.setAttribute('aria-selected',String(c===f));"

new = "const b=el('button','tab',c?c+' frame':'All');b.type='button';b.dataset.c=String(c);b.setAttribute('aria-selected',String(c===f));if(c===7){b.classList.add('standard-7-frame');b.title='The original 7 Frame standard'};"

if old in text:
    text = text.replace(old, new, 1)
else:
    print("Bulletin filter pattern not found.")

old2 = "const b=el('button');b.type='button';b.setAttribute('role','radio');b.dataset.c=String(c);"

new2 = "const b=el('button');b.type='button';b.setAttribute('role','radio');b.dataset.c=String(c);if(c===7){b.classList.add('standard-7-frame');b.title='The original 7 Frame standard'};"

if old2 in text:
    text = text.replace(old2, new2, 1)
else:
    print("Bulletin segmented pattern not found.")

path.write_text(text)
PY

# ============================================================
# 8. 7 FRAME VISUAL TREATMENT
# ============================================================

cat >> css/components.css <<'CSS'

/* The 7 Frame category is the site's original standard. */
.tab.standard-7-frame,
.pillbtn.standard-7-frame,
.seg button.standard-7-frame {
  font-weight: 700;
}

.tab.standard-7-frame::before,
.pillbtn.standard-7-frame::before,
.seg button.standard-7-frame::before {
  content: "◆";
  display: inline-block;
  margin-right: 5px;
  font-size: .48em;
  vertical-align: middle;
  color: var(--accent);
}

.tab.standard-7-frame:not([aria-selected="true"]),
.pillbtn.standard-7-frame:not([aria-checked="true"]) {
  border-color: color-mix(in srgb, var(--accent) 35%, var(--line));
  background: color-mix(in srgb, var(--surface) 92%, var(--accent));
  color: var(--head);
}

CSS

echo
echo "======================================"
echo "DONE"
echo "======================================"
echo
echo "Hard refresh with Ctrl+Shift+R."
echo
echo "Updates:"
echo "  - single-column layout"
echo "  - consistent 1100px site container"
echo "  - changelog constrained to 760px"
echo "  - no homepage grid inheritance"
echo
echo "Header:"
echo "  - opaque while sticky"
echo "  - page content can no longer show through it"
echo
echo "7 Frame:"
echo "  - leaderboard tabs"
echo "  - Bulletin tabs"
echo "  - Bulletin selector"
echo "  - Submit selector"
echo "  - Timer selector"
echo

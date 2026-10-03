#!/bin/bash
set -e

echo "Fixing layout, HTML artifacts, and 7 Frame styling..."

# ------------------------------------------------------------
# 1. Remove the broken standard-tab injection everywhere
# ------------------------------------------------------------

find . -type f -name "*.html" \
  -not -path "./.git/*" \
  -not -path "./node_modules/*" \
  -print0 |
while IFS= read -r -d '' file; do
  sed -i '/<script src="\/js\/standard-tab\.js"><\/script>/d' "$file"
done

rm -f js/standard-tab.js

# Remove literal "\n" text accidentally written into HTML.
find . -type f -name "*.html" \
  -not -path "./.git/*" \
  -not -path "./node_modules/*" \
  -print0 |
while IFS= read -r -d '' file; do
  perl -0pi -e 's/\\n/\n/g' "$file"
done

# ------------------------------------------------------------
# 2. Fix Updates inheriting the homepage two-column <main>
# ------------------------------------------------------------

cat >> css/components.css <<'CSS'

/* Updates is a standalone single-column page.
   Do not inherit the leaderboard main grid. */
main.updates-page {
  display: block;
  width: min(900px, calc(100% - 40px));
  max-width: 900px;
  margin: 0 auto;
  padding: 72px 0 100px;
}

main.updates-page .updates-list {
  width: 100%;
}

@media(max-width:700px) {
  main.updates-page {
    width: calc(100% - 32px);
    padding: 52px 0 72px;
  }
}

CSS

# ------------------------------------------------------------
# 3. Make 7 Frame a real site-wide standard
# ------------------------------------------------------------

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
      b.setAttribute('data-standard','7-frame');
    }

    b.appendChild(document.createTextNode(c+' frame'));

    if(count)b.appendChild(el('i',null,String(count(c))));

    b.onclick=()=>onPick(c);
    box.appendChild(b);
  });
}
JS

# ------------------------------------------------------------
# 4. Bulletin category controls
# ------------------------------------------------------------

python3 - <<'PY'
from pathlib import Path

path = Path("js/bulletin-page.js")
text = path.read_text()

old = """const b=el('button','tab',c?c+' frame':'All');b.type='button';b.dataset.c=String(c);b.setAttribute('aria-selected',String(c===f));"""

new = """const b=el('button','tab',c?c+' frame':'All');b.type='button';b.dataset.c=String(c);b.setAttribute('aria-selected',String(c===f));if(c===7)b.classList.add('standard-7-frame');"""

if old not in text:
    raise SystemExit("Could not find Bulletin filter tab code.")

text = text.replace(old, new, 1)

old = """const b=el('button');b.type='button';b.setAttribute('role','radio');b.dataset.c=String(c);"""

new = """const b=el('button');b.type='button';b.setAttribute('role','radio');b.dataset.c=String(c);if(c===7)b.classList.add('standard-7-frame');"""

if old not in text:
    raise SystemExit("Could not find Bulletin segmented control code.")

text = text.replace(old, new, 1)

path.write_text(text)
PY

# ------------------------------------------------------------
# 5. Submit category controls
# ------------------------------------------------------------

python3 - <<'PY'
from pathlib import Path

path = Path("js/submit-page.js")
text = path.read_text()

old = """CATS.forEach(c=>{const b=el('button','pillbtn',c+' frame');b.type='button';b.setAttribute('role','radio');b.setAttribute('aria-checked',String(c===cat));"""

new = """CATS.forEach(c=>{const b=el('button','pillbtn',c+' frame');b.type='button';b.setAttribute('role','radio');b.setAttribute('aria-checked',String(c===cat));if(c===7)b.classList.add('standard-7-frame');"""

if old not in text:
    raise SystemExit("Could not find Submit category code.")

text = text.replace(old, new, 1)

path.write_text(text)
PY

# ------------------------------------------------------------
# 6. Timer category controls
# ------------------------------------------------------------

python3 - <<'PY'
from pathlib import Path

path = Path("js/timer-page.js")
text = path.read_text()

old = """CATS.forEach(c=>{const b=el('button','pillbtn',c+' frame');b.type='button';b.setAttribute('role','radio');b.setAttribute('aria-checked',String(c===cat));"""

new = """CATS.forEach(c=>{const b=el('button','pillbtn',c+' frame');b.type='button';b.setAttribute('role','radio');b.setAttribute('aria-checked',String(c===cat));if(c===7)b.classList.add('standard-7-frame');"""

if old not in text:
    raise SystemExit("Could not find Timer category code.")

text = text.replace(old, new, 1)

path.write_text(text)
PY

# ------------------------------------------------------------
# 7. Replace the old broken 7 Frame CSS
# ------------------------------------------------------------

python3 - <<'PY'
from pathlib import Path

path = Path("css/components.css")
text = path.read_text()

start = text.find("/* 7 Frame original standard */")

if start != -1:
    text = text[:start].rstrip() + "\n"

text += r'''
/* 7 Frame original standard */

.standard-7-frame {
  position: relative;
  font-weight: 700 !important;
}

.tab.standard-7-frame:not([aria-selected="true"]),
.pillbtn.standard-7-frame:not([aria-checked="true"]) {
  background: color-mix(in srgb, var(--surface) 88%, var(--head));
  border-color: color-mix(in srgb, var(--accent) 42%, var(--line));
  color: var(--head);
}

.tab.standard-7-frame::before,
.pillbtn.standard-7-frame::before {
  content: "◆";
  display: inline-block;
  margin-right: 6px;
  font-size: .48em;
  vertical-align: middle;
  color: var(--accent);
}

.tab.standard-7-frame[aria-selected="true"]::before,
.pillbtn.standard-7-frame[aria-checked="true"]::before {
  color: currentColor;
}

.seg button.standard-7-frame {
  font-weight: 700;
}

.seg button.standard-7-frame::after {
  content: "◆";
  position: absolute;
  top: 5px;
  right: 7px;
  font-size: 5px;
  line-height: 1;
  color: var(--accent);
}

.seg button.standard-7-frame[aria-checked="true"]::after {
  color: currentColor;
}
'''

path.write_text(text.rstrip() + "\n")
PY

# ------------------------------------------------------------
# 8. Make the special treatment work inside Bulletin's
#    segmented control without changing its layout.
# ------------------------------------------------------------

cat >> css/bulletin.css <<'CSS'

.seg button.standard-7-frame {
  border-radius: 9px;
}

CSS

echo
echo "Done."
echo
echo "Fixed:"
echo "  - Updates page single-column layout"
echo "  - Removed literal \\n artifacts"
echo "  - Removed broken standard-tab.js injection"
echo "  - 7 Frame styling on leaderboard tabs"
echo "  - 7 Frame styling on Bulletin tabs"
echo "  - 7 Frame styling on Bulletin category selector"
echo "  - 7 Frame styling on Submit category selector"
echo "  - 7 Frame styling on Timer category selector"
echo
echo "Hard refresh with Ctrl+Shift+R before checking."

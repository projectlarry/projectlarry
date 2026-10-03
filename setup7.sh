#!/bin/bash
set -e

echo "==> Fixing theme flash..."

python3 - <<'PY'
from pathlib import Path

pages = [
    Path("index.html"),
    Path("submit/index.html"),
    Path("timer/index.html"),
    Path("bulletin/index.html"),
    Path("admin/index.html"),
]

theme_boot = """<script>
(function(){
  try {
    var saved = localStorage.getItem('tcl.theme');
    var theme = saved || 'dark';
    document.documentElement.dataset.theme = theme;
  } catch(e) {
    document.documentElement.dataset.theme = 'dark';
  }
})();
</script>
"""

for p in pages:
    if not p.exists():
        continue

    s = p.read_text()

    # Remove an existing copy so this stays clean/idempotent.
    start = s.find("<script>\n(function(){")
    if start != -1:
        end = s.find("</script>", start)
        if end != -1:
            block = s[start:end + len("</script>")]
            if "localStorage.getItem('tcl.theme')" in block:
                s = s[:start] + s[end + len("</script>"):]

    # Theme MUST be set before stylesheet loading.
    marker = "<head>"
    if marker in s and "localStorage.getItem('tcl.theme')" not in s[:s.find("</head>")]:
        s = s.replace(marker, marker + "\n" + theme_boot, 1)

    p.write_text(s)

# Make the JS theme initializer agree with the dark-first behavior.
p = Path("js/theme.js")

if p.exists():
    p.write_text("""export function initTheme(btn){
  const root=document.documentElement;
  let saved=null;

  try{
    saved=localStorage.getItem('tcl.theme');
  }catch{}

  // The inline theme boot script already applied this before CSS loaded.
  // Keep dark as the default if no preference exists.
  root.dataset.theme=saved||root.dataset.theme||'dark';

  if(btn){
    btn.onclick=()=>{
      const next=root.dataset.theme==='dark'?'light':'dark';
      root.dataset.theme=next;

      try{
        localStorage.setItem('tcl.theme',next);
      }catch{}
    };
  }
}
""")

PY

echo "==> Adding a dark-first fallback..."

cat >> css/tokens.css <<'EOF'

/* Prevent the first paint from appearing as the light theme. */
html:not([data-theme]) {
  background: #111;
  color-scheme: dark;
}
EOF

echo "==> Checking..."

grep -n "tcl.theme" index.html submit/index.html timer/index.html bulletin/index.html admin/index.html

echo "==> Done."
echo "Run the separate commit command when you're happy with it."

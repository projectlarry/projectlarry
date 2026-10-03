#!/bin/bash
set -e

echo "Updating 7 Frame category styling..."

cat > js/standard-tab.js <<'JS'
(function () {
  function markStandardTabs() {
    document.querySelectorAll(".tab").forEach(function (tab) {
      const text = (tab.textContent || "").trim().toLowerCase();

      if (/^7\s*frame\b/.test(text)) {
        tab.classList.add("standard-7-frame");
      }
    });
  }

  markStandardTabs();

  const observer = new MutationObserver(markStandardTabs);
  observer.observe(document.body, {
    childList: true,
    subtree: true
  });
})();
JS

cat >> css/components.css <<'CSS'

/* 7 Frame original standard */
.tab.standard-7-frame:not([aria-selected="true"]) {
  border-color: rgba(255, 255, 255, 0.18);
  background: rgba(255, 255, 255, 0.055);
  color: rgba(255, 255, 255, 0.82);
  font-weight: 650;
}

.tab.standard-7-frame:not([aria-selected="true"])::before {
  content: "◆";
  font-size: 7px;
  line-height: 1;
  margin-right: 5px;
  opacity: 0.7;
}

.tab.standard-7-frame:not([aria-selected="true"]):hover {
  border-color: rgba(255, 255, 255, 0.28);
  background: rgba(255, 255, 255, 0.085);
}

.tab.standard-7-frame[aria-selected="true"]::before {
  content: "◆";
  font-size: 7px;
  line-height: 1;
  margin-right: 5px;
  opacity: 0.7;
}
CSS

python3 - <<'PY'
from pathlib import Path

marker = '<script src="/js/standard-tab.js"></script>'

for path in Path(".").rglob("*.html"):
    if any(part in {".git", "node_modules"} for part in path.parts):
        continue

    text = path.read_text(encoding="utf-8")

    if marker in text:
        continue

    if "</body>" not in text:
        continue

    text = text.replace(
        "</body>",
        f"  {marker}\\n</body>",
        1
    )

    path.write_text(text, encoding="utf-8")
    print(f"Updated {path}")

PY

echo
echo "Done. 7 Frame is now visually marked as the original standard."

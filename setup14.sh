#!/bin/bash
set -e

echo "Fixing Updates page using the existing ProjectLarry layout..."

mkdir -p updates

cat > updates/index.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <script>
    (function(){
      try {
        var saved = localStorage.getItem('tcl.theme');
        document.documentElement.dataset.theme = saved || 'dark';
      } catch(e) {
        document.documentElement.dataset.theme = 'dark';
      }
    })();
  </script>

  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">

  <title>Updates | Projectlarry.lol</title>
  <meta name="description" content="What's new on Projectlarry.lol.">

  <link rel="icon" href="/assets/img/logo.png?v=3" type="image/png">

  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;600;700;800&display=swap">

  <link rel="stylesheet" href="/css/tokens.css">
  <link rel="stylesheet" href="/css/base.css">
  <link rel="stylesheet" href="/css/layout.css">
  <link rel="stylesheet" href="/css/components.css">
  <link rel="stylesheet" href="/css/motion.css">

  <style>
    .updates-page {
      width: min(900px, calc(100% - 40px));
      margin: 0 auto;
      padding: 72px 0 100px;
    }

    .updates-header {
      margin-bottom: 52px;
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
      font-size: clamp(2.4rem, 6vw, 4rem);
      line-height: 1;
      letter-spacing: -.045em;
    }

    .updates-header p:last-child {
      max-width: 560px;
      margin: 16px 0 0;
      color: var(--mute);
      font-size: 1rem;
      line-height: 1.6;
    }

    .updates-list {
      border-top: 1px solid var(--line);
    }

    .update-item {
      display: grid;
      grid-template-columns: 130px minmax(0, 1fr);
      gap: 34px;
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
      letter-spacing: -.015em;
    }

    .update-content p {
      max-width: 620px;
      margin: 0;
      color: var(--mute);
      font-size: .88rem;
      line-height: 1.65;
    }

    @media(max-width:700px) {
      .updates-page {
        width: min(100% - 32px, 900px);
        padding: 52px 0 72px;
      }

      .updates-header {
        margin-bottom: 38px;
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

  <script>
    window.va = window.va || function () {
      (window.vaq = window.vaq || []).push(arguments);
    };
  </script>
  <script defer src="/_vercel/insights/script.js"></script>
</head>

<body>

<header>
  <div class="bar bar3">

    <a class="logo" href="/">
      <img src="/assets/img/logo.png" alt="" width="36" height="30">
      Projectlarry.lol
    </a>

    <nav>
      <a href="/timer/">Timer</a>
      <a href="/bulletin/">Client Bulletin</a>
      <a href="/updates/" class="on" aria-current="page">Updates</a>
    </nav>

    <div class="bar-right">
      <a class="btn-sm" href="/submit/">Submit a run</a>
      <button
        class="icon-btn"
        id="theme"
        type="button"
        aria-label="Toggle dark mode"
        title="Toggle theme"
      >&#9680;</button>
    </div>

  </div>
</header>

<main class="updates-page">

  <header class="updates-header">
    <p class="updates-eyebrow">What's new</p>
    <h1>Updates</h1>
    <p>
      New features, improvements, and changes to Projectlarry.lol.
    </p>
  </header>

  <section class="updates-list" aria-label="Site updates">

    <article class="update-item">
      <div class="update-meta">
        <span class="update-date">Oct 2026</span>
        <span class="update-tag">New</span>
      </div>

      <div class="update-content">
        <h2>Client Bulletin</h2>
        <p>
          Clients can now post commission offers for designers to find.
          Offers are matched with relevant UI categories to make finding
          the right commission easier.
        </p>
      </div>
    </article>

    <article class="update-item">
      <div class="update-meta">
        <span class="update-date">Oct 2026</span>
        <span class="update-tag">New</span>
      </div>

      <div class="update-content">
        <h2>Commission Timer</h2>
        <p>
          Track how long a commission takes from start to finish with
          verified commission timers.
        </p>
      </div>
    </article>

    <article class="update-item">
      <div class="update-meta">
        <span class="update-date">Oct 2026</span>
        <span class="update-tag">New</span>
      </div>

      <div class="update-content">
        <h2>Upcoming Runs</h2>
        <p>
          See upcoming commission runs before they begin, making it easier
          to keep track of what's happening next.
        </p>
      </div>
    </article>

    <article class="update-item">
      <div class="update-meta">
        <span class="update-date">Sep 2026</span>
        <span class="update-tag">Improved</span>
      </div>

      <div class="update-content">
        <h2>Submission Flow</h2>
        <p>
          Submitting a commission run is now split into a cleaner,
          easier-to-follow process with improved form components.
        </p>
      </div>
    </article>

    <article class="update-item">
      <div class="update-meta">
        <span class="update-date">Sep 2026</span>
        <span class="update-tag">Improved</span>
      </div>

      <div class="update-content">
        <h2>UI Category Matching</h2>
        <p>
          Commission offers can now be matched with designers based on
          the UI category they're looking for.
        </p>
      </div>
    </article>

    <article class="update-item">
      <div class="update-meta">
        <span class="update-date">Sep 2026</span>
        <span class="update-tag">Improved</span>
      </div>

      <div class="update-content">
        <h2>Commission List</h2>
        <p>
          Improved searching and organization makes it easier to find
          designers and clients with relevant runs.
        </p>
      </div>
    </article>

    <article class="update-item">
      <div class="update-meta">
        <span class="update-date">Sep 2026</span>
        <span class="update-tag">New</span>
      </div>

      <div class="update-content">
        <h2>Verified Commission Times</h2>
        <p>
          Commission times are reviewed against submitted proof before
          runs are added to the list.
        </p>
      </div>
    </article>

  </section>

</main>

<script type="module">
  import { initTheme } from "/js/theme.js";

  initTheme(document.getElementById("theme"));
</script>

</body>
</html>
HTML

echo "Updates page replaced."

# Remove the old Updates-specific CSS we previously injected.
python3 - <<'PY'
from pathlib import Path

path = Path("css/components.css")
text = path.read_text(encoding="utf-8")

markers = [
    "/* Updates page */",
    "/* =========================================\n   Updates\n   ========================================= */"
]

for marker in markers:
    while marker in text:
        start = text.index(marker)

        # Find the next media block after the marker, then consume that
        # block if it belongs to the old Updates styles.
        rest = text[start:]
        next_media = rest.find("@media")

        if next_media == -1:
            text = text[:start].rstrip() + "\n"
            break

        media_start = start + next_media
        brace_start = text.find("{", media_start)

        if brace_start == -1:
            text = text[:start].rstrip() + "\n"
            break

        depth = 0
        end = None

        for i in range(brace_start, len(text)):
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
                if depth == 0:
                    end = i + 1
                    break

        if end is None:
            text = text[:start].rstrip() + "\n"
            break

        text = text[:start] + text[end:]

path.write_text(text.rstrip() + "\n", encoding="utf-8")
print("Removed old Updates CSS from components.css.")
PY

echo
echo "Done."
echo "Open /updates/ and hard refresh with Ctrl+Shift+R."

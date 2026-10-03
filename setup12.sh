#!/usr/bin/env bash
set -e

cd /workspaces/projectlarry

echo "==> Rebuilding Updates page..."

cat > updates/index.html <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <title>Updates | ProjectLarry.lol</title>
  <meta name="description" content="What's new on ProjectLarry.lol.">

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

  <link rel="stylesheet" href="../css/tokens.css">
  <link rel="stylesheet" href="../css/base.css">
  <link rel="stylesheet" href="../css/layout.css">
  <link rel="stylesheet" href="../css/components.css">

  <script>
    window.va = window.va || function () {
      (window.vaq = window.vaq || []).push(arguments);
    };
  </script>
  <script defer src="/_vercel/insights/script.js"></script>
</head>

<body>
  <header class="site-header">
    <div class="site-header-inner">

      <a class="brand" href="/">
        <span class="brand-mark">🐣</span>
        <span>Projectlarry.lol</span>
      </a>

      <nav class="site-nav" aria-label="Main navigation">
        <a href="/timer/">Timer</a>
        <a href="/bulletin/">Client Bulletin</a>
        <a href="/updates/" aria-current="page">Updates</a>
      </nav>

      <div class="site-actions">
        <a class="button button-primary" href="/submit/">Submit a run</a>
        <button class="theme-toggle" type="button" aria-label="Toggle theme">◐</button>
      </div>

    </div>
  </header>

  <main class="updates-page">
    <div class="updates-header">
      <p class="section-eyebrow">What's new</p>
      <h1>Updates</h1>
      <p>New features, improvements, and changes to ProjectLarry.lol.</p>
    </div>

    <div class="updates-list">

      <article class="update-item">
        <div class="update-meta">
          <span class="update-date">OCT 2026</span>
          <span class="update-tag update-tag-new">NEW</span>
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
          <span class="update-date">OCT 2026</span>
          <span class="update-tag update-tag-new">NEW</span>
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
          <span class="update-date">OCT 2026</span>
          <span class="update-tag update-tag-new">NEW</span>
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
          <span class="update-date">SEP 2026</span>
          <span class="update-tag update-tag-improved">IMPROVED</span>
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
          <span class="update-date">SEP 2026</span>
          <span class="update-tag update-tag-improved">IMPROVED</span>
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
          <span class="update-date">SEP 2026</span>
          <span class="update-tag update-tag-improved">IMPROVED</span>
        </div>

        <div class="update-content">
          <h2>Commission List</h2>
          <p>
            Added improved searching and organization so designers and
            clients can find relevant runs more easily.
          </p>
        </div>
      </article>

      <article class="update-item">
        <div class="update-meta">
          <span class="update-date">SEP 2026</span>
          <span class="update-tag update-tag-new">NEW</span>
        </div>

        <div class="update-content">
          <h2>Verified Commission Times</h2>
          <p>
            Commission runs can now have verified completion times, allowing
            the list to compare completed runs consistently.
          </p>
        </div>
      </article>

    </div>
  </main>

  <script type="module">
    import { initTheme } from "../js/theme.js";

    const themeButton = document.querySelector(".theme-toggle");
    initTheme(themeButton);
  </script>
</body>
</html>
HTML

echo "==> Adding clean Updates styling..."

cat >> css/components.css <<'CSS'

/* =========================================
   Updates
   ========================================= */

.updates-page {
  width: min(900px, calc(100% - 48px));
  margin: 0 auto;
  padding: 90px 0 120px;
}

.updates-header {
  margin-bottom: 56px;
}

.updates-header .section-eyebrow {
  margin: 0 0 8px;
}

.updates-header h1 {
  margin: 0;
  font-size: clamp(38px, 6vw, 56px);
  line-height: 1;
  letter-spacing: -.04em;
}

.updates-header > p:last-child {
  max-width: 560px;
  margin: 16px 0 0;
  font-size: 16px;
  line-height: 1.6;
  opacity: .58;
}

.updates-list {
  border-top: 1px solid var(--border, rgba(255,255,255,.12));
}

.update-item {
  display: grid;
  grid-template-columns: 150px minmax(0, 1fr);
  gap: 36px;
  padding: 30px 0;
  border-bottom: 1px solid var(--border, rgba(255,255,255,.12));
}

.update-meta {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 9px;
}

.update-date {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: .08em;
  opacity: .45;
}

.update-tag {
  display: inline-flex;
  align-items: center;
  min-height: 22px;
  padding: 0 8px;
  border: 1px solid currentColor;
  border-radius: 999px;
  font-size: 9px;
  font-weight: 800;
  letter-spacing: .07em;
  opacity: .65;
}

.update-tag-new {
  color: #fff;
}

.update-tag-improved {
  opacity: .45;
}

.update-content h2 {
  margin: 0 0 8px;
  font-size: 18px;
  line-height: 1.3;
  letter-spacing: -.015em;
}

.update-content p {
  max-width: 650px;
  margin: 0;
  font-size: 14px;
  line-height: 1.65;
  opacity: .58;
}

@media (max-width: 700px) {
  .updates-page {
    width: min(100% - 32px, 900px);
    padding: 56px 0 80px;
  }

  .updates-header {
    margin-bottom: 40px;
  }

  .update-item {
    grid-template-columns: 1fr;
    gap: 14px;
    padding: 24px 0;
  }

  .update-meta {
    flex-direction: row;
    align-items: center;
  }
}
CSS

echo
echo "==> Verifying Updates page..."

grep -n "<title>" updates/index.html
grep -n "Client Bulletin" updates/index.html
grep -n "Vercel Analytics" updates/index.html || true
grep -n "Commission List" updates/index.html

echo
echo "Done."

# The Commission List

Static site: no build step, no backend.

## Structure
- `index.html`: page markup
- `css/`: tokens (colors/theme), base, layout, gallery, components
- `js/`: `main` (wiring), `store` (data), `render`, `admin`, `gallery`, `utils`
- `data/runs.json`: the leaderboard. `data/gallery.json`: header gallery image list
- `assets/img/runs/`, `assets/img/gallery/`: images

## Run locally
ES modules need a server (not file://):
    python3 -m http.server 8000   # then open http://localhost:8000

## Host
Upload the folder to Netlify, Cloudflare Pages, GitHub Pages, or any web host.

## Updating the list
1. Click **Admin**, add/edit runs (saved in your browser only).
2. **Export runs.json** and overwrite `data/runs.json`.
3. Uploaded pics export as embedded data; for a lighter site, save them into `assets/img/runs/` and set the `img` path.
Note: the Admin button is client-side only and is not real security. For shared editing you'd need a backend.

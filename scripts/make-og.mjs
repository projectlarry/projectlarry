// Draws the social preview card from the live leaderboard and saves it as a PNG.
// Run by .github/workflows/og-preview.yml, or by hand: node scripts/make-og.mjs
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';
import satori from 'satori';
import resvg from '@resvg/resvg-js';

const { Resvg } = resvg;
const require = createRequire(import.meta.url);

const RUNS_URL = process.env.RUNS_URL || 'https://projectlarry.lol/api/runs';
const OUT = process.env.OUT || 'assets/img/og-preview.png';
const CATS = [3, 5, 7, 12, 15];
const CAT = CATS.includes(Number(process.env.CAT)) ? Number(process.env.CAT) : 7;

const fmt = ms => {
  const t = Math.floor(ms / 1000), h = Math.floor(t / 3600), m = Math.floor((t % 3600) / 60), s = t % 60;
  return (h ? h + 'h ' : '') + (h || m ? m + 'm ' : '') + s + 's';
};
const h = (style, ...kids) => ({ type: 'div', props: { style: { display: 'flex', ...style }, children: kids.length === 1 ? kids[0] : kids } });

async function loadRuns() {
  const r = await fetch(RUNS_URL);
  if (!r.ok) throw new Error('Could not load runs: HTTP ' + r.status);
  const j = await r.json();
  if (Array.isArray(j.runs)) return j.runs;
  // Nothing in storage yet: the site falls back to data/runs.json, so do the same.
  return JSON.parse(fs.readFileSync('data/runs.json', 'utf8')).runs || [];
}

function loadFonts() {
  const dir = path.join(path.dirname(require.resolve('@fontsource/montserrat/package.json')), 'files');
  const read = w => fs.readFileSync(path.join(dir, `montserrat-latin-${w}-normal.woff`));
  return [
    { name: 'Montserrat', data: read(500), weight: 500, style: 'normal' },
    { name: 'Montserrat', data: read(700), weight: 700, style: 'normal' },
  ];
}

const runs = await loadRuns();
const list = runs
  .filter(r => (CATS.includes(Number(r.cat)) ? Number(r.cat) : 7) === CAT)
  .sort((a, b) => a.ms - b.ms);
const top = list.slice(0, 3);

const rows = top.length ? top.map((r, i) =>
  h({ alignItems: 'center', height: 76, padding: '0 26px', background: '#1c1e21', border: '1px solid #2f3337', borderRadius: 16 },
    h({ width: 48, height: 48, borderRadius: 999, alignItems: 'center', justifyContent: 'center', fontSize: 24, fontWeight: 700, background: i === 0 ? '#f2f3f4' : '#26292d', color: i === 0 ? '#111111' : '#e8e9eb' }, String(i + 1)),
    h({ flexDirection: 'column', marginLeft: 22, flex: 1 },
      h({ fontSize: 30, fontWeight: 700, color: '#f2f3f4' }, String(r.name || '').slice(0, 26)),
      h({ fontSize: 19, fontWeight: 500, color: '#9aa0a8' }, 'commissioned by ' + String(r.client || 'Unknown').slice(0, 26))),
    h({ fontSize: 34, fontWeight: 700, color: '#f2f3f4' }, fmt(r.ms)))
) : [h({ height: 76, alignItems: 'center', padding: '0 26px', background: '#1c1e21', border: '1px solid #2f3337', borderRadius: 16, fontSize: 26, fontWeight: 500, color: '#9aa0a8' }, 'No runs yet. Be the first on the list.')];

const tree = h({ flexDirection: 'column', width: '100%', height: '100%', background: '#141517', color: '#e8e9eb', padding: 48, fontFamily: 'Montserrat' },
  h({ alignItems: 'center', justifyContent: 'space-between' },
    h({ fontSize: 26, fontWeight: 700, color: '#f2f3f4' }, 'Projectlarry.lol'),
    h({ fontSize: 20, fontWeight: 500, color: '#9aa0a8', border: '1px solid #2f3337', borderRadius: 999, padding: '8px 18px' }, CAT === 7 ? 'The 7-Frame Standard' : CAT + ' Frame')),
  h({ marginTop: 28, fontSize: 64, fontWeight: 700, letterSpacing: -2, color: '#f2f3f4' }, 'The Commission List'),
  h({ marginTop: 10, fontSize: 24, fontWeight: 500, color: '#9aa0a8' }, `Fastest verified ${CAT} frame times \u00b7 ${list.length} ${list.length === 1 ? 'run' : 'runs'}`),
  h({ marginTop: 28, flexDirection: 'column', gap: 12 }, ...rows),
  h({ marginTop: 'auto', fontSize: 20, fontWeight: 500, color: '#9aa0a8' }, 'projectlarry.lol'));

const svg = await satori(tree, { width: 1200, height: 630, fonts: loadFonts() });
const png = new Resvg(svg, { font: { loadSystemFonts: false } }).render().asPng();

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, png);
console.log(`Wrote ${OUT} (${png.length} bytes) with ${top.length} of ${list.length} ${CAT}-frame runs`);

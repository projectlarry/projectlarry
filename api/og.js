import { ImageResponse } from '@vercel/og';
export const config = { runtime: 'edge' };

const CATS = [3, 5, 7, 12, 15];
const fmt = ms => {
  const t = Math.floor(ms / 1000), h = Math.floor(t / 3600), m = Math.floor((t % 3600) / 60), s = t % 60;
  return (h ? h + 'h ' : '') + (h || m ? m + 'm ' : '') + s + 's';
};
const h = (style, ...kids) => ({ type: 'div', props: { style: { display: 'flex', ...style }, children: kids.length === 1 ? kids[0] : kids } });

let fonts;
async function loadFonts() {
  if (fonts) return fonts;
  try {
    const get = async w => {
      const r = await fetch(`https://cdn.jsdelivr.net/fontsource/fonts/montserrat@latest/latin-${w}-normal.woff`);
      if (!r.ok) throw new Error('font');
      return r.arrayBuffer();
    };
    const [a, b] = await Promise.all([get(500), get(700)]);
    fonts = [{ name: 'Montserrat', data: a, weight: 500, style: 'normal' }, { name: 'Montserrat', data: b, weight: 700, style: 'normal' }];
  } catch { fonts = []; }
  return fonts;
}

export default async function handler(req) {
  const url = new URL(req.url);
  let cat = Number(url.searchParams.get('cat'));
  if (!CATS.includes(cat)) cat = 7;

  let runs = [];
  try {
    const r = await fetch(new URL('/api/runs', url.origin));
    const j = await r.json();
    if (Array.isArray(j.runs)) runs = j.runs;
  } catch {}
  const list = runs
    .filter(r => (CATS.includes(Number(r.cat)) ? Number(r.cat) : 7) === cat)
    .sort((a, b) => a.ms - b.ms);
  const top = list.slice(0, 3);
  const f = await loadFonts();

  const rows = top.length ? top.map((r, i) =>
    h({ alignItems: 'center', height: 76, padding: '0 26px', background: '#1c1e21', border: '1px solid #2f3337', borderRadius: 16 },
      h({ width: 48, height: 48, borderRadius: 999, alignItems: 'center', justifyContent: 'center', fontSize: 24, fontWeight: 700, background: i === 0 ? '#f2f3f4' : '#26292d', color: i === 0 ? '#111111' : '#e8e9eb' }, String(i + 1)),
      h({ flexDirection: 'column', marginLeft: 22, flex: 1 },
        h({ fontSize: 30, fontWeight: 700, color: '#f2f3f4' }, String(r.name || '').slice(0, 26)),
        h({ fontSize: 19, color: '#9aa0a8' }, 'commissioned by ' + String(r.client || 'Unknown').slice(0, 26))),
      h({ fontSize: 34, fontWeight: 700, color: '#f2f3f4' }, fmt(r.ms)))
  ) : [h({ height: 76, alignItems: 'center', padding: '0 26px', background: '#1c1e21', border: '1px solid #2f3337', borderRadius: 16, fontSize: 26, color: '#9aa0a8' }, 'No runs yet. Be the first on the list.')];

  const tree = h({ flexDirection: 'column', width: '100%', height: '100%', background: '#141517', color: '#e8e9eb', padding: 48, fontFamily: f.length ? 'Montserrat' : undefined },
    h({ alignItems: 'center', justifyContent: 'space-between' },
      h({ fontSize: 26, fontWeight: 700, color: '#f2f3f4' }, 'Projectlarry.lol'),
      h({ fontSize: 20, fontWeight: 500, color: '#9aa0a8', border: '1px solid #2f3337', borderRadius: 999, padding: '8px 18px' }, cat === 7 ? 'The 7-Frame Standard' : cat + ' Frame')),
    h({ marginTop: 28, fontSize: 64, fontWeight: 700, letterSpacing: -2, color: '#f2f3f4' }, 'The Commission List'),
    h({ marginTop: 10, fontSize: 24, fontWeight: 500, color: '#9aa0a8' }, `Fastest verified ${cat} frame times · ${list.length} ${list.length === 1 ? 'run' : 'runs'}`),
    h({ marginTop: 28, flexDirection: 'column', gap: 12 }, ...rows),
    h({ marginTop: 'auto', fontSize: 20, fontWeight: 500, color: '#9aa0a8' }, 'projectlarry.lol'));

  return new ImageResponse(tree, {
    width: 1200,
    height: 630,
    fonts: f.length ? f : undefined,
    headers: { 'Cache-Control': 'public, s-maxage=300, stale-while-revalidate=600' },
  });
}

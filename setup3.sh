#!/bin/bash
set -e
[ -f index.html ] && [ -f js/cats.js ] && [ -d api ] || { echo "Run this in the folder that has index.html, js/cats.js and api/ (did the last update finish?)"; exit 1; }
mkdir -p timer bulletin

# ================= SERVER =================
cat > api/_lib.js <<'EOF'
const crypto=require('crypto');
const BASE=()=>process.env.KV_REST_API_URL||process.env.UPSTASH_REDIS_REST_URL;
const TOKEN=()=>process.env.KV_REST_API_TOKEN||process.env.UPSTASH_REDIS_REST_TOKEN;
async function redis(...cmd){
  const u=BASE(),t=TOKEN();
  if(!u||!t)throw new Error('Storage is not connected in Vercel yet');
  const r=await fetch(u,{method:'POST',headers:{Authorization:'Bearer '+t,'Content-Type':'application/json'},body:JSON.stringify(cmd)});
  const j=await r.json();
  if(!r.ok||j.error)throw new Error(j.error||('Storage error '+r.status));
  return j.result;
}
const ip=req=>String(req.headers['x-forwarded-for']||'').split(',')[0].trim()||'unknown';
async function limit(key,max,secs){
  const k='rl:'+key,n=await redis('INCR',k);
  if(n===1)await redis('EXPIRE',k,secs);
  return n<=max;
}
const sha=s=>crypto.createHash('sha256').update(String(s)).digest();
const same=(a,b)=>crypto.timingSafeEqual(sha(a),sha(b));
const ipk=req=>crypto.createHash('sha256').update('tcl|'+ip(req)).digest('hex').slice(0,20);
const rid=n=>{const a='abcdefghjkmnpqrstuvwxyz23456789',b=crypto.randomBytes(n);let s='';for(let i=0;i<n;i++)s+=a[b[i]%a.length];return s};
const hvals=a=>Array.isArray(a)?a.filter((_,i)=>i%2):Object.values(a||{});
const jparse=s=>{try{return JSON.parse(s)}catch{return null}};
async function admin(req,res){
  try{
    const pw=process.env.ADMIN_PASSWORD;
    if(!pw){res.status(500).json({error:'ADMIN_PASSWORD is not set in Vercel'});return false}
    const key='rl:fail:'+ip(req);
    if((Number(await redis('GET',key))||0)>=10){res.status(429).json({error:'Too many wrong attempts. Try again in 15 minutes.'});return false}
    if(!same(req.headers['x-admin-password']||'',pw)){
      const n=await redis('INCR',key);if(n===1)await redis('EXPIRE',key,900);
      res.status(401).json({error:'Wrong password'});return false}
    return true;
  }catch(e){res.status(500).json({error:e.message});return false}
}
module.exports={redis,ip,limit,admin,same,ipk,rid,hvals,jparse};
EOF

cat > api/submit.js <<'EOF'
const{redis,ip,limit,same,jparse}=require('./_lib');
const IMG=/^data:image\/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$/;
const CATS=[3,5,7,12,15];
const bad=(res,m)=>res.status(400).json({error:m});
module.exports=async(req,res)=>{
  if(req.method!=='POST')return res.status(405).json({error:'POST only'});
  try{
    const b=req.body||{};
    if(b.website)return res.status(200).json({ok:true});
    const name=String(b.name||'').trim().slice(0,40),client=String(b.client||'').trim().slice(0,60);
    let ms=Math.round(Number(b.ms)),cat=Number(b.cat),timer=null,video=String(b.video||'').trim();
    if(b.timerId){
      timer=jparse(await redis('HGET','timers',String(b.timerId)));
      const code=String(b.timerCode||'').toLowerCase().replace(/[^a-z0-9]/g,'');
      if(!timer||!same(timer.code,code))return bad(res,'Your timer was not found. It may have expired. Use a manual time instead.');
      if(!timer.stop)return bad(res,'Stop your timer before submitting.');
      ms=timer.stop-timer.start;cat=timer.cat;
    }
    if(!name)return bad(res,'Name is required');
    if(!CATS.includes(cat))return bad(res,'Pick a category');
    if(!(ms>=1000&&ms<3.6e9*1000))return bad(res,'Invalid time');
    if(video){try{const u=new URL(video);if(!/^https?:$/.test(u.protocol))throw 0;video=u.href.slice(0,300)}catch{return bad(res,'Recording link must start with http(s)://')}}
    const proofs=Array.isArray(b.proofs)?b.proofs.slice(0,3):[];
    const img=b.img?String(b.img):'',thumb=b.thumb?String(b.thumb):'';
    if(!proofs.length)return bad(res,'Add at least one proof image');
    if(!proofs.every(p=>typeof p==='string'&&IMG.test(p)))return bad(res,'Invalid image');
    if(img&&(!IMG.test(img)||img.length>120000))return bad(res,'Invalid card picture');
    if(thumb&&(!IMG.test(thumb)||thumb.length>40000))return bad(res,'Invalid thumbnail');
    if(proofs.join('').length+img.length+thumb.length>850000)return bad(res,'Images are too large. Use fewer or smaller ones.');
    if(!(await limit('sub:'+ip(req),5,3600)))return res.status(429).json({error:'Too many submissions. Try again in an hour.'});
    if((await redis('HLEN','subs'))>=100)return res.status(503).json({error:'Submissions are full right now. Try again later.'});
    const id=Date.now().toString(36)+Math.random().toString(36).slice(2,6);
    await redis('HSET','subs',id,JSON.stringify({id,name,ms,cat,client,video,img,thumb,proofs,verified:!!timer,timer:timer?{start:timer.start,stop:timer.stop}:null,at:Date.now()}));
    if(timer){await redis('HDEL','timers',timer.id);await redis('HDEL','tcodes',timer.code)}
    res.status(200).json({ok:true});
  }catch(e){res.status(500).json({error:e.message})}
};
EOF

cat > api/timer.js <<'EOF'
const{redis,ip,limit,same,ipk,rid,jparse}=require('./_lib');
const CATS=[3,5,7,12,15],DAY=864e5,LIM=2,WIN=3*DAY,REFUND=120000;
const bad=(res,m,c)=>res.status(c||400).json({error:m});
const norm=c=>String(c||'').toLowerCase().replace(/[^a-z0-9]/g,'');
async function getLim(k){const o=jparse(await redis('HGET','tlim',k)),now=Date.now();return o&&o.exp>now?o:{n:0,exp:now+WIN}}
const setLim=(k,o)=>redis('HSET','tlim',k,JSON.stringify(o));
module.exports=async(req,res)=>{
  res.setHeader('Cache-Control','no-store');
  if(req.method!=='POST')return bad(res,'POST only',405);
  try{
    const b=req.body||{},now=Date.now();
    if(b.action==='start'){
      const name=String(b.name||'').trim().slice(0,40),client=String(b.client||'').trim().slice(0,60),cat=Number(b.cat);
      if(!name)return bad(res,'Enter your name');
      if(!CATS.includes(cat))return bad(res,'Pick a category');
      if((await redis('HLEN','timers'))>=300)return bad(res,'Too many timers are running right now. Try again later.',503);
      const k=ipk(req),l=await getLim(k);
      if(l.n>=LIM){const h=Math.ceil((l.exp-now)/36e5);return bad(res,'You have used both timer starts for this period. You can start again in about '+(h>=48?Math.ceil(h/24)+' days':h+' hours')+'.',429)}
      l.n++;await setLim(k,l);
      const id=rid(8),code=rid(12);
      await redis('HSET','timers',id,JSON.stringify({id,code,name,cat,client,start:now,stop:0,ipk:k}));
      await redis('HSET','tcodes',code,id);
      return res.status(200).json({id,code,name,cat,client,start:now,stop:0,now});
    }
    if(b.action==='resume'){
      if(!(await limit('tresume:'+ip(req),30,3600)))return bad(res,'Too many tries. Try again later.',429);
      const code=norm(b.code),id=await redis('HGET','tcodes',code),t=id&&jparse(await redis('HGET','timers',id));
      if(!t)return bad(res,'Timer not found. It may have expired.',404);
      return res.status(200).json({id:t.id,code:t.code,name:t.name,cat:t.cat,client:t.client,start:t.start,stop:t.stop,now});
    }
    const t=jparse(await redis('HGET','timers',String(b.id||'')));
    if(!t||!same(t.code,norm(b.code)))return bad(res,'Timer not found. It may have expired.',404);
    if(b.action==='stop'){
      if(!t.stop){t.stop=now;await redis('HSET','timers',t.id,JSON.stringify(t))}
      return res.status(200).json({stop:t.stop,ms:t.stop-t.start,now});
    }
    if(b.action==='cancel'){
      let refunded=false;
      if(!t.stop&&now-t.start<REFUND){const l=await getLim(t.ipk);if(l.n>0){l.n--;await setLim(t.ipk,l);refunded=true}}
      await redis('HDEL','timers',t.id);await redis('HDEL','tcodes',t.code);
      return res.status(200).json({ok:true,refunded});
    }
    return bad(res,'Unknown action');
  }catch(e){res.status(500).json({error:e.message})}
};
EOF

cat > api/timers.js <<'EOF'
const{redis,hvals,jparse}=require('./_lib');
const TTL=14*864e5;
module.exports=async(req,res)=>{
  res.setHeader('Cache-Control','no-store');
  try{
    const now=Date.now(),out=[];
    for(const t of hvals(await redis('HGETALL','timers')).map(jparse).filter(Boolean)){
      if((t.stop||t.start)+TTL<now){await redis('HDEL','timers',t.id);await redis('HDEL','tcodes',t.code);continue}
      if(!t.stop)out.push({id:t.id,name:t.name,cat:t.cat,start:t.start});
    }
    out.sort((a,b)=>a.start-b.start);
    res.status(200).json({now,timers:out});
  }catch(e){res.status(500).json({error:e.message})}
};
EOF

cat > api/offers.js <<'EOF'
const{redis,ip,limit,rid,hvals,jparse}=require('./_lib');
const IMG=/^data:image\/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$/;
const CATS=[3,5,7,12,15];
const bad=(res,m)=>res.status(400).json({error:m});
module.exports=async(req,res)=>{
  try{
    if(req.method==='GET'){
      const list=hvals(await redis('HGETALL','offers')).map(jparse).filter(Boolean);
      list.sort((x,y)=>((x.status==='taken')-(y.status==='taken'))||y.at-x.at);
      res.setHeader('Cache-Control','public, s-maxage=10, stale-while-revalidate=30');
      return res.status(200).json({offers:list});
    }
    if(req.method!=='POST')return res.status(405).json({error:'GET or POST only'});
    const b=req.body||{};
    if(b.website)return res.status(200).json({ok:true});
    const cat=Number(b.cat),desc=String(b.desc||'').trim(),discord=String(b.discord||'').trim().replace(/^@/,'').toLowerCase(),avatar=String(b.avatar||'');
    if(!CATS.includes(cat))return bad(res,'Pick a frame category');
    if(desc.length<20||desc.length>600)return bad(res,'The description must be 20 to 600 characters');
    if(!/^[a-z0-9_.]{2,32}$/.test(discord))return bad(res,'Enter your Discord username, like name or name_01');
    if(!IMG.test(avatar)||avatar.length>30000)return bad(res,'Add a profile picture');
    if(b.consent!==true)return bad(res,'Please tick the agreement box');
    if(!(await limit('offer:'+ip(req),3,3600)))return res.status(429).json({error:'Too many offers. Try again in an hour.'});
    if((await redis('HLEN','offers_pending'))>=50)return res.status(503).json({error:'Offers are full right now. Try again later.'});
    const id=rid(8);
    await redis('HSET','offers_pending',id,JSON.stringify({id,cat,desc,discord,avatar,status:'open',at:Date.now()}));
    res.status(200).json({ok:true});
  }catch(e){res.status(500).json({error:e.message})}
};
EOF

cat > api/admin/offers.js <<'EOF'
const{redis,admin,hvals,jparse}=require('../_lib');
module.exports=async(req,res)=>{
  if(!(await admin(req,res)))return;
  try{
    if(req.method==='POST'){
      const b=req.body||{},id=String(b.id||'');
      if(b.action==='approve'){
        const o=jparse(await redis('HGET','offers_pending',id));if(!o)return res.status(404).json({error:'Offer not found'});
        await redis('HSET','offers',id,JSON.stringify(o));await redis('HDEL','offers_pending',id);
      }else if(b.action==='reject')await redis('HDEL','offers_pending',id);
      else if(b.action==='status'){
        const o=jparse(await redis('HGET','offers',id));if(!o)return res.status(404).json({error:'Offer not found'});
        o.status=b.status==='taken'?'taken':'open';await redis('HSET','offers',id,JSON.stringify(o));
      }else if(b.action==='delete')await redis('HDEL','offers',id);
      else return res.status(400).json({error:'Unknown action'});
      return res.status(200).json({ok:true});
    }
    const get=async k=>hvals(await redis('HGETALL',k)).map(jparse).filter(Boolean).sort((a,b)=>b.at-a.at);
    res.status(200).json({pending:await get('offers_pending'),approved:await get('offers')});
  }catch(e){res.status(500).json({error:e.message})}
};
EOF

cat > api/admin/timers.js <<'EOF'
const{redis,admin,hvals,jparse}=require('../_lib');
module.exports=async(req,res)=>{
  if(!(await admin(req,res)))return;
  try{
    if(req.method==='POST'){
      const b=req.body||{};
      if(b.action==='resetAll'){await redis('DEL','tlim');return res.status(200).json({ok:true})}
      const t=jparse(await redis('HGET','timers',String(b.id||'')));
      if(!t)return res.status(404).json({error:'Timer not found'});
      if(b.action==='resetLimit'){await redis('HDEL','tlim',t.ipk);return res.status(200).json({ok:true})}
      if(b.action==='remove'){await redis('HDEL','timers',t.id);await redis('HDEL','tcodes',t.code);return res.status(200).json({ok:true})}
      return res.status(400).json({error:'Unknown action'});
    }
    const list=hvals(await redis('HGETALL','timers')).map(jparse).filter(Boolean)
      .map(t=>({id:t.id,name:t.name,cat:t.cat,client:t.client,start:t.start,stop:t.stop})).sort((a,b)=>b.start-a.start);
    res.status(200).json({now:Date.now(),timers:list});
  }catch(e){res.status(500).json({error:e.message})}
};
EOF

python3 - <<'PY'
def rep(path,old,new):
    t=open(path,encoding='utf-8').read()
    if new in t: return
    assert old in t, f"Could not patch {path}. Is it the version from the last update?"
    open(path,'w',encoding='utf-8').write(t.replace(old,new,1))
rep('api/admin/submissions.js',"cat:s.cat||7,thumb:s.thumb||'',at:s.at,","cat:s.cat||7,thumb:s.thumb||'',verified:!!s.verified,at:s.at,")
rep('api/admin/runs.js',"img:String(r.img||'').slice(0,200000)}","img:String(r.img||'').slice(0,200000),verified:!!r.verified}")
rep('js/render.js',"meta.appendChild(el('strong',null,fmt(r.ms)));","meta.appendChild(el('strong',null,fmt(r.ms)));\n    if(r.verified)meta.appendChild(el('span','vbadge','Timer verified'));")
rep('js/submit-page.js',"website:$('website').value})","website:$('website').value,timerId:window.__timer&&window.__timer.id,timerCode:window.__timer&&window.__timer.code})")
rep('js/submit-page.js',"$('f').hidden=true;$('prog').hidden=true;","try{localStorage.removeItem('tcl.timer')}catch{}$('f').hidden=true;$('prog').hidden=true;")
print('Patched')
PY

# ================= SHARED FRONT-END =================
cat > css/dialog.css <<'EOF'
[hidden]{display:none!important}
dialog{border:1px solid var(--line);border-radius:14px;background:var(--surface);color:var(--text);padding:22px;width:min(460px,92vw)}
dialog::backdrop{background:rgba(0,0,0,.55)}
dialog h3{margin:0 0 10px;color:var(--head)}.dmsg{color:var(--mute);font-size:.92rem;margin:0 0 18px;line-height:1.5}
.dform{display:grid;gap:8px}.dform label{font-size:.78rem;font-weight:700;color:var(--mute);margin-top:4px}
.dform input:not([type=checkbox]),.dform select,.dform textarea{width:100%;padding:11px 12px}
.dform textarea{border-radius:6px;border:1px solid var(--line);background:var(--surface);color:var(--text);font:inherit;resize:vertical}
.hint{font-size:.78rem;color:var(--mute);min-height:1em}
EOF

python3 - <<'PY'
c=open('css/components.css',encoding='utf-8').read()
if '.upcoming{' not in c:
    open('css/components.css','a',encoding='utf-8').write("""
.upcoming{max-width:1100px;margin:0 auto 22px;padding:0 20px}.upcoming[hidden]{display:none}
.up-head{display:flex;align-items:center;gap:10px;font-size:.78rem;letter-spacing:1px;text-transform:uppercase;color:var(--mute);margin-bottom:10px;font-weight:700}
.live-dot{width:8px;height:8px;border-radius:50%;background:#2ecc71;animation:pulse 2s infinite}
@keyframes pulse{0%{box-shadow:0 0 0 0 rgba(46,204,113,.6)}70%{box-shadow:0 0 0 8px rgba(46,204,113,0)}100%{box-shadow:0 0 0 0 rgba(46,204,113,0)}}
.up-list{display:flex;gap:12px;overflow-x:auto;padding-bottom:4px}
.up-card{flex:none;min-width:210px;background:var(--surface);border:1px solid var(--line);border-radius:12px;padding:12px 14px}
.up-card b{display:block;color:var(--head)}.up-card .up-cat{font-size:.78rem;color:var(--mute)}
.up-card .up-time{display:block;font-variant-numeric:tabular-nums;font-size:1.1rem;color:var(--head);margin-top:6px;font-weight:700}
.badge{display:inline-block;background:var(--soft);color:var(--head);border-radius:999px;padding:3px 10px;font-size:.72rem;font-weight:700}
.vbadge{background:#d9f5e5;color:#17653a;border-radius:999px;padding:2px 9px;font-size:.72rem;font-weight:700}
.btn.red{background:var(--danger);color:#fff}.btn.sm{padding:9px 16px;font-size:.82rem}
.ava{width:56px;height:56px;border-radius:50%;object-fit:cover;background:var(--soft);flex:none;display:block}
""")
l=open('css/layout.css',encoding='utf-8').read()
if '/*hdr2*/' not in l:
    open('css/layout.css','a',encoding='utf-8').write("""
/*hdr2*/
nav a.on{color:var(--head)}
@media(max-width:860px){.bar3{grid-template-columns:auto 1fr;height:auto;min-height:64px;padding-top:8px;padding-bottom:8px;row-gap:6px}.bar3 nav{display:flex;grid-column:1/-1;order:3;gap:22px;overflow-x:auto;padding-bottom:4px}}
""")
s=open('css/submit.css',encoding='utf-8').read()
if '.tbanner' not in s:
    open('css/submit.css','a',encoding='utf-8').write("""
.tbanner{background:var(--soft);border-radius:10px;padding:12px 14px;margin-bottom:16px;font-size:.88rem;color:var(--head);display:flex;gap:12px;align-items:center;justify-content:space-between;flex-wrap:wrap}
.tbanner button{border:none;background:none;color:var(--accent);font:inherit;font-weight:700;cursor:pointer;text-decoration:underline}
""")
a=open('css/admin.css',encoding='utf-8').read()
if '.sec-title' not in a:
    open('css/admin.css','a',encoding='utf-8').write("""
.sec-title{font-size:.78rem;letter-spacing:1px;text-transform:uppercase;color:var(--mute);margin:0 0 12px;font-weight:700}
.ocard{grid-template-columns:72px 1fr auto;align-items:start}.tcard{grid-template-columns:1fr auto}
.odesc{white-space:pre-wrap;overflow-wrap:anywhere;margin:8px 0;font-size:.92rem;color:var(--text);line-height:1.5}
""")
print('CSS updated')
PY

# ================= HEADERS ON EXISTING PAGES =================
python3 - <<'PY'
import re
def hdr(on=''):
    def a(h,l): return f'<a{" class=on" if on==h else ""} href="{h}">{l}</a>'
    return ('<header><div class="bar bar3">\n  <a class="logo" href="/"><img src="/assets/img/logo.png" alt="" width="36" height="30">Projectlarry.lol</a>\n'
      f'  <nav>{a("/timer/","Timer")}{a("/bulletin/","Client Bulletin")}</nav>\n'
      '  <div class="bar-right"><a class="btn-sm" href="/submit/">Submit a run</a><button class="icon-btn" id="theme" type="button" aria-label="Toggle dark mode" title="Toggle theme">&#9680;</button></div>\n</div></header>')
for p in ['index.html','submit/index.html']:
    t=open(p,encoding='utf-8').read()
    t2=re.sub(r'(?s)<header>.*?</header>',lambda m:hdr(),t,count=1)
    assert t2!=t or 'href="/timer/"' in t, 'No header found in '+p
    open(p,'w',encoding='utf-8').write(t2)
t=open('index.html',encoding='utf-8').read()
if 'id="upcoming"' not in t:
    assert '<main>' in t,'No <main> in index.html'
    sec='<section class="upcoming" id="upcoming" hidden><div class="up-head"><span class="live-dot"></span><span>Upcoming runs</span></div><div class="up-list"></div></section>\n'
    t=t.replace('<main>',sec+'<main>',1)
    open('index.html','w',encoding='utf-8').write(t)
s=open('submit/index.html',encoding='utf-8').read()
if 'submit-timer.js' not in s:
    s=s.replace('<script type="module" src="/js/submit-page.js"></script>','<script type="module" src="/js/submit-page.js"></script>\n<script type="module" src="/js/submit-timer.js"></script>',1)
    open('submit/index.html','w',encoding='utf-8').write(s)
open('/tmp/hdr_timer.html','w').write(hdr('/timer/'));open('/tmp/hdr_bul.html','w').write(hdr('/bulletin/'))
print('Headers updated')
PY

# ================= UPCOMING STRIP + MAIN =================
cat > js/upcoming.js <<'EOF'
import{el,fmt}from'./utils.js';
export function initUpcoming(){
  const box=document.getElementById('upcoming');if(!box)return;
  const list=box.querySelector('.up-list');let timers=[],off=0;
  const dur=ms=>fmt(Math.max(0,Math.floor(ms/1000))*1000);
  const tick=()=>list.querySelectorAll('.up-time').forEach(s=>{s.textContent='Running for '+dur(Date.now()+off-Number(s.dataset.start))});
  function draw(){
    list.textContent='';box.hidden=!timers.length;
    timers.forEach(t=>{const c=el('div','up-card');c.appendChild(el('b',null,t.name));c.appendChild(el('span','up-cat',t.cat+' frame'));
      const s=el('span','up-time');s.dataset.start=String(t.start);c.appendChild(s);list.appendChild(c)});
    tick()}
  async function load(){
    try{const r=await fetch('/api/timers');if(!r.ok)return;const j=await r.json();off=j.now-Date.now();timers=j.timers||[];draw()}catch{}}
  load();setInterval(load,60000);setInterval(tick,1000)}
EOF

cat > js/main.js <<'EOF'
import{loadRuns,loadGallery}from'./store.js';
import{renderBoard,renderStats}from'./render.js';
import{buildGallery}from'./gallery.js';
import{initTheme}from'./theme.js';
import{buildTabs}from'./tabs.js';
import{initUpcoming}from'./upcoming.js';
import{CATS,catOf,inCat}from'./cats.js';
const $=id=>document.getElementById(id);
let runs=[],query='',cat=Number(localStorage.getItem('tcl.cat'))||7;
if(!CATS.includes(cat))cat=7;
initTheme($('theme'));
initUpcoming();
function draw(){
  buildTabs($('tabs'),CATS,cat,c=>{cat=c;try{localStorage.setItem('tcl.cat',c)}catch{}draw()},c=>inCat(runs,c).length);
  renderStats(runs,cat);renderBoard(runs,{cat,query})}
$('search').addEventListener('input',e=>{query=e.target.value.trim();draw()});
Promise.all([loadRuns(),loadGallery()]).then(([r,g])=>{
  runs=r;buildGallery(g);
  const m=location.hash.match(/^#run-(.+)$/),hit=m&&runs.find(x=>x.id===m[1]);if(hit)cat=catOf(hit);
  draw();if(m)document.getElementById('run-'+m[1])?.scrollIntoView()});
EOF

# ================= TIMER PAGE =================
cat > css/timer.css <<'EOF'
.tm-wrap{max-width:560px;margin:34px auto 60px;padding:0 20px;display:block}
.tm-card{padding:26px}.tm-card .intro{margin:0 0 14px}
.warn{background:var(--soft);border-radius:10px;padding:12px 14px;font-size:.88rem;line-height:1.5;color:var(--head);margin-bottom:16px}
.clock{font-size:clamp(2.2rem,9vw,3.4rem);font-weight:700;letter-spacing:-.04em;color:var(--head);text-align:center;font-variant-numeric:tabular-nums;margin:14px 0 6px}
.tm-meta{text-align:center;margin-bottom:14px;color:var(--head)}
.resume{margin-top:22px;padding-top:16px;border-top:1px solid var(--line);font-size:.85rem;color:var(--mute);display:grid;gap:8px}
.resume input{flex:1}
.codebox{margin-top:20px;font-size:.8rem;color:var(--mute);display:grid;gap:8px}
.codebox code{flex:1;background:var(--soft);border-radius:8px;padding:10px 12px;font-size:1rem;letter-spacing:.08em;color:var(--head);overflow-wrap:anywhere}
.tm-card .row2{margin-top:6px}
EOF

{ cat <<'EOF'
<!doctype html>
<html lang="en" data-theme="light">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Timer | Projectlarry.lol</title>
<meta name="robots" content="noindex">
<link rel="icon" href="/assets/img/logo.png" type="image/png">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;600;700;800&display=swap">
<link rel="stylesheet" href="/css/tokens.css"><link rel="stylesheet" href="/css/base.css"><link rel="stylesheet" href="/css/layout.css"><link rel="stylesheet" href="/css/components.css"><link rel="stylesheet" href="/css/submit.css"><link rel="stylesheet" href="/css/dialog.css"><link rel="stylesheet" href="/css/timer.css">
</head>
<body>
EOF
cat /tmp/hdr_timer.html
cat <<'EOF'

<main class="tm-wrap">
  <section id="view-start" class="card col tm-card">
    <h2>Run timer</h2>
    <p class="intro">Start the timer when you begin a commission. It runs on our server and keeps counting until you stop it, so the time you submit can be verified.</p>
    <div class="warn"><b>It never pauses.</b> The clock keeps running whether or not you are working, and the only way to end it is pressing Stop. You get 2 timer starts every 3 days.</div>
    <form id="sf" class="step" novalidate>
      <label>Category</label><div class="cats" id="cats" role="radiogroup" aria-label="Category"></div>
      <label for="n">Designer name</label><input id="n" maxlength="40" placeholder="Your name" autocomplete="off">
      <label for="c">Client name (optional)</label><input id="c" maxlength="60" placeholder="Who is it for?" autocomplete="off">
      <div class="err" id="e-start"></div>
      <button class="btn" type="submit" id="go">Start timer</button>
    </form>
    <div class="resume"><span>Started a timer on another device?</span>
      <div class="row2"><input id="rc" placeholder="Resume code" autocomplete="off"><button class="btn ghost" id="rb" type="button">Resume</button></div>
      <div class="err" id="e-resume"></div></div>
  </section>
  <section id="view-run" class="card col tm-card" hidden>
    <h2>Timer running</h2>
    <div class="clock" id="clock">0s</div>
    <div class="tm-meta"><b id="r-name"></b> <span class="badge" id="r-cat"></span></div>
    <p class="intro">You are listed under Upcoming runs on the main page. Press Stop the moment you finish.</p>
    <div class="row2"><button class="btn" id="stop" type="button">Stop timer</button><button class="btn ghost" id="cancel" type="button">Cancel timer</button></div>
    <div class="codebox"><span>Resume code. Save it to continue on another device.</span><div class="row2"><code id="code"></code><button class="btn ghost" id="copy" type="button">Copy</button></div></div>
  </section>
  <section id="view-done" class="card col tm-card" hidden>
    <h2>Timer stopped</h2>
    <div class="clock" id="d-time"></div>
    <div class="tm-meta"><b id="d-name"></b> <span class="badge" id="d-cat"></span></div>
    <p class="intro">Submit this time with your proof images. It will be marked as timer verified once approved.</p>
    <div class="row2"><a class="btn" href="/submit/">Continue to submit</a><button class="btn ghost" id="discard" type="button">Discard</button></div>
  </section>
</main>
<dialog id="dlg"><form method="dialog"><h3 id="dt"></h3><p class="dmsg" id="dm"></p>
  <div class="row2"><button class="btn ghost" value="cancel">Cancel</button><button class="btn red" id="dok" value="ok">OK</button></div></form></dialog>
<div class="toast" id="toast" role="status"></div>
<script type="module" src="/js/timer-page.js"></script>
</body></html>
EOF
} > timer/index.html

cat > js/timer-page.js <<'EOF'
import{fmt,el,toast}from'./utils.js';
import{CATS}from'./cats.js';
import{initTheme}from'./theme.js';
const $=id=>document.getElementById(id);
initTheme($('theme'));
const KEY='tcl.timer';
let st=null,off=0,cat=7,tk=null;
try{st=JSON.parse(localStorage.getItem(KEY)||'null')}catch{}
const persist=()=>{try{if(st)localStorage.setItem(KEY,JSON.stringify(st));else localStorage.removeItem(KEY)}catch{}};
async function api(body){
  const r=await fetch('/api/timer',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
  const j=await r.json().catch(()=>({}));
  if(!r.ok){const e=new Error(j.error||'Something went wrong. Try again.');e.status=r.status;throw e}
  return j}
const dur=ms=>fmt(Math.max(0,Math.floor(ms/1000))*1000);
const pretty=c=>String(c).replace(/(.{4})/g,'$1-').replace(/-$/,'');
const confirmBox=(title,text,ok)=>new Promise(res=>{
  const d=$('dlg');$('dt').textContent=title;$('dm').textContent=text;$('dok').textContent=ok;
  d.returnValue='';d.onclose=()=>res(d.returnValue==='ok');d.showModal()});
const drawCats=()=>{const box=$('cats');box.textContent='';
  CATS.forEach(c=>{const b=el('button','pillbtn',c+' frame');b.type='button';b.setAttribute('role','radio');b.setAttribute('aria-checked',String(c===cat));b.onclick=()=>{cat=c;drawCats()};box.appendChild(b)})};
drawCats();
function render(){
  const v=!st?'start':st.stop?'done':'run';
  ['start','run','done'].forEach(x=>$('view-'+x).hidden=x!==v);
  clearInterval(tk);
  if(v==='run'){
    $('r-name').textContent=st.name;$('r-cat').textContent=st.cat+' frame';$('code').textContent=pretty(st.code);
    const t=()=>{$('clock').textContent=dur(Date.now()+off-st.start)};t();tk=setInterval(t,1000)}
  if(v==='done'){$('d-time').textContent=fmt(st.stop-st.start);$('d-name').textContent=st.name;$('d-cat').textContent=st.cat+' frame'}}
$('sf').addEventListener('submit',async e=>{
  e.preventDefault();$('e-start').textContent='';
  const name=$('n').value.trim();if(!name){$('e-start').textContent='Enter your name';return}
  const btn=$('go');btn.disabled=true;btn.textContent='Starting...';
  try{const j=await api({action:'start',name,cat,client:$('c').value.trim()});
    st=j;off=j.now-Date.now();persist();render()}
  catch(err){$('e-start').textContent=err.message}
  btn.disabled=false;btn.textContent='Start timer'});
$('rb').onclick=async()=>{
  $('e-resume').textContent='';const code=$('rc').value.trim();if(!code){$('e-resume').textContent='Enter your resume code';return}
  try{const j=await api({action:'resume',code});st=j;off=j.now-Date.now();persist();render()}
  catch(err){$('e-resume').textContent=err.message}};
$('stop').onclick=async()=>{
  if(!await confirmBox('Stop the timer?','This ends your run. You cannot restart it afterwards.','Stop timer'))return;
  try{const j=await api({action:'stop',id:st.id,code:st.code});st.stop=j.stop;persist();render()}
  catch(err){toast(err.message)}};
$('cancel').onclick=async()=>{
  if(!await confirmBox('Cancel the timer?','This deletes your timer. If you cancel within 2 minutes of starting, it does not count against your limit of 2 starts per 3 days.','Cancel timer'))return;
  try{const j=await api({action:'cancel',id:st.id,code:st.code});st=null;persist();render();toast(j.refunded?'Cancelled. This start was not counted.':'Timer cancelled.')}
  catch(err){toast(err.message)}};
$('discard').onclick=async()=>{
  if(!await confirmBox('Discard this time?','Your stopped timer will be deleted and you will not be able to submit it.','Discard'))return;
  try{await api({action:'cancel',id:st.id,code:st.code})}catch{}
  st=null;persist();render()};
$('copy').onclick=()=>{navigator.clipboard.writeText(st.code).then(()=>toast('Resume code copied'),()=>toast(st.code))};
(async()=>{
  if(st){try{const j=await api({action:'resume',code:st.code});st=j;off=j.now-Date.now();persist()}catch(e){if(e.status===404){st=null;persist()}}}
  render()})();
EOF

cat > js/submit-timer.js <<'EOF'
import{fmt}from'./utils.js';
let st=null;try{st=JSON.parse(localStorage.getItem('tcl.timer')||'null')}catch{}
if(st&&st.stop){
  const $=id=>document.getElementById(id);
  window.__timer={id:st.id,code:st.code};
  $('n').value=st.name||'';$('c').value=st.client||'';
  $('t').value=fmt(st.stop-st.start);$('t').readOnly=true;$('t').dispatchEvent(new Event('input'));
  const pill=[...document.querySelectorAll('#cats button')].find(b=>b.textContent===st.cat+' frame');if(pill)pill.click();
  const b=document.createElement('div');b.className='tbanner';
  const s=document.createElement('span');s.textContent='Using your timer: '+fmt(st.stop-st.start)+'. This run will be marked timer verified.';
  const x=document.createElement('button');x.type='button';x.textContent='Use a manual time instead';
  x.onclick=()=>{window.__timer=null;$('t').readOnly=false;b.remove()};
  b.append(s,x);$('f').parentNode.insertBefore(b,$('f'))}
EOF

# ================= BULLETIN PAGE =================
cat > css/bulletin.css <<'EOF'
.bl-wrap{max-width:760px;margin:34px auto 60px;padding:0 20px;display:block}
.bl-head{display:flex;justify-content:space-between;align-items:flex-start;gap:16px;flex-wrap:wrap;margin-bottom:16px}
.bl-head h1{margin:0 0 6px;font-size:clamp(1.8rem,5vw,2.4rem);letter-spacing:-.04em;color:var(--head)}
.bl-head .intro{margin:0;max-width:480px}
.notice{background:var(--soft);border-radius:10px;padding:12px 14px;color:var(--mute);font-size:.85rem;line-height:1.5;margin-bottom:18px}
.offer{display:flex;gap:16px;padding:18px;background:var(--surface);border:1px dashed var(--line);border-radius:6px;box-shadow:var(--shadow);margin-bottom:16px}
.offer.taken{opacity:.6}
.obody{flex:1;min-width:0}.otop{display:flex;align-items:center;gap:8px;flex-wrap:wrap}.otop b{font-size:1.05rem;color:var(--head);margin-right:4px}
.otop .btn{margin-left:auto}
.odesc{white-space:pre-wrap;overflow-wrap:anywhere;margin:10px 0;color:var(--text);line-height:1.55;font-size:.95rem}
.ometa{font-size:.78rem;color:var(--mute)}
.badge.open{background:#d9f5e5;color:#17653a}.badge.gray{background:var(--soft);color:var(--mute)}
.check{display:flex;gap:10px;align-items:flex-start;font-size:.85rem;color:var(--text);margin-top:8px}.check input{width:auto;margin-top:3px}
.hp{position:absolute;left:-9999px;width:1px;height:1px;opacity:0}
.aprev .ava{margin-top:6px}
#omsg{color:var(--danger);font-size:.82rem}#omsg:empty{display:none}
.ok{text-align:center;padding:16px 4px}.ok h3{margin:0 0 8px}
.intro{color:var(--mute);font-size:.92rem;line-height:1.5}
@media(max-width:560px){.offer{flex-direction:column}}
EOF

{ cat <<'EOF'
<!doctype html>
<html lang="en" data-theme="light">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Client Bulletin | Projectlarry.lol</title>
<meta name="description" content="Commission offers from clients. Pick one up for practice or a timed run.">
<link rel="icon" href="/assets/img/logo.png" type="image/png">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;600;700;800&display=swap">
<link rel="stylesheet" href="/css/tokens.css"><link rel="stylesheet" href="/css/base.css"><link rel="stylesheet" href="/css/layout.css"><link rel="stylesheet" href="/css/components.css"><link rel="stylesheet" href="/css/dialog.css"><link rel="stylesheet" href="/css/bulletin.css">
</head>
<body>
EOF
cat /tmp/hdr_bul.html
cat <<'EOF'

<main class="bl-wrap">
  <div class="bl-head">
    <div><h1>Client Bulletin</h1><p class="intro">Clients post a commission here. Designers can pick one up and use it for practice or a timed run.</p></div>
    <button class="btn" id="post" type="button">Post an offer</button>
  </div>
  <div class="notice">This site does not handle payments or contracts. Agree terms with the client directly, and be careful about sharing personal details or paying anyone in advance.</div>
  <div class="tabs" id="ftabs"></div>
  <div id="offers"></div>
</main>
<dialog id="odlg">
  <form id="of" class="dform">
    <h3>Post an offer</h3>
    <label for="ocat">Frame category</label><select id="ocat"></select>
    <label for="od">What do you need designed?</label>
    <textarea id="od" rows="5" maxlength="600" placeholder="Describe the screens you want, the game style, and any requirements."></textarea><div class="hint" id="ocount">0/600</div>
    <label for="ou">Your Discord username</label><input id="ou" placeholder="username" maxlength="33" autocomplete="off">
    <label for="oa">Profile picture</label><input id="oa" type="file" accept="image/*"><div class="aprev" id="aprev"></div>
    <label class="check"><input type="checkbox" id="ocon"> I agree that designers may use this brief for practice and timed runs.</label>
    <input class="hp" id="website" tabindex="-1" autocomplete="off" aria-hidden="true">
    <div id="omsg"></div>
    <div class="row2"><button class="btn ghost" type="button" id="ocx">Cancel</button><button class="btn" type="submit" id="osub">Submit offer</button></div>
  </form>
  <div class="ok" id="odone" hidden><h3>Thanks, your offer was submitted.</h3><p class="intro">It will appear on the bulletin once it has been reviewed.</p><button class="btn" id="oclose" type="button">Close</button></div>
</dialog>
<div class="toast" id="toast" role="status"></div>
<script type="module" src="/js/bulletin-page.js"></script>
</body></html>
EOF
} > bulletin/index.html

cat > js/bulletin-page.js <<'EOF'
import{el,toast,safeImg}from'./utils.js';
import{cover}from'./images.js';
import{CATS}from'./cats.js';
import{initTheme}from'./theme.js';
const $=id=>document.getElementById(id);
initTheme($('theme'));
let offers=[],f=0,avatar='';
const ago=ts=>{const s=(Date.now()-ts)/1000;if(s<3600)return Math.max(1,Math.round(s/60))+' min ago';if(s<86400)return Math.round(s/3600)+' hours ago';return Math.round(s/86400)+' days ago'};
function draw(){
  const tb=$('ftabs');tb.textContent='';
  [0,...CATS].forEach(c=>{const b=el('button','tab',c?c+' frame':'All');b.type='button';b.setAttribute('aria-selected',String(c===f));
    b.appendChild(el('i',null,String(c?offers.filter(o=>o.cat===c).length:offers.length)));b.onclick=()=>{f=c;draw()};tb.appendChild(b)});
  const box=$('offers');box.textContent='';const list=offers.filter(o=>!f||o.cat===f);
  if(!list.length){box.appendChild(el('div','empty',offers.length?'No offers in this category.':'No offers yet. Be the first to post one.'));return}
  list.forEach(o=>{
    const c=el('article','offer'+(o.status==='taken'?' taken':''));
    const a=el('img','ava');a.src=safeImg(o.avatar);a.alt='';
    const body=el('div','obody'),top=el('div','otop');
    top.appendChild(el('b',null,'@'+o.discord));
    top.append(el('span','badge',o.cat+' frame'),el('span','badge '+(o.status==='taken'?'gray':'open'),o.status==='taken'?'Taken':'Open'));
    const cp=el('button','btn ghost sm','Copy username');cp.type='button';
    cp.onclick=()=>navigator.clipboard.writeText(o.discord).then(()=>toast('Copied '+o.discord),()=>toast(o.discord));
    top.appendChild(cp);
    body.append(top,el('p','odesc',o.desc),el('div','ometa','Posted '+ago(o.at)));
    c.append(a,body);box.appendChild(c)})}
fetch('/api/offers').then(r=>r.json()).then(j=>{offers=j.offers||[];draw()}).catch(()=>{$('offers').textContent='Could not load offers right now.'});
const sel=$('ocat');CATS.forEach(c=>{const o=document.createElement('option');o.value=c;o.textContent=c+' frame';sel.appendChild(o)});sel.value=7;
$('od').addEventListener('input',()=>{$('ocount').textContent=$('od').value.length+'/600'});
$('oa').onchange=async e=>{
  const file=e.target.files[0];avatar='';$('aprev').textContent='';if(!file)return;
  try{avatar=await cover(file,96,96,.7);const i=el('img','ava');i.src=avatar;i.alt='';$('aprev').appendChild(i)}
  catch{$('omsg').textContent='Could not read that image.'}};
$('post').onclick=()=>{$('of').hidden=false;$('odone').hidden=true;$('odlg').showModal()};
$('ocx').onclick=()=>$('odlg').close();$('oclose').onclick=()=>$('odlg').close();
$('of').addEventListener('submit',async e=>{
  e.preventDefault();const m=$('omsg');m.textContent='';
  const desc=$('od').value.trim();if(desc.length<20){m.textContent='Describe what you need in at least 20 characters.';return}
  const u=$('ou').value.trim().replace(/^@/,'').toLowerCase();if(!/^[a-z0-9_.]{2,32}$/.test(u)){m.textContent='Enter your Discord username, like name or name_01.';return}
  if(!avatar){m.textContent='Add a profile picture.';return}
  if(!$('ocon').checked){m.textContent='Please tick the agreement box.';return}
  const btn=$('osub');btn.disabled=true;btn.textContent='Sending...';
  try{
    const r=await fetch('/api/offers',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({cat:Number(sel.value),desc,discord:u,avatar,consent:true,website:$('website').value})});
    const j=await r.json().catch(()=>({}));if(!r.ok)throw new Error(j.error||'Something went wrong. Try again.');
    $('of').reset();avatar='';$('aprev').textContent='';$('ocount').textContent='0/600';$('of').hidden=true;$('odone').hidden=false
  }catch(err){m.textContent=err.message}
  btn.disabled=false;btn.textContent='Submit offer'});
EOF

# ================= ADMIN =================
python3 - <<'PY'
p='admin/index.html'
t=open(p,encoding='utf-8').read()
if 'pane-offers' not in t:
    marker='  </main>\n</div>'
    assert marker in t,'Could not patch admin/index.html'
    add='''    <section id="pane-offers" hidden>
      <h2 class="sec-title">Pending offers</h2><div id="opend"></div>
      <h2 class="sec-title" style="margin-top:28px">Live offers</h2><div id="olive"></div>
    </section>
    <section id="pane-timers" hidden>
      <div class="toolbar"><button class="btn ghost sm" id="trefresh" type="button">Refresh</button><button class="btn ghost sm" id="treset" type="button">Reset all limits</button></div>
      <div id="tlist"></div>
    </section>
'''
    t=t.replace(marker,add+marker,1)
    open(p,'w',encoding='utf-8').write(t)
print('Admin page updated')
PY

cat > js/admin-page.js <<'EOF'
import{loadRuns}from'./store.js';
import{renderBoard}from'./render.js';
import{initAdmin}from'./admin.js';
import{initTheme}from'./theme.js';
import{buildTabs}from'./tabs.js';
import{CATS,inCat}from'./cats.js';
import{fmt,el,ico,toast,safeImg}from'./utils.js';
const $=id=>document.getElementById(id);
initTheme();
let pw=sessionStorage.getItem('tcl.pw')||'',runs=[],subs=[],offers={pending:[],approved:[]},timers=[],toff=0,admin,pane='subs',cat=7,qs='',ql='';
async function api(method,url,body){
  const r=await fetch(url,{method,headers:{'Content-Type':'application/json','x-admin-password':pw},body:body?JSON.stringify(body):undefined});
  const j=await r.json().catch(()=>({}));
  if(!r.ok){const e=new Error(j.error||('Error '+r.status));e.status=r.status;throw e}
  return j}
const save=async(next,rm)=>{await api('POST','/api/admin/runs',{runs:next,removeSubmission:rm});runs=next};
const confirmBox=(title,text,ok)=>new Promise(res=>{
  const d=$('dlg');$('dt').textContent=title;$('dm').textContent=text;$('dok').textContent=ok;
  d.returnValue='';d.onclose=()=>res(d.returnValue==='ok');d.showModal()});
const PANES=['subs','lb','offers','timers'];
function drawTabs(){
  const box=$('atabs');box.textContent='';
  [['subs','Submissions',subs.length],['lb','Leaderboard',runs.length],['offers','Offers',offers.pending.length],['timers','Timers',timers.filter(t=>!t.stop).length]].forEach(([k,l,n])=>{
    const b=el('button','tab',l);b.type='button';b.setAttribute('aria-selected',String(pane===k));
    b.appendChild(el('i',null,String(n)));b.onclick=()=>{pane=k;drawAll()};box.appendChild(b)});
  PANES.forEach(k=>{$('pane-'+k).hidden=pane!==k})}
async function viewProof(id){
  try{
    const{submission:d}=await api('GET','/api/admin/submissions?id='+id);
    const lb=el('div','lb'),top=el('div','lbtop');
    function close(){lb.remove();document.removeEventListener('keydown',key)}
    function key(e){if(e.key==='Escape')close()}
    const x=el('button','btn ghost sm','Close');x.type='button';x.onclick=close;
    top.append(el('b',null,d.name+' \u2013 '+(d.cat||7)+' frame \u2013 '+fmt(d.ms)+(d.verified?' (timer verified)':'')),x);lb.appendChild(top);
    d.proofs.forEach(p=>{const i=el('img');i.src=p;i.alt='Proof';lb.appendChild(i)});
    document.addEventListener('keydown',key);document.body.appendChild(lb)
  }catch(e){toast(e.message)}}
async function approve(s,btn){
  btn.disabled=true;
  try{
    const{submission:d}=await api('GET','/api/admin/submissions?id='+s.id);
    await save([...runs,{id:s.id,name:d.name,ms:d.ms,cat:d.cat||7,client:d.client||'',video:d.video||'',img:d.img||'',verified:!!d.verified}],s.id);
    subs=subs.filter(x=>x.id!==s.id);drawAll();toast('Approved and added to the leaderboard')
  }catch(e){toast(e.message);btn.disabled=false}}
async function reject(s){
  if(!await confirmBox('Reject submission?','This permanently deletes the submission from '+s.name+' and its proof images.','Reject'))return;
  try{await api('DELETE','/api/admin/submissions',{id:s.id});subs=subs.filter(x=>x.id!==s.id);drawAll();toast('Rejected')}
  catch(e){toast(e.message)}}
function drawSubs(){
  const box=$('subs');box.textContent='';
  const q=qs.toLowerCase(),list=subs.filter(s=>!q||(s.name+' '+(s.client||'')).toLowerCase().includes(q));
  if(!list.length){box.appendChild(el('div','empty',subs.length?'No matches.':'Nothing to review. New submissions will show up here.'));return}
  list.forEach(s=>{
    const c=el('article','scard');
    const th=el('button','sthumb');th.type='button';th.title='View proof';th.onclick=()=>viewProof(s.id);
    if(s.thumb){const i=el('img');i.src=s.thumb;i.alt='';th.appendChild(i)}else th.appendChild(ico('image'));
    const info=el('div');
    info.appendChild(el('h3',null,s.name+' \u2013 '+fmt(s.ms)));
    const l1=el('div','line');l1.append(el('span','badge',(s.cat||7)+' frame'),el('span',null,s.client?('client: '+s.client):'client not given'));
    if(s.verified)l1.appendChild(el('span','vbadge','Timer verified'));
    const l2=el('div','line');l2.appendChild(el('span',null,new Date(s.at).toLocaleString()));
    l2.appendChild(el('span',null,s.proofCount+' proof image'+(s.proofCount===1?'':'s')));
    if(s.video){const a=el('a',null,'Recording');a.href=s.video;a.target='_blank';a.rel='noopener noreferrer';l2.appendChild(a)}
    info.append(l1,l2);
    const act=el('div','sact');
    const ap=el('button','btn sm','Approve');ap.onclick=()=>approve(s,ap);
    const pr=el('button','btn ghost sm','View proof');pr.onclick=()=>viewProof(s.id);
    const rj=el('button','btn red sm','Reject');rj.onclick=()=>reject(s);
    act.append(ap,pr,rj);c.append(th,info,act);box.appendChild(c)})}
function drawLb(){
  buildTabs($('ctabs'),CATS,cat,c=>{cat=c;drawLb()},c=>inCat(runs,c).length);
  renderBoard(runs,{cat,query:ql,admin:true,onEdit:r=>admin.startEdit(r),
    onDelete:async r=>{
      if(!await confirmBox('Remove run?','"'+r.name+'" will be removed from the leaderboard.','Remove'))return;
      try{await save(runs.filter(q=>q.id!==r.id));drawAll();toast('Removed')}catch(e){toast(e.message)}}})}
// offers
async function offerAct(body,msg){
  try{await api('POST','/api/admin/offers',body);offers=await api('GET','/api/admin/offers');drawAll();toast(msg)}
  catch(e){toast(e.message)}}
function offerCard(o,live){
  const c=el('article','scard ocard');
  const a=el('img','ava');a.src=safeImg(o.avatar);a.alt='';
  const info=el('div');info.appendChild(el('h3',null,'@'+o.discord));
  const l1=el('div','line');l1.append(el('span','badge',o.cat+' frame'),el('span','badge',o.status==='taken'?'Taken':'Open'));
  info.append(l1,el('p','odesc',o.desc),el('div','line',new Date(o.at).toLocaleString()));
  const act=el('div','sact');
  if(live){
    const t=el('button','btn ghost sm',o.status==='taken'?'Mark open':'Mark taken');t.onclick=()=>offerAct({action:'status',id:o.id,status:o.status==='taken'?'open':'taken'},'Updated');
    const d=el('button','btn red sm','Delete');d.onclick=async()=>{if(await confirmBox('Delete offer?','This removes the offer from the bulletin.','Delete'))offerAct({action:'delete',id:o.id},'Deleted')};
    act.append(t,d)
  }else{
    const ap=el('button','btn sm','Approve');ap.onclick=()=>offerAct({action:'approve',id:o.id},'Offer is live');
    const rj=el('button','btn red sm','Reject');rj.onclick=async()=>{if(await confirmBox('Reject offer?','This permanently deletes the offer.','Reject'))offerAct({action:'reject',id:o.id},'Rejected')};
    act.append(ap,rj)}
  c.append(a,info,act);return c}
function drawOffers(){
  const p=$('opend'),l=$('olive');p.textContent='';l.textContent='';
  if(!offers.pending.length)p.appendChild(el('div','empty','No pending offers.'));
  offers.pending.forEach(o=>p.appendChild(offerCard(o,false)));
  if(!offers.approved.length)l.appendChild(el('div','empty','No live offers yet.'));
  offers.approved.forEach(o=>l.appendChild(offerCard(o,true)))}
// timers
async function loadTimers(){const j=await api('GET','/api/admin/timers');timers=j.timers;toff=j.now-Date.now()}
async function timerAct(body,msg){
  try{await api('POST','/api/admin/timers',body);await loadTimers();drawAll();toast(msg)}catch(e){toast(e.message)}}
function drawTimers(){
  const box=$('tlist');box.textContent='';
  if(!timers.length){box.appendChild(el('div','empty','No timers right now.'));return}
  timers.forEach(t=>{
    const c=el('article','scard tcard'),info=el('div');
    info.appendChild(el('h3',null,t.name));
    const l1=el('div','line');l1.append(el('span','badge',t.cat+' frame'),
      el('span',null,t.stop?('Stopped, final time '+fmt(t.stop-t.start)):('Running for '+fmt(Math.floor((Date.now()+toff-t.start)/1000)*1000))));
    const l2=el('div','line',new Date(t.start).toLocaleString()+(t.client?(', client: '+t.client):''));
    info.append(l1,l2);
    const act=el('div','sact');
    const rl=el('button','btn ghost sm','Reset limit');rl.onclick=()=>timerAct({action:'resetLimit',id:t.id},'Limit reset for this person');
    const rm=el('button','btn red sm','Remove');rm.onclick=async()=>{if(await confirmBox('Remove timer?','The timer is deleted and the designer will be taken off Upcoming runs.','Remove'))timerAct({action:'remove',id:t.id},'Removed')};
    act.append(rl,rm);c.append(info,act);box.appendChild(c)})}
const drawAll=()=>{drawTabs();drawSubs();drawLb();drawOffers();drawTimers()};
async function enter(){
  const s=await api('GET','/api/admin/submissions');
  subs=s.submissions;runs=await loadRuns();
  offers=await api('GET','/api/admin/offers').catch(()=>({pending:[],approved:[]}));
  await loadTimers().catch(()=>{timers=[]});
  $('login').hidden=true;$('panel').hidden=false;
  admin=initAdmin({getRuns:()=>runs,setRuns:async n=>{await save(n);drawAll()}});
  drawAll()}
$('qs').addEventListener('input',e=>{qs=e.target.value.trim();drawSubs()});
$('ql').addEventListener('input',e=>{ql=e.target.value.trim();drawLb()});
$('addrun').onclick=()=>admin.startNew(cat);
$('trefresh').onclick=async()=>{try{await loadTimers();drawAll()}catch(e){toast(e.message)}};
$('treset').onclick=async()=>{if(await confirmBox('Reset all limits?','Everyone gets their 2 timer starts back.','Reset'))timerAct({action:'resetAll'},'All limits reset')};
$('lf').addEventListener('submit',async e=>{e.preventDefault();pw=$('pw').value;
  try{await enter();sessionStorage.setItem('tcl.pw',pw)}catch(err){$('lmsg').textContent=err.status===401?'Wrong password.':err.message}});
$('logout').onclick=()=>{sessionStorage.removeItem('tcl.pw');location.reload()};
if(pw)enter().catch(()=>sessionStorage.removeItem('tcl.pw'));
EOF

echo "Done. Now: git add -A && git commit -m 'Timer, upcoming runs, client bulletin' && git push"

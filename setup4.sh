#!/bin/bash
set -e
[ -f bulletin/index.html ] && [ -f api/offers.js ] && [ -f css/timer.css ] || { echo "Run this in your site folder, after setup3 has been applied."; exit 1; }

# ================= SERVER: 1 offer per person =================
cat > api/offers.js <<'EOF'
const{redis,ip,ipk,limit,rid,hvals,jparse}=require('./_lib');
const IMG=/^data:image\/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$/;
const CATS=[3,5,7,12,15];
const bad=(res,m)=>res.status(400).json({error:m});
module.exports=async(req,res)=>{
  try{
    if(req.method==='GET'){
      const list=hvals(await redis('HGETALL','offers')).map(jparse).filter(Boolean).map(({ipk,...o})=>o);
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
    const me=ipk(req);
    const all=[...hvals(await redis('HGETALL','offers_pending')),...hvals(await redis('HGETALL','offers'))].map(jparse).filter(Boolean);
    if(all.some(o=>o.status!=='taken'&&(o.ipk===me||o.discord===discord)))
      return res.status(409).json({error:'You already have an offer posted. Only 1 offer per person is allowed. You can post again once it is marked as taken or removed.'});
    if((await redis('HLEN','offers_pending'))>=50)return res.status(503).json({error:'Offers are full right now. Try again later.'});
    const id=rid(8);
    await redis('HSET','offers_pending',id,JSON.stringify({id,cat,desc,discord,avatar,ipk:me,status:'open',at:Date.now()}));
    res.status(200).json({ok:true});
  }catch(e){res.status(500).json({error:e.message})}
};
EOF

# ================= CSS =================
cat > css/bulletin.css <<'EOF'
.hero.flat{margin-top:0;padding-top:44px}
.offer{align-items:flex-start}
.offer.taken{opacity:.6}
.offer .thumb{width:96px;height:96px;border-radius:6px}
.offer .info h3{font-size:1.3rem}
.odesc{white-space:pre-wrap;overflow-wrap:anywhere;margin:10px 0 0;color:var(--text);line-height:1.55;font-size:.93rem}
.badge.open{background:#d9f5e5;color:#17653a}.badge.gray{background:var(--soft);color:var(--mute)}
.meta .badge{font-size:.7rem}
.side-note{font-size:.85rem;color:var(--mute);line-height:1.5;margin:0 0 14px}
.card.col .btn.full{width:100%;padding:14px}
#odlg{padding:0;width:min(560px,94vw);max-height:92vh;overflow:auto}
#odlg .step textarea{padding:13px 14px;border-radius:10px;font:inherit;font-size:1rem;width:100%;border:1px solid var(--line);background:var(--surface);color:var(--text);resize:vertical}
#odlg .step textarea:focus{outline:2px solid var(--accent);outline-offset:2px}
.step .check{display:flex;gap:10px;align-items:flex-start;font-size:.85rem;font-weight:500;color:var(--text);margin-top:10px}
.step .check input{width:auto;margin-top:3px;padding:0}
.aprev img{width:72px;height:72px;border-radius:6px;object-fit:cover;margin-top:6px;display:block}
@media(max-width:560px){.offer .thumb{width:72px;height:72px;aspect-ratio:1}}
EOF

python3 - <<'PY'
p='css/timer.css'
t=open(p,encoding='utf-8').read()
if '/*tm2*/' not in t:
    t=t.replace('.tm-wrap{max-width:560px','.tm-wrap{max-width:600px',1)
    t+="""
/*tm2*/
.tm-card h2{font-size:1.5rem;text-transform:none;letter-spacing:-.5px;color:var(--head);display:block;margin:0 0 12px}
#go{width:100%;padding:14px;margin-top:14px}
.tm-card .row2 .btn{padding:14px}
.resume .row2 .btn{padding:13px 18px;flex:none}
.resume input{padding:13px 14px;border-radius:10px;font-size:1rem}
"""
    open(p,'w',encoding='utf-8').write(t)
print('CSS updated')
PY

# ================= BULLETIN PAGE =================
python3 - <<'PY'
import re
old=open('bulletin/index.html',encoding='utf-8').read()
hdr=re.search(r'(?s)<header>.*?</header>',old).group(0)
page='''<!doctype html>
<html lang="en" data-theme="light">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Client Bulletin | Projectlarry.lol</title>
<meta name="description" content="Commission offers from clients. Pick one up for practice or a timed run.">
<link rel="icon" href="/assets/img/logo.png" type="image/png">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;600;700;800&display=swap">
<link rel="stylesheet" href="/css/tokens.css"><link rel="stylesheet" href="/css/base.css"><link rel="stylesheet" href="/css/layout.css"><link rel="stylesheet" href="/css/components.css"><link rel="stylesheet" href="/css/submit.css"><link rel="stylesheet" href="/css/dialog.css"><link rel="stylesheet" href="/css/bulletin.css">
</head>
<body>
'''+hdr+'''
<section class="hero flat">
  <span class="pill">Client Bulletin</span>
  <h1>Commission Offers</h1>
  <p>Clients post a brief. Designers can pick one up for practice or a timed run.</p>
</section>
<main>
  <section id="list">
    <div class="tabs" id="ftabs"></div>
    <div id="offers" aria-live="polite"></div>
  </section>
  <aside>
    <div class="card col">
      <h2>Post an offer</h2>
      <p class="side-note">Need something designed? Post your brief and designers can pick it up. Each person can have 1 offer at a time. Offers are reviewed before they are listed.</p>
      <button class="btn full" id="post" type="button">Post an offer</button>
    </div>
    <div class="card col">
      <h2>Good to know</h2>
      <ol class="rules">
        <li><span>1.</span><span>This site does not handle payments or contracts. Agree terms with the other person directly.</span></li>
        <li><span>2.</span><span>Be careful about sharing personal details or paying anyone in advance.</span></li>
        <li><span>3.</span><span>Contact the client on Discord using the username on their offer.</span></li>
      </ol>
    </div>
  </aside>
</main>
<dialog id="odlg"><div class="sub-card">
  <form id="of" class="step" novalidate>
    <h2>Post an offer</h2>
    <p class="intro">Describe the commission. It will appear on the bulletin once it has been reviewed.</p>
    <label>Frame category</label><div class="cats" id="ocats" role="radiogroup" aria-label="Frame category"></div>
    <label for="od">What do you need designed?</label>
    <textarea id="od" rows="5" maxlength="600" placeholder="Describe the screens you want, the game style, and any requirements."></textarea><div class="hint" id="ocount">0/600</div>
    <label for="ou">Your Discord username</label><input id="ou" placeholder="username" maxlength="33" autocomplete="off">
    <label for="oa">Profile picture</label><input id="oa" type="file" accept="image/*"><div class="aprev" id="aprev"></div>
    <label class="check"><input type="checkbox" id="ocon"> I agree that designers may use this brief for practice and timed runs.</label>
    <input class="hp" id="website" tabindex="-1" autocomplete="off" aria-hidden="true">
    <div class="err" id="omsg"></div>
    <div class="nav"><button class="btn ghost" type="button" id="ocx">Cancel</button><button class="btn" type="submit" id="osub">Submit offer</button></div>
  </form>
  <div class="ok" id="odone" hidden><h3>Thanks, your offer was submitted.</h3><p class="intro">It will appear on the bulletin once it has been reviewed.</p><button class="btn" id="oclose" type="button">Close</button></div>
</div></dialog>
<div class="toast" id="toast" role="status"></div>
<script type="module" src="/js/bulletin-page.js"></script>
</body></html>
'''
open('bulletin/index.html','w',encoding='utf-8').write(page)
print('Bulletin page rewritten')
PY

cat > js/bulletin-page.js <<'EOF'
import{el,toast,safeImg,ico}from'./utils.js';
import{cover}from'./images.js';
import{CATS}from'./cats.js';
import{initTheme}from'./theme.js';
const $=id=>document.getElementById(id);
initTheme($('theme'));
let offers=[],f=0,avatar='',ocat=7;
const ago=ts=>{const s=(Date.now()-ts)/1000;if(s<3600)return Math.max(1,Math.round(s/60))+' min ago';if(s<86400)return Math.round(s/3600)+' hours ago';return Math.round(s/86400)+' days ago'};
function draw(){
  const tb=$('ftabs');tb.textContent='';
  [0,...CATS].forEach(c=>{const b=el('button','tab',c?c+' frame':'All');b.type='button';b.setAttribute('aria-selected',String(c===f));
    b.appendChild(el('i',null,String(c?offers.filter(o=>o.cat===c).length:offers.length)));b.onclick=()=>{f=c;draw()};tb.appendChild(b)});
  const box=$('offers');box.textContent='';const list=offers.filter(o=>!f||o.cat===f);
  if(!list.length){const e=el('div','empty');e.appendChild(ico('image'));e.appendChild(el('div',null,offers.length?'No offers in this category.':'No offers yet. Be the first to post one.'));box.appendChild(e);return}
  list.forEach(o=>{
    const c=el('article','card offer'+(o.status==='taken'?' taken':''));
    const th=el('div','thumb'),src=safeImg(o.avatar);
    if(src){const i=el('img');i.src=src;i.alt='';th.appendChild(i)}else th.appendChild(ico('image'));
    const info=el('div','info');
    info.appendChild(el('h3',null,'@'+o.discord));
    info.appendChild(el('div','by','needs a '+o.cat+' frame design'));
    const meta=el('div','meta');
    meta.append(el('span','badge '+(o.status==='taken'?'gray':'open'),o.status==='taken'?'Taken':'Open'),el('span',null,'Posted '+ago(o.at)));
    info.append(meta,el('p','odesc',o.desc));
    const acts=el('div','acts'),cp=el('button');cp.type='button';cp.title='Copy Discord username';cp.setAttribute('aria-label','Copy Discord username');cp.appendChild(ico('link'));
    cp.onclick=()=>navigator.clipboard.writeText(o.discord).then(()=>toast('Copied '+o.discord),()=>toast(o.discord));
    acts.appendChild(cp);
    c.append(th,info,acts);box.appendChild(c)})}
fetch('/api/offers').then(r=>r.json()).then(j=>{offers=j.offers||[];draw()}).catch(()=>{$('offers').textContent='Could not load offers right now.'});
const drawCats=()=>{const box=$('ocats');box.textContent='';
  CATS.forEach(c=>{const b=el('button','pillbtn',c+' frame');b.type='button';b.setAttribute('role','radio');b.setAttribute('aria-checked',String(c===ocat));b.onclick=()=>{ocat=c;drawCats()};box.appendChild(b)})};
drawCats();
$('od').addEventListener('input',()=>{$('ocount').textContent=$('od').value.length+'/600'});
$('oa').onchange=async e=>{
  const file=e.target.files[0];avatar='';$('aprev').textContent='';if(!file)return;
  try{avatar=await cover(file,96,96,.7);const i=el('img');i.src=avatar;i.alt='';$('aprev').appendChild(i)}
  catch{$('omsg').textContent='Could not read that image.'}};
$('post').onclick=()=>{$('of').hidden=false;$('odone').hidden=true;$('omsg').textContent='';$('odlg').showModal()};
$('ocx').onclick=()=>$('odlg').close();$('oclose').onclick=()=>$('odlg').close();
$('of').addEventListener('submit',async e=>{
  e.preventDefault();const m=$('omsg');m.textContent='';
  const desc=$('od').value.trim();if(desc.length<20){m.textContent='Describe what you need in at least 20 characters.';return}
  const u=$('ou').value.trim().replace(/^@/,'').toLowerCase();if(!/^[a-z0-9_.]{2,32}$/.test(u)){m.textContent='Enter your Discord username, like name or name_01.';return}
  if(!avatar){m.textContent='Add a profile picture.';return}
  if(!$('ocon').checked){m.textContent='Please tick the agreement box.';return}
  const btn=$('osub');btn.disabled=true;btn.textContent='Sending...';
  try{
    const r=await fetch('/api/offers',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({cat:ocat,desc,discord:u,avatar,consent:true,website:$('website').value})});
    const j=await r.json().catch(()=>({}));if(!r.ok)throw new Error(j.error||'Something went wrong. Try again.');
    $('of').reset();avatar='';$('aprev').textContent='';$('ocount').textContent='0/600';$('of').hidden=true;$('odone').hidden=false
  }catch(err){m.textContent=err.message}
  btn.disabled=false;btn.textContent='Submit offer'});
EOF

echo "Done. Now: git add -A && git commit -m 'Bulletin: 1 offer per person, UI match' && git push"

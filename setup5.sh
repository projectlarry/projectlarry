#!/bin/bash
set -e
[ -f bulletin/index.html ] && [ -f js/bulletin-page.js ] && [ -f css/bulletin.css ] || { echo "Run this in your site folder, after setup4 has been applied."; exit 1; }

# ================= CSS =================
cat > css/bulletin.css <<'EOF'
[hidden]{display:none!important}
@keyframes rise{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:none}}
@keyframes fade{from{opacity:0}to{opacity:1}}
@keyframes fadeout{from{opacity:1}to{opacity:0}}
@keyframes pop{from{opacity:0;transform:translateY(16px) scale(.97)}to{opacity:1;transform:none}}
@keyframes popout{from{opacity:1;transform:none}to{opacity:0;transform:translateY(10px) scale(.98)}}
@keyframes slideup{from{transform:translateY(40px);opacity:0}to{transform:none;opacity:1}}
@keyframes slidedown{from{transform:none;opacity:1}to{transform:translateY(40px);opacity:0}}
@keyframes draw{to{stroke-dashoffset:0}}
@keyframes shake{20%{transform:translateX(-5px)}40%{transform:translateX(5px)}60%{transform:translateX(-3px)}80%{transform:translateX(3px)}}
@keyframes sp{to{transform:rotate(360deg)}}

/* page */
.hero.flat{margin-top:0;padding-top:44px}
.hero.flat>*{animation:rise .45s cubic-bezier(.2,.8,.2,1) both}
.hero.flat h1{animation-delay:.05s}.hero.flat p{animation-delay:.1s}
.btn{transition:transform .12s ease,opacity .15s ease,background .15s ease}
.btn:active{transform:scale(.97)}
.side-note{font-size:.85rem;color:var(--mute);line-height:1.5;margin:0 0 14px}
.card.col .btn.full{width:100%;padding:14px}

/* category tabs: always one line */
#ftabs{flex-wrap:nowrap;overflow-x:auto;gap:6px;padding:2px 1px 4px;margin-bottom:14px;scrollbar-width:none}
#ftabs::-webkit-scrollbar{display:none}
#ftabs .tab{flex:none;padding:8px 12px;transition:background .18s,color .18s,border-color .18s,transform .12s}
#ftabs .tab:active{transform:scale(.95)}
#ftabs .tab i{margin-left:6px;transition:background .18s}

/* offer cards */
.offer{align-items:flex-start;animation:rise .38s cubic-bezier(.2,.8,.2,1) both;animation-delay:calc(var(--n,0)*45ms);transition:transform .18s ease,border-color .18s ease}
.offer:hover{transform:translateY(-2px);border-color:var(--accent)}
.offer .thumb{width:96px;height:96px;border-radius:6px}
.offer .info h3{font-size:1.3rem}
.offer.taken .thumb,.offer.taken .info{opacity:.55}
.odesc{white-space:pre-wrap;overflow-wrap:anywhere;margin:10px 0 0;color:var(--text);line-height:1.55;font-size:.93rem}
.badge.open{background:#d9f5e5;color:#17653a}.badge.gray{background:var(--soft);color:var(--mute)}
.meta .badge{font-size:.7rem}
.acts button{transition:color .15s,border-color .15s,transform .12s}
.acts button:hover{border-color:var(--accent)}.acts button:active{transform:scale(.9)}
#offers .empty{animation:rise .35s both}
@media(max-width:560px){.offer .thumb{width:72px;height:72px;aspect-ratio:1}}

/* modal */
.modal{position:fixed;inset:0;z-index:50;display:grid;place-items:center;padding:16px}
.modal-bg{position:absolute;inset:0;background:rgba(0,0,0,.58);backdrop-filter:blur(3px);animation:fade .2s ease both}
.sheet{position:relative;width:min(520px,100%);max-height:calc(100dvh - 32px);overflow:auto;background:var(--surface);border:1px solid var(--line);border-radius:18px;box-shadow:0 24px 70px rgba(0,0,0,.45);padding:26px;animation:pop .26s cubic-bezier(.2,.9,.25,1) both}
.modal.out .modal-bg{animation:fadeout .16s ease both}
.modal.out .sheet{animation:popout .16s ease both}
@media(max-width:560px){
  .modal{place-items:end center;padding:0}
  .sheet{width:100%;border-radius:18px 18px 0 0;border-bottom:0;max-height:92dvh;padding:22px 18px calc(22px + env(safe-area-inset-bottom,0px));animation:slideup .28s cubic-bezier(.2,.9,.25,1) both}
  .modal.out .sheet{animation:slidedown .18s ease both}}
.sheet-head{display:flex;justify-content:space-between;align-items:flex-start;gap:12px;margin-bottom:20px}
.sheet h2{margin:0 0 4px;font-size:1.5rem;letter-spacing:-.5px;color:var(--head)}
.sheet-sub{margin:0;color:var(--mute);font-size:.9rem;line-height:1.45}
.x{flex:none;width:34px;height:34px;border-radius:50%;border:0;background:var(--soft);color:var(--mute);display:grid;place-items:center;cursor:pointer;transition:color .15s,transform .15s,background .15s}
.x:hover{color:var(--head);transform:rotate(90deg)}
.x svg{width:16px;height:16px;stroke:currentColor;stroke-width:2.2;stroke-linecap:round;fill:none}

/* fields */
.field{margin-bottom:18px}
.fl{display:block;font-size:.8rem;font-weight:700;color:var(--head);margin:0 0 8px}
.inp,.ta{position:relative;display:flex;align-items:center;border:1px solid var(--line);background:var(--bg);border-radius:12px;transition:border-color .15s,box-shadow .15s}
.inp:focus-within,.ta:focus-within{border-color:var(--accent);box-shadow:0 0 0 3px color-mix(in srgb,var(--accent) 22%,transparent)}
.field.bad .inp,.field.bad .ta,.field.bad .up,.field.bad .seg{border-color:var(--danger)}
.inp input,.ta textarea{border:0;background:none;box-shadow:none;border-radius:12px;width:100%;padding:13px 14px;font:inherit;font-size:1rem;color:var(--text)}
.inp input:focus,.ta textarea:focus{outline:none}
.inp .at{padding-left:14px;color:var(--mute);font-weight:600}.inp .at+input{padding-left:4px}
.ta{display:block}.ta textarea{display:block;resize:none;min-height:112px;padding-bottom:30px;line-height:1.5}
.cnt{position:absolute;right:12px;bottom:8px;font-size:.72rem;color:var(--mute);font-variant-numeric:tabular-nums;pointer-events:none}

/* segmented category control (one line) */
.seg{--i:2;position:relative;display:grid;grid-template-columns:repeat(5,1fr);background:var(--soft);border:1px solid transparent;border-radius:12px;padding:4px;transition:border-color .15s}
.seg-ind{position:absolute;top:4px;bottom:4px;left:4px;width:calc((100% - 8px)/5);background:var(--btn);border-radius:9px;transform:translateX(calc(var(--i)*100%));transition:transform .24s cubic-bezier(.3,.9,.3,1);box-shadow:0 2px 8px rgba(0,0,0,.2)}
.seg button{position:relative;z-index:1;border:0;background:none;font:inherit;padding:8px 0;border-radius:9px;cursor:pointer;color:var(--mute);display:grid;justify-items:center;line-height:1.15;transition:color .2s}
.seg button b{font-size:1.05rem}
.seg button small{font-size:.6rem;letter-spacing:.5px;text-transform:uppercase;opacity:.8}
.seg button[aria-checked=true]{color:var(--btn-text)}
.seg button:not([aria-checked=true]):hover{color:var(--head)}
.seg button:focus-visible{outline:2px solid var(--accent);outline-offset:1px}

/* picture upload */
.up{display:flex;align-items:center;gap:14px;padding:12px;border:1.5px dashed var(--line);border-radius:12px;cursor:pointer;transition:border-color .15s,background .15s}
.up:hover,.up.over,.up:focus-visible{border-color:var(--accent);background:var(--soft);outline:none}
.up-av{flex:none;width:56px;height:56px;border-radius:50%;background:var(--soft);color:var(--mute);display:grid;place-items:center;overflow:hidden;transition:transform .2s}
.up:hover .up-av{transform:scale(1.05)}
.up-av img{width:100%;height:100%;object-fit:cover;animation:fade .25s both}
.up-av .ico{width:22px;height:22px}
.up-t{flex:1;min-width:0;display:grid;gap:2px}.up-t b{font-size:.92rem;color:var(--head)}.up-t small{font-size:.78rem;color:var(--mute)}
.up .btn{flex:none;padding:8px 14px;font-size:.8rem;pointer-events:none}

/* agreement */
.tick{display:flex;gap:12px;align-items:flex-start;width:100%;border:0;background:none;padding:2px 0;text-align:left;font:inherit;font-size:.85rem;color:var(--text);line-height:1.45;cursor:pointer}
.tick .box{flex:none;width:20px;height:20px;margin-top:1px;border:1.5px solid var(--line);border-radius:6px;display:grid;place-items:center;background:var(--bg);transition:background .18s,border-color .18s,transform .12s}
.tick:active .box{transform:scale(.9)}
.tick:hover .box{border-color:var(--accent)}
.tick .box svg{width:14px;height:14px;fill:none;stroke:var(--btn-text);stroke-width:2.4;stroke-linecap:round;stroke-linejoin:round}
.tick .box path{stroke-dasharray:20;stroke-dashoffset:20;transition:stroke-dashoffset .22s ease}
.tick[aria-checked=true] .box{background:var(--btn);border-color:var(--btn)}
.tick[aria-checked=true] .box path{stroke-dashoffset:0}
.tick:focus-visible{outline:2px solid var(--accent);outline-offset:3px;border-radius:6px}
.field.bad .tick .box{border-color:var(--danger)}

/* errors, actions */
.err{color:var(--danger);font-size:.84rem;margin:2px 0 0}
.err:empty{display:none}
.err.show{animation:shake .32s ease}
.sheet-acts{display:flex;gap:10px;margin-top:20px}
.sheet-acts .btn{flex:1;padding:14px}
.spin{width:14px;height:14px;border:2px solid currentColor;border-right-color:transparent;border-radius:50%;animation:sp .6s linear infinite}
.hp{position:absolute;left:-9999px;width:1px;height:1px;opacity:0}

/* success */
.done{text-align:center;padding:14px 4px 4px;animation:rise .3s ease both}
.okc{width:64px;height:64px;margin:0 auto 14px;display:block}
.okc circle{fill:none;stroke:var(--accent);stroke-width:2;stroke-dasharray:151;stroke-dashoffset:151;animation:draw .5s .05s ease forwards}
.okc path{fill:none;stroke:var(--head);stroke-width:3;stroke-linecap:round;stroke-linejoin:round;stroke-dasharray:40;stroke-dashoffset:40;animation:draw .35s .4s ease forwards}
.done h3{margin:0 0 6px;font-size:1.3rem;color:var(--head)}
.done p{margin:0 0 20px;color:var(--mute);font-size:.92rem;line-height:1.5}
#of{animation:rise .25s ease both}

@media(prefers-reduced-motion:reduce){*,*::before,*::after{animation-duration:.01ms!important;animation-delay:0s!important;transition-duration:.01ms!important}}
EOF

# ================= PAGE =================
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
<link rel="stylesheet" href="/css/tokens.css"><link rel="stylesheet" href="/css/base.css"><link rel="stylesheet" href="/css/layout.css"><link rel="stylesheet" href="/css/components.css"><link rel="stylesheet" href="/css/bulletin.css">
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

<div class="modal" id="omodal" hidden>
  <div class="modal-bg" data-close></div>
  <div class="sheet" role="dialog" aria-modal="true" aria-labelledby="mt">
    <form id="of" novalidate>
      <div class="sheet-head">
        <div><h2 id="mt">Post an offer</h2><p class="sheet-sub">Describe the commission. It appears on the bulletin once it has been reviewed.</p></div>
        <button class="x" type="button" data-close aria-label="Close"><svg viewBox="0 0 16 16"><path d="M3 3l10 10M13 3L3 13"/></svg></button>
      </div>
      <div class="field"><span class="fl" id="lc">Frame category</span><div class="seg" id="oseg" role="radiogroup" aria-labelledby="lc"></div></div>
      <div class="field" id="f-d"><label class="fl" for="od">What do you need designed?</label>
        <div class="ta"><textarea id="od" maxlength="600" placeholder="Describe the screens you want, the game style, and any requirements."></textarea><span class="cnt" id="ocount">0/600</span></div></div>
      <div class="field" id="f-u"><label class="fl" for="ou">Discord username</label>
        <div class="inp"><span class="at">@</span><input id="ou" placeholder="username" maxlength="33" autocomplete="off" spellcheck="false"></div></div>
      <div class="field" id="f-a"><span class="fl">Profile picture</span>
        <div class="up" id="oup" tabindex="0" role="button" aria-label="Choose a profile picture">
          <div class="up-av" id="uav"></div>
          <div class="up-t"><b id="ut">Upload a picture</b><small>Drop an image here or click. PNG, JPG or WebP.</small></div>
          <span class="btn ghost" id="ubtn">Choose</span>
        </div>
        <input id="oa" type="file" accept="image/*" hidden></div>
      <div class="field" id="f-c"><button class="tick" id="ocon" type="button" role="checkbox" aria-checked="false"><span class="box"><svg viewBox="0 0 20 20"><path d="M5 10.5l3.5 3.5L15 7"/></svg></span><span>I agree that designers may use this brief for practice and timed runs.</span></button></div>
      <input class="hp" id="website" tabindex="-1" autocomplete="off" aria-hidden="true">
      <div class="err" id="omsg" role="alert"></div>
      <div class="sheet-acts"><button class="btn ghost" type="button" data-close>Cancel</button><button class="btn" type="submit" id="osub">Submit offer</button></div>
    </form>
    <div class="done" id="odone" hidden>
      <svg class="okc" viewBox="0 0 52 52" aria-hidden="true"><circle cx="26" cy="26" r="24"/><path d="M15 27l8 8 14-16"/></svg>
      <h3>Offer submitted</h3><p>It will appear on the bulletin once it has been reviewed.</p>
      <button class="btn" id="oclose" type="button" style="min-width:140px;padding:13px 22px">Done</button>
    </div>
  </div>
</div>
<div class="toast" id="toast" role="status"></div>
<script type="module" src="/js/bulletin-page.js"></script>
</body></html>
'''
open('bulletin/index.html','w',encoding='utf-8').write(page)
print('Bulletin page rewritten')
PY

# ================= SCRIPT =================
cat > js/bulletin-page.js <<'EOF'
import{el,toast,safeImg,ico}from'./utils.js';
import{cover}from'./images.js';
import{CATS}from'./cats.js';
import{initTheme}from'./theme.js';
const $=id=>document.getElementById(id);
initTheme($('theme'));
let offers=[],f=0,avatar='',ocat=7,agreed=false,busy=false;
const ago=ts=>{const s=(Date.now()-ts)/1000;if(s<3600)return Math.max(1,Math.round(s/60))+' min ago';if(s<86400)return Math.round(s/3600)+' hours ago';return Math.round(s/86400)+' days ago'};

/* ---------- list + filter tabs ---------- */
function buildTabs(){
  const tb=$('ftabs');tb.textContent='';
  [0,...CATS].forEach(c=>{
    const b=el('button','tab',c?c+' frame':'All');b.type='button';b.dataset.c=String(c);b.setAttribute('aria-selected',String(c===f));
    const n=el('i',null,'0');b.appendChild(n);b.onclick=()=>{f=c;tabState();drawList()};tb.appendChild(b)})}
function tabState(){
  document.querySelectorAll('#ftabs .tab').forEach(b=>{
    const c=Number(b.dataset.c);b.setAttribute('aria-selected',String(c===f));
    b.querySelector('i').textContent=String(c?offers.filter(o=>o.cat===c).length:offers.length)})}
function drawList(){
  const box=$('offers');box.textContent='';const list=offers.filter(o=>!f||o.cat===f);
  if(!list.length){const e=el('div','empty');e.appendChild(ico('image'));e.appendChild(el('div',null,offers.length?'No offers in this category.':'No offers yet. Be the first to post one.'));box.appendChild(e);return}
  list.forEach((o,i)=>{
    const c=el('article','card offer'+(o.status==='taken'?' taken':''));c.style.setProperty('--n',String(Math.min(i,8)));
    const th=el('div','thumb'),src=safeImg(o.avatar);
    if(src){const im=el('img');im.src=src;im.alt='';th.appendChild(im)}else th.appendChild(ico('image'));
    const info=el('div','info');
    info.appendChild(el('h3',null,'@'+o.discord));
    info.appendChild(el('div','by','needs a '+o.cat+' frame design'));
    const meta=el('div','meta');
    meta.append(el('span','badge '+(o.status==='taken'?'gray':'open'),o.status==='taken'?'Taken':'Open'),el('span',null,'Posted '+ago(o.at)));
    info.append(meta,el('p','odesc',o.desc));
    const acts=el('div','acts'),cp=el('button');cp.type='button';cp.title='Copy Discord username';cp.setAttribute('aria-label','Copy Discord username');cp.appendChild(ico('link'));
    cp.onclick=()=>navigator.clipboard.writeText(o.discord).then(()=>toast('Copied '+o.discord),()=>toast(o.discord));
    acts.appendChild(cp);c.append(th,info,acts);box.appendChild(c)})}
buildTabs();
fetch('/api/offers').then(r=>r.json()).then(j=>{offers=j.offers||[];tabState();drawList()}).catch(()=>{$('offers').textContent='Could not load offers right now.'});

/* ---------- category segmented control ---------- */
const seg=$('oseg');
const ind=el('i','seg-ind');seg.appendChild(ind);
CATS.forEach(c=>{
  const b=el('button');b.type='button';b.setAttribute('role','radio');b.dataset.c=String(c);
  b.append(el('b',null,String(c)),el('small',null,'frame'));
  b.onclick=()=>setCat(c);seg.appendChild(b)});
function setCat(c,focus){
  ocat=c;seg.style.setProperty('--i',String(CATS.indexOf(c)));
  seg.querySelectorAll('button').forEach(b=>{const on=Number(b.dataset.c)===c;b.setAttribute('aria-checked',String(on));b.tabIndex=on?0:-1;if(on&&focus)b.focus()})}
seg.addEventListener('keydown',e=>{
  const d=e.key==='ArrowRight'||e.key==='ArrowDown'?1:e.key==='ArrowLeft'||e.key==='ArrowUp'?-1:0;
  if(!d)return;e.preventDefault();setCat(CATS[(CATS.indexOf(ocat)+d+CATS.length)%CATS.length],true)});
setCat(7);

/* ---------- fields ---------- */
const msg=$('omsg');
function fail(fieldId,text,focusEl){
  msg.textContent=text;msg.classList.remove('show');void msg.offsetWidth;msg.classList.add('show');
  const fd=$(fieldId);fd.classList.add('bad');if(focusEl)focusEl.focus()}
function clearBad(){document.querySelectorAll('.field.bad').forEach(x=>x.classList.remove('bad'));msg.textContent=''}
['od','ou'].forEach(id=>$(id).addEventListener('input',clearBad));
$('od').addEventListener('input',()=>{$('ocount').textContent=$('od').value.length+'/600'});

/* agreement checkbox */
const tick=$('ocon');
function setAgree(v){agreed=v;tick.setAttribute('aria-checked',String(v))}
tick.onclick=()=>{setAgree(!agreed);clearBad()};

/* picture upload */
const up=$('oup');
function avatarEmpty(){const a=$('uav');a.textContent='';a.appendChild(ico('image'));$('ut').textContent='Upload a picture';$('ubtn').textContent='Choose'}
avatarEmpty();
async function pick(file){
  if(!file)return;
  if(!file.type.startsWith('image/')){fail('f-a','Choose an image file.');return}
  try{
    avatar=await cover(file,96,96,.7);
    const a=$('uav');a.textContent='';const i=el('img');i.src=avatar;i.alt='';a.appendChild(i);
    $('ut').textContent='Looks good';$('ubtn').textContent='Change';clearBad()
  }catch{avatar='';avatarEmpty();fail('f-a','Could not read that image.')}}
up.onclick=()=>$('oa').click();
up.onkeydown=e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();$('oa').click()}};
$('oa').onchange=e=>{pick(e.target.files[0]);e.target.value=''};
['dragenter','dragover'].forEach(t=>up.addEventListener(t,e=>{e.preventDefault();up.classList.add('over')}));
['dragleave','drop'].forEach(t=>up.addEventListener(t,e=>{e.preventDefault();up.classList.remove('over')}));
up.addEventListener('drop',e=>pick(e.dataTransfer.files[0]));

/* ---------- modal ---------- */
const M=$('omodal');let closing=false;
function resetForm(){
  $('of').reset();setCat(7);setAgree(false);avatar='';avatarEmpty();$('ocount').textContent='0/600';clearBad()}
function openModal(){
  if(!M.hidden)return;
  $('of').hidden=false;$('odone').hidden=true;clearBad();
  M.classList.remove('out');M.hidden=false;document.documentElement.style.overflow='hidden';
  setTimeout(()=>$('od').focus({preventScroll:true}),60)}
function closeModal(){
  if(M.hidden||closing)return;closing=true;M.classList.add('out');
  setTimeout(()=>{M.hidden=true;M.classList.remove('out');closing=false;document.documentElement.style.overflow='';$('post').focus({preventScroll:true})},170)}
$('post').onclick=openModal;
M.addEventListener('click',e=>{if(e.target.closest('[data-close]'))closeModal()});
$('oclose').onclick=closeModal;
document.addEventListener('keydown',e=>{
  if(M.hidden)return;
  if(e.key==='Escape'){e.preventDefault();closeModal();return}
  if(e.key!=='Tab')return;
  const nodes=[...M.querySelectorAll('button,input:not([type=hidden]):not(.hp),textarea,[tabindex="0"]')].filter(n=>!n.disabled&&n.offsetParent!==null&&n.tabIndex>=0);
  if(!nodes.length)return;const first=nodes[0],last=nodes[nodes.length-1];
  if(e.shiftKey&&document.activeElement===first){e.preventDefault();last.focus()}
  else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus()}});

/* ---------- submit ---------- */
$('of').addEventListener('submit',async e=>{
  e.preventDefault();if(busy)return;clearBad();
  const desc=$('od').value.trim();
  if(desc.length<20){fail('f-d','Describe what you need in at least 20 characters.',$('od'));return}
  const u=$('ou').value.trim().replace(/^@/,'').toLowerCase();
  if(!/^[a-z0-9_.]{2,32}$/.test(u)){fail('f-u','Enter your Discord username, like name or name_01.',$('ou'));return}
  if(!avatar){fail('f-a','Add a profile picture.',up);return}
  if(!agreed){fail('f-c','Please tick the agreement box.',tick);return}
  busy=true;const btn=$('osub');btn.disabled=true;btn.textContent='';btn.append(el('span','spin'),document.createTextNode(' Sending'));
  try{
    const r=await fetch('/api/offers',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({cat:ocat,desc,discord:u,avatar,consent:true,website:$('website').value})});
    const j=await r.json().catch(()=>({}));if(!r.ok)throw new Error(j.error||'Something went wrong. Try again.');
    resetForm();$('of').hidden=true;$('odone').hidden=false
  }catch(err){fail('f-c',err.message)}
  $('f-c').classList.remove('bad');
  busy=false;btn.disabled=false;btn.textContent='Submit offer'});
EOF

echo "Done. Now: git add -A && git commit -m 'Bulletin: custom form components and animations' && git push"

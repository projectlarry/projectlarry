import{stagger,animateIn}from './motion.js';
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
    const b=el('button','tab',c?c+' frame':'All');b.type='button';b.dataset.c=String(c);b.setAttribute('aria-selected',String(c===f));if(c===7){b.classList.add('standard-7-frame');b.title='The original 7 Frame standard'};if(c===7)b.classList.add('standard-7-frame');
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
  const b=el('button');b.type='button';b.setAttribute('role','radio');b.dataset.c=String(c);if(c===7){b.classList.add('standard-7-frame');b.title='The original 7 Frame standard'};if(c===7)b.classList.add('standard-7-frame');
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


requestAnimationFrame(()=>{
  stagger(document.querySelector('#offers'));
  stagger(document.querySelector('#board'));
});

import{parse,safeUrl,fmt,el}from'./utils.js';
import{shrink,cover}from'./images.js';
import{initTheme}from'./theme.js';
import{CATS}from'./cats.js';
const $=id=>document.getElementById(id);
initTheme($('theme'));
let step=1,cat=7,proofs=[],cardFile=null;
const steps=[...document.querySelectorAll('.step')];
const setErr=(id,m)=>{$('e-'+id).textContent=m||'';const i=$(id);if(i)i.classList.toggle('bad',!!m)};
const drawCats=()=>{const box=$('cats');box.textContent='';
  CATS.forEach(c=>{const b=el('button','pillbtn',c+' frame');b.type='button';b.setAttribute('role','radio');b.setAttribute('aria-checked',String(c===cat));if(c===7)b.classList.add('standard-7-frame');b.onclick=()=>{cat=c;drawCats()};box.appendChild(b)})};
drawCats();
$('t').addEventListener('input',()=>{const v=$('t').value.trim(),ms=parse(v);setErr('t','');
  $('tprev').textContent=v?(ms?'Reads as '+fmt(ms):'Not a valid time yet'):'Total time, like 2:34:54 or 2h 34m 54s'});
function show(n){
  step=n;steps.forEach((s,i)=>s.hidden=i+1!==n);
  $('slabel').textContent='Step '+n+' of 3';$('pfill').style.width=(n/3*100)+'%';
  $('back').hidden=n===1;$('next').hidden=n===3;$('sb').hidden=n!==3;$('msg').textContent='';
  if(n===3)summary();window.scrollTo({top:0,behavior:'smooth'})}
function valid(n){
  if(n===1){let ok=true;
    if(!$('n').value.trim()){setErr('n','Enter your name');ok=false}else setErr('n','');
    if(!parse($('t').value)){setErr('t','Use a time like 2:34:54 or 2h 34m 54s');ok=false}else setErr('t','');
    return ok}
  if(n===2){const v=$('v').value.trim();if(v&&!safeUrl(v)){setErr('v','Link must start with http:// or https://');return false}setErr('v','')}
  return true}
$('next').onclick=()=>{if(valid(step))show(step+1)};
$('back').onclick=()=>show(step-1);
function summary(){
  const s=$('summary');s.textContent='';
  [['Category',cat+' frame'],['Designer',$('n').value.trim()],['Time',fmt(parse($('t').value)||0)],['Client',$('c').value.trim()||'Not given']]
   .forEach(([k,v])=>{const r=el('div','srow');r.append(el('span',null,k),el('b',null,v));s.appendChild(r)})}
// proof upload
const drop=$('drop');
function drawThumbs(){
  const box=$('thumbs');box.textContent='';
  proofs.forEach((f,i)=>{const w=el('div','thumb2'),im=el('img');im.src=URL.createObjectURL(f);im.alt='';
    const x=el('button',null,'\u00d7');x.type='button';x.setAttribute('aria-label','Remove image');x.onclick=()=>{proofs.splice(i,1);drawThumbs()};
    w.append(im,x);box.appendChild(w)})}
function addFiles(list){
  setErr('p','');
  for(const f of list){if(!f.type.startsWith('image/'))continue;if(proofs.length>=3){setErr('p','Maximum 3 images');break}proofs.push(f)}
  drawThumbs()}
drop.onclick=()=>$('p').click();
drop.onkeydown=e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();$('p').click()}};
$('p').onchange=e=>{addFiles(e.target.files);e.target.value=''};
['dragenter','dragover'].forEach(ev=>drop.addEventListener(ev,e=>{e.preventDefault();drop.classList.add('over')}));
['dragleave','drop'].forEach(ev=>drop.addEventListener(ev,e=>{e.preventDefault();drop.classList.remove('over')}));
drop.addEventListener('drop',e=>addFiles(e.dataTransfer.files));
document.addEventListener('paste',e=>{if(step===3&&e.clipboardData&&e.clipboardData.files.length)addFiles(e.clipboardData.files)});
$('card').onchange=e=>{cardFile=e.target.files[0]||null;const b=$('cprev');b.textContent='';
  if(cardFile){const im=el('img');im.src=URL.createObjectURL(cardFile);im.alt='';b.appendChild(im)}};
// send
$('f').addEventListener('submit',async e=>{
  e.preventDefault();
  if(step<3){if(valid(step))show(step+1);return}
  if(!valid(1)){show(1);return}
  if(!valid(2)){show(2);return}
  if(!proofs.length){setErr('p','Add at least one proof image');return}
  const btn=$('sb');btn.disabled=true;btn.textContent='Sending...';$('msg').textContent='';
  try{
    let shr=await Promise.all(proofs.map(f=>shrink(f,1100,.6)));
    if(shr.join('').length>700000)shr=await Promise.all(proofs.map(f=>shrink(f,800,.5)));
    const thumb=await shrink(proofs[0],240,.5),img=cardFile?await cover(cardFile):'';
    const r=await fetch('/api/submit',{method:'POST',headers:{'Content-Type':'application/json'},
      body:JSON.stringify({cat,name:$('n').value.trim(),ms:parse($('t').value),client:$('c').value.trim(),video:$('v').value.trim(),proofs:shr,thumb,img,website:$('website').value,timerId:window.__timer&&window.__timer.id,timerCode:window.__timer&&window.__timer.code})});
    const j=await r.json().catch(()=>({}));
    if(!r.ok)throw new Error(j.error||'Something went wrong. Try again.');
    try{localStorage.removeItem('tcl.timer')}catch{}$('f').hidden=true;$('prog').hidden=true;$('done').hidden=false;window.scrollTo({top:0,behavior:'smooth'})
  }catch(err){$('msg').textContent=err.message;btn.disabled=false;btn.textContent='Submit run'}
});

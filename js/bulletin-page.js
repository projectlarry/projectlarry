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

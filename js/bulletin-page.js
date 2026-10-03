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

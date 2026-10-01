import{parse,safeUrl}from'./utils.js';
import{shrink,cover}from'./images.js';
import{initTheme}from'./theme.js';
const $=id=>document.getElementById(id);
initTheme($('theme'));
const msg=$('msg'),btn=$('sb');
const fail=m=>{msg.textContent=m};
$('f').addEventListener('submit',async e=>{
  e.preventDefault();msg.textContent='';
  const ms=parse($('t').value);if(!ms)return fail('Use a time like 2:34:54 or 2h 34m 54s.');
  const v=$('v').value.trim();if(v&&!safeUrl(v))return fail('Recording link must start with http(s)://');
  const files=[...$('p').files].slice(0,3);if(!files.length)return fail('Add at least one proof image.');
  btn.disabled=true;btn.textContent='Sending...';
  try{
    let proofs=await Promise.all(files.map(f=>shrink(f,1100,.6)));
    if(proofs.join('').length>700000)proofs=await Promise.all(files.map(f=>shrink(f,800,.5)));
    const cf=$('card').files[0],img=cf?await cover(cf):'';
    const r=await fetch('/api/submit',{method:'POST',headers:{'Content-Type':'application/json'},
      body:JSON.stringify({name:$('n').value.trim(),ms,client:$('c').value.trim(),video:v,proofs,img,website:$('website').value})});
    const j=await r.json().catch(()=>({}));
    if(!r.ok)throw new Error(j.error||'Something went wrong. Try again.');
    $('f').hidden=true;$('done').hidden=false;
  }catch(err){fail(err.message);btn.disabled=false;btn.textContent='Submit run'}
});

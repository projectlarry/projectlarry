import{fmt,parse,safeUrl}from'./utils.js';
import{cover}from'./images.js';
const $=id=>document.getElementById(id);
export function initAdmin({getRuns,setRuns}){
  let editId=null;const msg=$('msg'),f=$('f');
  const reset=()=>{editId=null;f.reset();msg.textContent='';$('cx').style.display='none';$('sb').textContent='Add to list'};
  $('cx').onclick=reset;
  f.addEventListener('submit',async ev=>{ev.preventDefault();
    const ms=parse($('t').value);if(!ms){msg.textContent='Use a time like 2:34:54 or 2h 34m 54s.';return}
    const v=$('v').value.trim();if(v&&!safeUrl(v)){msg.textContent='Recording link must start with http(s)://';return}
    let img='';const file=$('p').files[0];
    if(file){try{img=await cover(file)}catch{msg.textContent='Could not read that image.';return}}
    const runs=getRuns().map(r=>({...r})),d={name:$('n').value.trim(),ms,video:v,client:$('c').value.trim()};
    if(editId){const r=runs.find(q=>q.id===editId);if(r){Object.assign(r,d);if(img)r.img=img}}
    else runs.push({id:Date.now().toString(36)+Math.random().toString(36).slice(2,6),img,...d});
    try{await setRuns(runs);reset()}catch(err){msg.textContent=err.message}});
  return{startEdit(r){editId=r.id;$('n').value=r.name;$('t').value=fmt(r.ms);$('c').value=r.client||'';$('v').value=r.video||'';$('p').value='';
    $('cx').style.display='';$('sb').textContent='Save changes';$('admin').scrollIntoView({behavior:'smooth'})},reset}}

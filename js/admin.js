import{fmt,parse,safeUrl}from'./utils.js';
const $=id=>document.getElementById(id);
function readImg(file){return new Promise((res,rej)=>{const fr=new FileReader();fr.onerror=rej;fr.onload=()=>{const im=new Image();im.onerror=rej;im.onload=()=>{
  const W=412,H=232,c=document.createElement('canvas');c.width=W;c.height=H;const x=c.getContext('2d'),s=Math.max(W/im.width,H/im.height),w=im.width*s,h=im.height*s;
  x.fillStyle='#fff';x.fillRect(0,0,W,H);x.drawImage(im,(W-w)/2,(H-h)/2,w,h);res(c.toDataURL('image/jpeg',.82))};im.src=fr.result};fr.readAsDataURL(file)})}
export function initAdmin({getRuns,setRuns,onReset,onExport}){
  let editId=null;const msg=$('msg'),f=$('f');
  const reset=()=>{editId=null;f.reset();msg.textContent='';$('cx').style.display='none';$('sb').textContent='Add to list'};
  $('cx').onclick=reset;$('reset-data').onclick=()=>confirm('Discard local edits and reload data/runs.json?')&&onReset();$('export').onclick=onExport;
  f.addEventListener('submit',async ev=>{ev.preventDefault();
    const ms=parse($('t').value);if(!ms){msg.textContent='Use a time like 47:12 or 1:05:30.';return}
    const v=$('v').value.trim();if(v&&!safeUrl(v)){msg.textContent='Recording link must start with http(s)://';return}
    let img='';const file=$('p').files[0];if(file){try{img=await readImg(file)}catch{msg.textContent='Could not read that image.';return}}
    const runs=getRuns().slice(),d={name:$('n').value.trim(),ms,video:v,client:$('c').value.trim()};
    if(editId){const r=runs.find(q=>q.id===editId);if(r){Object.assign(r,d);if(img)r.img=img}}
    else runs.push({id:Date.now().toString(36)+Math.random().toString(36).slice(2,6),img,...d});
    reset();setRuns(runs)});
  return{startEdit(r){editId=r.id;$('n').value=r.name;$('t').value=fmt(r.ms);$('c').value=r.client||'';$('v').value=r.video||'';$('p').value='';
    $('cx').style.display='';$('sb').textContent='Save changes';$('admin').scrollIntoView({behavior:'smooth'})},reset}}

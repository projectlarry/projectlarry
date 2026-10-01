import{loadRuns}from'./store.js';
import{renderBoard}from'./render.js';
import{initAdmin}from'./admin.js';
import{initTheme}from'./theme.js';
import{fmt,el,toast}from'./utils.js';
const $=id=>document.getElementById(id);
initTheme();
let pw=sessionStorage.getItem('tcl.pw')||'',runs=[],subs=[],admin;
async function api(method,url,body){
  const r=await fetch(url,{method,headers:{'Content-Type':'application/json','x-admin-password':pw},body:body?JSON.stringify(body):undefined});
  const j=await r.json().catch(()=>({}));
  if(!r.ok){const e=new Error(j.error||('Error '+r.status));e.status=r.status;throw e}
  return j}
const save=async(next,rm)=>{await api('POST','/api/admin/runs',{runs:next,removeSubmission:rm});runs=next};
const drawBoard=()=>renderBoard(runs,{admin:true,onEdit:r=>admin.startEdit(r),
  onDelete:async r=>{try{await save(runs.filter(q=>q.id!==r.id));drawBoard();toast('Removed')}catch(e){toast(e.message)}}});
async function viewProof(id){
  try{const{submission:d}=await api('GET','/api/admin/submissions?id='+id);
    const lb=el('div','lb');d.proofs.forEach(p=>{const i=el('img');i.src=p;lb.appendChild(i)});
    lb.onclick=()=>lb.remove();document.body.appendChild(lb)}catch(e){toast(e.message)}}
async function approve(s,btn){
  btn.disabled=true;
  try{const{submission:d}=await api('GET','/api/admin/submissions?id='+s.id);
    await save([...runs,{id:s.id,name:d.name,ms:d.ms,client:d.client||'',video:d.video||'',img:d.img||''}],s.id);
    subs=subs.filter(x=>x.id!==s.id);drawSubs();drawBoard();toast('Approved')}
  catch(e){toast(e.message);btn.disabled=false}}
async function reject(s){
  if(!confirm('Reject and delete this submission from '+s.name+'?'))return;
  try{await api('DELETE','/api/admin/submissions',{id:s.id});subs=subs.filter(x=>x.id!==s.id);drawSubs();toast('Rejected')}
  catch(e){toast(e.message)}}
function drawSubs(){
  const box=$('subs');box.textContent='';$('scount').textContent=subs.length;
  if(!subs.length){box.appendChild(el('div','empty','No pending submissions.'));return}
  subs.forEach(s=>{
    const c=el('article','card sub'),info=el('div','info');
    info.appendChild(el('h3',null,s.name+' \u2013 '+fmt(s.ms)));
    info.appendChild(el('div','by',s.client?('client: '+s.client):'client not given'));
    const m=el('div','meta');m.appendChild(el('span',null,new Date(s.at).toLocaleString()));
    if(s.video){const a=el('a',null,'Recording');a.href=s.video;a.target='_blank';a.rel='noopener noreferrer';m.appendChild(a)}
    info.appendChild(m);c.appendChild(info);
    const b=el('div','btns');
    const pr=el('button','btn ghost','View proof ('+s.proofCount+')');pr.onclick=()=>viewProof(s.id);
    const ap=el('button','btn','Approve');ap.onclick=()=>approve(s,ap);
    const rj=el('button','btn red','Reject');rj.onclick=()=>reject(s);
    b.append(pr,ap,rj);c.appendChild(b);$('subs').appendChild(c)})}
async function enter(){
  const s=await api('GET','/api/admin/submissions');
  subs=s.submissions;runs=await loadRuns();
  $('login').hidden=true;$('panel').hidden=false;
  admin=initAdmin({getRuns:()=>runs,setRuns:async n=>{await save(n);drawBoard()}});
  drawSubs();drawBoard()}
$('lf').addEventListener('submit',async e=>{e.preventDefault();pw=$('pw').value;
  try{await enter();sessionStorage.setItem('tcl.pw',pw)}catch(err){$('lmsg').textContent=err.status===401?'Wrong password.':err.message}});
$('logout').onclick=()=>{sessionStorage.removeItem('tcl.pw');location.reload()};
if(pw)enter().catch(()=>sessionStorage.removeItem('tcl.pw'));

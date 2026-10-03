import{loadRuns}from'./store.js';
import{renderBoard}from'./render.js';
import{initAdmin}from'./admin.js';
import{initTheme}from'./theme.js';
import{buildTabs}from'./tabs.js';
import{CATS,inCat}from'./cats.js';
import{fmt,el,ico,toast}from'./utils.js';
const $=id=>document.getElementById(id);
initTheme();
let pw=sessionStorage.getItem('tcl.pw')||'',runs=[],subs=[],admin,pane='subs',cat=7,qs='',ql='';
async function api(method,url,body){
  const r=await fetch(url,{method,headers:{'Content-Type':'application/json','x-admin-password':pw},body:body?JSON.stringify(body):undefined});
  const j=await r.json().catch(()=>({}));
  if(!r.ok){const e=new Error(j.error||('Error '+r.status));e.status=r.status;throw e}
  return j}
const save=async(next,rm)=>{await api('POST','/api/admin/runs',{runs:next,removeSubmission:rm});runs=next};
const confirmBox=(title,text,ok)=>new Promise(res=>{
  const d=$('dlg');$('dt').textContent=title;$('dm').textContent=text;$('dok').textContent=ok;
  d.returnValue='';d.onclose=()=>res(d.returnValue==='ok');d.showModal()});
function drawTabs(){
  const box=$('atabs');box.textContent='';
  [['subs','Submissions',subs.length],['lb','Leaderboard',runs.length]].forEach(([k,l,n])=>{
    const b=el('button','tab',l);b.type='button';b.setAttribute('aria-selected',String(pane===k));
    b.appendChild(el('i',null,String(n)));b.onclick=()=>{pane=k;drawAll()};box.appendChild(b)});
  $('pane-subs').hidden=pane!=='subs';$('pane-lb').hidden=pane!=='lb'}
async function viewProof(id){
  try{
    const{submission:d}=await api('GET','/api/admin/submissions?id='+id);
    const lb=el('div','lb'),top=el('div','lbtop');
    function close(){lb.remove();document.removeEventListener('keydown',key)}
    function key(e){if(e.key==='Escape')close()}
    const x=el('button','btn ghost sm','Close');x.type='button';x.onclick=close;
    top.append(el('b',null,d.name+' \u2013 '+(d.cat||7)+' frame \u2013 '+fmt(d.ms)),x);lb.appendChild(top);
    d.proofs.forEach(p=>{const i=el('img');i.src=p;i.alt='Proof';lb.appendChild(i)});
    document.addEventListener('keydown',key);document.body.appendChild(lb)
  }catch(e){toast(e.message)}}
async function approve(s,btn){
  btn.disabled=true;
  try{
    const{submission:d}=await api('GET','/api/admin/submissions?id='+s.id);
    await save([...runs,{id:s.id,name:d.name,ms:d.ms,cat:d.cat||7,client:d.client||'',video:d.video||'',img:d.img||''}],s.id);
    subs=subs.filter(x=>x.id!==s.id);drawAll();toast('Approved and added to the leaderboard')
  }catch(e){toast(e.message);btn.disabled=false}}
async function reject(s){
  if(!await confirmBox('Reject submission?','This permanently deletes the submission from '+s.name+' and its proof images.','Reject'))return;
  try{await api('DELETE','/api/admin/submissions',{id:s.id});subs=subs.filter(x=>x.id!==s.id);drawAll();toast('Rejected')}
  catch(e){toast(e.message)}}
function drawSubs(){
  const box=$('subs');box.textContent='';
  const q=qs.toLowerCase(),list=subs.filter(s=>!q||(s.name+' '+(s.client||'')).toLowerCase().includes(q));
  if(!list.length){box.appendChild(el('div','empty',subs.length?'No matches.':'Nothing to review. New submissions will show up here.'));return}
  list.forEach(s=>{
    const c=el('article','scard');
    const th=el('button','sthumb');th.type='button';th.title='View proof';th.onclick=()=>viewProof(s.id);
    if(s.thumb){const i=el('img');i.src=s.thumb;i.alt='';th.appendChild(i)}else th.appendChild(ico('image'));
    const info=el('div');
    info.appendChild(el('h3',null,s.name+' \u2013 '+fmt(s.ms)));
    const l1=el('div','line');l1.append(el('span','badge',(s.cat||7)+' frame'),el('span',null,s.client?('client: '+s.client):'client not given'));
    const l2=el('div','line');l2.appendChild(el('span',null,new Date(s.at).toLocaleString()));
    l2.appendChild(el('span',null,s.proofCount+' proof image'+(s.proofCount===1?'':'s')));
    if(s.video){const a=el('a',null,'Recording');a.href=s.video;a.target='_blank';a.rel='noopener noreferrer';l2.appendChild(a)}
    info.append(l1,l2);
    const act=el('div','sact');
    const ap=el('button','btn sm','Approve');ap.onclick=()=>approve(s,ap);
    const pr=el('button','btn ghost sm','View proof');pr.onclick=()=>viewProof(s.id);
    const rj=el('button','btn red sm','Reject');rj.onclick=()=>reject(s);
    act.append(ap,pr,rj);c.append(th,info,act);box.appendChild(c)})}
function drawLb(){
  buildTabs($('ctabs'),CATS,cat,c=>{cat=c;drawLb()},c=>inCat(runs,c).length);
  renderBoard(runs,{cat,query:ql,admin:true,onEdit:r=>admin.startEdit(r),
    onDelete:async r=>{
      if(!await confirmBox('Remove run?','"'+r.name+'" will be removed from the leaderboard.','Remove'))return;
      try{await save(runs.filter(q=>q.id!==r.id));drawAll();toast('Removed')}catch(e){toast(e.message)}}})}
const drawAll=()=>{drawTabs();drawSubs();drawLb()};
async function enter(){
  const s=await api('GET','/api/admin/submissions');
  subs=s.submissions;runs=await loadRuns();
  $('login').hidden=true;$('panel').hidden=false;
  admin=initAdmin({getRuns:()=>runs,setRuns:async n=>{await save(n);drawAll()}});
  drawAll()}
$('qs').addEventListener('input',e=>{qs=e.target.value.trim();drawSubs()});
$('ql').addEventListener('input',e=>{ql=e.target.value.trim();drawLb()});
$('addrun').onclick=()=>admin.startNew(cat);
$('lf').addEventListener('submit',async e=>{e.preventDefault();pw=$('pw').value;
  try{await enter();sessionStorage.setItem('tcl.pw',pw)}catch(err){$('lmsg').textContent=err.status===401?'Wrong password.':err.message}});
$('logout').onclick=()=>{sessionStorage.removeItem('tcl.pw');location.reload()};
if(pw)enter().catch(()=>sessionStorage.removeItem('tcl.pw'));

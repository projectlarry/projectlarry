import{loadRuns}from'./store.js';
import{renderBoard}from'./render.js';
import{initAdmin}from'./admin.js';
import{initTheme}from'./theme.js';
import{buildTabs}from'./tabs.js';
import{CATS,inCat}from'./cats.js';
import{fmt,el,ico,toast,safeImg}from'./utils.js';
const $=id=>document.getElementById(id);
initTheme();
let pw=sessionStorage.getItem('tcl.pw')||'',runs=[],subs=[],offers={pending:[],approved:[]},timers=[],toff=0,admin,pane='subs',cat=7,qs='',ql='';
async function api(method,url,body){
  const r=await fetch(url,{method,headers:{'Content-Type':'application/json','x-admin-password':pw},body:body?JSON.stringify(body):undefined});
  const j=await r.json().catch(()=>({}));
  if(!r.ok){const e=new Error(j.error||('Error '+r.status));e.status=r.status;throw e}
  return j}
const save=async(next,rm)=>{await api('POST','/api/admin/runs',{runs:next,removeSubmission:rm});runs=next};
const confirmBox=(title,text,ok)=>new Promise(res=>{
  const d=$('dlg');$('dt').textContent=title;$('dm').textContent=text;$('dok').textContent=ok;
  d.returnValue='';d.onclose=()=>res(d.returnValue==='ok');d.showModal()});
const PANES=['subs','lb','offers','timers'];
function drawTabs(){
  const box=$('atabs');box.textContent='';
  [['subs','Submissions',subs.length],['lb','Leaderboard',runs.length],['offers','Offers',offers.pending.length],['timers','Timers',timers.filter(t=>!t.stop).length]].forEach(([k,l,n])=>{
    const b=el('button','tab',l);b.type='button';b.setAttribute('aria-selected',String(pane===k));
    b.appendChild(el('i',null,String(n)));b.onclick=()=>{pane=k;drawAll()};box.appendChild(b)});
  PANES.forEach(k=>{$('pane-'+k).hidden=pane!==k})}
async function viewProof(id){
  try{
    const{submission:d}=await api('GET','/api/admin/submissions?id='+id);
    const lb=el('div','lb'),top=el('div','lbtop');
    function close(){lb.remove();document.removeEventListener('keydown',key)}
    function key(e){if(e.key==='Escape')close()}
    const x=el('button','btn ghost sm','Close');x.type='button';x.onclick=close;
    top.append(el('b',null,d.name+' \u2013 '+(d.cat||7)+' frame \u2013 '+fmt(d.ms)+(d.verified?' (timer verified)':'')),x);lb.appendChild(top);
    d.proofs.forEach(p=>{const i=el('img');i.src=p;i.alt='Proof';lb.appendChild(i)});
    document.addEventListener('keydown',key);document.body.appendChild(lb)
  }catch(e){toast(e.message)}}
async function approve(s,btn){
  btn.disabled=true;
  try{
    const{submission:d}=await api('GET','/api/admin/submissions?id='+s.id);
    await save([...runs,{id:s.id,name:d.name,ms:d.ms,cat:d.cat||7,client:d.client||'',video:d.video||'',img:d.img||'',verified:!!d.verified}],s.id);
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
    if(s.verified)l1.appendChild(el('span','vbadge','Timer verified'));
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
// offers
async function offerAct(body,msg){
  try{await api('POST','/api/admin/offers',body);offers=await api('GET','/api/admin/offers');drawAll();toast(msg)}
  catch(e){toast(e.message)}}
function offerCard(o,live){
  const c=el('article','scard ocard');
  const a=el('img','ava');a.src=safeImg(o.avatar);a.alt='';
  const info=el('div');info.appendChild(el('h3',null,'@'+o.discord));
  const l1=el('div','line');l1.append(el('span','badge',o.cat+' frame'),el('span','badge',o.status==='taken'?'Taken':'Open'));
  info.append(l1,el('p','odesc',o.desc),el('div','line',new Date(o.at).toLocaleString()));
  const act=el('div','sact');
  if(live){
    const t=el('button','btn ghost sm',o.status==='taken'?'Mark open':'Mark taken');t.onclick=()=>offerAct({action:'status',id:o.id,status:o.status==='taken'?'open':'taken'},'Updated');
    const d=el('button','btn red sm','Delete');d.onclick=async()=>{if(await confirmBox('Delete offer?','This removes the offer from the bulletin.','Delete'))offerAct({action:'delete',id:o.id},'Deleted')};
    act.append(t,d)
  }else{
    const ap=el('button','btn sm','Approve');ap.onclick=()=>offerAct({action:'approve',id:o.id},'Offer is live');
    const rj=el('button','btn red sm','Reject');rj.onclick=async()=>{if(await confirmBox('Reject offer?','This permanently deletes the offer.','Reject'))offerAct({action:'reject',id:o.id},'Rejected')};
    act.append(ap,rj)}
  c.append(a,info,act);return c}
function drawOffers(){
  const p=$('opend'),l=$('olive');p.textContent='';l.textContent='';
  if(!offers.pending.length)p.appendChild(el('div','empty','No pending offers.'));
  offers.pending.forEach(o=>p.appendChild(offerCard(o,false)));
  if(!offers.approved.length)l.appendChild(el('div','empty','No live offers yet.'));
  offers.approved.forEach(o=>l.appendChild(offerCard(o,true)))}
// timers
async function loadTimers(){const j=await api('GET','/api/admin/timers');timers=j.timers;toff=j.now-Date.now()}
async function timerAct(body,msg){
  try{await api('POST','/api/admin/timers',body);await loadTimers();drawAll();toast(msg)}catch(e){toast(e.message)}}
function drawTimers(){
  const box=$('tlist');box.textContent='';
  if(!timers.length){box.appendChild(el('div','empty','No timers right now.'));return}
  timers.forEach(t=>{
    const c=el('article','scard tcard'),info=el('div');
    info.appendChild(el('h3',null,t.name));
    const l1=el('div','line');l1.append(el('span','badge',t.cat+' frame'),
      el('span',null,t.stop?('Stopped, final time '+fmt(t.stop-t.start)):('Running for '+fmt(Math.floor((Date.now()+toff-t.start)/1000)*1000))));
    const l2=el('div','line',new Date(t.start).toLocaleString()+(t.client?(', client: '+t.client):''));
    info.append(l1,l2);
    const act=el('div','sact');
    const rl=el('button','btn ghost sm','Reset limit');rl.onclick=()=>timerAct({action:'resetLimit',id:t.id},'Limit reset for this person');
    const rm=el('button','btn red sm','Remove');rm.onclick=async()=>{if(await confirmBox('Remove timer?','The timer is deleted and the designer will be taken off Upcoming runs.','Remove'))timerAct({action:'remove',id:t.id},'Removed')};
    act.append(rl,rm);c.append(info,act);box.appendChild(c)})}
const drawAll=()=>{drawTabs();drawSubs();drawLb();drawOffers();drawTimers()};
async function enter(){
  const s=await api('GET','/api/admin/submissions');
  subs=s.submissions;runs=await loadRuns();
  offers=await api('GET','/api/admin/offers').catch(()=>({pending:[],approved:[]}));
  await loadTimers().catch(()=>{timers=[]});
  $('login').hidden=true;$('panel').hidden=false;
  admin=initAdmin({getRuns:()=>runs,setRuns:async n=>{await save(n);drawAll()}});
  drawAll()}
$('qs').addEventListener('input',e=>{qs=e.target.value.trim();drawSubs()});
$('ql').addEventListener('input',e=>{ql=e.target.value.trim();drawLb()});
$('addrun').onclick=()=>admin.startNew(cat);
$('trefresh').onclick=async()=>{try{await loadTimers();drawAll()}catch(e){toast(e.message)}};
$('treset').onclick=async()=>{if(await confirmBox('Reset all limits?','Everyone gets their 2 timer starts back.','Reset'))timerAct({action:'resetAll'},'All limits reset')};
$('lf').addEventListener('submit',async e=>{e.preventDefault();pw=$('pw').value;
  try{await enter();sessionStorage.setItem('tcl.pw',pw)}catch(err){$('lmsg').textContent=err.status===401?'Wrong password.':err.message}});
$('logout').onclick=()=>{sessionStorage.removeItem('tcl.pw');location.reload()};
if(pw)enter().catch(()=>sessionStorage.removeItem('tcl.pw'));

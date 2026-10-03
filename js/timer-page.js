import{stagger}from './motion.js';
import{fmt,el,toast}from'./utils.js';
import{CATS}from'./cats.js';
import{initTheme}from'./theme.js';
const $=id=>document.getElementById(id);
initTheme($('theme'));
const KEY='tcl.timer';
let st=null,off=0,cat=7,tk=null;
try{st=JSON.parse(localStorage.getItem(KEY)||'null')}catch{}
const persist=()=>{try{if(st)localStorage.setItem(KEY,JSON.stringify(st));else localStorage.removeItem(KEY)}catch{}};
async function api(body){
  const r=await fetch('/api/timer',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
  const j=await r.json().catch(()=>({}));
  if(!r.ok){const e=new Error(j.error||'Something went wrong. Try again.');e.status=r.status;throw e}
  return j}
const dur=ms=>fmt(Math.max(0,Math.floor(ms/1000))*1000);
const pretty=c=>String(c).replace(/(.{4})/g,'$1-').replace(/-$/,'');
const confirmBox=(title,text,ok)=>new Promise(res=>{
  const d=$('dlg');$('dt').textContent=title;$('dm').textContent=text;$('dok').textContent=ok;
  d.returnValue='';d.onclose=()=>res(d.returnValue==='ok');d.showModal()});
const drawCats=()=>{const box=$('cats');box.textContent='';
  CATS.forEach(c=>{const b=el('button','pillbtn',c+' frame');b.type='button';b.setAttribute('role','radio');b.setAttribute('aria-checked',String(c===cat));if(c===7)b.classList.add('standard-7-frame');b.onclick=()=>{cat=c;drawCats()};box.appendChild(b)})};
drawCats();
function render(){
  const v=!st?'start':st.stop?'done':'run';
  ['start','run','done'].forEach(x=>$('view-'+x).hidden=x!==v);
  clearInterval(tk);
  if(v==='run'){
    $('r-name').textContent=st.name;$('r-cat').textContent=st.cat+' frame';$('code').textContent=pretty(st.code);
    const t=()=>{$('clock').textContent=dur(Date.now()+off-st.start)};t();tk=setInterval(t,1000)}
  if(v==='done'){$('d-time').textContent=fmt(st.stop-st.start);$('d-name').textContent=st.name;$('d-cat').textContent=st.cat+' frame'}}
$('sf').addEventListener('submit',async e=>{
  e.preventDefault();$('e-start').textContent='';
  const name=$('n').value.trim();if(!name){$('e-start').textContent='Enter your name';return}
  const btn=$('go');btn.disabled=true;btn.textContent='Starting...';
  try{const j=await api({action:'start',name,cat,client:$('c').value.trim()});
    st=j;off=j.now-Date.now();persist();render()}
  catch(err){$('e-start').textContent=err.message}
  btn.disabled=false;btn.textContent='Start timer'});
$('rb').onclick=async()=>{
  $('e-resume').textContent='';const code=$('rc').value.trim();if(!code){$('e-resume').textContent='Enter your resume code';return}
  try{const j=await api({action:'resume',code});st=j;off=j.now-Date.now();persist();render()}
  catch(err){$('e-resume').textContent=err.message}};
$('stop').onclick=async()=>{
  if(!await confirmBox('Stop the timer?','This ends your run. You cannot restart it afterwards.','Stop timer'))return;
  try{const j=await api({action:'stop',id:st.id,code:st.code});st.stop=j.stop;persist();render()}
  catch(err){toast(err.message)}};
$('cancel').onclick=async()=>{
  if(!await confirmBox('Cancel the timer?','This deletes your timer. If you cancel within 2 minutes of starting, it does not count against your limit of 2 starts per 3 days.','Cancel timer'))return;
  try{const j=await api({action:'cancel',id:st.id,code:st.code});st=null;persist();render();toast(j.refunded?'Cancelled. This start was not counted.':'Timer cancelled.')}
  catch(err){toast(err.message)}};
$('discard').onclick=async()=>{
  if(!await confirmBox('Discard this time?','Your stopped timer will be deleted and you will not be able to submit it.','Discard'))return;
  try{await api({action:'cancel',id:st.id,code:st.code})}catch{}
  st=null;persist();render()};
$('copy').onclick=()=>{navigator.clipboard.writeText(st.code).then(()=>toast('Resume code copied'),()=>toast(st.code))};
(async()=>{
  if(st){try{const j=await api({action:'resume',code:st.code});st=j;off=j.now-Date.now();persist()}catch(e){if(e.status===404){st=null;persist()}}}
  render()})();


requestAnimationFrame(()=>{
  stagger(document.querySelector('#upcoming'));
  stagger(document.querySelector('#board'));
});

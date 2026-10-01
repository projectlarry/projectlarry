import{loadRuns,saveRuns,resetRuns,exportRuns}from'./store.js';
import{renderBoard}from'./render.js';
import{initAdmin}from'./admin.js';
import{initTheme}from'./theme.js';
import{ADMIN_HASH}from'./config.js';
const $=id=>document.getElementById(id);
initTheme();
const sha=async s=>[...new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(s)))].map(b=>b.toString(16).padStart(2,'0')).join('');
let runs=[],admin;
const draw=()=>renderBoard(runs,{admin:true,onEdit:r=>admin.startEdit(r),onDelete:r=>update(runs.filter(q=>q.id!==r.id))});
function update(n){runs=n;saveRuns(runs);draw()}
async function enter(){
  $('login').hidden=true;$('panel').hidden=false;
  admin=initAdmin({getRuns:()=>runs,setRuns:update,onReset:async()=>{resetRuns();runs=await loadRuns();draw()},onExport:()=>exportRuns(runs)});
  try{runs=await loadRuns();draw()}
  catch(e){$('board').textContent='Could not load data/runs.json: '+e.message}}
$('lf').addEventListener('submit',async e=>{e.preventDefault();
  if(!crypto.subtle){$('lmsg').textContent='Needs https:// or localhost.';return}
  if(await sha($('pw').value)===ADMIN_HASH){sessionStorage.setItem('tcl.auth','1');enter()}else{$('lmsg').textContent='Wrong password.';$('pw').select()}});
$('logout').onclick=()=>{sessionStorage.removeItem('tcl.auth');location.reload()};
if(sessionStorage.getItem('tcl.auth')==='1')enter();
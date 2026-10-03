import{fmt}from'./utils.js';
let st=null;try{st=JSON.parse(localStorage.getItem('tcl.timer')||'null')}catch{}
if(st&&st.stop){
  const $=id=>document.getElementById(id);
  window.__timer={id:st.id,code:st.code};
  $('n').value=st.name||'';$('c').value=st.client||'';
  $('t').value=fmt(st.stop-st.start);$('t').readOnly=true;$('t').dispatchEvent(new Event('input'));
  const pill=[...document.querySelectorAll('#cats button')].find(b=>b.textContent===st.cat+' frame');if(pill)pill.click();
  const b=document.createElement('div');b.className='tbanner';
  const s=document.createElement('span');s.textContent='Using your timer: '+fmt(st.stop-st.start)+'. This run will be marked timer verified.';
  const x=document.createElement('button');x.type='button';x.textContent='Use a manual time instead';
  x.onclick=()=>{window.__timer=null;$('t').readOnly=false;b.remove()};
  b.append(s,x);$('f').parentNode.insertBefore(b,$('f'))}

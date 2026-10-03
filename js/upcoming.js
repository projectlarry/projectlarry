import{el,fmt}from'./utils.js';
export function initUpcoming(){
  const box=document.getElementById('upcoming');if(!box)return;
  const list=box.querySelector('.up-list');let timers=[],off=0;
  const dur=ms=>fmt(Math.max(0,Math.floor(ms/1000))*1000);
  const tick=()=>list.querySelectorAll('.up-time').forEach(s=>{s.textContent='Running for '+dur(Date.now()+off-Number(s.dataset.start))});
  function draw(){
    list.textContent='';box.hidden=!timers.length;
    timers.forEach(t=>{const c=el('div','up-card');c.appendChild(el('b',null,t.name));c.appendChild(el('span','up-cat',t.cat+' frame'));
      const s=el('span','up-time');s.dataset.start=String(t.start);c.appendChild(s);list.appendChild(c)});
    tick()}
  async function load(){
    try{const r=await fetch('/api/timers');if(!r.ok)return;const j=await r.json();off=j.now-Date.now();timers=j.timers||[];draw()}catch{}}
  load();setInterval(load,60000);setInterval(tick,1000)}

import{fmt,safeUrl,safeImg,el,ico,toast}from'./utils.js';
import{assetUrl}from'./store.js';
import{inCat}from'./cats.js';
export const sorted=(runs,cat)=>(cat?inCat(runs,cat):runs).slice().sort((a,b)=>a.ms-b.ms);
export function renderStats(runs,cat){
  const s=sorted(runs,cat),box=document.getElementById('stats');box.textContent='';
  const avg=s.length?s.reduce((a,r)=>a+r.ms,0)/s.length:0;
  [['Runs',s.length],['Fastest',s.length?fmt(s[0].ms):'\u2014'],['Average',s.length?fmt(Math.round(avg)):'\u2014'],['Lead over #2',s.length>1?'+'+fmt(s[1].ms-s[0].ms):'\u2014']]
   .forEach(([l,v])=>{const d=el('div','stat');d.append(el('b',null,String(v)),el('span',null,l));box.appendChild(d)})}
export function renderBoard(runs,{cat=7,query='',admin=false,onEdit,onDelete}={}){
  const board=document.getElementById('board'),all=sorted(runs,cat),q=query.toLowerCase();board.textContent='';
  const rows=all.map((r,i)=>({r,rank:i+1})).filter(({r})=>!q||(r.name+' '+(r.client||'')).toLowerCase().includes(q));
  if(!rows.length){const e=el('div','empty');e.appendChild(ico('trophy'));e.appendChild(el('div',null,q?'No matches.':'No '+cat+' frame runs yet. Be the first on the list.'));board.appendChild(e);return}
  rows.forEach(({r,rank})=>{
    const card=el('article','card');card.id='run-'+r.id;
    const th=el('div','thumb'),img=safeImg(r.img);
    if(img){const im=el('img');im.src=assetUrl(img);im.alt=r.name;im.loading='lazy';th.appendChild(im)}else th.appendChild(ico('image'));
    card.appendChild(th);
    const info=el('div','info');info.appendChild(el('h3',null,'#'+rank+' \u2013 '+r.name));
    if(r.client){const by=el('div','by','commissioned by ');by.appendChild(el('u',null,r.client));info.appendChild(by)}
    else info.appendChild(el('div','by','client not listed'));
    const meta=el('div','meta');meta.appendChild(el('strong',null,fmt(r.ms)));
    if(r.verified)meta.appendChild(el('span','vbadge','Timer verified'));
    if(rank>1)meta.appendChild(el('span',null,'\u2014 +'+fmt(r.ms-all[0].ms)+' behind #1'));
    const link=safeUrl(r.video||'');
    if(link){const a=el('a',null,'Watch proof');a.href=link;a.target='_blank';a.rel='noopener noreferrer';meta.appendChild(a)}
    info.appendChild(meta);card.appendChild(info);
    const acts=el('div','acts');
    const cp=el('button');cp.title='Copy link';cp.setAttribute('aria-label','Copy link');cp.appendChild(ico('link'));
    cp.onclick=()=>{const u=location.origin+location.pathname.replace(/admin\/?$/,'')+'#run-'+r.id;(navigator.clipboard?navigator.clipboard.writeText(u):Promise.reject()).then(()=>toast('Link copied'),()=>toast(u))};
    acts.appendChild(cp);
    if(admin){const ed=el('button');ed.title='Edit';ed.appendChild(ico('edit'));ed.onclick=()=>onEdit(r);
      const x=el('button','del');x.title='Remove';x.appendChild(ico('trash'));x.onclick=()=>onDelete(r);acts.append(ed,x)}
    card.appendChild(acts);board.appendChild(card)})}

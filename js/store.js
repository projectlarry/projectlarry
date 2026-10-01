const KEY='tcl.runs.v1',U=p=>new URL('../'+p,import.meta.url);
export const assetUrl=p=>/^(data:|https?:)/.test(p)?p:U(p).href;
export async function loadRuns(){
  try{const l=localStorage.getItem(KEY);if(l)return JSON.parse(l).runs||[]}catch{}
  const r=await fetch(U('data/runs.json'));return(await r.json()).runs||[]}
export const saveRuns=runs=>{try{localStorage.setItem(KEY,JSON.stringify({runs}))}catch{}};
export const resetRuns=()=>{try{localStorage.removeItem(KEY)}catch{}};
export const exportRuns=runs=>{const a=document.createElement('a');
  a.href=URL.createObjectURL(new Blob([JSON.stringify({runs},null,2)],{type:'application/json'}));a.download='runs.json';a.click()};
export const loadGallery=()=>fetch(U('data/gallery.json')).then(r=>r.json()).catch(()=>[]);
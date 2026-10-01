const U=p=>new URL('../'+p,import.meta.url);
export const assetUrl=p=>/^(data:|https?:)/.test(p)?p:U(p).href;
export async function loadRuns(){
  try{const r=await fetch('/api/runs');if(r.ok){const j=await r.json();if(Array.isArray(j.runs))return j.runs}}catch{}
  const r=await fetch(U('data/runs.json'));return(await r.json()).runs||[]}
export const loadGallery=()=>fetch(U('data/gallery.json')).then(r=>r.json()).catch(()=>[]);

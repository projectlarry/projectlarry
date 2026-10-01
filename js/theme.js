export function initTheme(btn){
  const root=document.documentElement,saved=localStorage.getItem('tcl.theme');
  root.dataset.theme=saved||(matchMedia('(prefers-color-scheme:dark)').matches?'dark':'light');
  btn&&(btn.onclick=()=>{root.dataset.theme=root.dataset.theme==='dark'?'light':'dark';try{localStorage.setItem('tcl.theme',root.dataset.theme)}catch{}})}
export function initTheme(btn){
  const root=document.documentElement;
  let saved=null;

  try{
    saved=localStorage.getItem('tcl.theme');
  }catch{}

  // The inline theme boot script already applied this before CSS loaded.
  // Keep dark as the default if no preference exists.
  root.dataset.theme=saved||root.dataset.theme||'dark';

  if(btn){
    btn.onclick=()=>{
      const next=root.dataset.theme==='dark'?'light':'dark';
      root.dataset.theme=next;

      try{
        localStorage.setItem('tcl.theme',next);
      }catch{}
    };
  }
}

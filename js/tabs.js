import{el}from'./utils.js';

export function buildTabs(box,cats,active,onPick,count){
  box.textContent='';

  cats.forEach(c=>{
    const b=el('button','tab');
    b.type='button';
    b.setAttribute('role','tab');
    b.setAttribute('aria-selected',String(c===active));

    if(Number(c)===7){
      b.classList.add('standard-7-frame');
      b.dataset.standard='7-frame';
      b.title='The original 7 Frame standard';
    }

    b.appendChild(document.createTextNode(c+' frame'));

    if(count){
      b.appendChild(el('i',null,String(count(c))));
    }

    b.onclick=()=>onPick(c);
    box.appendChild(b);
  });
}

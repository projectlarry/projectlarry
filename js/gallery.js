import{el}from'./utils.js';
export function buildGallery(files){
  const track=document.getElementById('gallery-track');if(!files.length)return;track.textContent='';
  for(let r=0;r<5;r++){const row=el('div','gallery-row');row.style.animationDuration=(60+r*9)+'s';
    for(let k=0;k<2;k++){const set=el('div','gallery-set');
      for(let i=0;i<14;i++){const t=el('div','gallery-tile'),im=el('img');im.src='assets/img/gallery/'+files[(i+r*3)%files.length];im.alt='';im.loading='lazy';t.appendChild(im);set.appendChild(t)}
      row.appendChild(set)}
    track.appendChild(row)}}
export const fmt=ms=>{const s=Math.floor(ms/1000),h=Math.floor(s/3600),m=Math.floor(s%3600/60),sec=s%60;
  const f=ms%1000?('.'+String(ms%1000).padStart(3,'0').replace(/0+$/,'')):'';
  return h?`${h}h ${m}m ${sec}s`:m?`${m}m ${sec}${f}s`:`${sec}${f}s`};export const parse=str=>{str=str.trim();
  if(/[hms]/i.test(str)){const g=u=>{const x=str.match(new RegExp('([\\d.]+)\\s*'+u,'i'));return x?parseFloat(x[1]):0};
    const ms=Math.round((g('h')*3600+g('m')*60+g('s'))*1000);return ms>0?ms:null}
  const parts=str.split(':');if(parts.length<2||parts.length>3)return null;
  const sec=parseFloat(parts.pop()),nums=parts.map(Number);if(isNaN(sec)||nums.some(n=>isNaN(n)||n<0))return null;
  let ms=Math.round(sec*1000)+nums.pop()*60000;if(nums.length)ms+=nums.pop()*3600000;return ms>0?ms:null};export const safeUrl=u=>{try{const x=new URL(u);return/^https?:$/.test(x.protocol)?x.href:''}catch{return''}};
export const safeImg=u=>typeof u==='string'&&(/^data:image\/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$/.test(u)||/^[\w./-]+\.(jpe?g|png|webp)$/i.test(u))?u:'';
export const el=(tag,cls,text)=>{const e=document.createElement(tag);if(cls)e.className=cls;if(text!=null)e.textContent=text;return e};
const P={trophy:'M7 3h10v2h3v3a4 4 0 01-4 4h-.3A5 5 0 0113 14.9V17h3v2H8v-2h3v-2.1A5 5 0 018.3 12H8a4 4 0 01-4-4V5h3z',trash:'M6 7h12l-1 14H7zM9 3h6l1 2h4v2H4V5h4z',plus:'M11 5h2v6h6v2h-6v6h-2v-6H5v-2h6z',edit:'M3 17.25V21h3.75L17.8 9.94l-3.75-3.75zM20.7 7.04a1 1 0 000-1.41l-2.34-2.34a1 1 0 00-1.41 0l-1.83 1.83 3.75 3.75z',image:'M21 19V5a2 2 0 00-2-2H5a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2zM8.5 13.5l2.5 3 3.5-4.5 4.5 6H5z',link:'M10.6 13.4a4 4 0 005.7 0l3-3a4 4 0 00-5.7-5.7l-1 1 1.4 1.4 1-1a2 2 0 013 3l-3 3a2 2 0 01-2.8 0zm2.8-2.8a4 4 0 00-5.7 0l-3 3a4 4 0 005.7 5.7l1-1-1.4-1.4-1 1a2 2 0 01-3-3l3-3a2 2 0 012.8 0z'};
export const ico=n=>{const s=document.createElementNS('http://www.w3.org/2000/svg','svg');s.setAttribute('class','ico');s.setAttribute('viewBox','0 0 24 24');s.setAttribute('aria-hidden','true');
  const p=document.createElementNS('http://www.w3.org/2000/svg','path');p.setAttribute('d',P[n]);s.appendChild(p);return s};
let t;export const toast=m=>{let e=document.getElementById('toast');e.textContent=m;e.classList.add('show');clearTimeout(t);t=setTimeout(()=>e.classList.remove('show'),1800)};

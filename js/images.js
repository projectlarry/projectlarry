const load=file=>new Promise((res,rej)=>{const fr=new FileReader();fr.onerror=rej;fr.onload=()=>{const im=new Image();im.onerror=rej;im.onload=()=>res(im);im.src=fr.result};fr.readAsDataURL(file)});
export async function shrink(file,max=1100,q=.6){
  const im=await load(file),s=Math.min(1,max/Math.max(im.width,im.height)),c=document.createElement('canvas');
  c.width=Math.round(im.width*s);c.height=Math.round(im.height*s);
  const x=c.getContext('2d');x.fillStyle='#fff';x.fillRect(0,0,c.width,c.height);x.drawImage(im,0,0,c.width,c.height);
  return c.toDataURL('image/jpeg',q)}
export async function cover(file,W=412,H=232,q=.75){
  const im=await load(file),c=document.createElement('canvas');c.width=W;c.height=H;
  const x=c.getContext('2d'),s=Math.max(W/im.width,H/im.height),w=im.width*s,h=im.height*s;
  x.fillStyle='#fff';x.fillRect(0,0,W,H);x.drawImage(im,(W-w)/2,(H-h)/2,w,h);
  return c.toDataURL('image/jpeg',q)}

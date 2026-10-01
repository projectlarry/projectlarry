const{redis,ip,limit}=require('./_lib');
const IMG=/^data:image\/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$/;
const bad=(res,m)=>res.status(400).json({error:m});
module.exports=async(req,res)=>{
  if(req.method!=='POST')return res.status(405).json({error:'POST only'});
  try{
    const b=req.body||{};
    if(b.website)return res.status(200).json({ok:true});
    const name=String(b.name||'').trim().slice(0,40),client=String(b.client||'').trim().slice(0,60),ms=Math.round(Number(b.ms));
    let video=String(b.video||'').trim();
    if(!name)return bad(res,'Name is required');
    if(!(ms>0&&ms<3.6e9*1000))return bad(res,'Invalid time');
    if(video){try{const u=new URL(video);if(!/^https?:$/.test(u.protocol))throw 0;video=u.href.slice(0,300)}catch{return bad(res,'Recording link must start with http(s)://')}}
    const proofs=Array.isArray(b.proofs)?b.proofs.slice(0,3):[];
    const img=b.img?String(b.img):'';
    if(!proofs.length)return bad(res,'Add at least one proof image');
    if(!proofs.every(p=>typeof p==='string'&&IMG.test(p)))return bad(res,'Invalid image');
    if(img&&(!IMG.test(img)||img.length>120000))return bad(res,'Invalid card picture');
    if(proofs.join('').length+img.length>850000)return bad(res,'Images are too large. Use fewer or smaller ones.');
    if(!(await limit('sub:'+ip(req),5,3600)))return res.status(429).json({error:'Too many submissions. Try again in an hour.'});
    if((await redis('HLEN','subs'))>=100)return res.status(503).json({error:'Submissions are full right now. Try again later.'});
    const id=Date.now().toString(36)+Math.random().toString(36).slice(2,6);
    await redis('HSET','subs',id,JSON.stringify({id,name,ms,client,video,img,proofs,at:Date.now()}));
    res.status(200).json({ok:true});
  }catch(e){res.status(500).json({error:e.message})}
};

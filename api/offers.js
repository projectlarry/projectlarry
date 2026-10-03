const{redis,ip,limit,rid,hvals,jparse}=require('./_lib');
const IMG=/^data:image\/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$/;
const CATS=[3,5,7,12,15];
const bad=(res,m)=>res.status(400).json({error:m});
module.exports=async(req,res)=>{
  try{
    if(req.method==='GET'){
      const list=hvals(await redis('HGETALL','offers')).map(jparse).filter(Boolean);
      list.sort((x,y)=>((x.status==='taken')-(y.status==='taken'))||y.at-x.at);
      res.setHeader('Cache-Control','public, s-maxage=10, stale-while-revalidate=30');
      return res.status(200).json({offers:list});
    }
    if(req.method!=='POST')return res.status(405).json({error:'GET or POST only'});
    const b=req.body||{};
    if(b.website)return res.status(200).json({ok:true});
    const cat=Number(b.cat),desc=String(b.desc||'').trim(),discord=String(b.discord||'').trim().replace(/^@/,'').toLowerCase(),avatar=String(b.avatar||'');
    if(!CATS.includes(cat))return bad(res,'Pick a frame category');
    if(desc.length<20||desc.length>600)return bad(res,'The description must be 20 to 600 characters');
    if(!/^[a-z0-9_.]{2,32}$/.test(discord))return bad(res,'Enter your Discord username, like name or name_01');
    if(!IMG.test(avatar)||avatar.length>30000)return bad(res,'Add a profile picture');
    if(b.consent!==true)return bad(res,'Please tick the agreement box');
    if(!(await limit('offer:'+ip(req),3,3600)))return res.status(429).json({error:'Too many offers. Try again in an hour.'});
    if((await redis('HLEN','offers_pending'))>=50)return res.status(503).json({error:'Offers are full right now. Try again later.'});
    const id=rid(8);
    await redis('HSET','offers_pending',id,JSON.stringify({id,cat,desc,discord,avatar,status:'open',at:Date.now()}));
    res.status(200).json({ok:true});
  }catch(e){res.status(500).json({error:e.message})}
};

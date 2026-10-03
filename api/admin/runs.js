const{redis,admin}=require('../_lib');
module.exports=async(req,res)=>{
  if(!(await admin(req,res)))return;
  if(req.method!=='POST')return res.status(405).json({error:'POST only'});
  try{
    const b=req.body||{};
    if(!Array.isArray(b.runs)||b.runs.length>500)return res.status(400).json({error:'Invalid runs'});
    const clean=b.runs.map(r=>({id:String(r.id||'').slice(0,40),name:String(r.name||'').slice(0,40),ms:Math.round(Number(r.ms)),cat:[3,5,7,12,15].includes(Number(r.cat))?Number(r.cat):7,video:String(r.video||'').slice(0,300),client:String(r.client||'').slice(0,60),img:String(r.img||'').slice(0,200000)})).filter(r=>r.id&&r.name&&r.ms>0);
    const s=JSON.stringify(clean);
    if(s.length>950000)return res.status(400).json({error:'Leaderboard data is too large'});
    await redis('SET','runs',s);
    if(b.removeSubmission)await redis('HDEL','subs',String(b.removeSubmission));
    res.status(200).json({ok:true});
  }catch(e){res.status(500).json({error:e.message})}
};

const{redis,admin,hvals,jparse}=require('../_lib');
module.exports=async(req,res)=>{
  if(!(await admin(req,res)))return;
  try{
    if(req.method==='POST'){
      const b=req.body||{};
      if(b.action==='resetAll'){await redis('DEL','tlim');return res.status(200).json({ok:true})}
      const t=jparse(await redis('HGET','timers',String(b.id||'')));
      if(!t)return res.status(404).json({error:'Timer not found'});
      if(b.action==='resetLimit'){await redis('HDEL','tlim',t.ipk);return res.status(200).json({ok:true})}
      if(b.action==='remove'){await redis('HDEL','timers',t.id);await redis('HDEL','tcodes',t.code);return res.status(200).json({ok:true})}
      return res.status(400).json({error:'Unknown action'});
    }
    const list=hvals(await redis('HGETALL','timers')).map(jparse).filter(Boolean)
      .map(t=>({id:t.id,name:t.name,cat:t.cat,client:t.client,start:t.start,stop:t.stop})).sort((a,b)=>b.start-a.start);
    res.status(200).json({now:Date.now(),timers:list});
  }catch(e){res.status(500).json({error:e.message})}
};

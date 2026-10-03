const{redis,hvals,jparse}=require('./_lib');
const TTL=14*864e5;
module.exports=async(req,res)=>{
  res.setHeader('Cache-Control','no-store');
  try{
    const now=Date.now(),out=[];
    for(const t of hvals(await redis('HGETALL','timers')).map(jparse).filter(Boolean)){
      if((t.stop||t.start)+TTL<now){await redis('HDEL','timers',t.id);await redis('HDEL','tcodes',t.code);continue}
      if(!t.stop)out.push({id:t.id,name:t.name,cat:t.cat,start:t.start});
    }
    out.sort((a,b)=>a.start-b.start);
    res.status(200).json({now,timers:out});
  }catch(e){res.status(500).json({error:e.message})}
};

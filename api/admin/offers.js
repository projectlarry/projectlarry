const{redis,admin,hvals,jparse}=require('../_lib');
module.exports=async(req,res)=>{
  if(!(await admin(req,res)))return;
  try{
    if(req.method==='POST'){
      const b=req.body||{},id=String(b.id||'');
      if(b.action==='approve'){
        const o=jparse(await redis('HGET','offers_pending',id));if(!o)return res.status(404).json({error:'Offer not found'});
        await redis('HSET','offers',id,JSON.stringify(o));await redis('HDEL','offers_pending',id);
      }else if(b.action==='reject')await redis('HDEL','offers_pending',id);
      else if(b.action==='status'){
        const o=jparse(await redis('HGET','offers',id));if(!o)return res.status(404).json({error:'Offer not found'});
        o.status=b.status==='taken'?'taken':'open';await redis('HSET','offers',id,JSON.stringify(o));
      }else if(b.action==='delete')await redis('HDEL','offers',id);
      else return res.status(400).json({error:'Unknown action'});
      return res.status(200).json({ok:true});
    }
    const get=async k=>hvals(await redis('HGETALL',k)).map(jparse).filter(Boolean).sort((a,b)=>b.at-a.at);
    res.status(200).json({pending:await get('offers_pending'),approved:await get('offers')});
  }catch(e){res.status(500).json({error:e.message})}
};

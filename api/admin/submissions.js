const{redis,admin}=require('../_lib');
module.exports=async(req,res)=>{
  if(!(await admin(req,res)))return;
  try{
    if(req.method==='DELETE'){await redis('HDEL','subs',String((req.body||{}).id||''));return res.status(200).json({ok:true})}
    const id=req.query&&req.query.id;
    if(id){const v=await redis('HGET','subs',String(id));if(!v)return res.status(404).json({error:'Not found'});return res.status(200).json({submission:JSON.parse(v)})}
    const a=(await redis('HGETALL','subs'))||[];
    const vals=Array.isArray(a)?a.filter((_,i)=>i%2):Object.values(a);
    const list=[];
    for(const v of vals){try{const s=JSON.parse(v);list.push({id:s.id,name:s.name,ms:s.ms,client:s.client,video:s.video,cat:s.cat||7,thumb:s.thumb||'',at:s.at,proofCount:(s.proofs||[]).length})}catch{}}
    list.sort((x,y)=>y.at-x.at);
    res.status(200).json({submissions:list});
  }catch(e){res.status(500).json({error:e.message})}
};

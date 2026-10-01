const{redis}=require('./_lib');
module.exports=async(req,res)=>{
  try{
    const v=await redis('GET','runs');
    res.setHeader('Cache-Control','public, s-maxage=10, stale-while-revalidate=30');
    res.status(200).json({runs:v?JSON.parse(v):null});
  }catch(e){res.status(500).json({error:e.message})}
};

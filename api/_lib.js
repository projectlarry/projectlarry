const crypto=require('crypto');
const BASE=()=>process.env.KV_REST_API_URL||process.env.UPSTASH_REDIS_REST_URL;
const TOKEN=()=>process.env.KV_REST_API_TOKEN||process.env.UPSTASH_REDIS_REST_TOKEN;
async function redis(...cmd){
  const u=BASE(),t=TOKEN();
  if(!u||!t)throw new Error('Storage is not connected in Vercel yet');
  const r=await fetch(u,{method:'POST',headers:{Authorization:'Bearer '+t,'Content-Type':'application/json'},body:JSON.stringify(cmd)});
  const j=await r.json();
  if(!r.ok||j.error)throw new Error(j.error||('Storage error '+r.status));
  return j.result;
}
const ip=req=>String(req.headers['x-forwarded-for']||'').split(',')[0].trim()||'unknown';
async function limit(key,max,secs){
  const k='rl:'+key,n=await redis('INCR',k);
  if(n===1)await redis('EXPIRE',k,secs);
  return n<=max;
}
const sha=s=>crypto.createHash('sha256').update(String(s)).digest();
const same=(a,b)=>crypto.timingSafeEqual(sha(a),sha(b));
const ipk=req=>crypto.createHash('sha256').update('tcl|'+ip(req)).digest('hex').slice(0,20);
const rid=n=>{const a='abcdefghjkmnpqrstuvwxyz23456789',b=crypto.randomBytes(n);let s='';for(let i=0;i<n;i++)s+=a[b[i]%a.length];return s};
const hvals=a=>Array.isArray(a)?a.filter((_,i)=>i%2):Object.values(a||{});
const jparse=s=>{try{return JSON.parse(s)}catch{return null}};
async function admin(req,res){
  try{
    const pw=process.env.ADMIN_PASSWORD;
    if(!pw){res.status(500).json({error:'ADMIN_PASSWORD is not set in Vercel'});return false}
    const key='rl:fail:'+ip(req);
    if((Number(await redis('GET',key))||0)>=10){res.status(429).json({error:'Too many wrong attempts. Try again in 15 minutes.'});return false}
    if(!same(req.headers['x-admin-password']||'',pw)){
      const n=await redis('INCR',key);if(n===1)await redis('EXPIRE',key,900);
      res.status(401).json({error:'Wrong password'});return false}
    return true;
  }catch(e){res.status(500).json({error:e.message});return false}
}
module.exports={redis,ip,limit,admin,same,ipk,rid,hvals,jparse};

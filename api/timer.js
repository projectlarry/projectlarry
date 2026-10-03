const{redis,ip,limit,same,ipk,rid,jparse}=require('./_lib');
const CATS=[3,5,7,12,15],DAY=864e5,LIM=2,WIN=3*DAY,REFUND=120000;
const bad=(res,m,c)=>res.status(c||400).json({error:m});
const norm=c=>String(c||'').toLowerCase().replace(/[^a-z0-9]/g,'');
async function getLim(k){const o=jparse(await redis('HGET','tlim',k)),now=Date.now();return o&&o.exp>now?o:{n:0,exp:now+WIN}}
const setLim=(k,o)=>redis('HSET','tlim',k,JSON.stringify(o));
module.exports=async(req,res)=>{
  res.setHeader('Cache-Control','no-store');
  if(req.method!=='POST')return bad(res,'POST only',405);
  try{
    const b=req.body||{},now=Date.now();
    if(b.action==='start'){
      const name=String(b.name||'').trim().slice(0,40),client=String(b.client||'').trim().slice(0,60),cat=Number(b.cat);
      if(!name)return bad(res,'Enter your name');
      if(!CATS.includes(cat))return bad(res,'Pick a category');
      if((await redis('HLEN','timers'))>=300)return bad(res,'Too many timers are running right now. Try again later.',503);
      const k=ipk(req),l=await getLim(k);
      if(l.n>=LIM){const h=Math.ceil((l.exp-now)/36e5);return bad(res,'You have used both timer starts for this period. You can start again in about '+(h>=48?Math.ceil(h/24)+' days':h+' hours')+'.',429)}
      l.n++;await setLim(k,l);
      const id=rid(8),code=rid(12);
      await redis('HSET','timers',id,JSON.stringify({id,code,name,cat,client,start:now,stop:0,ipk:k}));
      await redis('HSET','tcodes',code,id);
      return res.status(200).json({id,code,name,cat,client,start:now,stop:0,now});
    }
    if(b.action==='resume'){
      if(!(await limit('tresume:'+ip(req),30,3600)))return bad(res,'Too many tries. Try again later.',429);
      const code=norm(b.code),id=await redis('HGET','tcodes',code),t=id&&jparse(await redis('HGET','timers',id));
      if(!t)return bad(res,'Timer not found. It may have expired.',404);
      return res.status(200).json({id:t.id,code:t.code,name:t.name,cat:t.cat,client:t.client,start:t.start,stop:t.stop,now});
    }
    const t=jparse(await redis('HGET','timers',String(b.id||'')));
    if(!t||!same(t.code,norm(b.code)))return bad(res,'Timer not found. It may have expired.',404);
    if(b.action==='stop'){
      if(!t.stop){t.stop=now;await redis('HSET','timers',t.id,JSON.stringify(t))}
      return res.status(200).json({stop:t.stop,ms:t.stop-t.start,now});
    }
    if(b.action==='cancel'){
      let refunded=false;
      if(!t.stop&&now-t.start<REFUND){const l=await getLim(t.ipk);if(l.n>0){l.n--;await setLim(t.ipk,l);refunded=true}}
      await redis('HDEL','timers',t.id);await redis('HDEL','tcodes',t.code);
      return res.status(200).json({ok:true,refunded});
    }
    return bad(res,'Unknown action');
  }catch(e){res.status(500).json({error:e.message})}
};

export const CATS=[3,5,7,12,15];
export const catOf=r=>CATS.includes(Number(r.cat))?Number(r.cat):7;
export const inCat=(runs,cat)=>runs.filter(r=>catOf(r)===cat);

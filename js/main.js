import{stagger}from './motion.js';
import{loadRuns,loadGallery}from'./store.js';
import{renderBoard,renderStats}from'./render.js';
import{buildGallery}from'./gallery.js';
import{initTheme}from'./theme.js';
import{buildTabs}from'./tabs.js';
import{initUpcoming}from'./upcoming.js';
import{CATS,catOf,inCat}from'./cats.js';
const $=id=>document.getElementById(id);
let runs=[],query='',cat=Number(localStorage.getItem('tcl.cat'))||7;
if(!CATS.includes(cat))cat=7;
initTheme($('theme'));
initUpcoming();
function draw(){
  buildTabs($('tabs'),CATS,cat,c=>{cat=c;try{localStorage.setItem('tcl.cat',c)}catch{}draw()},c=>inCat(runs,c).length);
  renderStats(runs,cat);renderBoard(runs,{cat,query})}
$('search').addEventListener('input',e=>{query=e.target.value.trim();draw()});
Promise.all([loadRuns(),loadGallery()]).then(([r,g])=>{
  runs=r;buildGallery(g);
  const m=location.hash.match(/^#run-(.+)$/),hit=m&&runs.find(x=>x.id===m[1]);if(hit)cat=catOf(hit);
  draw();if(m)document.getElementById('run-'+m[1])?.scrollIntoView()});


requestAnimationFrame(()=>{
  stagger(document.querySelector('#board'));
});

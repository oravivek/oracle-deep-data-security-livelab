import {readFileSync,writeFileSync} from 'node:fs';
import {resolve,dirname,relative,extname} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';

const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const modulePath=process.argv[2];
if(!modulePath) throw Error('Usage: node tools/build-preview.mjs /absolute/path/to/marked/lib/marked.esm.js');
const {marked}=await import(pathToFileURL(resolve(modulePath)).href);
const manifestPath=resolve(root,'workshops/livelabs/manifest.json');
const manifest=JSON.parse(readFileSync(manifestPath,'utf8'));
const escape=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
const paths=manifest.tutorials.map(t=>resolve(dirname(manifestPath),t.filename));
const pages=manifest.tutorials.map((t,i)=>{
  const path=paths[i];
  const md=readFileSync(path,'utf8').replace(/^<\/?copy>\s*$/gm,'');
  let html=marked.parse(md,{gfm:true});
  html=html.replace(/(href|src)="([^"]+)"/g,(all,attr,url)=>{
    if(/^(https?:|mailto:|#|data:)/.test(url))return all;
    const abs=resolve(dirname(path),decodeURI(url));
    const index=paths.indexOf(abs);
    if(index>=0)return `${attr}="#lab=${index}"`;
    if(attr==='src' && extname(abs)==='.svg')return `src="data:image/svg+xml;base64,${readFileSync(abs).toString('base64')}"`;
    return `${attr}="${escape(relative(root,abs).split('/').map(encodeURIComponent).join('/'))}"`;
  });
  return `<article class="lab" id="lab-${i}" ${i?'hidden':''} data-title="${escape(t.title)}">${html}</article>`;
});
const nav=manifest.tutorials.map((t,i)=>`<a href="#lab=${i}" data-lab="${i}" ${i?'':'aria-current="page"'}>${escape(t.title)}</a>`).join('\n');
const html=`<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${escape(manifest.workshoptitle)}</title>
<style>
:root{--ink:#272522;--accent:#8c4937;--nav:#f4f2ef;--border:#d8d4cf}*{box-sizing:border-box}
body{margin:0;color:var(--ink);font:16px/1.65 Arial,sans-serif;background:white}
header{background:#302d29;color:white;padding:17px 28px;position:sticky;top:0;z-index:2;display:flex;align-items:center;gap:20px}
header strong{font-size:21px}header span{font-size:13px;color:#e1dad3}header a{color:white;margin-left:auto;font-size:13px}
aside{position:fixed;top:70px;bottom:0;left:0;width:300px;background:var(--nav);overflow:auto;border-right:3px solid #a45b43;padding:23px 16px}
aside h2{font-size:15px;margin:0 10px 16px}nav a{display:block;padding:9px 12px;margin:3px 0;text-decoration:none;color:#72452e;font-size:14px;line-height:1.5}
nav a:hover,nav a[aria-current]{background:#e8e4df;border-left:3px solid var(--accent);padding-left:9px;font-weight:bold}
main{margin-left:300px;max-width:1500px;padding:30px 48px 70px}.breadcrumb{color:#756c64;font-size:13px;border-bottom:1px solid var(--border);padding-bottom:14px}
h1{font-size:31px;line-height:1.25;margin:28px 0 23px}h2{font-size:23px;line-height:1.35;margin:32px 0 14px}h3{font-size:18px;margin:25px 0 10px}
p{margin:12px 0}a{color:#86503b}li{margin:7px 0}code{font-family:ui-monospace,SFMono-Regular,Consolas,monospace;font-size:.91em}
pre{position:relative;white-space:pre-wrap;overflow-wrap:anywhere;background:#f6f5f3;border:1px solid var(--border);padding:43px 18px 18px;line-height:1.55;margin:20px 0;font-size:14px}
pre .copy{position:absolute;top:7px;right:8px;background:white;color:#4c4139;border:1px solid #aaa;padding:3px 12px;font-size:12px}
button{cursor:pointer;border:1px solid #6f6258;border-radius:3px;background:#4b4742;color:white;padding:8px 15px;font-size:14px}
button:hover{filter:brightness(.92)}button:focus-visible,a:focus-visible,summary:focus-visible{outline:3px solid #4086ac;outline-offset:3px}
.controls{display:flex;gap:10px;margin:20px 0}.controls:empty{display:none}details.task{border-bottom:1px solid var(--border);margin:14px 0}
details.task summary{font-weight:bold;font-size:21px;line-height:1.4;cursor:pointer;background:#faf9f7;padding:16px 18px}
details.task .task-body{padding:4px 18px 20px}table{border-collapse:collapse;width:100%;margin:20px 0;font-size:14px}th,td{border:1px solid var(--border);padding:11px 12px;text-align:left;vertical-align:middle}th{background:#eae7e2}
img{display:block;max-width:100%;height:auto;margin:25px 0}.page-nav{display:flex;gap:14px;justify-content:space-between;margin-top:35px;border-top:1px solid var(--border);padding-top:25px}
.page-nav a{padding:9px 15px;background:#f2efeb;text-decoration:none}footer{font-size:13px;color:#6e645c;margin-top:40px} [hidden]{display:none!important}
@media(max-width:850px){aside{position:static;width:auto;border-right:0;border-bottom:2px solid var(--accent)}header{position:static;flex-wrap:wrap}header a{margin-left:0}main{margin-left:0;padding:20px}nav a{display:inline-block}table{display:block;overflow-x:auto}}
@media print{header,aside,.controls,.copy,.page-nav,.breadcrumb{display:none!important}main{margin:0;padding:0}.lab[hidden]{display:block!important}.lab{break-before:page}details.task>.task-body{display:block!important}}
</style></head><body>
<header><strong>Deep Data Security</strong><span>Custom LiveLabs workshop · Local preview</span><a href="workshops/livelabs/">Open sample renderer</a></header>
<aside><h2>${escape(manifest.workshoptitle)}</h2><nav aria-label="Workshop labs">${nav}</nav></aside>
<main><div class="breadcrumb" id="breadcrumb">Introduction</div><div class="controls" id="controls"></div>
${pages.join('\n')}<div class="page-nav" id="page-nav"></div>
<footer>Custom workshop content · Updated 23 November 2026 · Expected results must be verified in your configured lab.</footer></main>
<script>
const labs=[...document.querySelectorAll('article.lab')];
labs.forEach(lab=>{
 const headings=[...lab.querySelectorAll('h2')].filter(h=>/^Task \\d+:/.test(h.textContent));
 headings.forEach(heading=>{
  const details=document.createElement('details');details.className='task';
  const summary=document.createElement('summary');summary.textContent=heading.textContent;
  const body=document.createElement('div');body.className='task-body';
  let next=heading.nextSibling;
  while(next && !(next.nodeType===1&&next.tagName==='H2')){const following=next.nextSibling;body.append(next);next=following;}
  heading.replaceWith(details);details.append(summary,body);
 });
 lab.querySelectorAll('pre').forEach(pre=>{
  const button=document.createElement('button');button.className='copy';button.textContent='Copy';button.type='button';
  button.setAttribute('aria-label','Copy command block');
  button.addEventListener('click',async()=>{
   const content=pre.querySelector('code').textContent;
   button.textContent='Copying...';
   try{await Promise.race([navigator.clipboard.writeText(content),new Promise((_,reject)=>setTimeout(()=>reject(Error('Clipboard unavailable')),900))]);button.textContent='Copied';}
   catch{const area=document.createElement('textarea');area.value=content;document.body.append(area);area.select();let copied=false;try{copied=document.execCommand('copy');}catch{}area.remove();button.textContent=copied?'Copied':'Select code to copy';}
   setTimeout(()=>button.textContent='Copy',1400);
  });pre.append(button);
 });
});
function show(){
 let index=Number((location.hash.match(/^#lab=(\\d+)$/)||[])[1]||0);if(index<0||index>=labs.length)index=0;
 labs.forEach((lab,i)=>lab.hidden=i!==index);
 document.querySelectorAll('nav a').forEach((a,i)=>{if(i===index)a.setAttribute('aria-current','page');else a.removeAttribute('aria-current');});
 document.getElementById('breadcrumb').textContent='Deep Data Security / '+labs[index].dataset.title;
 document.title=labs[index].dataset.title+' | Deep Data Security';
 const controls=document.getElementById('controls');controls.replaceChildren();
 if(labs[index].querySelector('details.task'))['Expand All Tasks','Collapse All Tasks'].forEach((label,i)=>{
  const button=document.createElement('button');button.textContent=label;button.addEventListener('click',()=>labs[index].querySelectorAll('details.task').forEach(d=>d.open=i===0));controls.append(button);
 });
 const pageNav=document.getElementById('page-nav');pageNav.replaceChildren();
 for(const [target,label] of [[index-1,'Previous lab'],[index+1,'Next lab']]){if(target>=0&&target<labs.length){const a=document.createElement('a');a.href='#lab='+target;a.textContent=label+' · '+labs[target].dataset.title;pageNav.append(a);}}
 window.scrollTo(0,0);
}
window.addEventListener('hashchange',show);show();
</script></body></html>`;
writeFileSync(resolve(root,'index.html'),html);
console.log(`Built standalone preview with ${pages.length} workshop pages`);

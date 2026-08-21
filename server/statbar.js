// augustinus 공통 시스템 상태바 — 모든 페이지 최상단 고정(한 줄). /stats 3초 폴링.
(function(){
  if(window.__augStatbar) return; window.__augStatbar=true;
  var css=`
  #augbar{position:fixed;top:0;left:0;right:0;z-index:99999;display:flex;flex-wrap:nowrap;align-items:stretch;
    background:#070A0E;border-bottom:1px solid #1E2530;
    font-family:"JetBrains Mono","Nanum Gothic Coding",ui-monospace,monospace;
    font-size:15px;line-height:1.2;color:#ECEEF1;overflow-x:auto;overflow-y:hidden;white-space:nowrap}
  #augbar::-webkit-scrollbar{height:0}
  #augbar .cell{padding:9px 14px;border-right:1px solid #161B22;display:flex;align-items:center;gap:8px;flex:none}
  #augbar .lb{color:#828A94;font-size:12.5px}
  #augbar b{color:#4DE08A;font-weight:700}
  #augbar .crit{color:#F0645A}
  #augbar .mini{width:46px;height:6px;background:#161B22;display:inline-block;overflow:hidden;vertical-align:middle}
  #augbar .mini i{display:block;height:100%;background:#4DE08A}
  #augbar .mini i.crit{background:#F0645A}
  #augbar .host{color:#4DE08A;font-weight:700;position:sticky;left:0;background:#070A0E;border-right:1px solid #1E2530;z-index:1}
  `;
  var s=document.createElement('style'); s.textContent=css; document.head.appendChild(s);
  var bar=document.createElement('div'); bar.id='augbar';
  bar.innerHTML='<div class="cell host">augustinus@890m</div><div class="cell lb">상태 로딩…</div>';
  document.body.insertBefore(bar, document.body.firstChild);
  function pad(){ document.body.style.paddingTop = bar.offsetHeight + 'px'; }
  pad(); window.addEventListener('resize', pad);

  function gib(b){return (b/1073741824).toFixed(1);}
  function cls(p){return p>=92?'crit':'';}
  function tc(t){return t>=85?'crit':'';}
  function mini(p){return '<span class="mini"><i class="'+cls(p)+'" style="width:'+Math.min(100,p)+'%"></i></span>';}
  function cell(lb, html){return '<div class="cell"><span class="lb">'+lb+'</span>'+html+'</div>';}

  async function tick(){
    try{
      var r=await fetch('/stats',{cache:'no-store'});
      if(r.status===401){bar.innerHTML='<div class="cell host">augustinus@890m</div><div class="cell lb">로그인 필요</div>';pad();return;}
      var d=await r.json();
      var gtt=d.gtt_total?Math.round(d.gtt_used/d.gtt_total*100):0;
      var mem=d.mem_total?Math.round(d.mem_used/d.mem_total*100):0;
      var disk=d.disk_total?Math.round(d.disk_used/d.disk_total*100):0;
      bar.innerHTML=
        '<div class="cell host" title="'+(d.cpu_model||'')+'">augustinus@890m</div>'+
        cell('CPU','<b class="'+cls(d.cpu_pct)+'">'+d.cpu_pct+'%</b> '+mini(d.cpu_pct)+(d.cpu_temp!=null?' <span class="'+tc(d.cpu_temp)+'">'+d.cpu_temp+'°</span>':''))+
        cell('GPU','<b class="'+cls(d.gpu_busy)+'">'+d.gpu_busy+'%</b> '+mini(d.gpu_busy)+(d.gpu_temp!=null?' <span class="'+tc(d.gpu_temp)+'">'+d.gpu_temp+'°</span>':''))+
        cell('GTT','<b>'+gib(d.gtt_used)+'</b>/'+gib(d.gtt_total)+'G '+mini(gtt))+
        cell('RAM','<b>'+gib(d.mem_used)+'</b>/'+gib(d.mem_total)+'G '+mini(mem))+
        cell('DISK','<b>'+(d.disk_free/1099511627776).toFixed(2)+'T</b> free '+mini(disk))+
        (d.nvme_temp!=null?cell('SSD','<span class="'+tc(d.nvme_temp)+'">'+d.nvme_temp+'°</span>'):'');
      pad();
    }catch(e){}
  }
  tick(); setInterval(tick, 3000);
})();

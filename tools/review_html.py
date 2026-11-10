#!/usr/bin/env python3
"""회화 초안 → 사용자 리뷰 페이지(일본어앱 tools/review_html.py 의 몽골어판).
  python3 tools/review_html.py        → data/review/REVIEW_mn.html (R 구조 전체)
한 번에 한 편만 보인다(목록에서 고르거나 이전·다음, 주소 #편id). 음성 = data/tts/audio_mn.json(Azure, tools/tts/azure_pack.py). 장면 컷은 나오면 칸을 더한다."""
import datetime, glob, html, json, pathlib
ROOT = pathlib.Path(__file__).resolve().parent.parent
_af = ROOT / 'data/tts/audio_mn.json'
AUD = json.load(open(_af, encoding='utf-8')) if _af.exists() else {}
EMO = {'stiff': '긴장', 'flustered': '당황', 'excited': '흥분', 'amused': '유쾌', 'teasing': '놀림', 'shout': '버럭', 'cheerful': '밝음', 'gentle': '다정', 'neutral': '담담',
       'polite': '공손', 'sad': '슬픔', 'annoyed': '짜증', 'surprised': '놀람', 'shy': '수줍음', 'worried': '걱정', 'happy': '기쁨', 'angry': '화남', 'tired': '지침'}


def aurl(r):
    return f"https://auth.talkverse.uk/art/{r['key']}?v={r['sha1'][:8]}"


def play(eid, n):
    rs = {r['voice']: r for r in AUD.get(eid, []) if r['turn'] == n}
    if not rs:
        return ''
    m, f = rs.get('m'), rs.get('f')
    if m and f and m['sha1'] != f['sha1'] and m['speaker'] in ('am', 'af'):
        return f"<div class=au><button class='pl m' data-u='{aurl(m)}' onclick='p1(this)'>▶ 남자</button><button class='pl f' data-u='{aurl(f)}' onclick='p1(this)'>▶ 여자</button></div>"
    return f"<div class=au><button class='pl c' data-u='{aurl(m or f)}' onclick='p1(this)'>▶ 재생</button></div>"
out = ROOT / 'data/review/REVIEW_mn.html'
eps = [json.load(open(p, encoding='utf-8')) for p in sorted(glob.glob(str(ROOT / 'app/assets/data/dialogues/R*/*/*.json')))]
css = """body{font-family:-apple-system,'Noto Sans KR','Hiragino Sans',sans-serif;max-width:860px;margin:0 auto;padding:16px;background:#fff;color:#0a2540;line-height:1.5}
h1{font-size:20px}h2{font-size:17px;margin:28px 0 4px;color:#b77548}.meta{font-size:12px;color:#6b7c93;margin-bottom:12px}
.t{margin:10px 0;padding:10px 12px;border-radius:12px;background:#f6f8fb;border:1px solid #e6ebf1}.t.A{background:#fff7f0}
.sp{font-size:11px;color:#6b7c93}.tl{font-size:17px;font-weight:600}.rd{font-size:12px;color:#635bff;line-height:1.3}.ko{font-size:13px;line-height:1.3}
.ok{display:inline-block;font-size:11px;padding:1px 6px;border-radius:8px;background:#e6f4ea;color:#1b7f3b}.dr{display:inline-block;font-size:11px;padding:1px 6px;border-radius:8px;background:#fff1e0;color:#b77548}
.nav a{display:inline-block;margin:2px 6px 2px 0;font-size:12px;color:#635bff}
.rv{display:flex;gap:6px;margin-top:8px}.rv textarea{flex:1;min-width:0;min-height:38px;border:1px solid #cfd8e3;border-radius:8px;padding:6px 8px;font:inherit;font-size:14px;background:#fff;color:#0a2540;resize:vertical}
.rv button{border:0;border-radius:8px;padding:0 12px;background:#635bff;color:#fff;font-size:13px;cursor:pointer}.rv button.ok{background:#1b7f3b}.rv button.err{background:#b42318}
.rs{font-size:11px;color:#6b7c93;margin-top:2px}.ep{margin:0 0 6px}.ep textarea,.aubox textarea{min-height:32px;height:32px}h2{margin:12px 0 2px}.t .rv,.t .rs{display:none}.t.ed .rv{display:flex}.t.ed .rs,.t .rs.has{display:block}.pen{border:0;background:none;color:#6b7c93;font-size:13px;padding:0 4px;cursor:pointer;float:right}.pen.has{color:#635bff}
.t{margin:4px 0;padding:6px 10px;border-radius:10px}.t.A{margin-left:12%}.t:not(.A){margin-right:12%}.sp{display:inline;margin-right:6px}.tl{display:inline;font-size:15px;line-height:1.35;overflow-wrap:anywhere;font-family:-apple-system,'Helvetica Neue',Arial,sans-serif}.au{display:inline-flex;gap:4px;margin-left:6px;vertical-align:middle}.pl{border:1px solid #cfd8e3;border-radius:14px;padding:1px 8px;background:#fff;color:#0a2540;font-size:13px;cursor:pointer}.pl.on{background:#635bff;border-color:#635bff;color:#fff}.t.now{outline:2px solid #635bff}
.aubox{margin:10px 0;padding:10px 12px;border-radius:12px;border:1px solid #f0d9c4;background:#fffaf5;font-size:13px}
.epx{display:none}.epx.on{display:block}.bar{position:sticky;top:0;z-index:5;background:#fff;padding:8px 0;display:flex;gap:6px;align-items:center;border-bottom:1px solid #e6ebf1}
.bar select{flex:1;min-width:0;font-size:14px;padding:6px;border:1px solid #cfd8e3;border-radius:8px;background:#fff;color:#0a2540}.bar button{border:1px solid #cfd8e3;border-radius:8px;background:#fff;padding:6px 10px;font-size:14px;color:#0a2540}
.pager{display:flex;justify-content:space-between;margin:18px 0 40px}.pager button{border:0;border-radius:8px;background:#635bff;color:#fff;padding:8px 14px;font-size:14px}"""
js = r"""const API='https://talkverse.uk/api/review/mn';  // uk 세션이 여는 저장 API(POST {key,text,at} / GET → {key:{text,at}})
const LS='review_mn_v1';
function ld(){try{return JSON.parse(localStorage.getItem(LS)||'{}')}catch(e){return {}}}
function st(k,m,c){const el=document.querySelector(`[data-s="${k}"]`);if(el){el.textContent=m;}const b=document.querySelector(`[data-k="${k}"]`).nextElementSibling;b.className=c||'';}
function fill(d){for(const k in d){const t=document.querySelector(`[data-k="${k}"]`);if(t&&!t.value){t.value=d[k].text||'';const s=document.querySelector(`[data-s="${k}"]`);if(s)s.textContent='저장됨 '+(d[k].at||'');const tt=t.closest('.t');if(tt&&t.value){tt.classList.add('ed');}}}}
async function sv(btn){const ta=btn.previousElementSibling,k=ta.dataset.k,text=ta.value.trim(),at=new Date().toLocaleString('ko-KR',{hour12:false});
 const d=ld();d[k]={text,at};try{localStorage.setItem(LS,JSON.stringify(d))}catch(e){}
 st(k,'저장 중…','');
 try{const r=await fetch(API,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({key:k,text,at})});
  if(!r.ok)throw new Error(r.status);st(k,'서버 저장됨 '+at,'ok');}
 catch(e){st(k,'폰에만 저장됨 '+at+' (서버 연결 안 됨)','err');}}
const AU=new Audio();AU.preload='auto';let Q=[],B=null;
function off(){if(B)B.classList.remove('on');document.querySelectorAll('.t.now').forEach(x=>x.classList.remove('now'));}
function stop(){Q=[];AU.pause();off();B=null;}
function p1(b){if(B===b&&!AU.paused){stop();return;}stop();B=b;b.classList.add('on');AU.src=b.dataset.u;AU.play().catch(()=>stop());}
function pa(b,g){if(B===b){stop();return;}stop();const L=[];b.closest('.epx').querySelectorAll('.t').forEach(t=>{const x=t.querySelector('.pl.'+g)||t.querySelector('.pl.c');if(x)L.push(x);});Q=L;B=b;b.classList.add('on');nx();}
function nx(){const x=Q.shift();if(!x){stop();return;}const t=x.closest('.t');document.querySelectorAll('.t.now').forEach(y=>y.classList.remove('now'));t.classList.add('now');t.scrollIntoView({block:'center',behavior:'smooth'});AU.src=x.dataset.u;AU.play().catch(()=>stop());}
AU.onended=()=>{if(Q.length){setTimeout(nx,350);}else{stop();}};
const EPS=[...document.querySelectorAll('.epx')].map(x=>x.dataset.id),SEL=document.getElementById('sel');
function show(id){stop();if(!EPS.includes(id))id=EPS[0];document.querySelectorAll('.epx').forEach(x=>x.classList.toggle('on',x.dataset.id===id));SEL.value=id;if(location.hash!=='#'+id)history.replaceState(null,'','#'+id);setTimeout(()=>window.scrollTo(0,0),0);}
function mv(d){const i=EPS.indexOf(SEL.value)+d;if(i>=0&&i<EPS.length)show(EPS[i]);}
SEL.onchange=()=>show(SEL.value);window.onhashchange=()=>show(location.hash.slice(1));show(location.hash.slice(1));
(async()=>{fill(ld());try{const r=await fetch(API);if(r.ok){fill(await r.json());}}catch(e){}})();
"""
e_ = html.escape
parts = [f"<!doctype html><html lang=ko><head><meta charset=utf-8><meta name=viewport content='width=device-width,initial-scale=1'><title>몽골어 회화 리뷰</title><style>{css}</style></head><body>",
         f"<h1 style='font-size:16px;margin:0 0 2px'>몽골어 회화 리뷰 <small style='font-size:11px;color:#6b7c93;font-weight:400'>{datetime.datetime.now():%m-%d %H:%M} · {len(eps)}편 · 그림 없음</small></h1>"
         "<div class=bar><button onclick='mv(-1)'>◀</button><select id=sel>"]
parts += [f"<option value='{e['id']}'>{i}. {e_(e.get('emoji', ''))} {e_(e['title'])}{' ✓' if e.get('approved') else ''}</option>" for i, e in enumerate(eps, 1)] + ["</select><button onclick='mv(1)'>▶</button></div>"]
for e in eps:
    tag = f"<span class=ok>통과 {e_(e['approved'])}</span>" if e.get('approved') else "<span class=dr>리뷰 대기</span>"
    sp = ' · '.join(f'{k}={v}' for k, v in e['speakers'].items())
    k = e['id'] + ':all'
    play_all = (f"<div class=au style='margin:4px 0 6px'><button class=pl onclick=\"pa(this,'m')\">▶ 전체 듣기 · 남자 학습자(Алекс)</button><button class=pl onclick=\"pa(this,'f')\">▶ 여자 학습자(Эмма)</button></div>") if e['id'] in AUD else ''
    tail = (f"<div class='rv ep'><textarea data-k='{k}' placeholder='이 편 전체 리뷰 — 통과 / 다시 / 턴이 너무 짧다 등…'></textarea><button onclick=\"sv(this)\">저장</button></div><div class=rs data-s='{k}'></div>"
            + (f"<div class='rv ep'><textarea data-k='{e['id']}:audio' placeholder='음성 리뷰 — 목소리·감정·억양·속도…'></textarea><button onclick=\"sv(this)\">저장</button></div><div class=rs data-s='{e['id']}:audio'></div>" if e['id'] in AUD else ''))
    parts.append(f"<section class=epx data-id='{e['id']}'><h2>{e_(e.get('emoji', ''))} {e_(e['title'])} <small style='font-size:11px;color:#6b7c93'>{e['id']}</small> {tag}</h2>"
                 f"<div class=meta style='margin-bottom:2px'>{e_(e['scene'])} · {e['region']} · 반전 {e.get('twist')}턴</div>" + play_all)
    nm = {k: ('나' if v == '{name}' else v) for k, v in e['speakers'].items()}
    for t in e['turns']:
        k = f"{e['id']}:{t['num']}"
        parts.append(f"<div class='t {t['speaker']}'><button class=pen onclick=\"this.parentNode.classList.toggle('ed')\">✎</button><div class=sp>{t['num']} {e_(nm.get(t['speaker'], t['speaker']))} · {EMO.get(t.get('emotion', ''), t.get('emotion', ''))}</div><div class=tl>{e_(t['tl'])}</div>{play(e['id'], t['num'])}<div class=rd>{e_(t.get('rd', ''))}</div><div class=ko>{e_(t['ko'])}</div>"
                     f"<div class=rv><textarea data-k='{k}' placeholder='이 턴 리뷰…'></textarea><button onclick=\"sv(this)\">저장</button></div><div class=rs data-s='{k}'></div></div>")
    parts.append(tail + "<div class=pager><button onclick='mv(-1)'>◀ 이전 편</button><button onclick='mv(1)'>다음 편 ▶</button></div></section>")
parts.append(f"<script>{js}</script></body></html>")
out.write_text('\n'.join(parts), encoding='utf-8')
print(out, len(eps))

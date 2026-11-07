#!/usr/bin/env python3
"""회화 초안 → 사용자 리뷰 페이지(일본어앱 tools/review_html.py 의 몽골어판, 음성·그림 칸 없음).
  python3 tools/review_html.py        → data/review/REVIEW_mn.html (R 구조 전체)
음성 모델이 정해지고 장면 컷이 나오면 그때 칸을 더한다."""
import datetime, glob, html, json, pathlib
ROOT = pathlib.Path(__file__).resolve().parent.parent
out = ROOT / 'data/review/REVIEW_mn.html'
eps = [json.load(open(p, encoding='utf-8')) for p in sorted(glob.glob(str(ROOT / 'app/assets/data/dialogues/R*/*/*.json')))]
css = """body{font-family:-apple-system,'Noto Sans KR','Hiragino Sans',sans-serif;max-width:860px;margin:0 auto;padding:16px;background:#fff;color:#0a2540;line-height:1.5}
h1{font-size:20px}h2{font-size:17px;margin:28px 0 4px;color:#b77548}.meta{font-size:12px;color:#6b7c93;margin-bottom:12px}
.t{margin:10px 0;padding:10px 12px;border-radius:12px;background:#f6f8fb;border:1px solid #e6ebf1}.t.A{background:#fff7f0}
.sp{font-size:11px;color:#6b7c93}.tl{font-size:17px;font-weight:600}.rd{font-size:13px;color:#635bff}.ko{font-size:14px}
.ok{display:inline-block;font-size:11px;padding:1px 6px;border-radius:8px;background:#e6f4ea;color:#1b7f3b}.dr{display:inline-block;font-size:11px;padding:1px 6px;border-radius:8px;background:#fff1e0;color:#b77548}
.nav a{display:inline-block;margin:2px 6px 2px 0;font-size:12px;color:#635bff}
.rv{display:flex;gap:6px;margin-top:8px}.rv textarea{flex:1;min-height:38px;border:1px solid #cfd8e3;border-radius:8px;padding:6px 8px;font:inherit;font-size:14px;background:#fff;color:#0a2540;resize:vertical}
.rv button{border:0;border-radius:8px;padding:0 12px;background:#635bff;color:#fff;font-size:13px;cursor:pointer}.rv button.ok{background:#1b7f3b}.rv button.err{background:#b42318}
.rs{font-size:11px;color:#6b7c93;margin-top:2px}.ep{margin:0 0 6px}.ep textarea{min-height:46px}"""
js = r"""const API='https://talkverse.uk/api/review/mn';  // uk 세션이 여는 저장 API(POST {key,text,at} / GET → {key:{text,at}})
const LS='review_mn_v1';
function ld(){try{return JSON.parse(localStorage.getItem(LS)||'{}')}catch(e){return {}}}
function st(k,m,c){const el=document.querySelector(`[data-s="${k}"]`);if(el){el.textContent=m;}const b=document.querySelector(`[data-k="${k}"]`).nextElementSibling;b.className=c||'';}
function fill(d){for(const k in d){const t=document.querySelector(`[data-k="${k}"]`);if(t&&!t.value){t.value=d[k].text||'';const s=document.querySelector(`[data-s="${k}"]`);if(s)s.textContent='저장됨 '+(d[k].at||'');}}}
async function sv(btn){const ta=btn.previousElementSibling,k=ta.dataset.k,text=ta.value.trim(),at=new Date().toLocaleString('ko-KR',{hour12:false});
 const d=ld();d[k]={text,at};try{localStorage.setItem(LS,JSON.stringify(d))}catch(e){}
 st(k,'저장 중…','');
 try{const r=await fetch(API,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({key:k,text,at})});
  if(!r.ok)throw new Error(r.status);st(k,'서버 저장됨 '+at,'ok');}
 catch(e){st(k,'폰에만 저장됨 '+at+' (서버 연결 안 됨)','err');}}
(async()=>{fill(ld());try{const r=await fetch(API);if(r.ok){fill(await r.json());}}catch(e){}})();
"""
e_ = html.escape
parts = [f"<!doctype html><html lang=ko><head><meta charset=utf-8><meta name=viewport content='width=device-width,initial-scale=1'><title>몽골어 회화 리뷰</title><style>{css}</style></head><body>",
         f"<h1>몽골어 회화 리뷰 시트</h1><div class=meta>갱신 {datetime.datetime.now():%Y-%m-%d %H:%M} · {len(eps)}편 · 턴마다 몽골어 / 한글 독음 / 한국어 · Claude 초안(Grok·Gemini 검수 전) · 음성·그림은 아직 없음</div><div class=nav>"]
parts += [f"<a href='#{e['id']}'>{e_(e['title'])}</a>" for e in eps] + ['</div>']
for e in eps:
    tag = f"<span class=ok>통과 {e_(e['approved'])}</span>" if e.get('approved') else "<span class=dr>리뷰 대기</span>"
    sp = ' · '.join(f'{k}={v}' for k, v in e['speakers'].items())
    k = e['id'] + ':all'
    parts.append(f"<h2 id='{e['id']}'>{e_(e.get('emoji', ''))} {e_(e['title'])} <small>{e['id']}</small></h2>"
                 f"<div class='rv ep'><textarea data-k='{k}' placeholder='이 편 전체 리뷰 — 통과 / 다시 / 턴이 너무 짧다 등…'></textarea><button onclick=\"sv(this)\">저장</button></div><div class=rs data-s='{k}'></div>"
                 f"<div class=meta>{tag}<br>{e_(e['scene'])}<br>{e['region']} · {e.get('register')} · 턴 {len(e['turns'])} · 반전 {e.get('twist')}턴({e.get('twist_type')}) · {e_(sp)}</div>")
    for t in e['turns']:
        k = f"{e['id']}:{t['num']}"
        parts.append(f"<div class='t {t['speaker']}'><div class=sp>{t['num']} {t['speaker']}</div><div class=tl>{e_(t['tl'])}</div><div class=rd>{e_(t.get('rd', ''))}</div><div class=ko>{e_(t['ko'])}</div>"
                     f"<div class=rv><textarea data-k='{k}' placeholder='이 턴 리뷰…'></textarea><button onclick=\"sv(this)\">저장</button></div><div class=rs data-s='{k}'></div></div>")
parts.append(f"<script>{js}</script></body></html>")
out.write_text('\n'.join(parts), encoding='utf-8')
print(out, len(eps))

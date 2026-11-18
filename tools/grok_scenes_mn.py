#!/usr/bin/env python3
"""몽골어 회화 장면 컷 — 한 방에서 편마다 1장(인도네시아어앱 grok_scenes_room.py 를 옮김, 2026-11-18).

  GROK_CDP_PORT=9253 [ROOM=<방 id>] python3 tools/grok_scenes_mn.py <편id> [...]

- 편 파일 = data/review/scenes/room/<편id>.txt(장면·인물·흐름·반전 턴). 받은 그림 = data/review/scenes/<편id>_1.jpg.
- 첫 메시지: 규칙 + 캐릭터 시트(data/review/art/chars_mn_v1.jpg) 첨부, 「앞으로 파일 이름 한 줄만」 약속.
  편마다: 편 파일 + 시트 첨부 + 「<편id>.txt」 한 줄(사용자 지시 2026-11-09 프롬프트 최소화).
- 모델 「빠른」(사용자 지시 2026-11-18 이 세션). 「빠른」은 요청당 1장 — 컷도 요청당 1장(uk 11-18 안내).
- 그림마다 3분까지만 기다리고 넘으면 생성 중지(사용자 지시 2026-11-10). 한도 문구면 멈춤(종료 3).
- 크롬은 PC(작업 스케줄러 Grok-Chrome-mn-9253), M6 에서 ssh -fN -L 9253:127.0.0.1:9253 pc. 첨부는 PC D:\\grok_att\\mn\\ 경로.
"""
import base64
import json
import os
import subprocess
import sys
import time
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import grok_cdp as G  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'data/review/scenes')
WORK = os.path.join(OUT, 'room')
SHEET = os.path.join(ROOT, 'data/review/art/chars_mn_v1.jpg')
PC_ATT = 'D:/grok_att/mn/'
MODEL = '빠른'
RULES = """[MN-SCENE 규칙 — 이 방 전체에 적용]
- 첨부 시트 = 몽골어앱 고정 인물(점토·펠트 인형 톤). 사라·바트·노민·테뮬렌·학습자(남: 하늘파랑 후드티·베이지 팬츠·갈색 백팩)는 얼굴·머리·옷을 시트와 똑같이.
- 시트에 없는 조연(할머니·식당 주인·은행 직원·면접관 등)은 같은 화풍의 몽골 사람으로, 편마다 새 얼굴.
- 이후 메시지는 「<편id>.txt」 한 줄 + 그 편 파일 + 시트만 보냅니다. 편마다 그림 1장 = 「반전 턴」이 터지는 순간.
- 화풍: 시트와 같은 점토·펠트 인형(실사·사진풍 금지), 파스텔·따뜻한 조명, 요즘 울란바토르·몽골 일상 분위기. 가로 3:2.
- 그림 안에 글자·말풍선·간판 글씨·상표 없음(앱이 얹음). 대사는 그리지 말고 상황·표정·몸짓만 크게.
- 실제 일상에서 있을 법한 장면으로(판타지·과장된 소동 금지).
- 답은 그림 1장과 「완료」 한 줄.
"""


def put(paths):
    subprocess.run(['ssh', 'pc', 'cmd /c if not exist D:\\grok_att\\mn mkdir D:\\grok_att\\mn'], capture_output=True)
    out = []
    for p in paths:
        subprocess.run(['scp', '-q', p, 'pc:' + PC_ATT], check=True)
        out.append((PC_ATT + os.path.basename(p)).replace('/', '\\'))
    return out


BTN = "[...document.querySelectorAll('button')].find(x=>/^(모델|Model):/.test(x.getAttribute('aria-label')||''))"


def model(c):
    return c.ev("(()=>{const b=%s;return b?b.getAttribute('aria-label'):''})()" % BTN) or ''


def set_model(c):
    lab = model(c)
    if MODEL in lab:
        return lab
    c.ev("(()=>{const b=%s;if(!b)return 0;['pointerdown','pointerup'].forEach(t=>b.dispatchEvent(new PointerEvent(t,{bubbles:true})));b.click();return 1})()" % BTN)
    time.sleep(2)
    c.ev("(()=>{const it=[...document.querySelectorAll('[role=menuitem],[role=option],[role=menuitemradio],[role=menuitemcheckbox],button,div')].find(x=>/^(빠른|Fast)(\\s|$)/.test((x.innerText||'').trim())&&x.offsetParent&&!(x.getAttribute('aria-label')||'').match(/^(모델|Model):/));if(!it)return 0;['pointerdown','pointerup'].forEach(t=>it.dispatchEvent(new PointerEvent(t,{bubbles:true})));it.click();return 1})()")
    time.sleep(2)
    lab = model(c)
    if MODEL not in lab:
        raise SystemExit('모델을 「빠른」으로 못 맞춤: ' + lab)
    return lab


def send(c, text, files):
    if files:
        doc = c.call('DOM.getDocument', depth=-1, pierce=True)
        q = c.call('DOM.querySelector', nodeId=doc['root']['nodeId'], selector='input[type=file]')
        if not q.get('nodeId'):
            raise SystemExit('파일 입력 없음')
        c.call('DOM.setFileInputFiles', nodeId=q['nodeId'], files=files)
        time.sleep(4 + 2 * len(files))
    c.ev("(()=>{const e=%s;e.focus();return 1})()" % G.FIND)
    c.call('Input.insertText', text=text)
    time.sleep(1)
    for typ in ('keyDown', 'keyUp'):
        c.call('Input.dispatchKeyEvent', type=typ, key='Enter', code='Enter', windowsVirtualKeyCode=13, nativeVirtualKeyCode=13)
    time.sleep(3)
    if (c.ev("(()=>{const e=%s;return e?(e.value||e.innerText||'').trim().length:0})()" % G.FIND) or 0) > 0:
        c.ev("(()=>{const b=[...document.querySelectorAll('button')].find(e=>['보내기','제출','Submit','Send'].includes(e.getAttribute('aria-label')||''));if(b)b.click()})()")
        time.sleep(3)


def srcs(c):
    return json.loads(c.ev("JSON.stringify([...new Set([...document.querySelectorAll('img')].filter(i=>i.src.includes('generated')).map(i=>i.src))])"))


def busy(c):
    return c.ev("document.body.innerText.includes('이미지 생성 중')||document.body.innerText.includes('작업 중')||!![...document.querySelectorAll('button')].find(e=>/^(응답 중지|중지|Stop)/.test(e.getAttribute('aria-label')||''))")


def limit(c):
    return c.ev("document.body.innerText.includes('한도에 도달')||/limit reached/i.test(document.body.innerText)")


def stop(c):
    ok = c.ev("(()=>{const b=[...document.querySelectorAll('button')].find(e=>/^(응답 중지|중지|Stop)/.test(e.getAttribute('aria-label')||''));if(b){b.click();return 1}return 0})()")
    if not ok:
        for t in ('keyDown', 'keyUp'):
            c.call('Input.dispatchKeyEvent', type=t, key='Escape', code='Escape', windowsVirtualKeyCode=27)


def wait_new(frag, have, timeout=180):
    t0 = time.time()
    while time.time() - t0 < timeout:
        time.sleep(15)
        c = G.CDP(G.tab(frag))
        if limit(c):
            print('LIMIT', flush=True)
            sys.exit(3)
        ss = srcs(c)
        if not busy(c) and len(ss) > len(have):
            return c, ss
    stop(G.CDP(G.tab(frag)))
    print('시간초과 3분 — 생성 중지', flush=True)
    return None, None


def save(c, url, path):
    c.call('Page.enable')
    c.ev("(()=>{const x=new Image();x.src=" + json.dumps(url) + ";x.style.cssText='position:fixed;left:-9999px;width:4px';document.body.appendChild(x)})()")
    time.sleep(6)
    fid = c.call('Page.getResourceTree')['frameTree']['frame']['id']
    r = c.call('Page.getResourceContent', frameId=fid, url=url)
    open(path, 'wb').write(base64.b64decode(r['content']) if r.get('base64Encoded') else r['content'].encode('latin1'))


def main(ids):
    room = os.environ.get('ROOM')
    if not room:
        rules = os.path.join(WORK, 'SCENE_RULES_mn.txt')
        open(rules, 'w', encoding='utf-8').write(RULES)
        t = json.load(urllib.request.urlopen(urllib.request.Request(G.BASE + '/json/new?https://grok.com/', method='PUT')))
        time.sleep(10)
        c = G.CDP(t)
        c.call('Page.bringToFront')
        print('model:', set_model(c), flush=True)
        send(c, '첨부 규칙대로 이 방에서 장면 컷을 그립니다. 앞으로는 파일 이름 한 줄만 보냅니다. 지금은 「확인」 한 줄만.', put([rules, SHEET]))
        for _ in range(36):
            time.sleep(5)
            room = c.ev("(location.pathname.match(/\\/c\\/([\\w-]+)/)||[])[1]")
            if room and not busy(c):
                break
        if not room:
            raise SystemExit('방 주소를 못 얻음')
    print('room', room, flush=True)
    frag = room[:8]
    bad = []
    for eid in ids:
        dst = os.path.join(OUT, f'{eid}_1.jpg')
        if os.path.exists(dst):
            print('skip', eid, flush=True)
            continue
        c = G.CDP(G.tab(frag))
        set_model(c)
        have = srcs(c)
        send(c, f'{eid}.txt', put([os.path.join(WORK, eid + '.txt'), SHEET]))
        c, ss = wait_new(frag, have)
        if not c:
            bad.append(eid)
            continue
        new = [x for x in ss if x not in have]
        save(c, new[-1], dst)
        print(eid, '저장', dst, flush=True)
        time.sleep(5)
    print('끝 room', room, '시간초과', bad, flush=True)


if __name__ == '__main__':
    main(sys.argv[1:])

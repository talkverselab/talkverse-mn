#!/usr/bin/python3
"""회화 음성(몽골어) — Azure mn-MN(여 YesuiNeural·남 BataaNeural)으로 턴별 남성판·여성판 mp4 → R2 `audio/mn/<편>/<턴>_<m|f>.mp4` + D1 `audio_lines`.
MOSS·VoxCPM 이 몽골어를 못 읽어 클라우드 TTS 를 쓴다(GPU 를 안 쓰므로 새벽 규칙 대상 아님). 목소리가 둘뿐이라 인물마다 높낮이·빠르기로 구분한다.
학습자(A) 이름 자리는 남성판 「Алекс」, 여성판 「Эмма」. A 가 아닌 턴은 두 판의 소리가 같다(구조를 단순하게 두 파일·두 줄).
  doppler run -p keys -c prd -- python3 tools/tts/azure_pack.py <편id…|all> [--upload]
목록 = data/tts/audio_mn.json(리뷰 페이지용)."""
import datetime, glob, hashlib, html, json, os, subprocess, sys, tempfile, time, urllib.request
from concurrent.futures import ThreadPoolExecutor
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
EP = {os.path.basename(p)[:-5]: p for p in glob.glob(f'{R}/app/assets/data/dialogues/R*/*/*.json')}
NAME = {'m': ('Алекс', '알렉스', '알렉스'), 'f': ('Эмма', '엠마', '에마')}
FIX = {'Сараа': ('F', '+6%', '+8%'), 'Номин': ('F', '-3%', '0%'), 'Бат': ('M', '-6%', '-4%'), 'Тэмүүлэн': ('M', '+3%', '0%')}
OLD_F = ('할머니', '아주머니', '이모', '어머니'); OLD_M = ('아저씨', '사냥꾼', '삼촌', '아버지')
YOUNG_F = ('점원', '식당 주인', '접수원', '약사')
EMO = {'excited': ('+6%', '+8%'), 'surprised': ('+8%', '+5%'), 'happy': ('+4%', '+4%'), 'teasing': ('+3%', '+3%'), 'angry': ('+2%', '+6%'),
       'sad': ('-5%', '-8%'), 'worried': ('-3%', '-4%'), 'tired': ('-6%', '-10%'), 'shy': ('+2%', '-5%')}
W = ['npx', '-y', 'wrangler@4']; MF = f'{R}/data/tts/audio_mn.json'


def voice(name, g):
    """(azure 목소리, 높낮이, 빠르기, 이름표)"""
    if name == '{name}':
        return ('mn-MN-BataaNeural', '0%', '0%', 'am') if g == 'm' else ('mn-MN-YesuiNeural', '0%', '0%', 'af')
    if name in FIX:
        s, p, r = FIX[name]
    elif any(k in name for k in OLD_F):
        s, p, r = 'F', '-9%', '-8%'
    elif any(k in name for k in OLD_M):
        s, p, r = 'M', '-10%', '-6%'
    elif any(k in name for k in YOUNG_F):
        s, p, r = 'F', '+2%', '0%'
    else:
        s, p, r = 'M', '-2%', '0%'
    return ('mn-MN-YesuiNeural' if s == 'F' else 'mn-MN-BataaNeural', p, r, name)


def pct(a, b):
    return f'{int(a[:-1]) + int(b[:-1]):+d}%'


def synth(text, v, emo, out):
    p, r = v[1], v[2]
    if emo in EMO:
        p, r = pct(p, EMO[emo][0]), pct(r, EMO[emo][1])
    ssml = (f"<speak version='1.0' xml:lang='mn-MN'><voice name='{v[0]}'><prosody pitch='{p}' rate='{r}'>"
            f"{html.escape(text)}</prosody></voice></speak>").encode()
    reg = os.environ.get('AZURE_SPEECH_REGION', 'koreacentral')
    for i in range(5):
        try:
            q = urllib.request.Request(f'https://{reg}.tts.speech.microsoft.com/cognitiveservices/v1', data=ssml, headers={
                'Ocp-Apim-Subscription-Key': os.environ['AZURE_SPEECH_KEY'], 'Content-Type': 'application/ssml+xml',
                'X-Microsoft-OutputFormat': 'riff-24khz-16bit-mono-pcm', 'User-Agent': 'talkverse-mn'})
            open(out + '.wav', 'wb').write(urllib.request.urlopen(q, timeout=60).read())
            break
        except Exception as e:
            if i == 4:
                raise
            time.sleep(3 * (i + 1))
    subprocess.run(['ffmpeg', '-y', '-i', out + '.wav', '-af', 'apad=pad_dur=0.12,loudnorm=I=-18:TP=-1.5:LRA=11,aresample=44100', '-ac', '1',
                    '-c:a', 'aac', '-b:a', '80k', '-movflags', '+faststart', '-f', 'mp4', '-map_metadata', '-1', out], check=True, capture_output=True)
    os.remove(out + '.wav')
    return int(float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', out], capture_output=True, text=True).stdout) * 1000)


def rows(ep, tmp):
    d = json.load(open(EP[ep], encoding='utf-8')); out = []
    for t in d['turns']:
        nm = d['speakers'].get(t['speaker'], '')
        for g in 'mf':
            n = NAME[g]; text = t['tl'].replace('{name}', n[0])
            if not ''.join(c for c in text if c.isalpha()):
                continue
            v = voice(nm, g); f = f"{tmp}/{ep}_{t['num']:02d}_{g}.mp4"
            out.append(dict(turn=t['num'], voice=g, speaker=v[3], emotion=t.get('emotion', ''), key=f"audio/mn/{ep}/{t['num']:02d}_{g}.mp4",
                            text=text, reading='', rd=t.get('rd', '').replace('{name}', n[1]), ko=t['ko'].replace('{name}', n[2]), f=f, v=v))
    return out


def make(r):
    ms = synth(r['text'], r['v'], r['emotion'], r['f'])
    r['ms'] = ms; r['sha1'] = hashlib.sha1(open(r['f'], 'rb').read()).hexdigest()
    return r


def put(r):
    for _ in range(3):
        x = subprocess.run(W + ['r2', 'object', 'put', f"talkverse-art/{r['key']}", '--file', r['f'], '--content-type', 'audio/mp4', '--remote'], cwd=R, capture_output=True, text=True)
        if x.returncode == 0:
            return None
    return r['key'] + ' ' + x.stderr[-200:]


def main():
    UP = '--upload' in sys.argv; eps = [x for x in sys.argv[1:] if x != '--upload']
    eps = sorted(EP) if eps == ['all'] else eps
    q = lambda s: "'" + s.replace("'", "''") + "'"
    for ep in eps:
        tmp = tempfile.mkdtemp()
        with ThreadPoolExecutor(4) as ex:
            rs = list(ex.map(make, rows(ep, tmp)))
        if UP:
            with ThreadPoolExecutor(8) as ex:
                err = [e for e in ex.map(put, rs) if e]
            if err:
                sys.exit('R2 실패 ' + ' | '.join(err[:3]))
            now = datetime.datetime.now(datetime.UTC).strftime('%Y-%m-%d %H:%M:%S')
            sql = [f"DELETE FROM audio_lines WHERE lang='mn' AND episode='{ep}';"] + [
                "INSERT INTO audio_lines (lang,episode,turn,voice,speaker,emotion,key,ms,sha1,text,reading,rd,ko,created_at) VALUES "
                f"('mn','{ep}',{r['turn']},'{r['voice']}',{q(r['speaker'])},'{r['emotion']}','{r['key']}',{r['ms']},'{r['sha1']}',{q(r['text'])},'',{q(r['rd'])},{q(r['ko'])},'{now}');" for r in rs]
            sf = f'{tmp}/{ep}.sql'; open(sf, 'w', encoding='utf-8').write('\n'.join(sql) + '\n')
            x = subprocess.run(W + ['d1', 'execute', 'talkverse-db', '--remote', '--file', sf, '-y'], cwd=R, capture_output=True, text=True)
            if x.returncode:
                sys.exit('D1 실패 ' + ep + x.stderr[-400:] + x.stdout[-300:])
        M = json.load(open(MF, encoding='utf-8')) if os.path.exists(MF) else {}
        M[ep] = [{k: v for k, v in r.items() if k in ('turn', 'voice', 'speaker', 'emotion', 'key', 'ms', 'sha1')} for r in rs]
        json.dump(M, open(MF, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
        subprocess.run(['rm', '-rf', tmp])
        print(ep, len(rs), '줄', sum(r['ms'] for r in rs) // 1000, '초', '올림' if UP else '안 올림', flush=True)


if __name__ == '__main__':
    main()

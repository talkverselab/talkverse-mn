# -*- coding: utf-8 -*-
"""앱 런처 아이콘 생성기 — branding/icons/A-mongolian.svg 디자인을 PIL로 렌더링.

Talkverse 브랜드 체계(언어 대표 글자 + t, 차콜 말풍선)를 따른 몽골 아이콘.
산출물:
  app/assets/icon/icon_full.png  (1024) 풀 디자인: 골드 프레임 + 차콜 말풍선 + Mt
  app/assets/icon/icon_fg.png    (1024) 어댑티브 전경: 풀 디자인을 세이프존으로 축소
Run:  python scripts/gen_icon.py   (이후 `dart run flutter_launcher_icons`)
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "app" / "assets" / "icon"

CANVAS = 1024
BG = "#FFE3A3"                  # 몽골 소욤보 골드 악센트
CHARCOAL = (35, 35, 35, 255)   # #232323 말풍선
CREAM = "#FCFCF8"              # 글자
FONT = "C:/Windows/Fonts/ariblk.ttf"  # Arial Black
TEXT = "Mt"                    # 키릴 М(Монгол) + t(talkverse)
FSIZE = 380
SPACING = -12                  # SVG letter-spacing
SAFE = 0.66                    # 어댑티브 세이프존 비율


def render_full():
    img = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # 배경 둥근 사각형 (rx 224)
    d.rounded_rectangle([0, 0, CANVAS - 1, CANVAS - 1], radius=224, fill=BG)
    # 말풍선 본체 (rect x96 y88 w832 h720 rx180) + 꼬리
    d.rounded_rectangle([96, 88, 96 + 832, 88 + 720], radius=180, fill=CHARCOAL)
    d.polygon([(298, 770), (240, 908), (440, 784)], fill=CHARCOAL)

    # 글자: 별도 레이어에 자간 적용 후 잉크 기준 중앙(512,436) 정렬
    tl = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    td = ImageDraw.Draw(tl)
    font = ImageFont.truetype(FONT, FSIZE)
    widths = [font.getlength(c) for c in TEXT]
    total = sum(widths) + SPACING * (len(TEXT) - 1)
    cursor = (CANVAS - total) / 2
    for c, w in zip(TEXT, widths):
        td.text((cursor, 512), c, font=font, fill=CREAM, anchor="lm")
        cursor += w + SPACING
    b = tl.getbbox()
    img.alpha_composite(tl, (int(round(512 - (b[0] + b[2]) / 2)),
                             int(round(436 - (b[1] + b[3]) / 2))))
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    full = render_full()
    full.save(OUT / "icon_full.png")

    sz = int(CANVAS * SAFE)
    fg = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    fg.alpha_composite(full.resize((sz, sz), Image.LANCZOS), ((CANVAS - sz) // 2,) * 2)
    fg.save(OUT / "icon_fg.png")
    print("wrote icon_full.png + icon_fg.png to", OUT)


if __name__ == "__main__":
    main()

"""Generate the mn_app launcher icons (МН brand tile).

Mirrors the in-app BrandMark: sky tile (#B7EBFF) + black outline + black "МН".
Outputs:
  app/assets/icon/icon_full.png  legacy full-bleed icon
  app/assets/icon/icon_fg.png    adaptive foreground (centered in 66% safe zone)
Run:  cd scripts && python gen_icon.py   (then `flutter pub run flutter_launcher_icons`)
"""
from PIL import Image, ImageDraw, ImageFont
import os

S = 1024
SKY = (183, 235, 255, 255)      # AppColors.sky  #B7EBFF
INK = (26, 26, 26, 255)         # AppColors.outline #1A1A1A
FONT = "C:/Windows/Fonts/seguibl.ttf"  # Segoe UI Black (Cyrillic-capable)
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "app", "assets", "icon")


def rounded(draw, box, radius, fill, outline=None, width=0):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def draw_mn(img, tile_box, radius, outline_w, font_frac):
    """Draw a sky tile with black outline and centered black МН onto img."""
    d = ImageDraw.Draw(img)
    x0, y0, x1, y1 = tile_box
    tw = x1 - x0
    rounded(d, tile_box, radius, SKY, INK, outline_w)
    fs = int(tw * font_frac)
    font = ImageFont.truetype(FONT, fs)
    text = "МН"
    # tracking: nudge letters tighter, centered
    bbox = d.textbbox((0, 0), text, font=font)
    tx = (x0 + x1) / 2 - (bbox[0] + bbox[2]) / 2
    ty = (y0 + y1) / 2 - (bbox[1] + bbox[3]) / 2
    d.text((tx, ty), text, font=font, fill=INK)


# --- icon_full: full-bleed sky tile with margin ---
full = Image.new("RGBA", (S, S), (0, 0, 0, 0))
m = int(S * 0.055)
draw_mn(full, (m, m, S - m, S - m), radius=int(S * 0.30), outline_w=int(S * 0.018),
        font_frac=0.40)
full.save(os.path.join(OUT, "icon_full.png"))

# --- icon_fg: adaptive foreground, tile centered within 66% safe zone ---
fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
# safe zone ~ center 66%; keep tile ~ 0.64*S so outline survives the mask
ts = int(S * 0.64)
off = (S - ts) // 2
draw_mn(fg, (off, off, off + ts, off + ts), radius=int(ts * 0.30),
        outline_w=int(ts * 0.022), font_frac=0.40)
fg.save(os.path.join(OUT, "icon_fg.png"))

print("wrote icon_full.png + icon_fg.png to", os.path.normpath(OUT))

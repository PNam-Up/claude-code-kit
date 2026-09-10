#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""설치 단계별 화면을 이미지로 렌더링한다 (영상 촬영용).

실제로 설치하지 않고 각 단계의 터미널 화면만 만든다.
Menlo 는 한글 글리프가 없어 ASCII 는 Menlo, 한글은 AppleSDGothicNeo 로 그리고
셀 폭을 고정해 진짜 터미널처럼 격자를 맞춘다.
"""
import os, unicodedata
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
W, H = 1920, 1080
FS = 26
MONO = "/System/Library/Fonts/Menlo.ttc"
HAN = "/System/Library/Fonts/AppleSDGothicNeo.ttc"

C = {
    "fg": "#e6e6e6", "dim": "#8a8a8a", "cyan": "#5fd7ff", "green": "#5fd75f",
    "red": "#ff6b6b", "yellow": "#ffd75f", "white": "#ffffff",
}
MAC_BG, WIN_BG = "#1e1e1e", "#012456"


def wide(ch):
    return unicodedata.east_asian_width(ch) in ("W", "F")


EMOJI = "/System/Library/Fonts/Apple Color Emoji.ttc"


def _strike_ok(n):
    try:
        ImageFont.truetype(EMOJI, n)
        return True
    except Exception:
        return False

# 이 폰트는 정해진 크기(strike)로만 렌더된다. 버전마다 목록이 달라 실제로 찾아본다.
EMOJI_STRIKE = next(
    (n for n in (160, 96, 64, 48, 32) if _strike_ok(n)), None)


def is_emoji(ch):
    o = ord(ch)
    return (0x1F300 <= o <= 0x1FAFF) or (0x2600 <= o <= 0x27BF) or o in (0x2705, 0x26A0)


class Pen:
    def __init__(self):
        self.mono = ImageFont.truetype(MONO, FS)
        self.han = ImageFont.truetype(HAN, FS)
        self.cell = self.mono.getlength("M")
        try:
            self.emoji = ImageFont.truetype(EMOJI, EMOJI_STRIKE)
        except Exception:
            self.emoji = None

    def _emoji(self, img, ch, x, y):
        """컬러 이모지는 고정 크기로만 렌더된다 → 크게 그려 축소해 붙인다."""
        if not self.emoji:
            return
        tile = Image.new("RGBA", (EMOJI_STRIKE * 2, EMOJI_STRIKE * 2), (0, 0, 0, 0))
        ImageDraw.Draw(tile).text((0, 0), ch, font=self.emoji, embedded_color=True)
        size = int(FS * 1.15)
        tile = tile.crop(tile.getbbox() or (0, 0, 1, 1)).resize((size, size), Image.LANCZOS)
        img.paste(tile, (int(x), int(y)), tile)

    def line(self, img, d, x, y, parts):
        for text, color in parts:
            for ch in text:
                if ord(ch) in (0xFE0E, 0xFE0F, 0x200D):
                    continue          # 변이 선택자 — 두부로 찍히므로 버린다
                if is_emoji(ch):
                    self._emoji(img, ch, x, y)
                    x += self.cell * 2
                    continue
                f = self.han if (ord(ch) > 0x2500 or wide(ch)) else self.mono
                if wide(ch):
                    # 2셀 폭 안에서 가운데 정렬 — 안 하면 자간이 뜬다.
                    gw = f.getlength(ch)
                    d.text((x + (self.cell * 2 - gw) / 2, y), ch, font=f,
                           fill=C.get(color, color))
                    x += self.cell * 2
                else:
                    d.text((x, y), ch, font=f, fill=C.get(color, color))
                    x += self.cell


def chrome(img, d, os_name, title):
    if os_name == "mac":
        d.rectangle([0, 0, W, 54], fill="#3a3a3a")
        for i, col in enumerate(("#ff5f57", "#febc2e", "#28c840")):
            d.ellipse([26 + i * 30, 20, 42 + i * 30, 36], fill=col)
    else:
        d.rectangle([0, 0, W, 54], fill="#1f1f1f")
        d.rectangle([W - 60, 14, W - 24, 40], outline="#888")
    return title


def render(os_name, name, lines, title):
    bg = MAC_BG if os_name == "mac" else WIN_BG
    img = Image.new("RGB", (W, H), bg)
    d = ImageDraw.Draw(img)
    p = Pen()
    chrome(img, d, os_name, title)
    tf = ImageFont.truetype(HAN, 22)
    d.text((W / 2 - tf.getlength(title) / 2, 16), title, font=tf, fill="#dddddd")
    y = 90
    for parts in lines:
        p.line(img, d, 60, y, parts if isinstance(parts, list) else [(parts, "fg")])
        y += FS + 12
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, f"{os_name}-{name}.png")
    img.save(path)
    return path

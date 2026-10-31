"""G 키 핑 휠 — 바깥 고리 4칸 = 핑, 가운데 원 위 = 스프레이 / 아래 = 이모트.

    python sources/gwheel/gwheel_gen.py            # 리팩(pack/assets/gwheel) + 데이터팩(Gwheel) 생성
    python sources/gwheel/gwheel_gen.py preview    # 미리보기 PNG (sources/gwheel/preview 또는 인자로 준 폴더)

G = 바닐라 Quick Actions 키. 클라가 #minecraft:quick_actions 다이얼로그(gwheel:wheel, 모두 같은 화면)를 바로 연다.
칸을 누르면 custom 클릭이 서버로 가고 gwheel.sk 가 처리한다.

배치
  plain_message 텍스트 한 덩어리. 줄 폭을 전부 L 로 맞춰 가운데 정렬이 줄마다 같게 한다.
  글리프마다 ascent 를 따로 줘서 원하는 y 에 놓는다(글리프 위 = 줄 위 + 7 - ascent).
  배경은 0번 줄(가장 먼저 그림), 클릭 띠는 보이지 않는 글리프를 제 위치 줄에 놓는다(26.3 은 글리프 사각형으로 클릭 판정).
"""
import json
import math
import os
import shutil
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
RP = os.path.dirname(os.path.dirname(HERE))                       # resourcepack-26.3
SERVER = os.path.join(os.path.dirname(RP), "hwalcass-26.3")
ASSETS = os.path.join(RP, "pack", "assets", "gwheel")
DATAPACK = os.path.join(SERVER, "world", "datapacks", "Gwheel")
PING_TEX = os.path.join(RP, "packs", "base", "assets", "minecraft", "textures", "font", "ping")
TTF = os.path.join(HERE, "galmuri9.ttf")
TTF_BIG = os.path.join(HERE, "galmuri11.ttf")
NS = "gwheel"
FONT = f"{NS}:ui"

# ── 기하 (GUI px) ──
# 본문 높이 = 화면 높이 - 66 (머리·바닥). 1080p + GUI 크기 4 = 270 - 66 = 204 안에 위 여백 16 + 휠 182 (줄 22개 = 198) 이 들어가게.
R_OUT, R_IN, R_CORE = 90, 55, 51
GAP = 2                       # 십자 틈 반폭
HX = R_OUT + 24               # 가로 반폭 (대각선 바깥의 핑 이름까지)
HY = R_OUT + 1                # 세로 반폭
TOP = 16                      # 위 여백 (본문은 위에 붙어서 나온다)
L = 2 * HX + 4                # 줄 폭
CX, CY = L // 2, TOP + HY     # 휠 중심 (본문 좌표)
NL = -(-(TOP + 2 * HY) // 9)  # 줄 수 = 높이 / 9 올림
CORE_ROW = 17                 # 가운데 원 클릭 띠 높이

# 핑: (키, 이름, 강조색, 칸) 칸 = 0 왼위 1 오른위 2 오른아래 3 왼아래 (zxcv 순서대로 시계 방향)
PINGS = [
    ("z", "해당 위치", (64, 184, 242)),
    ("x", "위험", (255, 84, 96)),
    ("c", "가는 중", (80, 226, 210)),
    ("v", "적 사라짐", (255, 210, 64)),
]

# ───────────────────────── 그리기 ─────────────────────────

_fonts = {}


def text_img(s, color, shadow=True, big=False):
    key = (TTF_BIG, 12) if big else (TTF, 10)
    if key not in _fonts:
        _fonts[key] = ImageFont.truetype(*key)
    font = _fonts[key]
    box = font.getbbox(s)
    w, h = box[2] - box[0] + 2, key[1] + 3
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.fontmode = "1"
    if shadow:
        d.text((1 - box[0], 1), s, font=font, fill=(0, 0, 0, 150))
    d.text((-box[0], 0), s, font=font, fill=tuple(color) + (255,))
    return img


def fit(im, size):
    box = im.getbbox() or (0, 0, im.width, im.height)
    im = im.crop(box)
    k = size / max(im.width, im.height)
    w, h = max(1, round(im.width * k)), max(1, round(im.height * k))
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.alpha_composite(im.resize((w, h), Image.LANCZOS), ((size - w) // 2, (size - h) // 2))
    return out


def quadrant_of(dx, dy):
    if dy < 0:
        return 0 if dx < 0 else 1
    return 3 if dx < 0 else 2


def draw_wheel():
    """배경 전부 (고리 4칸 + 핑 아이콘 + 바깥 모서리 핑 이름 + 가운데 원 위아래). 글리프 한 장은 255px 까지라 4조각으로 쓴다"""
    S = 4                                            # 4배로 그려 줄이면 가장자리가 매끈
    W = 2 * R_OUT + 2
    big = Image.new("RGBA", (W * S, W * S), (0, 0, 0, 0))
    px = big.load()
    c = W * S / 2
    for y in range(W * S):
        for x in range(W * S):
            dx, dy = (x + 0.5 - c) / S, (y + 0.5 - c) / S
            r = math.hypot(dx, dy)
            if r <= R_CORE:
                if abs(dy) < GAP / 2 + 0.5:                 # 위아래 갈림선 (고리 가로 틈과 이어짐)
                    continue
                t = r / R_CORE
                col = (int(14 + 8 * t), int(15 + 9 * t), int(20 + 12 * t), 232)
                if r > R_CORE - 1.2:
                    col = (255, 255, 255, 70)
                px[x, y] = col
            elif R_IN <= r <= R_OUT:
                if abs(dx) < GAP or abs(dy) < GAP:
                    continue
                q = quadrant_of(dx, dy)
                acc = PINGS[q][2]
                t = (r - R_IN) / (R_OUT - R_IN)
                base = (int(16 + 10 * t), int(17 + 11 * t), int(23 + 14 * t))
                col = base + (200,)
                if r > R_OUT - 3.2:                      # 바깥 강조 테
                    col = acc + (235,)
                elif r > R_OUT - 5:
                    col = tuple(int(base[i] * 0.4 + acc[i] * 0.6) for i in range(3)) + (220,)
                elif r < R_IN + 1.2 or abs(dx) < GAP + 1.2 or abs(dy) < GAP + 1.2:
                    col = (255, 255, 255, 40)
                px[x, y] = col
    ring = big.resize((W, W), Image.LANCZOS)
    img = Image.new("RGBA", (2 * HX, 2 * HY), (0, 0, 0, 0))
    ox, oy = HX, HY
    img.alpha_composite(ring, (ox - W // 2, oy - W // 2))

    rm = (R_IN + R_OUT) / 2
    for q, (key, name, acc) in enumerate(PINGS):
        sx = -1 if q in (0, 3) else 1
        sy = -1 if q in (0, 1) else 1
        # 아이콘: 칸의 대각선 가운데
        src = Image.open(os.path.join(PING_TEX, f"{q + 1}.png")).convert("RGBA")
        ic = fit(src, 24)
        m = rm / math.sqrt(2)
        img.alpha_composite(ic, (round(ox + sx * m - 12), round(oy + sy * m - 12)))
        # 이름: 고리 바로 바깥 대각선 모서리 (가까운 모서리가 고리에서 4px 떨어지는 첫 자리)
        lab = text_img(name, acc)
        t = rm / math.sqrt(2)
        while math.hypot(t - lab.width / 2, t - lab.height / 2) < R_OUT + 4:
            t += 0.5
        img.alpha_composite(lab, (round(ox + sx * t - lab.width / 2), round(oy + sy * t - lab.height / 2)))
        assert t + lab.width / 2 <= HX and t + lab.height / 2 <= HY, (name, t)

    # 가운데: 위 스프레이, 아래 이모트
    for sy, txt in ((-1, "스프레이"), (1, "이모트")):
        lab = text_img(txt, (240, 242, 248), big=True)
        img.alpha_composite(lab, (round(ox - lab.width / 2), round(oy + sy * R_CORE * 0.45 - lab.height / 2)))
    return img


def hit_image(w, h):
    """보이지 않는 띠. 마지막 열을 비워 글자폭(오른쪽 끝+1 +1)이 정확히 w 가 되게"""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for x in range(w - 1):
        for y in range(h):
            img.putpixel((x, y), (0, 0, 0, 1))
    return img


def mc_advance(img):
    a = img.getchannel("A")
    for x in range(img.width - 1, -1, -1):
        if any(a.getpixel((x, y)) for y in range(img.height)):
            return x + 2
    return 1


# ───────────────────────── 레이아웃 ─────────────────────────

class Font:
    """gwheel:ui 한 벌. 공백 + 그림 글리프(그림마다 자기 ascent)"""

    SP = {2 ** k: chr(0xE000 + k) for k in range(9)} | {-(2 ** k): chr(0xE010 + k) for k in range(9)}

    def __init__(self):
        self.providers = [{"type": "space", "advances": {ch: a for a, ch in self.SP.items()}}]
        self.next = 0xE100
        self.files = {}

    def glyph(self, file, img, ascent):
        ch = chr(self.next)
        self.next += 1
        self.providers.append({"type": "bitmap", "file": file, "height": img.height, "ascent": ascent, "chars": [ch]})
        return ch, mc_advance(img)

    def move(self, dx):
        out = ""
        sign = 1 if dx > 0 else -1
        dx = abs(dx)
        for k in range(8, -1, -1):
            while dx >= 2 ** k:
                out += self.SP[sign * 2 ** k]
                dx -= 2 ** k
        return out


class Layout:
    def __init__(self):
        self.lines = {}

    def put(self, k, x, item):
        """item = (문자, 폭, 클릭id 또는 None)"""
        self.lines.setdefault(k, []).append((x,) + item)

    def compose(self, F):
        extra, buf = [], ""
        for k in range(NL):
            if k:
                buf += "\n"
            cur = 0
            for x, ch, adv, click in self.lines.get(k, []):
                buf += F.move(x - cur)
                if click:
                    if buf:
                        extra.append(buf)
                        buf = ""
                    extra.append({"text": ch, "click_event": {"action": "custom", "id": f"{NS}:{click}"}})
                else:
                    buf += ch
                cur = x + adv
            buf += F.move(L - cur)
        if buf:
            extra.append(buf)
        return {"text": "", "font": FONT, "color": "#FFFFFF", "shadow_color": 0, "extra": extra}


def place(F, y, file, img):
    """본문 y 에 놓을 글리프 → (줄, 문자, 폭)"""
    k = y // 9
    s = y - 9 * k
    if 7 - s > img.height:
        k -= 1
        s += 9
    ch, adv = F.glyph(file, img, 7 - s)
    return k, ch, adv


def hit_strips():
    """(x, y, w, h, 칸) — 겹치지 않게 나눈 클릭 띠"""
    x0, x1 = CX - HX, CX + HX
    strips = []
    top = CY - HY
    strips += [(x0, top, CX - x0, HY - R_CORE, "p1"), (CX, top, x1 - CX, HY - R_CORE, "p2")]
    for y in range(CY - R_CORE, CY + R_CORE, CORE_ROW):
        h = min(CORE_ROW, CY + R_CORE - y)
        near = min(abs(y - CY), abs(y + h - CY)) if not (y < CY < y + h) else 0
        cw = round(math.sqrt(max(0, R_CORE ** 2 - near ** 2)))
        left_q, right_q = ("p1", "p2") if y < CY else ("p4", "p3")
        strips += [(x0, y, CX - cw - x0, h, left_q), (CX - cw, y, 2 * cw, h, "spray" if y < CY else "emote"),
                   (CX + cw, y, x1 - CX - cw, h, right_q)]
    strips += [(x0, CY + R_CORE, CX - x0, HY - R_CORE, "p4"), (CX, CY + R_CORE, x1 - CX, HY - R_CORE, "p3")]
    return [s for s in strips if s[2] > 0]


# ───────────────────────── 생성 ─────────────────────────

def write_json(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(obj, f, ensure_ascii=False, separators=(",", ":"))


def generate():
    for d in (ASSETS, DATAPACK):
        if os.path.isdir(d):
            shutil.rmtree(d)
    tex = os.path.join(ASSETS, "textures")
    os.makedirs(os.path.join(tex, "ui"), exist_ok=True)

    F = Font()
    base = Layout()

    wheel = draw_wheel()
    for ty in (0, 1):                                              # 0번 줄에서 아래로 내려 그림
        for tx in (0, 1):
            tile = wheel.crop((tx * HX, ty * HY, (tx + 1) * HX, (ty + 1) * HY))
            tile.save(os.path.join(tex, "ui", f"wheel{ty}{tx}.png"))
            ch, adv = F.glyph(f"{NS}:ui/wheel{ty}{tx}.png", tile, 7 - (CY - HY + ty * HY))
            base.put(0, CX - HX + tx * HX, (ch, adv, None))

    hits = {}
    for x, y, w, h, zone in hit_strips():
        key = (w, h)
        if key not in hits:
            hits[key] = hit_image(w, h)
            hits[key].save(os.path.join(tex, "ui", f"hit_{w}x{h}.png"))
        k, ch, adv = place(F, y, f"{NS}:ui/hit_{w}x{h}.png", hits[key])
        base.put(k, x, (ch, adv, zone))

    write_json(os.path.join(ASSETS, "font", "ui.json"), {"providers": F.providers})

    dialog = {
        "type": "minecraft:dialog_list",
        "title": "",
        "external_title": "핑 휠",
        "after_action": "close",
        "pause": False,
        "dialogs": [],
        "body": [{"type": "minecraft:plain_message", "width": L + 16, "contents": base.compose(F)}],
    }
    write_json(os.path.join(DATAPACK, "data", NS, "dialog", "wheel.json"), dialog)
    write_json(os.path.join(DATAPACK, "data", "minecraft", "tags", "dialog", "quick_actions.json"),
               {"replace": False, "values": [f"{NS}:wheel"]})
    write_json(os.path.join(DATAPACK, "pack.mcmeta"),
               {"pack": {"description": "G 핑 휠", "min_format": [121, 0], "max_format": [121, 0]}})
    fn = os.path.join(DATAPACK, "data", NS, "function")
    os.makedirs(fn, exist_ok=True)
    gate = ('@s[scores={rclass=1..},gamemode=!spectator,nbt={HurtTime:0s},'
            'nbt=!{active_effects:[{id:"minecraft:invisibility"}]}]')
    for kind, cool in (("spray", "spraycool"), ("emote", "emotecool")):
        with open(os.path.join(fn, f"{kind}.mcfunction"), "w", encoding="utf-8", newline="\r\n") as f:
            f.write(f"# 휠 가운데 {'위' if kind == 'spray' else '아래'} 반원. 9번칸/모드키(game:9lccheck → game:9lc)와 같은 조건\n")
            f.write(f"execute if entity {gate} unless score @s {cool} matches 1.. run function game:{kind}/use\n")
            f.write(f"execute if entity {gate} run tag @s add emotecool\n")

    size = sum(os.path.getsize(os.path.join(dp, f)) for dp, _, fs in os.walk(DATAPACK) for f in fs)
    print(f"그림 글리프 {len(F.providers) - 1}개, 클릭 띠 {len(hit_strips())}개, 데이터팩 {size // 1024}KB")


# ───────────────────────── 미리보기 ─────────────────────────

def preview(out_dir):
    font = json.load(open(os.path.join(ASSETS, "font", "ui.json"), encoding="utf-8"))
    space, glyphs = {}, {}
    for p in font["providers"]:
        if p["type"] == "space":
            space.update(p["advances"])
        else:
            ns, path = p["file"].split(":")
            img = Image.open(os.path.join(RP, "pack", "assets", ns, "textures", path)).convert("RGBA")
            glyphs[p["chars"][0]] = (img, p["ascent"])
    cols = {"p1": (64, 184, 242), "p2": (255, 84, 96), "p3": (80, 226, 210), "p4": (255, 210, 64),
            "spray": (200, 120, 255), "emote": (120, 255, 120)}
    os.makedirs(out_dir, exist_ok=True)
    for _ in (0,):
        d = json.load(open(os.path.join(DATAPACK, "data", NS, "dialog", "wheel.json"), encoding="utf-8"))
        S = 2
        H = NL * 9 + 8
        canvas = Image.new("RGBA", (L * S, H * S), (58, 70, 62, 255))
        hits = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        hd = ImageDraw.Draw(hits)
        st = {"x": 0, "k": 0, "warn": set()}

        def run(text, click):
            for c in text:
                if c == "\n":
                    if st["x"] != L:
                        st["warn"].add(f"줄{st['k']} 폭{st['x']}")
                    st["k"] += 1
                    st["x"] = 0
                elif c in space:
                    st["x"] += space[c]
                elif c in glyphs:
                    img, asc = glyphs[c]
                    top = 9 * st["k"] + 7 - asc
                    canvas.alpha_composite(img.resize((img.width * S, img.height * S), Image.NEAREST), (st["x"] * S, top * S))
                    if click:
                        z = click.split(":")[1]
                        hd.rectangle((st["x"] * S, top * S, (st["x"] + img.width) * S - 1, (top + img.height) * S - 1),
                                     fill=cols[z] + (70,), outline=cols[z] + (200,))
                    st["x"] += mc_advance(img)
                else:
                    st["warn"].add(f"없는 글자 {ord(c):X}")

        for part in d["body"][0]["contents"]["extra"]:
            if isinstance(part, str):
                run(part, None)
            else:
                run(part["text"], part["click_event"]["id"])
        both = Image.new("RGBA", (canvas.width * 2 + 8, canvas.height), (255, 255, 255, 255))
        both.paste(canvas, (0, 0))
        hc = canvas.copy()
        hc.alpha_composite(hits)
        both.paste(hc, (canvas.width + 8, 0))
        p = os.path.join(out_dir, "gwheel.png")
        both.save(p)
        print(p, "경고: " + "; ".join(sorted(st["warn"])[:6]) if st["warn"] else "ok")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "preview":
        preview(sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, "preview"))
    else:
        generate()

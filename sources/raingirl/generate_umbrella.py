"""여우비 우산 리디자인 v2 — 정팔각형 층 띠 방식.
원본(38=펼침, 39=접힘)의 축 (6, 8.5), 전체 높이(-14.5..25), 천 반경·돔 높이, display를 유지.
천: 8폭 정팔각형 돔을 얇은 층 띠로 쌓음(각 변 = 직사각형 큐브를 Y축 ±22.5°로 회전, 단일축만 사용).
살: 꼭짓점 방향(0/45/90...)으로 천 아래 계단형, 대·손잡이·꼭지는 실버.
usage: python gen2.py <outdir> [mc_sign]
"""
import json, math, sys, os
from PIL import Image

OUT = sys.argv[1]
SGN = float(sys.argv[2]) if len(sys.argv) > 2 else -1.0   # MC Y회전 부호 (검증용)
os.makedirs(OUT, exist_ok=True)
CX, CZ = 6.0, 8.5
TEXREF = "dor:item/char/raingirl/umbrella"
T22 = math.tan(math.radians(22.5))
C22 = math.cos(math.radians(22.5))

PAL = {  # name: (top/side, down)
    "sky":    ((0x8C, 0xD2, 0xF4), (0xB9, 0xE5, 0xF9)),
    "trim":   ((0xF2, 0xFA, 0xFE), (0xDC, 0xF0, 0xFB)),
    "silver": ((0xC6, 0xCC, 0xD4), (0xA8, 0xAF, 0xB8)),
    "chrome": ((0xF0, 0xF3, 0xF7), (0xCC, 0xD2, 0xD9)),
    "grip":   ((0x86, 0x8E, 0x99), (0x6E, 0x76, 0x81)),
    "strap":  ((0x5E, 0xA9, 0xDA), (0x50, 0x97, 0xC8)),
    "skyD":   ((0x76, 0xC0, 0xEC), (0xA2, 0xD8, 0xF5)),
}
NAMES = list(PAL)
TEX = 32

def uv(name, down):
    i = NAMES.index(name)
    px, py = (i % 8) * 4, (i // 8) * 8 + (4 if down else 0)
    k = 16 / TEX
    return [round((px + 1) * k, 4), round((py + 1) * k, 4), round((px + 3) * k, 4), round((py + 3) * k, 4)]

def write_texture(path):
    im = Image.new("RGBA", (TEX, TEX), (0, 0, 0, 0))
    for i, n in enumerate(NAMES):
        for d in (0, 1):
            px, py = (i % 8) * 4, (i // 8) * 8 + 4 * d
            for x in range(px, px + 4):
                for y in range(py, py + 4):
                    im.putpixel((x, y), PAL[n][d] + (255,))
    im.save(path)

R = lambda v: round(v, 4)

def box(f, t, color, rot=None, skip=()):
    faces = {fn: {"uv": uv(color, fn == "down"), "texture": "#0"}
             for fn in ("north", "south", "east", "west", "up", "down") if fn not in skip}
    e = {"from": [R(c) for c in f], "to": [R(c) for c in t], "faces": faces}
    if rot:
        e["rotation"] = rot
    return e

def radial_box(phi, r0, r1, half, y0, y1, color, skip=()):
    """phi 방향(도, +x→+z)으로 반경 r0..r1, 접선 ±half, 높이 y0..y1 인 직사각형."""
    beta = round(phi / 90.0) * 90 % 360
    delta = phi - round(phi / 90.0) * 90
    if beta == 0:
        f, t = (CX + r0, y0, CZ - half), (CX + r1, y1, CZ + half)
    elif beta == 90:
        f, t = (CX - half, y0, CZ + r0), (CX + half, y1, CZ + r1)
    elif beta == 180:
        f, t = (CX - r1, y0, CZ - half), (CX - r0, y1, CZ + half)
    else:
        f, t = (CX - half, y0, CZ - r1), (CX + half, y1, CZ - r0)
    rot = None
    if abs(delta) > 1e-6:
        rot = {"angle": SGN * delta, "axis": "y", "origin": [CX, R((y0 + y1) / 2), CZ]}
    return box(f, t, color, rot, skip)

SIDES = [22.5 + 45 * k for k in range(8)]     # 변(천 폭) 법선 방향
VERTS = [45 * k for k in range(8)]            # 꼭짓점(살) 방향

def octagon_band(a_in, a_out, y0, y1, color, skip=()):
    half = a_out * T22
    return [radial_box(p, a_in, a_out, half, y0, y1, color, skip) for p in SIDES]

def shaft_parts(els, rod_top):
    els.append(box((5.5, -8.5, 8.0), (6.5, rod_top, 9.0), "silver"))
    els.append(box((5.25, -14.0, 7.75), (6.75, -8.5, 9.25), "grip"))
    els.append(box((5.0, -14.5, 7.5), (7.0, -14.0, 9.5), "chrome"))
    els.append(box((5.0, -9.0, 7.5), (7.0, -8.5, 9.5), "chrome"))
    els.append(box((5.75, rod_top, 8.25), (6.25, 25.0, 8.75), "chrome"))

# ---------------- 펼친 우산 ----------------
A0 = 15.25                 # 가장자리 apothem (원본 반경 ~16.5 꼭짓점 기준)
Y_RIM, Y_APEX = 9.5, 21.0
EXP = 1.85

def prof_y(a):
    u = min(1.0, a / A0)
    return Y_RIM + (Y_APEX - Y_RIM) * (1 - u ** EXP)

def prof_a(y):
    u = (1 - (y - Y_RIM) / (Y_APEX - Y_RIM))
    return A0 * max(0.0, u) ** (1 / EXP)

def levels(step_arc=0.45):
    """돔을 호 길이 기준으로 균등 분할한 층 높이들 (아래→위)."""
    ys = [Y_RIM]
    y = Y_RIM
    while True:
        a = prof_a(y)
        # 다음 높이: 호 길이 step_arc 만큼, 0.25 격자로 스냅(최소 0.25)
        best = None
        for k in range(1, 400):
            y2 = y + 0.01 * k
            if y2 > Y_APEX:
                break
            d = math.hypot(a - prof_a(y2), y2 - y)
            if d >= step_arc:
                best = y2
                break
            best = y2
        if best is None or best >= Y_APEX - 1e-6:
            break
        ys.append(best)
        y = best
    return ys

def open_model(part="all"):
    els = []
    ys = levels()
    for i, y0 in enumerate(ys):
        y1 = ys[i + 1] if i + 1 < len(ys) else y0 + 0.5
        a_out = prof_a(y0)
        a_in = prof_a(y1) if i + 1 < len(ys) else 0.0
        a_in = max(0.0, a_in - 0.02)
        thick = max(0.2, y1 - y0)
        els += octagon_band(a_in, a_out, y1 - thick, y1, "sky")
    top = ys[-1] + 0.5
    # 가장자리 흰 파이핑
    els += octagon_band(A0 - 0.6, A0 + 0.25, Y_RIM - 0.25, Y_RIM + 0.25, "trim")
    # 꼭대기 캡
    els.append(box((5.0, top, 7.5), (7.0, top + 0.5, 9.5), "chrome"))
    els.append(box((5.25, top + 0.5, 7.75), (6.75, top + 1.0, 9.25), "chrome"))
    # 살: 꼭짓점 방향, 2층마다 천 아래 한 마디
    for p in VERTS:
        for i in range(0, len(ys) - 1, 2):
            y0 = ys[i]
            j = min(i + 2, len(ys) - 1)
            yj = ys[j]
            d_out = prof_a(y0) / C22
            d_in = prof_a(yj) / C22
            if d_out < 1.2:
                continue
            yb = ys[i + 1] - max(0.2, ys[i + 1] - ys[i])          # 이 마디 천 밑면
            ytop = ys[j] - max(0.2, ys[j] - ys[j - 1])               # 다음 마디 천 밑면
            els.append(radial_box(p, max(0.9, d_in - 0.05), d_out - 0.1, 0.18, yb - 0.3, max(ytop, yb + 0.05), "silver"))
        d = A0 / C22
        els.append(radial_box(p, d - 0.7, d + 0.15, 0.32, Y_RIM - 0.7, Y_RIM - 0.2, "chrome"))
    canopy = els
    stick = []
    # 런너(대 위 슬라이더)
    stick.append(box((5.0, 4.5, 7.5), (7.0, 6.0, 9.5), "chrome"))
    shaft_parts(stick, top)
    if part == "canopy":
        return shift(canopy, 8.0 - CX, -(Y_RIM + top + 1.0) / 2 + 8.0, 8.0 - CZ)
    if part == "stick":
        return stick
    return canopy + stick

def shift(els, dx, dy, dz):
    """날아가는 천 디스플레이용: 천 축을 모델 중심(8, 8, 8)으로 옮겨 제자리 회전이 깔끔하게."""
    out = []
    for e in els:
        e = json.loads(json.dumps(e))
        e["from"] = [R(e["from"][0] + dx), R(e["from"][1] + dy), R(e["from"][2] + dz)]
        e["to"] = [R(e["to"][0] + dx), R(e["to"][1] + dy), R(e["to"][2] + dz)]
        if "rotation" in e:
            o = e["rotation"]["origin"]
            e["rotation"]["origin"] = [R(o[0] + dx), R(o[1] + dy), R(o[2] + dz)]
        out.append(e)
    return out

# ---------------- 접힌 우산 ----------------
CLOSED_PTS = [(-6.0, 1.3), (-5.0, 1.95), (-3.75, 2.3), (-2.5, 2.4), (11.0, 2.4), (14.0, 2.25),
              (17.0, 1.95), (19.5, 1.5), (21.5, 1.0), (22.75, 0.6)]

def closed_a(y):
    for (ya, ra), (yb, rb) in zip(CLOSED_PTS, CLOSED_PTS[1:]):
        if ya <= y <= yb:
            u = (y - ya) / (yb - ya)
            return ra + (rb - ra) * u
    return 0.0

def closed_model():
    els = []
    # 테이퍼 구간은 0.5 단위 마디, 일정한 몸통은 한 마디
    ys = []
    y = -6.0
    while y < 22.75 - 1e-6:
        if -2.5 <= y < 11.0:
            y2 = 11.0
        else:
            y2 = min(22.75, y + 0.5)
        ys.append((y, y2))
        y = y2
    for (y0, y1) in ys:
        a = closed_a((y0 + y1) / 2)
        els += octagon_band(0.0, a, y0, y1, "sky")
    # 고정끈 + 똑딱이
    els += octagon_band(0.0, 2.6, 8.25, 9.25, "strap")
    els.append(box((8.45, 8.4, 8.15), (9.05, 9.1, 8.85), "chrome"))
    # 천 아래 링
    els.append(box((5.0, -6.5, 7.5), (7.0, -6.0, 9.5), "chrome"))
    shaft_parts(els, 22.75)
    return els


# ---- display: 손잡이 중심(GRIP)이 손 위치에 오도록 회전 후 이동값을 계산한다 ----
GRIP = (6.0, -11.5, 8.5)

def _rot(rx, ry, rz, v):
    # Minecraft ItemTransform: rotationXYZ → v' = Rx(Ry(Rz v))
    x, y, z = v
    a = math.radians(rz); x, y = x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a)
    a = math.radians(ry); x, z = x * math.cos(a) + z * math.sin(a), -x * math.sin(a) + z * math.cos(a)
    a = math.radians(rx); y, z = y * math.cos(a) - z * math.sin(a), y * math.sin(a) + z * math.cos(a)
    return (x, y, z)

def _slot(rot, scale, anchor=GRIP, offset=(0, 0, 0)):
    g = tuple((anchor[i] - 8) * scale for i in range(3))
    p = _rot(rot[0], rot[1], rot[2], g)
    t = [round(-p[i] + offset[i], 2) for i in range(3)]
    t = [max(-80, min(80, v)) for v in t]
    return {"rotation": list(rot), "translation": t, "scale": [scale] * 3}

def _left(d):
    return {"rotation": [d["rotation"][0], -d["rotation"][1], -d["rotation"][2]],
            "translation": [-d["translation"][0], d["translation"][1], d["translation"][2]], "scale": d["scale"]}

def display_for(kind):
    """kind: open / closed. Blockbench 플레이어 참조 모델로 맞춘 값(2026-10-10).
    3인칭 펼침 = 머리 위로 우산을 쓴 자세, 접힘 = 검처럼 앞으로 겨눈 자세."""
    center = (6.0, 5.25, 8.5)
    if kind == "open":
        tp = _slot((90, 0, 0), 0.9)
        fp = _slot((-15, 0, 15), 0.45)
        gui = _slot((25, -35, 0), 0.4, center)
        ground = _slot((0, 0, 0), 0.3, center)
        fixed = _slot((0, 0, 0), 0.45, center)
    else:
        tp = _slot((120, 0, 0), 0.8)
        fp = _slot((-45, 0, 0), 0.6)
        gui = _slot((0, 0, -45), 0.42, center)
        ground = _slot((0, 0, 90), 0.3, center)
        fixed = _slot((0, 0, -45), 0.45, center)
    return {"thirdperson_righthand": tp, "thirdperson_lefthand": _left(tp),
            "firstperson_righthand": fp, "firstperson_lefthand": _left(fp),
            "gui": gui, "ground": ground, "fixed": fixed}

def display_of(p):
    return json.load(open(p, encoding="utf-8")).get("display", {})

src = os.path.join(os.path.dirname(os.path.abspath(__file__)), "original")   # 원본 38/39 (display 출처)
write_texture(os.path.join(OUT, "umbrella.png"))
MODELS = [
    ("umbrella_open", lambda: open_model("all"), "38"),
    ("umbrella_closed", closed_model, "39"),
    ("umbrella_stick", lambda: open_model("stick"), "38"),      # 천이 날아간 동안 손에 남는 대
    ("umbrella_canopy", lambda: open_model("canopy"), None),     # 날아가는 천 (item_display 용, 중심 정렬)
]
for name, fn, srcn in MODELS:
    els = fn()
    m = {"credit": "Hwalcass raingirl umbrella redesign", "texture_size": [TEX, TEX],
         "textures": {"0": TEXREF, "particle": TEXREF}, "elements": els}
    if srcn:
        m["display"] = display_for("closed" if name == "umbrella_closed" else "open")
    co = [c for e in els for c in e["from"] + e["to"]]
    print(name, "elements", len(els), "range", min(co), max(co))
    with open(os.path.join(OUT, name + ".json"), "w", encoding="utf-8") as f:
        json.dump(m, f, ensure_ascii=False, indent=1)

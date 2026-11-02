"""상태이상 HUD — 오른쪽 위에 카드가 쌓이고, 새로 걸릴 때마다 기존 카드가 왼쪽으로 밀린다.

    python sources/statushud/statushud_gen.py                      # 카드 텍스처 + 포스트이펙트 JSON 생성
    python sources/statushud/statushud_gen.py preview <배경> [폴더]  # 셰이더 알고리즘을 그대로 돌린 미리보기

효과 ID = hwalcass:status/<종류>. 서버는 걸릴 때 posteffect add, 풀릴 때 remove 만 한다.
클라 효과 목록은 add 순서를 유지하고, 셰이더(shaders/post/status_icon.fsh)가 매 프레임
"이미 그려진 카드를 한 칸 왼쪽으로 밀고 자기를 오른쪽 끝에 그린다" → 칸 계산이 필요 없다.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
RP = os.path.dirname(os.path.dirname(HERE))
ASSETS = os.path.join(RP, "pack", "assets", "hwalcass")
TEX_DIR = os.path.join(ASSETS, "textures", "effect", "status")
FX_DIR = os.path.join(ASSETS, "post_effect", "status")

# (id, 원본 아이콘, 이름)
STATUS = [
    ("stun", "40px-Stun_icon.png", "기절"),
    ("root", "40px-Root_icon.png", "속박"),
    ("silence", "40px-Silence_icon.png", "침묵"),
    ("disarm", "40px-Disarm_icon.png", "무장해제"),
    ("grounded", "40px-Grounded_icon.png", "이동기 봉인"),
    ("grievous", "40px-Grievous_Wounds_icon.png", "치유 감소"),
]

# 셰이더 상수와 같아야 한다 (status_icon.fsh, 1080p 기준 px)
CARD, STEP, RIGHT, TOP, RADIUS, SLOTS = 52, 58, 16, 15, 9, 6
SIG0, SIG1 = (28, 30, 38), (30, 28, 38)


def accent(icon):
    """아이콘에서 채도 높은 부분의 평균색. 회색 아이콘이면 은색"""
    tot, n = [0, 0, 0], 0
    for r, g, b, a in getattr(icon, "get_flattened_data", icon.getdata)():
        if a < 200:
            continue
        mx, mn = max(r, g, b), min(r, g, b)
        if mx < 60 or (mx - mn) / mx < 0.35:
            continue
        tot = [tot[0] + r, tot[1] + g, tot[2] + b]
        n += 1
    if n < 30:
        return (196, 202, 210)
    c = [v / n for v in tot]
    k = 235 / max(c)
    return tuple(min(255, round(v * k)) for v in c)


def card(icon):
    """52x52 불투명 카드. 바깥 1px 는 모든 카드가 같은 어두운 테(밀 때 가장자리 색이 섞여도 티가 안 나게)"""
    S = 4
    acc = accent(icon)
    big = Image.new("RGBA", (CARD * S, CARD * S), (0, 0, 0, 0))
    e = CARD * S - 1
    mask = Image.new("L", big.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, e, e), RADIUS * S, fill=255)
    body = Image.new("RGBA", big.size, (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    for y in range(CARD * S):                            # 위가 살짝 밝은 세로 그라데이션
        t = y / e
        bd.line((0, y, e, y), fill=(int(30 - 14 * t), int(32 - 15 * t), int(40 - 18 * t), 255))
    big.paste(body, (0, 0), mask)
    d = ImageDraw.Draw(big)
    d.rounded_rectangle((0, 0, e, e), RADIUS * S, outline=(8, 9, 12, 255), width=S)                    # 공통 바깥 테
    d.rounded_rectangle((S, S, e - S, e - S), (RADIUS - 1) * S, outline=acc + (255,), width=2 * S)       # 강조 테두리
    d.rounded_rectangle((3 * S, 3 * S, e - 3 * S, e - 3 * S), (RADIUS - 3) * S,
                        outline=(255, 255, 255, 30), width=S)                                         # 안쪽 하이라이트
    img = big.resize((CARD, CARD), Image.LANCZOS)

    ix, iy = (CARD - icon.width) // 2, (CARD - icon.height) // 2
    halo = Image.new("RGBA", (CARD, CARD), (0, 0, 0, 0))
    halo.paste(Image.new("RGBA", icon.size, acc + (255,)), (ix, iy), icon.getchannel("A"))
    halo = halo.filter(ImageFilter.GaussianBlur(3))
    halo.putalpha(halo.getchannel("A").point(lambda a: a * 0.45))
    a = img.getchannel("A")
    img.alpha_composite(halo)                            # 아이콘 뒤 은은한 빛
    img.alpha_composite(icon, (ix, iy))
    img.putalpha(a)                                      # 카드 모양 밖으로 번지지 않게
    return img


def write_json(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)
        f.write("\n")


def effect(sid):
    return {
        "targets": {"swap": {}},
        "passes": [
            {
                "vertex_shader": "minecraft:core/screenquad",
                "fragment_shader": "hwalcass:post/status_icon",
                "inputs": [
                    {"sampler_name": "In", "target": "minecraft:main"},
                    {"sampler_name": "Icon", "location": f"hwalcass:status/{sid}", "width": CARD, "height": CARD,
                     "bilinear": True},
                ],
                "output": "swap",
            },
            {
                "vertex_shader": "minecraft:core/screenquad",
                "fragment_shader": "minecraft:post/blit",
                "inputs": [{"sampler_name": "In", "target": "swap"}],
                "uniforms": {"BlitConfig": [{"name": "ColorModulate", "type": "vec4", "value": [1.0, 1.0, 1.0, 1.0]}]},
                "output": "minecraft:main",
            },
        ],
    }


def generate():
    for d in (TEX_DIR, FX_DIR):
        os.makedirs(d, exist_ok=True)
        for f in os.listdir(d):
            os.remove(os.path.join(d, f))
    for sid, src, _ in STATUS:
        icon = Image.open(os.path.join(HERE, "icons", src)).convert("RGBA")
        card(icon).save(os.path.join(TEX_DIR, f"{sid}.png"))
        write_json(os.path.join(FX_DIR, f"{sid}.json"), effect(sid))
    print(f"카드 {len(STATUS)}장, 효과 {len(STATUS)}개")


# ───────────── 미리보기: 셰이더 한 패스를 numpy 로 그대로 흉내 ─────────────

def px(v, unit):
    return max(1, int(np.floor(v * unit + 0.5)))


def run_pass(img, tex):
    """img: (H, W, 3) float 0~1, 위쪽 원점. tex: (CARD, CARD, 4) float. 셰이더 status_icon 한 번"""
    H, W, _ = img.shape
    unit = H / 1080
    card, step, right, top = px(CARD, unit), px(STEP, unit), px(RIGHT, unit), px(TOP, unit)
    sig = (card // 2, px(4.5, unit))
    out = img.copy()
    n = 0
    for i in range(SLOTS):
        x = W - right - card - i * step + sig[0]
        y = top + sig[1]
        if not (np.allclose(img[y, x] * 255, SIG0, atol=0.5) and np.allclose(img[y, x + 1] * 255, SIG1, atol=0.5)):
            break
        n += 1
    yy, xx = np.mgrid[0:card, 0:card]
    p = np.stack([xx, yy], -1) + 0.5 - card * 0.5
    rad = 9 * unit
    q = np.abs(p) - (card * 0.5 - rad)
    d = np.linalg.norm(np.maximum(q, 0), axis=-1) + np.minimum(np.max(q, axis=-1), 0) - rad
    cov = np.clip(0.5 - d, 0, 1)[..., None]
    tx = Image.fromarray((tex * 255).astype(np.uint8), "RGBA").resize((card, card), Image.BILINEAR)
    c = np.asarray(tx).astype(float) / 255
    for k in range(SLOTS):
        x0 = W - right - card - k * step
        dst = out[top:top + card, x0:x0 + card]
        if k == 0:
            rgb = dst * (1 - c[..., 3:]) + c[..., :3] * c[..., 3:]
            rgb[sig[1], sig[0]] = np.array(SIG0) / 255
            rgb[sig[1], sig[0] + 1] = np.array(SIG1) / 255
            out[top:top + card, x0:x0 + card] = np.where(cov > 0, rgb, dst)
        elif k <= n:
            src = img[top:top + card, x0 + step:x0 + step + card]
            here = img[top:top + card, x0:x0 + card]
            out[top:top + card, x0:x0 + card] = here * (1 - cov) + src * cov
    return out


def count_cards(img):
    H, W, _ = img.shape
    unit = H / 1080
    card, step, right, top = px(CARD, unit), px(STEP, unit), px(RIGHT, unit), px(TOP, unit)
    sx, sy = card // 2, px(4.5, unit)
    n = 0
    for i in range(SLOTS):
        x = W - right - card - i * step + sx
        if not (np.allclose(img[top + sy, x] * 255, SIG0, atol=0.5) and np.allclose(img[top + sy, x + 1] * 255, SIG1, atol=0.5)):
            break
        n += 1
    return n


def film_pass(img, guard=True):
    """화면 전체를 흑백으로 바꾸는 효과(레인걸 필름 같은 것). guard = statusHudKeep 적용"""
    out = img.copy()
    g = img @ np.array([0.299, 0.587, 0.114])
    out[:] = g[..., None] * 0.9
    if guard:
        H, W, _ = img.shape
        unit = H / 1080
        card, step, right, top = px(CARD, unit), px(STEP, unit), px(RIGHT, unit), px(TOP, unit)
        for k in range(count_cards(img)):
            x0 = W - right - card - k * step
            yy, xx = np.mgrid[0:card, 0:card]
            pp = np.stack([xx, yy], -1) + 0.5 - card * 0.5
            rad = 9 * unit
            q = np.abs(pp) - (card * 0.5 - rad)
            d = np.linalg.norm(np.maximum(q, 0), axis=-1) + np.minimum(np.max(q, axis=-1), 0) - rad
            m = (np.clip(0.5 - d, 0, 1) > 0)[..., None]
            out[top:top + card, x0:x0 + card] = np.where(m, img[top:top + card, x0:x0 + card], out[top:top + card, x0:x0 + card])
    return out


def preview(bg_path, out_dir):
    bg = np.asarray(Image.open(bg_path).convert("RGB")).astype(float) / 255
    tex = {sid: np.asarray(Image.open(os.path.join(TEX_DIR, f"{sid}.png")).convert("RGBA")).astype(float) / 255
           for sid, _, _ in STATUS}
    # 서버가 add/remove 만 한 결과 목록 (= 클라 패스 순서)
    # "film" = 카드를 지키는 흑백 효과, "film!" = 지키지 않는 흑백 효과 (비교용)
    steps = [["stun"], ["stun", "root"], ["stun", "root", "silence"],
             ["stun", "root", "silence", "grievous"], ["stun", "silence", "grievous"],
             ["stun", "silence", "grievous", "disarm", "grounded", "root"],
             ["stun", "root", "film", "silence"], ["stun", "root", "film!", "silence"]]
    os.makedirs(out_dir, exist_ok=True)
    crops = []
    for i, active in enumerate(steps):
        img = bg
        for sid in active:
            if sid.startswith("film"):
                img = np.round(film_pass(img, guard=sid == "film") * 255) / 255
            else:
                img = np.round(run_pass(img, tex[sid]) * 255) / 255      # 패스마다 8비트 대상에 기록
        im = Image.fromarray((img * 255).round().astype(np.uint8))
        im.save(os.path.join(out_dir, f"status_{i}.png"))
        crops.append(im.crop((im.width - 520, 0, im.width, 100)))
        print(i, "+".join(active), "→ 카드", count_cards(img), "장")
    sheet = Image.new("RGB", (520, 106 * len(crops) - 6), (255, 255, 255))
    for i, c in enumerate(crops):
        sheet.paste(c, (0, i * 106))
    p = os.path.join(out_dir, "status_steps.png")
    sheet.save(p)
    print(p)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "preview":
        preview(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else os.path.join(HERE, "preview"))
    else:
        generate()

"""레인걸(153) VFX 리소스 생성기.
cloud / stormcloud (복셀 구름), rain / sunrain (애니메이션 빗줄기 빌보드), bolt (번개 빔 조각),
hail (얼음 결정), ring (충격파 링).
usage: python generate_vfx.py <pack/assets/dor 경로>
"""
import json, math, os, random, sys
from PIL import Image, ImageDraw, ImageFilter

DOR = sys.argv[1]
NS = "dor:item/char/raingirl/"
MODEL_DIR = os.path.join(DOR, "models", "item", "char", "raingirl")
TEX_DIR = os.path.join(DOR, "textures", "item", "char", "raingirl")
ITEM_DIR = os.path.join(DOR, "items", "char", "raingirl")
for d in (MODEL_DIR, TEX_DIR, ITEM_DIR):
    os.makedirs(d, exist_ok=True)


def save_json(path, obj):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(obj, f, ensure_ascii=False, indent=1)
        f.write("\n")


def item_def(name):
    save_json(os.path.join(ITEM_DIR, name + ".json"),
              {"oversized_in_gui": True, "model": {"type": "minecraft:model", "model": NS + name}})


# ---------------------------------------------------------------- 공통: 단색 팔레트 텍스처
def palette_texture(path, rows):
    """rows: [(top_rgba, down_rgba), ...] → 32x32, 4px 칸. 위 줄 = 윗면/옆면, 아래 줄 = 아랫면."""
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for i, (top, down) in enumerate(rows):
        for d, col in enumerate((top, down)):
            px, py = (i % 8) * 4, (i // 8) * 8 + 4 * d
            for x in range(px, px + 4):
                for y in range(py, py + 4):
                    im.putpixel((x, y), col)
    im.save(path)


def swatch(i, down):
    px, py = (i % 8) * 4, (i // 8) * 8 + (4 if down else 0)
    k = 0.5
    return [(px + 1) * k, (py + 1) * k, (px + 3) * k, (py + 3) * k]


# ---------------------------------------------------------------- 구름 (복셀 + greedy)
def greedy(vox):
    left = dict(vox)
    boxes = []
    for key in sorted(left, key=lambda k: (k[1], k[2], k[0])):
        if key not in left:
            continue
        c = left[key]
        x0, y0, z0 = key
        x1 = x0 + 1
        while left.get((x1, y0, z0)) == c:
            x1 += 1
        z1 = z0 + 1
        while all(left.get((x, y0, z1)) == c for x in range(x0, x1)):
            z1 += 1
        y1 = y0 + 1
        while all(left.get((x, y1, z)) == c for x in range(x0, x1) for z in range(z0, z1)):
            y1 += 1
        for x in range(x0, x1):
            for y in range(y0, y1):
                for z in range(z0, z1):
                    del left[(x, y, z)]
        boxes.append(((x0, y0, z0), (x1, y1, z1), c))
    return boxes


def voxel_model(vox, tex_ref, shade=True):
    elements = []
    for (a, b, c) in greedy(vox):
        faces = {}
        rx, ry, rz = range(a[0], b[0]), range(a[1], b[1]), range(a[2], b[2])
        checks = {
            "north": [(x, y, a[2] - 1) for x in rx for y in ry],
            "south": [(x, y, b[2]) for x in rx for y in ry],
            "west": [(a[0] - 1, y, z) for y in ry for z in rz],
            "east": [(b[0], y, z) for y in ry for z in rz],
            "up": [(x, b[1], z) for x in rx for z in rz],
            "down": [(x, a[1] - 1, z) for x in rx for z in rz],
        }
        for fn, cells in checks.items():
            if all(cl in vox for cl in cells):
                continue
            faces[fn] = {"uv": swatch(c, fn == "down"), "texture": "#0"}
        if faces:
            e = {"from": list(a), "to": list(b), "faces": faces}
            if not shade:
                e["shade"] = False
            elements.append(e)
    return {"texture_size": [32, 32], "textures": {"0": tex_ref, "particle": tex_ref}, "elements": elements}


def cloud_voxels():
    # (cx, cy, cz, r) — 바닥은 y=4 에서 평평하게 자른다.
    blobs = [(8, 7, 8, 5.6), (2.5, 6, 7.5, 4.2), (13.5, 6.4, 8.8, 4.8), (5, 9.2, 9, 4.2),
             (11, 9.6, 7.2, 4.6), (-1.5, 5.4, 8, 3), (17.5, 5.5, 8.2, 3.1), (8, 6, 12.6, 3.8),
             (8.5, 6, 3.6, 3.6), (8, 11.2, 8.5, 3.2)]
    vox = {}
    for x in range(-6, 23):
        for y in range(4, 16):
            for z in range(-2, 19):
                px, py, pz = x + 0.5, y + 0.5, z + 0.5
                inside = any((px - cx) ** 2 + ((py - cy) * 1.15) ** 2 + (pz - cz) ** 2 <= r * r
                             for cx, cy, cz, r in blobs)
                if inside:
                    vox[(x, y, z)] = None
    # 높이 띠로 색 지정: 0 = 꼭대기, 1 = 중간, 2 = 아래
    for (x, y, z) in vox:
        vox[(x, y, z)] = 0 if y >= 10 else (1 if y >= 7 else 2)
    return vox


def make_clouds():
    vox = cloud_voxels()
    palette_texture(os.path.join(TEX_DIR, "cloud.png"), [
        ((255, 255, 255, 255), (214, 226, 240, 255)),
        ((238, 244, 251, 255), (198, 212, 230, 255)),
        ((216, 228, 242, 255), (176, 192, 214, 255)),
    ])
    palette_texture(os.path.join(TEX_DIR, "stormcloud.png"), [
        ((132, 142, 160, 255), (82, 90, 108, 255)),
        ((112, 122, 140, 255), (72, 80, 98, 255)),
        ((94, 103, 122, 255), (60, 67, 84, 255)),
    ])
    m = voxel_model(vox, NS + "cloud")
    m["credit"] = "Hwalcass raingirl cloud"
    save_json(os.path.join(MODEL_DIR, "cloud.json"), m)
    save_json(os.path.join(MODEL_DIR, "stormcloud.json"),
              {"parent": NS + "cloud", "textures": {"0": NS + "stormcloud", "particle": NS + "stormcloud"}})
    item_def("cloud")
    item_def("stormcloud")
    return len(m["elements"])


# ---------------------------------------------------------------- 빗줄기 빌보드 (애니메이션)
def plane_model():
    # 세로 평면 (z=8), 양면. 엔티티 billboard vertical 로 세운다.
    save_json(os.path.join(MODEL_DIR, "_plane.json"), {
        "ambientocclusion": False, "gui_light": "front", "textures": {"particle": "#layer0"},
        "elements": [{"from": [0, 0, 8], "to": [16, 16, 8], "shade": False, "faces": {
            "north": {"uv": [0, 0, 16, 16], "texture": "#layer0"},
            "south": {"uv": [0, 0, 16, 16], "texture": "#layer0"}}}]})
    # 바닥 평면 (y=8), 양면. 충격파 링용.
    save_json(os.path.join(MODEL_DIR, "_floor.json"), {
        "ambientocclusion": False, "gui_light": "front", "textures": {"particle": "#layer0"},
        "elements": [{"from": [0, 8, 0], "to": [16, 8, 16], "shade": False, "faces": {
            "up": {"uv": [0, 0, 16, 16], "texture": "#layer0"},
            "down": {"uv": [0, 0, 16, 16], "texture": "#layer0"}}}]})


def rain_texture(path, color, sparkle, seed):
    W, H, F = 32, 64, 8
    rng = random.Random(seed)
    streaks = [(rng.randrange(W), rng.randrange(H), rng.randint(6, 13), rng.randint(110, 200)) for _ in range(34)]
    sheet = Image.new("RGBA", (W, H * F), (0, 0, 0, 0))
    for f in range(F):
        fr = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        for (x, y0, ln, a) in streaks:
            y = (y0 + f * (H // F)) % H
            for k in range(ln):
                yy = (y + k) % H
                t = k / max(1, ln - 1)
                alpha = int(a * (0.25 + 0.75 * t))
                fr.putpixel((x, yy), color + (alpha,))
        if sparkle:
            for _ in range(5):
                x, y = rng.randrange(W), rng.randrange(H)
                fr.putpixel((x, y), (255, 255, 240, 230))
        # 위·아래 가장자리를 부드럽게 사라지게
        px = fr.load()
        for yy in range(H):
            edge = min(yy, H - 1 - yy)
            k = min(1.0, edge / 8.0)
            for xx in range(W):
                r, g, b, a = px[xx, yy]
                px[xx, yy] = (r, g, b, int(a * k))
        sheet.paste(fr, (0, f * H))
    sheet.save(path)
    with open(path + ".mcmeta", "w", encoding="utf-8", newline="\n") as fp:
        json.dump({"animation": {"frametime": 1, "interpolate": False}}, fp)
        fp.write("\n")


def make_rain():
    rain_texture(os.path.join(TEX_DIR, "rain.png"), (178, 214, 255), False, 153)
    rain_texture(os.path.join(TEX_DIR, "sunrain.png"), (255, 222, 140), True, 1531)
    for n in ("rain", "sunrain"):
        save_json(os.path.join(MODEL_DIR, n + ".json"), {"parent": NS + "_plane", "textures": {"layer0": NS + n}})
        item_def(n)


# ---------------------------------------------------------------- 충격파 링
def make_ring():
    S = 128
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    px = im.load()
    c = (S - 1) / 2
    for y in range(S):
        for x in range(S):
            r = math.hypot(x - c, y - c) / c
            # 바깥 테두리 쪽이 밝고 안쪽으로 흐려지는 링
            a = 0.0
            if 0.55 <= r <= 0.98:
                a = max(0.0, 1 - abs(r - 0.88) / 0.10)
                a = max(a, 0.35 * max(0.0, (r - 0.55) / 0.33))
            if a > 0:
                k = min(1, a)
                px[x, y] = (int(210 + 45 * k), int(236 + 19 * k), 255, int(230 * k))
    im = im.filter(ImageFilter.GaussianBlur(0.8))
    im.save(os.path.join(TEX_DIR, "ring.png"))
    save_json(os.path.join(MODEL_DIR, "ring.json"), {"parent": NS + "_floor", "textures": {"layer0": NS + "ring"}})
    item_def("ring")


# ---------------------------------------------------------------- 번개 빔 조각
def make_bolt():
    palette_texture(os.path.join(TEX_DIR, "bolt.png"), [
        ((250, 254, 255, 255), (250, 254, 255, 255)),   # 심
        ((120, 205, 255, 120), (120, 205, 255, 120)),   # 바깥 빛
    ])
    ref = NS + "bolt"

    def bx(f, t, i):
        return {"from": f, "to": t, "shade": False,
                "faces": {fn: {"uv": swatch(i, False), "texture": "#0"} for fn in ("north", "south", "east", "west", "up", "down")}}
    # z 방향으로 16(=1칸) 길이. 엔티티 scale z 로 조각 길이를 맞춘다.
    m = {"credit": "Hwalcass raingirl bolt", "texture_size": [32, 32], "textures": {"0": ref, "particle": ref},
         "elements": [bx([7.3, 7.3, 0], [8.7, 8.7, 16], 0), bx([6.2, 6.2, 0], [9.8, 9.8, 16], 1)]}
    save_json(os.path.join(MODEL_DIR, "bolt.json"), m)
    item_def("bolt")


# ---------------------------------------------------------------- 우박 (얼음 결정)
def make_hail():
    palette_texture(os.path.join(TEX_DIR, "hail.png"), [
        ((236, 250, 255, 235), (200, 232, 250, 235)),
        ((176, 224, 250, 215), (150, 205, 240, 215)),
        ((255, 255, 255, 255), (230, 246, 255, 255)),
    ])
    ref = NS + "hail"

    def bx(f, t, i, rot=None):
        e = {"from": f, "to": t, "faces": {fn: {"uv": swatch(i, fn == "down"), "texture": "#0"}
                                           for fn in ("north", "south", "east", "west", "up", "down")}}
        if rot:
            e["rotation"] = {"angle": rot[1], "axis": rot[0], "origin": [8, 8, 8]}
        return e
    m = {"credit": "Hwalcass raingirl hail", "texture_size": [32, 32], "textures": {"0": ref, "particle": ref},
         "elements": [
             bx([5.5, 5.5, 5.5], [10.5, 10.5, 10.5], 1),
             bx([6, 3, 6], [10, 13, 10], 0, ("y", 45)),
             bx([3, 6, 6], [13, 10, 10], 0, ("x", 45)),
             bx([6, 6, 3], [10, 10, 13], 0, ("z", 45)),
             bx([7, 7, 7], [9, 9, 9], 2),
         ]}
    save_json(os.path.join(MODEL_DIR, "hail.json"), m)
    item_def("hail")


# ---------------------------------------------------------------- 태풍의 눈: 오목한 끝단의 우산 천 (60° 조각)
def slice_texture(fill, size=1024):
    """Same pivot, direction and tip radius; a concave quadratic rim between tips.
    Draw coverage at 4x resolution, then downsample only once for smooth edges.
    """
    aa = 4
    c = size / 2
    tip_forward = 0.97 * math.cos(math.pi / 6)
    tip_side = 0.97 * math.sin(math.pi / 6)
    middle = 0.65
    rim = []
    for i in range(513):
        t = -1 + 2 * i / 512
        forward = middle + (tip_forward - middle) * t * t
        rim.append(((c - forward * c) * aa, (c + tip_side * t * c) * aa))
    pivot = (c * aa, c * aa)
    shape = Image.new("L", (size * aa, size * aa), 0)
    ImageDraw.Draw(shape).polygon([pivot] + rim, fill=255)
    border = Image.new("L", shape.size, 0)
    draw = ImageDraw.Draw(border)
    draw.line([rim[-1], pivot, rim[0]], fill=210, width=round(size * aa * 0.0045))
    draw.line(rim, fill=255, width=round(size * aa * 0.009), joint="curve")
    # Clip the border to the silhouette, preserving a clean, pointed outline.
    from PIL import ImageChops
    border = ImageChops.multiply(border, shape)
    shape = shape.resize((size, size), Image.Resampling.LANCZOS)
    border = border.resize((size, size), Image.Resampling.LANCZOS)
    im = Image.new("RGBA", (size, size), fill + (0,))
    pixels, coverage, edges = im.load(), shape.load(), border.load()
    for y in range(size):
        for x in range(size // 2 + 1):
            cov = coverage[x, y] / 255
            if not cov:
                continue
            radius = min(1, math.hypot(x + 0.5 - c, y + 0.5 - c) / c)
            edge = min(1, edges[x, y] / max(1, coverage[x, y]))
            base_alpha = 125 + 55 * radius
            color = tuple(round(v + (target - v) * edge)
                          for v, target in zip(fill, (240, 250, 255)))
            pixels[x, y] = color + (round((base_alpha + (235 - base_alpha) * edge) * cov),)
    return im


def make_slices():
    """위에서 본 우산처럼 6조각으로 나뉜 천. 꼭짓점은 텍스처 중앙,
    조각은 텍스처 왼쪽(-u = 모델 -x)을 향한다. 엔티티 yaw 로 각 방향에 돌려 놓는다."""
    for name, fill in (("slice_a", (140, 210, 245)), ("slice_b", (118, 192, 238))):
        im = slice_texture(fill)
        im.save(os.path.join(TEX_DIR, name + ".png"))
        save_json(os.path.join(MODEL_DIR, name + ".json"), {"parent": NS + "_floor", "textures": {"layer0": NS + name}})
        item_def(name)


if __name__ == "__main__":
    if "--slices-only" in sys.argv[2:]:
        make_slices()
        print("Generated 1024px concave umbrella slices only")
        sys.exit(0)
    plane_model()
    n = make_clouds()
    make_rain()
    make_ring()
    make_bolt()
    make_hail()
    make_slices()
    print("cloud elements", n)

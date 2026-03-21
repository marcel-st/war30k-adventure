from pathlib import Path
import struct

W, H = 192, 256
FRAME = 32


def clamp(v):
    return max(0, min(255, int(v)))


def brighten(rgb, factor):
    r, g, b = rgb
    return (clamp(r * factor), clamp(g * factor), clamp(b * factor))


def make_canvas(color):
    return [[list(color) for _ in range(W)] for _ in range(H)]


def rect(img, x, y, w, h, color):
    for yy in range(y, y + h):
        if yy < 0 or yy >= H:
            continue
        for xx in range(x, x + w):
            if 0 <= xx < W:
                img[yy][xx][0], img[yy][xx][1], img[yy][xx][2] = color


def armor_plate(img, x, y, w, h, base, shade=0.86, hi=1.42):
    rect(img, x, y, w, h, base)
    shadow = brighten(base, shade)
    h1 = brighten(base, hi)
    h2 = brighten(base, 1.22)

    rect(img, x + w - 2, y + 1, 2, h - 1, shadow)
    rect(img, x + 1, y + h - 2, w - 1, 2, shadow)

    # Top-edge highlight logic ('Eavy Metal-inspired)
    rect(img, x, y, w, 1, h1)
    rect(img, x, y + 1, w, 1, h2)
    rect(img, x, y, 1, h // 2, h2)


def draw_marine_frame(img, ox, oy, armor, trim, eye, walk_phase=0, facing=2):
    rect(img, ox, oy, FRAME, FRAME, (14, 15, 18))

    armor_plate(img, ox + 5, oy + 7, 9, 6, armor)
    armor_plate(img, ox + 18, oy + 7, 9, 6, armor)
    armor_plate(img, ox + 10, oy + 10, 12, 10, armor)

    rect(img, ox + 5, oy + 7, 9, 1, trim)
    rect(img, ox + 18, oy + 7, 9, 1, trim)
    rect(img, ox + 10, oy + 10, 12, 1, trim)

    armor_plate(img, ox + 11, oy + 5, 10, 6, brighten(armor, 1.08), hi=1.35)

    if facing in (0, 1, 7):
        rect(img, ox + 14, oy + 8, 4, 1, eye)
    elif facing in (3, 4, 5):
        rect(img, ox + 13, oy + 8, 5, 1, eye)
    else:
        rect(img, ox + 13, oy + 8, 5, 1, eye)

    dy = [0, 2, 0, 3][walk_phase % 4]
    armor_plate(img, ox + 10, oy + 20 + (dy if walk_phase in (1, 3) else 0), 4, 9, armor, hi=1.35)
    armor_plate(img, ox + 18, oy + 20 + (dy if walk_phase in (0, 2) else 0), 4, 9, armor, hi=1.35)

    rect(img, ox + 9, oy + 29 + (dy if walk_phase in (1, 3) else 0), 6, 2, brighten(armor, 0.74))
    rect(img, ox + 17, oy + 29 + (dy if walk_phase in (0, 2) else 0), 6, 2, brighten(armor, 0.74))


def write_bmp(path, img):
    height = len(img)
    width = len(img[0])
    row_size = (width * 3 + 3) & ~3
    pixel_data_size = row_size * height
    file_size = 14 + 40 + pixel_data_size

    with open(path, 'wb') as f:
        f.write(b'BM')
        f.write(struct.pack('<IHHI', file_size, 0, 0, 54))
        f.write(struct.pack('<IIIHHIIIIII', 40, width, height, 1, 24, 0, pixel_data_size, 2835, 2835, 0, 0))

        padding = b'\x00' * (row_size - width * 3)
        for y in range(height - 1, -1, -1):
            row = img[y]
            for r, g, b in row:
                f.write(bytes((b, g, r)))
            f.write(padding)


def build_sheet(path, armor, trim, eye, bg):
    img = make_canvas(bg)
    for d in range(8):
        y = d * FRAME
        draw_marine_frame(img, 0, y, armor, trim, eye, walk_phase=0, facing=d)
        draw_marine_frame(img, 32, y, armor, trim, eye, walk_phase=2, facing=d)
        for i, x in enumerate((64, 96, 128, 160)):
            draw_marine_frame(img, x, y, armor, trim, eye, walk_phase=i, facing=d)
    write_bmp(path, img)


assets = Path('assets')
assets.mkdir(exist_ok=True)

build_sheet(assets / 'garro_sheet.bmp', armor=(170, 180, 156), trim=(194, 158, 82), eye=(220, 228, 255), bg=(15, 18, 14))
build_sheet(assets / 'traitor_sheet.bmp', armor=(150, 48, 48), trim=(178, 138, 74), eye=(255, 188, 122), bg=(19, 10, 10))

print('generated spritesheets in assets/')

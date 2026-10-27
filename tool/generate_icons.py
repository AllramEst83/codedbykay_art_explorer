"""Builds the launcher icon layers from assets/icon/icon.png.

Run:  python tool/generate_icons.py
Then: dart run flutter_launcher_icons

Outputs (assets/icon/):
  icon_background.png  adaptive background: warm paper gradient + grain
  icon_foreground.png  adaptive foreground: artwork + soft shadow
  icon_monochrome.png  Android 13+ themed-icon layer
  icon_legacy.png      rounded flattened icon for Android 7.1 and older
"""

from PIL import Image, ImageChops, ImageDraw, ImageFilter

SIZE = 1024
SRC = 'assets/icon/icon.png'
OUT = 'assets/icon/'

CREAM_CENTER = (0xFF, 0xF7, 0xEC)
CREAM_EDGE = (0xE8, 0xCF, 0xAE)
SHADOW = (0x4A, 0x2A, 0x14)


def load_symbol():
    src = Image.open(SRC).convert('RGBA')
    sym = src.crop(src.getchannel('A').getbbox())
    return sym


def scaled(sym, width_frac):
    w = round(SIZE * width_frac)
    h = round(sym.height * w / sym.width)
    out = sym.resize((w, h), Image.LANCZOS)
    # Upscaling softens detail; a light unsharp mask restores crispness.
    return out.filter(ImageFilter.UnsharpMask(radius=1.6, percent=70, threshold=2))


def place(layer, img, dy=0):
    x = (SIZE - img.width) // 2
    y = (SIZE - img.height) // 2 + dy
    layer.alpha_composite(img, (x, y))


def shadowed(sym_scaled, blur=26, offset=22, opacity=0.38):
    """Artwork with a soft contact shadow, on a transparent SIZE canvas."""
    canvas = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    alpha = Image.new('L', (SIZE, SIZE), 0)
    a = sym_scaled.getchannel('A')
    alpha.paste(a, ((SIZE - a.width) // 2, (SIZE - a.height) // 2 + offset))
    alpha = alpha.filter(ImageFilter.GaussianBlur(blur)).point(
        lambda v: int(v * opacity)
    )
    shadow = Image.new('RGBA', (SIZE, SIZE), SHADOW + (0,))
    shadow.putalpha(alpha)
    canvas.alpha_composite(shadow)
    place(canvas, sym_scaled)
    return canvas


def background():
    grad = Image.radial_gradient('L').resize((SIZE, SIZE), Image.BICUBIC)
    # Push the gradient outward so the bright centre is broad and the
    # falloff only shows near the edges.
    grad = grad.point(lambda v: min(255, int((v / 255) ** 1.6 * 255 * 1.1)))
    base = Image.composite(
        Image.new('RGB', (SIZE, SIZE), CREAM_EDGE),
        Image.new('RGB', (SIZE, SIZE), CREAM_CENTER),
        grad,
    )
    # Fine paper grain.
    noise = Image.effect_noise((SIZE, SIZE), 18).convert('RGB')
    grain = Image.blend(base, ImageChops.multiply(base, noise), 0.06)
    return grain.convert('RGBA')


def monochrome(sym_scaled):
    """Tonal silhouette: darker areas of the art become more opaque."""
    gray = sym_scaled.convert('L')
    tone = gray.point(lambda v: int(255 - v * 0.55))  # dark art -> high alpha
    alpha = ImageChops.multiply(sym_scaled.getchannel('A'), tone)
    layer = Image.new('RGBA', sym_scaled.size, (0, 0, 0, 255))
    layer.putalpha(alpha)
    canvas = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    place(canvas, layer)
    return canvas


def rounded(img, radius_frac=0.22):
    mask = Image.new('L', (SIZE * 2, SIZE * 2), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, SIZE * 2 - 1, SIZE * 2 - 1), radius=int(SIZE * 2 * radius_frac), fill=255
    )
    mask = mask.resize((SIZE, SIZE), Image.LANCZOS)
    out = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def main():
    sym = load_symbol()

    # Adaptive icon: visible area is the centre ~66%, so keep the art inside it.
    fg = shadowed(scaled(sym, 0.52))
    bg = background()
    fg.save(OUT + 'icon_foreground.png')
    bg.convert('RGB').save(OUT + 'icon_background.png')
    monochrome(scaled(sym, 0.52)).save(OUT + 'icon_monochrome.png')

    # Legacy: no mask is applied by the launcher, so bake in rounded corners.
    legacy = bg.copy()
    legacy.alpha_composite(shadowed(scaled(sym, 0.72), blur=30, offset=26))
    rounded(legacy).save(OUT + 'icon_legacy.png')
    print('icon layers written to', OUT)


if __name__ == '__main__':
    main()

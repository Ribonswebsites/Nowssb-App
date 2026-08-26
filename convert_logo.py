from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parent
source = root / 'assets' / 'icons' / 'logo-disc.webp'
target_dir = root / 'assets' / 'blender'
target_dir.mkdir(parents=True, exist_ok=True)
target = target_dir / 'nowssb-logo-disc.png'
image = Image.open(source).convert('RGBA')
image.save(target, format='PNG', optimize=True)
print(target)

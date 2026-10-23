"""Encode the actual frames captured by motion_preview_test.dart as a GIF."""
import argparse
import json
from pathlib import Path
from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument('--frames', type=Path, default=Path('docs/motion'))
parser.add_argument('--output', type=Path, default=Path('docs/preview/13-motion.gif'))
args = parser.parse_args()
manifest = json.loads((args.frames / 'manifest.json').read_text())
images = [Image.open(args.frames / frame['file']).convert('RGB') for frame in manifest]
if not images:
    raise SystemExit('No captured frames.')
# A shared palette keeps the interface's colors stable across frames.
samples = images[::max(1, len(images) // 8)]
strip = Image.new('RGB', (98 * len(samples), 213))
for index, image in enumerate(samples):
    strip.paste(image.resize((98, 213)), (98 * index, 0))
palette = strip.quantize(colors=192)
frames = [image.quantize(palette=palette, dither=Image.Dither.NONE) for image in images]
args.output.parent.mkdir(parents=True, exist_ok=True)
frames[0].save(args.output, save_all=True, append_images=frames[1:],
               duration=[frame['duration'] for frame in manifest],
               loop=0, disposal=2, optimize=True)
with Image.open(args.output) as result:
    print(f'{args.output}: {result.n_frames} frames, {args.output.stat().st_size:,} bytes')

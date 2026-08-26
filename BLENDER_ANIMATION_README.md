# NOWSSB 3D Hero Logo Animation

This package creates a warm orange-and-black premium logo reveal for the Nowssb-App brand. The animation is four seconds long at 60 frames per second, for a total of 240 frames.

## Included files

| File | Purpose |
|---|---|
| `nowssb_hero_animation.py` | Blender Python generator for the scene, materials, camera, lights, particles, shockwave, and keyframes. |
| `nowssb_hero_animation.blend` | Generated Blender project, created when the script runs in Blender. |
| `assets/blender/nowssb-logo-disc.png` | PNG-converted Nowssb logo artwork used on the emblem face. |

## Run in Blender

Open Blender 4.x, switch to the Scripting workspace, open `nowssb_hero_animation.py`, and click **Run Script**. The script creates and saves `nowssb_hero_animation.blend` beside itself. Alternatively, from a terminal in this folder run:

```bash
blender --background --python nowssb_hero_animation.py
```

To render the full animation directly:

```bash
blender --background --python nowssb_hero_animation.py --render
```

The default scene uses Eevee Next for a fast preview and compatibility. For the requested final glossy/volumetric look, open the generated file, switch Render Engine to Cycles, select the GPU device in Preferences, enable GPU denoising, and render to a movie format such as FFmpeg video. The compositor already includes fog glow and warm color grading to create a subtle bloom-like finish.

## Animation design

The emblem begins almost invisible in a black void while amber particles converge toward the logo. The hero then spins through one full Y-axis rotation with eased scaling, a slight wobble, and a landing pulse. The camera performs a fast dolly-zoom from a long lens into a wider lens and then settles into a slow orbital move. A warm spotlight and volume create god-rays behind the emblem. An emissive torus expands as the landing shockwave and fades after impact. The dark metallic body, raised amber rim, and glossy logo plane provide the orange-black brand treatment.

## Important asset note

The repository contains branded logo artwork as raster assets rather than a clean transparent SVG mascot mark. The scene therefore uses the circular Nowssb logo artwork as a PNG plane over a modeled, beveled metallic emblem. If you provide a transparent mascot SVG/PNG later, replace `assets/blender/nowssb-logo-disc.png` and the same scene can use it as the face artwork.

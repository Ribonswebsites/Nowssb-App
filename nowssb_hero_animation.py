import bpy
import math
import random
from mathutils import Vector
from pathlib import Path

# Nowssb premium logo-reveal animation
# Run from Blender with: blender --background --python nowssb_hero_animation.py
# Optional render: blender --background --python nowssb_hero_animation.py --render

SEED = 26
random.seed(SEED)
FPS = 60
FRAME_END = 240  # 4 seconds at 60 fps
ROOT = Path(__file__).resolve().parent
LOGO_PATH = ROOT / "assets" / "blender" / "nowssb-logo-disc.png"


def look_at(obj, target=(0.0, 0.0, 0.0)):
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()


def mat_principled(name, base, metallic=0.0, roughness=0.45, emission=None, emission_strength=0.0, alpha=1.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*base, 1.0)
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Roughness'].default_value = roughness
    if 'Emission Color' in bsdf.inputs:
        bsdf.inputs['Emission Color'].default_value = (*(emission or base), 1.0)
        bsdf.inputs['Emission Strength'].default_value = emission_strength
    elif 'Emission' in bsdf.inputs:
        bsdf.inputs['Emission'].default_value = (*(emission or base), 1.0)
        bsdf.inputs['Emission Strength'].default_value = emission_strength
    bsdf.inputs['Alpha'].default_value = alpha
    if alpha < 1.0:
        mat.surface_render_method = 'DITHERED' if hasattr(mat, 'surface_render_method') else None
    return mat


def emission_material(name, color, strength=8.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    out = nodes.new('ShaderNodeOutputMaterial')
    emission = nodes.new('ShaderNodeEmission')
    emission.inputs['Color'].default_value = (*color, 1.0)
    emission.inputs['Strength'].default_value = strength
    links.new(emission.outputs['Emission'], out.inputs['Surface'])
    return mat


def add_beveled_cylinder(name, radius, depth, location=(0, 0, 0), material=None, bevel=0.08):
    bpy.ops.mesh.primitive_cylinder_add(vertices=96, radius=radius, depth=depth, location=location, rotation=(math.pi / 2, 0, 0))
    obj = bpy.context.object
    obj.name = name
    if material:
        obj.data.materials.append(material)
    bevel_mod = obj.modifiers.new('Precision bevel', 'BEVEL')
    bevel_mod.width = bevel
    bevel_mod.segments = 5
    bevel_mod.limit_method = 'ANGLE'
    sub = obj.modifiers.new('Subdivision surface', 'SUBSURF')
    sub.subdivision_type = 'CATMULL_CLARK'
    sub.levels = 1
    sub.render_levels = 1
    return obj


def add_logo_plane(image_path, parent):
    image = bpy.data.images.load(str(image_path), check_existing=True)
    bpy.ops.mesh.primitive_plane_add(size=2.0, location=(0, -0.24, 0), rotation=(math.pi / 2, 0, 0))
    plane = bpy.context.object
    plane.name = 'NOWSSB logo reference plane'
    plane.scale = (3.12, 3.12, 3.12)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    plane.parent = parent

    mat = bpy.data.materials.new('Logo artwork - glossy decal')
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes.get('Principled BSDF')
    tex = nodes.new('ShaderNodeTexImage')
    tex.image = image
    tex.interpolation = 'Linear'
    links.new(tex.outputs['Color'], bsdf.inputs['Base Color'])
    if 'Alpha' in tex.outputs:
        links.new(tex.outputs['Alpha'], bsdf.inputs['Alpha'])
    bsdf.inputs['Metallic'].default_value = 0.35
    bsdf.inputs['Roughness'].default_value = 0.23
    if 'Emission Color' in bsdf.inputs:
        links.new(tex.outputs['Color'], bsdf.inputs['Emission Color'])
        bsdf.inputs['Emission Strength'].default_value = 0.12
    plane.data.materials.append(mat)
    return plane


def add_particle_dissolve(collection, parent, gold_mat):
    # Instanced-looking points are intentionally lightweight and render reliably
    # in both Cycles and Eevee. They travel from a broad scatter into the emblem.
    for i in range(220):
        angle = random.random() * math.tau
        radial = random.uniform(2.0, 7.0)
        start = Vector((math.cos(angle) * radial, random.uniform(-0.05, 1.25), math.sin(angle) * radial * 0.72))
        # final distribution forms the circular logo silhouette
        final_angle = random.random() * math.tau
        final_r = math.sqrt(random.random()) * 3.12
        final = Vector((math.cos(final_angle) * final_r, -0.34, math.sin(final_angle) * final_r))
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=random.uniform(0.012, 0.035), location=start)
        p = bpy.context.object
        p.name = f'Dissolve particle {i:03d}'
        p.data.materials.append(gold_mat)
        p.parent = parent
        p.scale = (0.15, 0.15, 0.15)
        p.keyframe_insert('scale', frame=1)
        p.scale = (1.0, 1.0, 1.0)
        p.keyframe_insert('scale', frame=28)
        p.location = start
        p.keyframe_insert('location', frame=1)
        p.location = final
        p.keyframe_insert('location', frame=random.randint(62, 88))
        p.scale = (0.04, 0.04, 0.04)
        p.keyframe_insert('scale', frame=104)
        for fc in p.animation_data.action.fcurves:
            for key in fc.keyframe_points:
                key.interpolation = 'BEZIER'


def add_shockwave(parent, ring_mat):
    bpy.ops.mesh.primitive_torus_add(major_radius=1.0, minor_radius=0.028, major_segments=96, minor_segments=12,
                                     location=(0, -0.48, 0), rotation=(math.pi / 2, 0, 0))
    ring = bpy.context.object
    ring.name = 'Amber landing shockwave'
    ring.data.materials.append(ring_mat)
    ring.scale = (0.16, 0.16, 0.16)
    ring.keyframe_insert('scale', frame=74)
    ring.scale = (4.8, 4.8, 4.8)
    ring.keyframe_insert('scale', frame=116)
    ring.scale = (6.5, 6.5, 6.5)
    ring.keyframe_insert('scale', frame=140)
    ring.scale = (0.02, 0.02, 0.02)
    ring.keyframe_insert('scale', frame=170)
    for fc in ring.animation_data.action.fcurves:
        for key in fc.keyframe_points:
            key.interpolation = 'BEZIER'
    return ring


def add_camera():
    bpy.ops.object.camera_add(location=(0, -14.0, 0.35))
    camera = bpy.context.object
    camera.name = 'Fast dolly-zoom camera'
    camera.data.lens = 58
    camera.data.sensor_width = 36
    look_at(camera, (0, 0, 0))
    camera.keyframe_insert('location', frame=1)
    camera.data.lens = 58
    camera.data.keyframe_insert('lens', frame=1)
    camera.location = (0.0, -7.2, 0.12)
    camera.data.lens = 30
    look_at(camera, (0, 0, 0))
    camera.keyframe_insert('location', frame=70)
    camera.data.keyframe_insert('lens', frame=70)
    camera.location = (0.0, -10.8, 0.25)
    camera.data.lens = 48
    look_at(camera, (0, 0, 0))
    camera.keyframe_insert('location', frame=120)
    camera.data.keyframe_insert('lens', frame=120)
    camera.location = (2.6, -10.5, 1.0)
    camera.data.lens = 52
    look_at(camera, (0, 0, 0))
    camera.keyframe_insert('location', frame=240)
    camera.data.keyframe_insert('lens', frame=240)
    for fc in camera.animation_data.action.fcurves:
        for key in fc.keyframe_points:
            key.interpolation = 'BEZIER'
    bpy.context.scene.camera = camera
    return camera


def add_lights():
    # Warm amber key and cool fill create a premium dark-stage silhouette.
    bpy.ops.object.light_add(type='AREA', location=(4.5, -4.0, 4.0))
    key = bpy.context.object
    key.name = 'Amber rim key'
    key.data.energy = 900
    key.data.color = (1.0, 0.22, 0.035)
    key.data.shape = 'DISK'
    key.data.size = 4.0
    look_at(key, (0, 0, 0))

    bpy.ops.object.light_add(type='AREA', location=(-4.0, -3.0, 1.5))
    fill = bpy.context.object
    fill.name = 'Soft gold fill'
    fill.data.energy = 500
    fill.data.color = (1.0, 0.52, 0.10)
    fill.data.size = 5.0
    look_at(fill, (0, 0, 0))

    bpy.ops.object.light_add(type='SPOT', location=(0.0, 2.5, 4.2))
    spot = bpy.context.object
    spot.name = 'Volumetric god-ray spotlight'
    spot.data.energy = 1600
    spot.data.color = (1.0, 0.16, 0.025)
    spot.data.spot_size = math.radians(42)
    spot.data.spot_blend = 0.72
    spot.data.shadow_soft_size = 1.2
    look_at(spot, (0, 0, 0))
    return spot


def add_volume():
    bpy.ops.mesh.primitive_cube_add(location=(0, 1.4, 0), scale=(8.5, 3.0, 6.0))
    volume = bpy.context.object
    volume.name = 'God-rays volume'
    mat = bpy.data.materials.new('Amber volumetric scatter')
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    out = nodes.new('ShaderNodeOutputMaterial')
    scatter = nodes.new('ShaderNodeVolumeScatter')
    scatter.inputs['Color'].default_value = (1.0, 0.11, 0.018, 1.0)
    scatter.inputs['Density'].default_value = 0.035
    scatter.inputs['Anisotropy'].default_value = 0.62
    links.new(scatter.outputs['Volume'], out.inputs['Volume'])
    volume.data.materials.append(mat)
    return volume


def animate_hero(hero):
    hero.scale = (0.02, 0.02, 0.02)
    hero.rotation_euler = (0.08, -math.pi * 0.55, -0.08)
    hero.keyframe_insert('scale', frame=1)
    hero.keyframe_insert('rotation_euler', frame=1)
    hero.scale = (0.72, 0.72, 0.72)
    hero.rotation_euler = (0.02, math.pi * 0.18, 0.02)
    hero.keyframe_insert('scale', frame=48)
    hero.keyframe_insert('rotation_euler', frame=48)
    hero.scale = (1.10, 1.10, 1.10)
    hero.rotation_euler = (0.0, math.tau * 1.0, 0.055)
    hero.keyframe_insert('scale', frame=86)
    hero.keyframe_insert('rotation_euler', frame=86)
    hero.scale = (0.98, 0.98, 0.98)
    hero.rotation_euler = (0.0, math.tau * 1.04, -0.025)
    hero.keyframe_insert('scale', frame=101)
    hero.keyframe_insert('rotation_euler', frame=101)
    hero.scale = (1.0, 1.0, 1.0)
    hero.rotation_euler = (0.0, math.tau * 1.08, 0.0)
    hero.keyframe_insert('scale', frame=118)
    hero.keyframe_insert('rotation_euler', frame=118)
    hero.keyframe_insert('scale', frame=240)
    hero.keyframe_insert('rotation_euler', frame=240)
    if hero.animation_data and hero.animation_data.action:
        for fc in hero.animation_data.action.fcurves:
            for key in fc.keyframe_points:
                key.interpolation = 'BEZIER'
            if fc.data_path == 'rotation_euler' and fc.array_index == 1:
                mod = fc.modifiers.new('CYCLES')
                mod.mode_before = 'REPEAT_OFFSET'
                mod.mode_after = 'REPEAT_OFFSET'


def setup_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        pass

    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = FRAME_END
    scene.render.fps = FPS
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
    scene.render.resolution_x = 1080
    scene.render.resolution_y = 1080
    scene.render.resolution_percentage = 50
    scene.render.image_settings.file_format = 'FFMPEG' if False else 'PNG'
    scene.render.filepath = str(ROOT / 'renders' / 'nowssb_hero_')
    scene.render.film_transparent = False
    scene.render.image_settings.color_mode = 'RGBA'
    scene.view_settings.look = 'AgX - Medium High Contrast'
    scene.world.color = (0.0, 0.0, 0.0)
    scene.render.use_file_extension = True
    if hasattr(scene, 'render') and hasattr(scene.render, 'use_motion_blur'):
        scene.render.use_motion_blur = True
    # Eevee bloom is handled by compositor glare for Blender 4.x.
    scene.use_nodes = True
    tree = scene.node_tree
    tree.nodes.clear()
    rl = tree.nodes.new('CompositorNodeRLayers')
    glare = tree.nodes.new('CompositorNodeGlare')
    glare.glare_type = 'FOG_GLOW'
    glare.quality = 'HIGH'
    glare.threshold = 0.7
    glare.size = 7
    grade = tree.nodes.new('CompositorNodeColorBalance')
    grade.lift = (0.92, 0.92, 0.92)
    grade.gamma = (1.0, 0.91, 0.78)
    grade.gain = (1.14, 1.02, 0.86)
    comp = tree.nodes.new('CompositorNodeComposite')
    tree.links.new(rl.outputs['Image'], glare.inputs['Image'])
    tree.links.new(glare.outputs['Image'], grade.inputs['Image'])
    tree.links.new(grade.outputs['Image'], comp.inputs['Image'])

    dark = mat_principled('Dark metallic emblem', (0.012, 0.008, 0.006), metallic=0.82, roughness=0.18)
    edge = mat_principled('Amber metal rim', (0.12, 0.018, 0.002), metallic=0.7, roughness=0.2, emission=(1.0, 0.06, 0.005), emission_strength=0.8)
    gold = emission_material('Dissolve amber particles', (1.0, 0.09, 0.012), strength=10.0)
    shock = emission_material('Shockwave emission', (1.0, 0.16, 0.025), strength=22.0)

    bpy.ops.object.empty_add(type='PLAIN_AXES', location=(0, 0, 0))
    hero = bpy.context.object
    hero.name = 'NOWSSB Hero Emblem'
    back = add_beveled_cylinder('Dark metallic emblem body', 3.28, 0.42, location=(0, 0.12, 0), material=dark, bevel=0.12)
    back.parent = hero
    rim = add_beveled_cylinder('Raised amber rim', 3.20, 0.50, location=(0, 0.02, 0), material=edge, bevel=0.11)
    rim.parent = hero
    # Slightly smaller dark face creates a visible premium rim around the artwork.
    face = add_beveled_cylinder('Dark face plate', 3.07, 0.54, location=(0, -0.09, 0), material=dark, bevel=0.08)
    face.parent = hero
    logo = add_logo_plane(LOGO_PATH, hero)
    add_particle_dissolve(bpy.data.collections.get('Collection'), hero, gold)
    add_shockwave(hero, shock)
    animate_hero(hero)
    add_camera()
    add_lights()
    add_volume()

    # Optional Cycles settings when the user changes the engine in Blender.
    scene['cycles_gpu_denoise_ready'] = True
    scene['animation_notes'] = 'NOWSSB warm orange-black hero reveal; 4 seconds; 60 fps; 240 frames.'
    scene['source_logo'] = str(LOGO_PATH)
    scene.frame_set(1)


if __name__ == '__main__':
    setup_scene()
    if '--render' in __import__('sys').argv:
        bpy.context.scene.render.resolution_percentage = 50
        bpy.ops.render.render(animation=True)
    else:
        bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'nowssb_hero_animation.blend'))

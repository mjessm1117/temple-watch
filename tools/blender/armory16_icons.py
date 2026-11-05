"""Render armory gear cards at 256 square with a transparent studio backdrop."""
import bpy
import math
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / "godot/assets/ui/armory16"
OUT.mkdir(parents=True, exist_ok=True)
TILES = OUT / "tiles"
TILES.mkdir(exist_ok=True)


def mat(name, color, metal=0.0, rough=0.42, emit=0.0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    p = m.node_tree.nodes.get("Principled BSDF")
    p.inputs["Base Color"].default_value = (*color, 1)
    p.inputs["Metallic"].default_value = metal
    p.inputs["Roughness"].default_value = rough
    if emit:
        p.inputs["Emission Color"].default_value = (*color, 1)
        p.inputs["Emission Strength"].default_value = emit
    return m


DARK = mat("Gunmetal", (0.07, 0.12, 0.15), 0.76)
STEEL = mat("Steel", (0.45, 0.64, 0.68), 0.72)
BRONZE = mat("Bronze", (0.68, 0.44, 0.22), 0.72)
GOLD = mat("Gold", (0.82, 0.65, 0.32), 0.77)
CLOTH = mat("Padded cloth", (0.42, 0.29, 0.19), 0.0, 0.8)
BLUE = mat("Kyber blue", (0.09, 0.54, 1.0), 0.0, 0.18, 0.8)
GREEN = mat("Kyber green", (0.12, 0.95, 0.48), 0.0, 0.18, 0.8)
PURPLE = mat("Kyber violet", (0.59, 0.31, 1.0), 0.0, 0.18, 0.8)
RED = mat("Kyber red", (1.0, 0.18, 0.14), 0.0, 0.18, 0.8)
YELLOW = mat("Kyber yellow", (1.0, 0.77, 0.19), 0.0, 0.18, 0.8)
WHITE = mat("Kyber white", (0.76, 0.91, 1.0), 0.0, 0.18, 0.8)


def clear():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)  # Remove the factory cube.


def cube(name, at, size, material, bevel=0.03):
    bpy.ops.mesh.primitive_cube_add(size=1, location=at)
    o = bpy.context.object
    o.name = name
    o.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(material)
    if bevel:
        b = o.modifiers.new("Machined edge", 'BEVEL')
        b.width = bevel
        b.segments = 2
        o.modifiers.new("Weighted normals", 'WEIGHTED_NORMAL')
    return o


def cylinder(name, at, radius, depth, material, vertices=24):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=at)
    o = bpy.context.object
    o.name = name
    o.data.materials.append(material)
    b = o.modifiers.new("Edge", 'BEVEL')
    b.width = 0.015
    b.segments = 2
    o.modifiers.new("Weighted normals", 'WEIGHTED_NORMAL')
    return o


def torus(name, at, major, minor, material):
    bpy.ops.mesh.primitive_torus_add(major_segments=24, minor_segments=8, location=at, major_radius=major, minor_radius=minor)
    bpy.context.object.name = name
    bpy.context.object.data.materials.append(material)


def saber(tier):
    body = (DARK, STEEL, GOLD)[tier-1]
    cylinder("Hilt core", (0, 0, 0), 0.17 + tier*0.015, 1.36, body)
    cylinder("Emitter", (0, 0, 0.73), 0.27, 0.18, STEEL if tier == 1 else GOLD)
    cylinder("Pommel", (0, 0, -0.73), 0.23, 0.16, BRONZE if tier == 1 else DARK)
    for z in (-0.38, -0.12, 0.14, 0.4):
        torus("Grip ring", (0, 0, z), 0.18 + tier*0.015, 0.025, DARK)
    if tier >= 2:
        for x in (-0.16, 0.16):
            cube("Emitter wing", (x, 0, 0.64), (0.08, 0.20, 0.36), body, 0.018)
    if tier == 3:
        cylinder("Kyber socket", (0, -0.19, 0.26), 0.10, 0.05, BLUE, 12)


def crystal(material):
    bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.34, radius2=0, depth=1.15, location=(0, 0, 0.2))
    bpy.context.object.data.materials.append(material)
    bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0, radius2=0.27, depth=0.55, location=(0, 0, -0.65))
    bpy.context.object.data.materials.append(material)
    torus("Socket", (0, 0, -0.35), 0.29, 0.06, STEEL)


def blaster():
    cube("Receiver", (0, 0, 0.1), (1.15, 0.31, 0.35), DARK)
    cube("Barrel", (0.77, 0, 0.15), (0.62, 0.20, 0.21), STEEL)
    cube("Grip", (-0.24, 0, -0.45), (0.28, 0.29, 0.76), BRONZE)
    cylinder("Muzzle", (1.11, 0, 0.15), 0.15, 0.11, GOLD)
    cube("Energy rail", (0.12, -0.19, 0.35), (0.95, 0.07, 0.08), BLUE, 0.015)
    cube("Sight", (-0.24, 0, 0.40), (0.28, 0.20, 0.22), STEEL)


def module(armor=False):
    cylinder("Module body", (0, 0, 0), 0.54, 0.25, DARK, 12)
    cylinder("Inner rotor", (0, 0, 0.17), 0.35, 0.10, GOLD if armor else STEEL, 12)
    cylinder("Kyber core", (0, 0, 0.25), 0.20, 0.07, GREEN if armor else BLUE, 8)
    for angle in range(0, 360, 60):
        a = math.radians(angle)
        cube("Contact", (0.48*math.cos(a), 0.48*math.sin(a), -0.02), (0.12, 0.12, 0.22), BRONZE, 0.01)


def armor(tier, trooper=False):
    base = CLOTH if tier == 1 else STEEL if tier == 2 else GOLD
    trim = BRONZE if tier == 1 else GOLD if tier == 2 else DARK
    cube("Cuirass", (0, 0, 0), (1.04, 0.48, 1.28), base, 0.15)
    cube("Collar", (0, 0, 0.66), (1.00, 0.54, 0.13), trim)
    cube("Waist bind", (0, 0, -0.62), (0.85, 0.53, 0.14), trim)
    for x in (-0.62, 0.62):
        cube("Pauldron", (x, 0, 0.43), (0.43, 0.54, 0.43), base, 0.13)
    if tier >= 2:
        cube("Center spine", (0, -0.26, 0.0), (0.10, 0.09, 1.02), trim)
    if tier == 3:
        for x in (-0.25, 0.25):
            crest = cube("Ornate crest", (x, -0.31, 0.27), (0.43, 0.075, 0.07), trim, 0.01)
            crest.rotation_euler[1] = (1 if x > 0 else -1) * 0.45
    if trooper:
        cube("Belt", (0, 0, -0.83), (0.82, 0.56, 0.25), DARK)


def studio():
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE'
    scene.render.resolution_x = 256
    scene.render.resolution_y = 256
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.image_settings.color_depth = '8'
    scene.world.color = (0.10, 0.14, 0.17)
    bpy.ops.object.camera_add(location=(3.1, -4.4, 2.7))
    camera = bpy.context.object
    camera.rotation_euler = (0, 0, 0)
    direction = -camera.location
    camera.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    camera.data.type = 'ORTHO'
    camera.data.ortho_scale = 2.55
    scene.camera = camera
    for location, energy, color, size in (((-3, -4, 5), 650, (0.75, 0.9, 1), 4), ((3, 1, 4), 850, (1, 0.76, 0.42), 3)):
        bpy.ops.object.light_add(type='AREA', location=location)
        light = bpy.context.object
        light.data.energy = energy
        light.data.color = color
        light.data.shape = 'DISK'
        light.data.size = size
        light.rotation_euler = (-light.location).to_track_quat('-Z', 'Y').to_euler()
    scene.view_settings.view_transform = 'AgX'
    scene.render.filepath = str(OUT / CURRENT)
    bpy.ops.render.render(write_still=True)


ITEMS = []
for tier in (1, 2, 3):
    ITEMS.extend([(f"saber_mk{tier}", lambda tier=tier: saber(tier)),
                  (f"armor_jedi_mk{tier}", lambda tier=tier: armor(tier)),
                  (f"armor_troop_mk{tier}", lambda tier=tier: armor(tier, True))])
ITEMS += [("crystal_blue", lambda: crystal(BLUE)), ("crystal_green", lambda: crystal(GREEN)),
          ("crystal_purple", lambda: crystal(PURPLE)), ("crystal_red", lambda: crystal(RED)),
          ("crystal_yellow", lambda: crystal(YELLOW)), ("crystal_white", lambda: crystal(WHITE)),
          ("blaster", blaster), ("module", module), ("armor_mod", lambda: module(True))]

for CURRENT, create in ITEMS:
    clear()
    create()
    studio()
    thumb = bpy.data.images.load(str(OUT / f"{CURRENT}.png"), check_existing=False)
    thumb.scale(128, 128)
    thumb.filepath_raw = str(TILES / f"{CURRENT}.png")
    thumb.file_format = 'PNG'
    thumb.save()
    bpy.data.images.remove(thumb)
    print("ARMORY16 ICON", CURRENT)

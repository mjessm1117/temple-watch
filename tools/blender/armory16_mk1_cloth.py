"""Build the free Blender Mk I cloth icon using the Meshy icon studio setup."""
from pathlib import Path
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "godot/assets/ui/armory16/meshy"

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)


def material(name, color, roughness=0.9):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Roughness"].default_value = roughness
    return mat


cloth = material("warm tan quilted cloth", (.48, .32, .18))
pad = material("padded chest panel", (.62, .43, .24))
edge = material("dark stitched edge", (.25, .15, .08))
belt = material("dark brown belt", (.13, .075, .035))
buckle = material("dull brass buckle", (.55, .39, .16), .6)
shadow = material("collar lining", (.19, .12, .07))


def block(name, location, scale, mat, bevel=.04):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new("soft cloth edges", "BEVEL")
        mod.width = bevel
        mod.segments = 2
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def stitch(name, points, thickness=.007):
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.bevel_depth = thickness
    curve.bevel_resolution = 2
    poly = curve.splines.new("POLY")
    poly.points.add(len(points)-1)
    for point, position in zip(poly.points, points):
        point.co = (*position, 1)
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(edge)


# A padded tunic with capped sleeves and a clearly separate raised chest panel.
block("cloth torso", (0, 0, .08), (1.24, .54, 1.52), cloth, .12)
block("lower tabard", (0, -.08, -.67), (1.04, .49, .31), cloth, .06)
for side in (-1, 1):
    block("quilted shoulder", (side*.70, .01, .53), (.48, .67, .39), cloth, .12)
    block("short cloth sleeve", (side*.88, .015, .32), (.38, .60, .46), pad, .07)
    block("sleeve hem", (side*.89, -.01, .12), (.39, .64, .10), edge, .025)
    for height in (.28, .42, .56):
        stitch("shoulder quilting", [(side*.56, -.34, height-.10),
                                     (side*.70, -.345, height),
                                     (side*.89, -.33, height+.08)], .006)

block("chest pad dark piping", (0, -.32, .28), (1.03, .105, .94), edge, .10)
block("raised tan chest pad", (0, -.385, .28), (.92, .09, .82), pad, .09)
for offset in (-.34, -.17, 0, .17, .34):
    stitch("diagonal quilt", [(-.40, -.445, .28+offset-.27),
                               (0, -.445, .28+offset),
                               (.40, -.445, .28+offset+.27)], .006)
    stitch("cross quilt", [(-.40, -.448, .28+offset+.27),
                            (0, -.448, .28+offset),
                            (.40, -.448, .28+offset-.27)], .006)

block("wide dark belt", (0, -.32, -.42), (1.24, .14, .21), belt, .025)
block("belt keeper", (0, -.413, -.42), (.24, .045, .24), buckle, .018)
block("keeper hollow", (0, -.44, -.42), (.13, .025, .13), belt, .01)
block("collar lining", (0, -.19, .80), (.52, .31, .10), shadow, .045)

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.image_settings.color_depth = "8"
scene.world.color = (.10, .14, .17)
bpy.ops.object.camera_add(location=(3.1, -4.4, 2.7))
camera = bpy.context.object
camera.rotation_euler = (-camera.location).to_track_quat("-Z", "Y").to_euler()
camera.data.type = "ORTHO"
camera.data.ortho_scale = 2.05
scene.camera = camera
for location, energy, color, size in (((-3, -4, 5), 650, (.75, .9, 1), 4),
                                       ((3, 1, 4), 850, (1, .76, .42), 3)):
    bpy.ops.object.light_add(type="AREA", location=location)
    light = bpy.context.object
    light.data.energy = energy
    light.data.color = color
    light.data.shape = "DISK"
    light.data.size = size
    light.rotation_euler = (-light.location).to_track_quat("-Z", "Y").to_euler()
scene.view_settings.view_transform = "AgX"
for size, path in ((256, OUT/"armor_jedi_mk1.png"),
                   (128, OUT/"tiles/armor_jedi_mk1.png")):
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    print("MK1 ICON", path, size)

"""Render staged Meshy armor GLBs with the armory16 transparent studio setup."""
import bpy
import bmesh
import sys
from mathutils import Vector
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MODELS = ROOT / "godot/assets/armor16/meshy"
OUT = ROOT / "godot/assets/ui/armory16/meshy"
LARGE = ROOT / "docs/godot/w16/armor-meshy"
(OUT / "tiles").mkdir(parents=True, exist_ok=True)


def prep_mk1():
    """Keep the Meshy cloth torso and crop its long robe at the belt."""
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(LARGE / "mk1.A.preview.glb"))
    shell = next(obj for obj in bpy.context.scene.objects if obj.type == "MESH")
    bpy.context.view_layer.objects.active = shell
    mesh = bmesh.new()
    mesh.from_mesh(shell.data)
    bmesh.ops.bisect_plane(mesh, geom=list(mesh.verts) + list(mesh.edges) + list(mesh.faces),
                           plane_co=(0, 0, -0.24), plane_no=(0, 0, 1), clear_inner=True)
    bmesh.ops.bisect_plane(mesh, geom=list(mesh.verts) + list(mesh.edges) + list(mesh.faces),
                           plane_co=(0, 0, .80), plane_no=(0, 0, 1), clear_outer=True)
    mesh.to_mesh(shell.data)
    mesh.free()

    def material(name, color):
        mat = bpy.data.materials.new(name)
        mat.diffuse_color = (*color, 1)
        mat.use_nodes = True
        node = mat.node_tree.nodes.get("Principled BSDF")
        node.inputs["Base Color"].default_value = (*color, 1)
        node.inputs["Roughness"].default_value = .9
        return mat

    tan = material("padded camel cloth", (.48, .32, .17))
    leather = material("dark umber leather", (.17, .09, .045))
    shell.data.materials.clear()
    shell.data.materials.append(tan)
    shell.data.materials.append(leather)
    for face in shell.data.polygons:
        if -.20 < face.center.z < -.11:
            face.material_index = 1
    seam = material("quilt stitch", (.25, .16, .08))
    for slope in (-.8, .8):
        for offset in (.19, .29, .39, .49):
            path = bpy.data.curves.new("quilt seam path", "CURVE")
            path.dimensions = "3D"
            path.bevel_depth = .004
            path.bevel_resolution = 0
            spline = path.splines.new("POLY")
            samples = []
            for i in range(19):
                x = -.18 + i * .02
                z = offset + slope * x
                if not .19 <= z <= .56:
                    continue
                hit, pos, _, _ = shell.ray_cast(Vector((x, -1, z)), Vector((0, 1, 0)))
                if hit:
                    samples.append((x, pos.y - .006, z))
            if len(samples) < 2:
                bpy.data.curves.remove(path)
                continue
            spline.points.add(len(samples) - 1)
            for point, xyz in zip(spline.points, samples):
                point.co = (*xyz, 1)
            stitch_obj = bpy.data.objects.new("quilt stitch", path)
            bpy.context.collection.objects.link(stitch_obj)
            stitch_obj.data.materials.append(seam)
            bpy.ops.object.select_all(action="DESELECT")
            stitch_obj.select_set(True)
            bpy.context.view_layer.objects.active = stitch_obj
            bpy.ops.object.convert(target="MESH")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.context.scene.objects:
        if obj.type == "MESH":
            obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(LARGE / "mk1-prepared.glb"), export_format="GLB",
                              use_selection=True, export_apply=True)
    print("Prepared Mk I Meshy cloth shell")


if "--prep-mk1" in sys.argv:
    prep_mk1()
    sys.exit(0)


def crop_mk2_neck():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(LARGE / "mk2.A.raw.glb"))
    for obj in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
        mesh = bmesh.new()
        mesh.from_mesh(obj.data)
        bmesh.ops.bisect_plane(mesh, geom=list(mesh.verts) + list(mesh.edges) + list(mesh.faces),
                               plane_co=(0, 0, .78), plane_no=(0, 0, 1), clear_outer=True)
        mesh.to_mesh(obj.data)
        mesh.free()
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.context.scene.objects:
        if obj.type == "MESH":
            obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(LARGE / "mk2-prepared.glb"), export_format="GLB",
                              use_selection=True, export_apply=True)
    print("Cropped Mk II neck stump")


if "--crop-mk2" in sys.argv:
    crop_mk2_neck()
    sys.exit(0)


def fit_glb(source, dest, limit):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=source)
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    for image in bpy.data.images:
        if image.size[0] > 1024 or image.size[1] > 1024:
            image.scale(1024, 1024)
    for obj in meshes:
        bpy.context.view_layer.objects.active = obj
        tri = obj.modifiers.new("triangulate", "TRIANGULATE")
        bpy.ops.object.modifier_apply(modifier=tri.name)
    count = lambda: sum(len(obj.data.polygons) for obj in meshes)
    original = count()
    for _ in range(5):
        if count() <= limit:
            break
        ratio = min(.99, limit / count() * .96)
        for obj in meshes:
            bpy.context.view_layer.objects.active = obj
            dec = obj.modifiers.new("triangle budget", "DECIMATE")
            dec.ratio = ratio
            bpy.ops.object.modifier_apply(modifier=dec.name)
    if count() > limit:
        raise RuntimeError(f"Triangle cap missed: {count()} > {limit}")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=dest, export_format="GLB", use_selection=True,
                              export_apply=True, export_image_format="AUTO")
    print(f"FITTED {source}: {original} -> {count()} triangles")


if "--fit" in sys.argv:
    i = sys.argv.index("--fit")
    fit_glb(sys.argv[i + 1], sys.argv[i + 2], int(sys.argv[i + 3]))
    sys.exit(0)


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def bounds(objects):
    points = [obj.matrix_world @ Vector(corner) for obj in objects for corner in obj.bound_box]
    lo = Vector(tuple(min(p[i] for p in points) for i in range(3)))
    hi = Vector(tuple(max(p[i] for p in points) for i in range(3)))
    return lo, hi


def render(path, size):
    scene = bpy.context.scene
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


tiers = [int(sys.argv[sys.argv.index("--tier") + 1])] if "--tier" in sys.argv else (1, 2, 3)
for tier in tiers:
    clear()
    bpy.ops.import_scene.gltf(filepath=str(MODELS / f"armor_mk{tier}_meshy.glb"))
    objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not objects:
        raise RuntimeError(f"Mk {tier}: GLB contains no mesh")
    lo, hi = bounds(objects)
    center = (lo + hi) / 2
    for obj in bpy.context.scene.objects:
        if obj.parent is None and obj.type in {"MESH", "EMPTY"}:
            obj.location -= center
    lo, hi = bounds(objects)
    extent = hi - lo
    for material in bpy.data.materials:
        if material.use_nodes:
            principled = material.node_tree.nodes.get("Principled BSDF")
            if principled:
                principled.inputs["Roughness"].default_value = 0.85
                principled.inputs["Metallic"].default_value = 0.0

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.world.color = (0.10, 0.14, 0.17)
    bpy.ops.object.camera_add(location=(3.1, -4.4, 2.7))
    camera = bpy.context.object
    camera.rotation_euler = (-camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = max(1.8, extent.x * 1.2, extent.y * 1.2, extent.z * 1.2)
    scene.camera = camera
    for location, energy, color, size in (((-3, -4, 5), 650, (0.75, 0.9, 1), 4), ((3, 1, 4), 850, (1, 0.76, 0.42), 3)):
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.object
        light.data.energy = energy
        light.data.color = color
        light.data.shape = "DISK"
        light.data.size = size
        light.rotation_euler = (-light.location).to_track_quat("-Z", "Y").to_euler()
    scene.view_settings.view_transform = "AgX"
    name = f"armor_jedi_mk{tier}.png"
    render(OUT / name, 256)
    render(OUT / "tiles" / name, 128)
    render(LARGE / f"mk{tier}-large.png", 640)
    print(f"MESHY ARMOR ICON Mk {tier}: dimensions {tuple(round(x, 3) for x in extent)}")

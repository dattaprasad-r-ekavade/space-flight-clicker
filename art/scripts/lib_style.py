"""Shared style library for every Blender asset script.

Run asset scripts from the repository root:
    blender --background --python art/scripts/<asset_id>.py

Start each asset script with:
    import os, sys
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from lib_style import *

Rules (see conventions.md, "Blender rules"):
- Units are metres. +Z is up. The origin (0, 0, 0) is the bottom centre of the asset.
- Use only colour names from PALETTE. Never create materials by hand.
- End every script with finish(asset_id, max_tris=...).

Position rules of the helpers:
- box, sphere, torus:  `pos` is the CENTRE of the shape.
- cylinder, cone, fin: `pos` is the centre of the BOTTOM; the shape grows along its local +Z.
- `rot` is (x, y, z) in DEGREES and turns the shape around `pos`.
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

__all__ = [
    "PALETTE", "get_material", "reset_scene", "box", "cylinder", "cone", "sphere", "torus", "fin",
    "ring_positions", "join_and_apply", "normalize", "tri_count", "export_glb", "render_preview", "finish",
]

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
MODELS_DIR = os.path.join(REPO, "game", "assets", "models")
PREVIEWS_DIR = os.path.join(REPO, "art", "previews")

# Colour name -> sRGB hex. Stages 1-2 use the warm set, 3-5 the industrial set, 6-9 the space set.
PALETTE = {
    # warm (stages 1-2)
    "grass": "#6BBF59",
    "grass_dark": "#3F8F4A",
    "sky_blue": "#7EC8E3",
    "sun_yellow": "#FFD966",
    "wood": "#A9744F",
    "wood_dark": "#6E4A32",
    "cardboard": "#D2A679",
    "glass": "#BFE8E0",
    "paper": "#FFF6E0",
    "skin": "#F2C6A0",
    "red": "#E2574C",
    # industrial (stages 3-5)
    "white": "#F4F4F0",
    "metal_light": "#C9CED6",
    "metal": "#8E97A3",
    "metal_dark": "#4A525E",
    "deep_blue": "#2B4C7E",
    "orange": "#F28C28",
    "sand": "#E0C08A",
    "black": "#1C1E24",
    # space (stages 6-9)
    "moon_grey": "#B8B8C0",
    "mars_red": "#B5533C",
    "space_purple": "#4B2E83",
    "space_dark": "#161226",
    "solar_panel": "#1F3A93",
    # emissive accents
    "glow_cyan": "#5CF2FF",
    "glow_white": "#FFFFFF",
    "glow_orange": "#FFB347",
}
EMISSIVE = {"glow_cyan": 4.0, "glow_white": 4.0, "glow_orange": 3.0}


def _srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _hex_to_linear(hex_code):
    h = hex_code.lstrip("#")
    return tuple(_srgb_to_linear(int(h[i:i + 2], 16) / 255.0) for i in (0, 2, 4))


def get_material(name):
    """Return the shared flat-colour material for a PALETTE name."""
    if name not in PALETTE:
        raise KeyError(f"'{name}' is not in PALETTE. Use one of: {', '.join(sorted(PALETTE))}")
    key = "mat_" + name
    mat = bpy.data.materials.get(key)
    if mat is not None:
        return mat
    rgb = _hex_to_linear(PALETTE[name])
    mat = bpy.data.materials.new(key)
    if mat.node_tree is None:
        mat.use_nodes = True
    mat.diffuse_color = (*rgb, 1.0)  # viewport / Workbench preview colour
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.9
    bsdf.inputs["Metallic"].default_value = 0.0
    if name in EMISSIVE:
        bsdf.inputs["Emission Color"].default_value = (*rgb, 1.0)
        bsdf.inputs["Emission Strength"].default_value = EMISSIVE[name]
    return mat


def reset_scene():
    """Start from an empty file. Call this first."""
    bpy.ops.wm.read_factory_settings(use_empty=True)


def _place(obj, pos, rot, material, lift=0.0):
    if lift:
        obj.data.transform(Matrix.Translation((0.0, 0.0, lift)))
    obj.location = pos
    obj.rotation_euler = tuple(math.radians(a) for a in rot)
    obj.data.materials.append(get_material(material))
    return obj


def box(pos, size, material, rot=(0, 0, 0)):
    """Box. pos = centre, size = (x, y, z) full lengths. 12 triangles."""
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    obj = bpy.context.active_object
    obj.data.transform(Matrix.Diagonal((size[0], size[1], size[2], 1.0)))
    return _place(obj, pos, rot, material)


def cylinder(pos, radius, height, material, segments=12, rot=(0, 0, 0)):
    """Cylinder. pos = centre of the bottom. Triangles = 4 * segments - 4."""
    bpy.ops.mesh.primitive_cylinder_add(vertices=segments, radius=radius, depth=height)
    return _place(bpy.context.active_object, pos, rot, material, lift=height / 2.0)


def cone(pos, radius, height, material, segments=12, radius_top=0.0, rot=(0, 0, 0)):
    """Cone or tapered tube. pos = centre of the bottom. radius_top > 0 makes a tapered section."""
    bpy.ops.mesh.primitive_cone_add(vertices=segments, radius1=radius, radius2=radius_top, depth=height)
    return _place(bpy.context.active_object, pos, rot, material, lift=height / 2.0)


def sphere(pos, radius, material, segments=12, rings=6, scale=(1, 1, 1), rot=(0, 0, 0)):
    """UV sphere. pos = centre. Triangles = 2 * segments * (rings - 1). Use scale to squash it."""
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=radius)
    obj = bpy.context.active_object
    obj.data.transform(Matrix.Diagonal((scale[0], scale[1], scale[2], 1.0)))
    return _place(obj, pos, rot, material)


def torus(pos, major_radius, minor_radius, material, major_segments=16, minor_segments=6, rot=(0, 0, 0)):
    """Ring that lies flat in the XY plane. pos = centre. Triangles = 2 * major * minor segments."""
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major_radius, minor_radius=minor_radius,
        major_segments=major_segments, minor_segments=minor_segments,
    )
    return _place(bpy.context.active_object, pos, rot, material)


def fin(pos, length, height, thickness, material, rot=(0, 0, 0)):
    """Triangular fin. The root edge runs up local +Z from pos; the tip points along local +X.
    Turn it around Z with rot=(0, 0, angle). 8 triangles."""
    t = thickness / 2.0
    mesh = bpy.data.meshes.new("fin")
    bm = bmesh.new()
    a0, a1 = bm.verts.new((0, -t, 0)), bm.verts.new((0, t, 0))
    b0, b1 = bm.verts.new((length, -t, 0)), bm.verts.new((length, t, 0))
    c0, c1 = bm.verts.new((0, -t, height)), bm.verts.new((0, t, height))
    for face in ((a0, b0, c0), (a1, c1, b1), (a0, a1, b1, b0), (b0, b1, c1, c0), (c0, c1, a1, a0)):
        bm.faces.new(face)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("fin", mesh)
    bpy.context.scene.collection.objects.link(obj)
    return _place(obj, pos, rot, material)


def ring_positions(count, radius, z=0.0, start_deg=0.0):
    """Evenly spaced points on a circle. Returns a list of ((x, y, z), angle_deg).
    Example: for pos, ang in ring_positions(3, 0.2): fin(pos, 0.3, 0.4, 0.03, "red", rot=(0, 0, ang))"""
    out = []
    for i in range(count):
        ang = start_deg + 360.0 * i / count
        r = math.radians(ang)
        out.append(((radius * math.cos(r), radius * math.sin(r), z), ang))
    return out


def _mesh_objects():
    return [o for o in bpy.context.scene.objects if o.type == "MESH"]


def join_and_apply(name, objects=None):
    """Join objects (default: all meshes) into one object called `name`.
    Transforms are applied and the object origin is moved to the world origin."""
    objs = list(objects) if objects is not None else _mesh_objects()
    if not objs:
        raise RuntimeError("join_and_apply: no mesh objects")
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    obj.name = name
    obj.data.name = name
    return obj


def _bounds(objs):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for o in objs:
        for corner in o.bound_box:
            w = o.matrix_world @ Vector(corner)
            lo = Vector((min(lo.x, w.x), min(lo.y, w.y), min(lo.z, w.z)))
            hi = Vector((max(hi.x, w.x), max(hi.y, w.y), max(hi.z, w.z)))
    return lo, hi


def normalize(obj, height=2.0):
    """Scale `obj` so that it is exactly `height` tall, with its bottom centre at the origin.
    Use this on every vehicle after join_and_apply."""
    bpy.context.view_layer.update()
    lo, hi = _bounds([obj])
    s = height / (hi.z - lo.z)
    cx, cy = (lo.x + hi.x) / 2.0, (lo.y + hi.y) / 2.0
    obj.data.transform(Matrix.Diagonal((s, s, s, 1.0)) @ Matrix.Translation((-cx, -cy, -lo.z)))
    obj.data.update()
    return obj


def tri_count():
    """Triangle count of all meshes in the scene."""
    return sum(len(p.vertices) - 2 for o in _mesh_objects() for p in o.data.polygons)


def export_glb(asset_id):
    """Write game/assets/models/<asset_id>.glb with every object in the scene."""
    os.makedirs(MODELS_DIR, exist_ok=True)
    path = os.path.join(MODELS_DIR, asset_id + ".glb")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True, use_selection=False)
    print(f"EXPORTED {path}")
    return path


def render_preview(asset_id):
    """Write art/previews/<asset_id>.png (512x768, fixed three-quarter view, flat lighting)."""
    os.makedirs(PREVIEWS_DIR, exist_ok=True)
    path = os.path.join(PREVIEWS_DIR, asset_id + ".png")
    scene = bpy.context.scene
    bpy.context.view_layer.update()
    lo, hi = _bounds(_mesh_objects())
    centre = (lo + hi) / 2.0
    size = hi - lo

    cam_data = bpy.data.cameras.new("preview_cam")
    cam_data.type = "ORTHO"
    cam = bpy.data.objects.new("preview_cam", cam_data)
    scene.collection.objects.link(cam)
    direction = Vector((1.0, -1.6, 0.7)).normalized()
    cam.location = centre + direction * (size.length * 3.0 + 5.0)
    cam.rotation_euler = (-direction).to_track_quat("-Z", "Y").to_euler()
    cam_data.clip_end = size.length * 10.0 + 50.0
    # Portrait frame: ortho_scale is the larger (vertical) side.
    cam_data.ortho_scale = max(size.z * 1.35, max(size.x, size.y) * 1.35 * 1.5, 0.5)
    scene.camera = cam

    engines = [i.identifier for i in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
    try:
        scene.render.engine = "BLENDER_WORKBENCH"
        shading = scene.display.shading
        shading.light = "STUDIO"
        shading.color_type = "MATERIAL"
        shading.show_object_outline = True
    except (TypeError, AttributeError) as err:
        print(f"WARNING preview engine setup: {err}; engines: {engines}")
    scene.render.film_transparent = False
    world = bpy.data.worlds.new("preview_world") if scene.world is None else scene.world
    scene.world = world
    world.color = (0.75, 0.78, 0.82)
    scene.render.resolution_x = 512
    scene.render.resolution_y = 768
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam)
    print(f"PREVIEW {path}")
    return path


def finish(asset_id, max_tris):
    """Last line of every asset script: check the budget, export the .glb, render the preview."""
    tris = tri_count()
    print(f"TRIANGLES {asset_id}: {tris} (budget {max_tris})")
    if tris > max_tris:
        print(f"FAIL {asset_id}: over the triangle budget")
        sys.exit(1)
    export_glb(asset_id)
    render_preview(asset_id)
    print(f"OK {asset_id}")

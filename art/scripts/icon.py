"""Store art: 1024x1024 icon and 1024x500 feature graphic, both built from the orbital rocket.

Reuses game/assets/models/vehicle_orbital.glb. Writes two PNG files to art/store/.
This script does not call finish(): it writes no .glb and no preview.

Run from the repository root:
    blender --background --python art/scripts/icon.py
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lib_style
from lib_style import *
import bpy
from mathutils import Vector

ROCKET_GLB = os.path.join(lib_style.REPO, "game", "assets", "models", "vehicle_orbital.glb")
STORE_DIR = os.path.join(lib_style.REPO, "art", "store")
ICON_PATH = os.path.join(STORE_DIR, "icon_1024.png")
FEATURE_PATH = os.path.join(STORE_DIR, "feature_1024x500.png")

TILT_DEG = 40.0            # nose tilts from vertical toward the upper right
ICON_FILL = 0.75           # rocket size as a share of the icon frame
FEATURE_FILL = 0.75        # rocket height as a share of the feature frame height
FEATURE_ANCHOR_U = 5.0 / 6.0   # rocket centre sits in the right third
CAM_DISTANCE = 10.0        # camera sits on -Y and looks along +Y
STAR_Y = 1.0               # stars sit behind the rocket
STAR_CLEARANCE = 0.30      # metres; no star closer than this to the rocket
FLAME_LENGTH = 0.88

frame_objs = []


def import_rocket():
    """Import the orbital rocket and return (imported objects, mesh parts)."""
    if not os.path.exists(ROCKET_GLB):
        raise FileNotFoundError(f"Missing rocket model: {ROCKET_GLB}")
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=ROCKET_GLB)
    new_objs = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new_objs if o.type == "MESH"]
    if not meshes:
        raise RuntimeError("glTF import produced no mesh objects")
    # Use the palette base colour for the viewport / Workbench colour.
    for o in meshes:
        for slot in o.material_slots:
            mat = slot.material
            if mat is None or not mat.use_nodes:
                continue
            bsdf = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
            if bsdf is not None:
                mat.diffuse_color = tuple(bsdf.inputs["Base Color"].default_value)
    return new_objs, meshes


def build_rig(new_objs):
    """Put the imported rocket under one empty, so the whole rocket can be tilted as one."""
    rig = bpy.data.objects.new("rig", None)
    bpy.context.scene.collection.objects.link(rig)
    for o in new_objs:
        if o.parent is None:
            o.parent = rig
    return rig


def add_flame(rig):
    """Orange flame cone with a yellow core, under the engine bell. Tip points down."""
    outer = cone((0, 0, 0), radius=0.20, height=FLAME_LENGTH, material="orange", segments=12, rot=(180, 0, 0))
    inner = cone((0, 0, 0), radius=0.11, height=FLAME_LENGTH * 0.72, material="sun_yellow",
                 segments=12, rot=(180, 0, 0))
    outer.parent = rig
    inner.parent = rig
    return [outer, inner]


def rocket_points(parts):
    """World-space (x, z) of every vertex of the rocket parts, after the rig tilt."""
    bpy.context.view_layer.update()
    pts = []
    for o in parts:
        for v in o.data.vertices:
            w = o.matrix_world @ v.co
            pts.append((w.x, w.z))
    return pts


def clear_frame():
    """Remove the camera and stars of the previous render."""
    for o in frame_objs:
        bpy.data.objects.remove(o, do_unlink=True)
    frame_objs.clear()


def make_camera(cam_x, cam_z, ortho_width):
    cam_data = bpy.data.cameras.new("store_cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = ortho_width
    cam_data.clip_start = 0.1
    cam_data.clip_end = 100.0
    cam = bpy.data.objects.new("store_cam", cam_data)
    bpy.context.scene.collection.objects.link(cam)
    cam.location = (cam_x, -CAM_DISTANCE, cam_z)
    cam.rotation_euler = (math.radians(90.0), 0.0, 0.0)  # looks along +Y, up is +Z
    bpy.context.scene.camera = cam
    frame_objs.append(cam)


def add_stars(rng, count, cam_x, cam_z, width_world, height_world, pts,
              min_u=0.05, planet_keepout=None):
    """Place larger stars away from the rocket, the planet, and any title area."""
    placed = 0
    attempts = 0
    clear_sq = STAR_CLEARANCE * STAR_CLEARANCE
    while placed < count and attempts < 5000:
        attempts += 1
        x = cam_x + rng.uniform(min_u - 0.5, 0.45) * width_world
        z = cam_z + rng.uniform(-0.45, 0.45) * height_world
        if min((x - px) ** 2 + (z - pz) ** 2 for px, pz in pts) < clear_sq:
            continue
        radius = rng.uniform(0.05, 0.085)
        if planet_keepout is not None:
            planet_x, planet_z, planet_radius = planet_keepout
            if (x - planet_x) ** 2 + (z - planet_z) ** 2 < (planet_radius + radius) ** 2:
                continue
        star = sphere((x, STAR_Y, z), radius=radius, material="glow_white", segments=8, rings=4)
        frame_objs.append(star)
        placed += 1
    print(f"STARS placed {placed} of {count}")


def add_planet_arc(cam_x, cam_z, width_world, height_world, anchor_u, anchor_v, radius_fraction):
    """Add a low-poly moon partly outside a lower frame corner."""
    radius = height_world * radius_fraction
    x = cam_x + (anchor_u - 0.5) * width_world
    z = cam_z + (0.5 - anchor_v) * height_world
    moon = sphere((x, STAR_Y + 0.15, z), radius=radius, material="moon_grey",
                  segments=16, rings=8, scale=(1.0, 0.08, 1.0))
    frame_objs.append(moon)
    return x, z, radius


def render_frame(out_path, width_px, height_px, anchor_u, width_world, cx, cz, pts,
                 star_count, seed, planet_anchor, planet_radius_fraction, star_min_u):
    """Set up the camera and stars, then render one PNG.

    anchor_u: horizontal image position of the rocket centre (0 to 1).
    width_world: world width of the frame in metres (ortho scale, the larger side).
    """
    clear_frame()
    height_world = width_world * height_px / width_px
    cam_x = cx - (anchor_u - 0.5) * width_world
    cam_z = cz
    make_camera(cam_x, cam_z, width_world)
    planet_keepout = add_planet_arc(cam_x, cam_z, width_world, height_world,
                                    planet_anchor[0], planet_anchor[1], planet_radius_fraction)
    add_stars(random.Random(seed), star_count, cam_x, cam_z, width_world, height_world, pts,
              min_u=star_min_u, planet_keepout=planet_keepout)

    scene = bpy.context.scene
    scene.render.resolution_x = width_px
    scene.render.resolution_y = height_px
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = out_path
    bpy.ops.render.render(write_still=True)
    print(f"RENDERED {out_path}")
    print(f"TRIANGLES {os.path.basename(out_path)} render: {tri_count()}")


# ---- Build the scene once ----
reset_scene()
new_objs, rocket_meshes = import_rocket()
rig = build_rig(new_objs)
flame_parts = add_flame(rig)
rig.rotation_euler = (0.0, math.radians(TILT_DEG), 0.0)
parts = rocket_meshes + flame_parts

pts = rocket_points(parts)
xs = [p[0] for p in pts]
zs = [p[1] for p in pts]
ext_x = max(xs) - min(xs)
ext_z = max(zs) - min(zs)
cx = (max(xs) + min(xs)) / 2.0
cz = (max(zs) + min(zs)) / 2.0
print(f"ROCKET extent x={ext_x:.3f} z={ext_z:.3f} centre=({cx:.3f}, {cz:.3f})")

# ---- Background and render settings (shared by both renders) ----
scene = bpy.context.scene
try:
    scene.render.engine = "BLENDER_WORKBENCH"
    shading = scene.display.shading
    shading.light = "STUDIO"
    shading.color_type = "MATERIAL"
    shading.show_object_outline = True
except (TypeError, AttributeError) as err:
    print(f"WARNING engine setup: {err}")
try:
    scene.view_settings.view_transform = "Standard"
except (TypeError, AttributeError) as err:
    print(f"WARNING view transform: {err}")
scene.render.film_transparent = False
world = bpy.data.worlds.new("store_world") if scene.world is None else scene.world
scene.world = world
world.color = lib_style._hex_to_linear(lib_style.PALETTE["deep_blue"])

# ---- Icon: square frame, rocket fills ICON_FILL of the larger rocket side ----
os.makedirs(STORE_DIR, exist_ok=True)
icon_width = max(ext_x, ext_z) / ICON_FILL
render_frame(ICON_PATH, 1024, 1024, 0.5, icon_width, cx, cz, pts, star_count=10, seed=7,
             planet_anchor=(0.91, 0.99), planet_radius_fraction=0.31, star_min_u=0.05)

# ---- Feature graphic: wide frame, rocket in the right third ----
feature_height = ext_z / FEATURE_FILL
feature_width = feature_height * 1024 / 500
render_frame(FEATURE_PATH, 1024, 500, FEATURE_ANCHOR_U, feature_width, cx, cz, pts, star_count=14, seed=11,
             planet_anchor=(1.00, 1.08), planet_radius_fraction=0.34, star_min_u=0.53)

clear_frame()
print(f"OUTPUT {ICON_PATH}")
print(f"OUTPUT {FEATURE_PATH}")

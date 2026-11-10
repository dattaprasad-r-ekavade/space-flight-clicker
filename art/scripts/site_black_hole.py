"""Launch site: black_hole. A research station on an irregular asteroid.

The launch point is the origin. The flat top of the asteroid is at z = 0.
A small metal landing pad sits on the top. Nothing stands within 1.5 m of the origin.
This script does not call normalize: the asset is built at its real scale.

Run from the repository root:
    blender --background --python art/scripts/site_black_hole.py
"""
import os
import sys
import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "site_black_hole"

reset_scene()

# One broad asteroid mesa with a single, flat landing surface at z = 0.
top_ring = [(-4.8, -2.6, 0.0), (3.9, -2.6, 0.0), (5.2, -1.6, 0.0),
            (5.2, 1.3, 0.0), (3.8, 2.5, 0.0), (-3.7, 2.5, 0.0),
            (-5.3, 1.4, 0.0), (-5.3, -1.4, 0.0)]
mid_ring = [(-5.2, -3.0, -0.75), (4.5, -3.1, -0.75), (6.0, -2.0, -0.75),
            (6.1, 1.5, -0.75), (4.6, 3.0, -0.75), (-4.5, 3.0, -0.75),
            (-6.1, 1.7, -0.75), (-6.2, -2.0, -0.75)]
bottom_ring = [(-4.4, -2.4, -2.2), (3.9, -2.5, -2.2), (5.2, -1.7, -2.2),
               (5.3, 1.1, -2.2), (4.0, 2.4, -2.2), (-3.9, 2.4, -2.2),
               (-5.0, 1.5, -2.2), (-5.1, -1.8, -2.2)]
rock_mesh = bpy.data.meshes.new("asteroid_mesa")
rock_verts = top_ring + mid_ring + bottom_ring
rock_faces = [tuple(range(8))]
for lower_offset in (8, 16):
    upper_offset = lower_offset - 8
    for i in range(8):
        j = (i + 1) % 8
        rock_faces.append((upper_offset + i, lower_offset + i,
                           lower_offset + j, upper_offset + j))
rock_mesh.from_pydata(rock_verts, [], rock_faces)
rock_mesh.materials.append(get_material("moon_grey"))
rock_mesh.materials.append(get_material("space_dark"))
rock_mesh.materials.append(get_material("space_purple"))
rock_obj = bpy.data.objects.new("asteroid_mesa", rock_mesh)
bpy.context.scene.collection.objects.link(rock_obj)
for face in rock_mesh.polygons:
    if face.index == 0:
        face.material_index = 0
    else:
        face.material_index = 1 if face.index % 3 else 2

# Landing pad: raised just above the flat asteroid top and centred on the origin.
box((0, 0, 0.05), size=(1.2, 1.2, 0.1), material="metal_light")
for sx, sy in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
    box((0.45 * sx, 0.45 * sy, 0.11), size=(0.12, 0.12, 0.02), material="glow_cyan")

# Habitat module: box with a glass dome and a door on its +X face.
box((-3.6, -0.6, 0.8), size=(2.0, 1.4, 1.6), material="metal_light")
sphere((-3.6, -0.6, 1.6), radius=0.7, material="glass", segments=16, rings=8, scale=(1, 1, 0.6))
box((-2.6, -0.6, 0.45), size=(0.08, 0.5, 0.9), material="metal_dark")

# Supply crates: two stacked crates.
box((3.0, -1.4, 0.45), size=(0.9, 0.9, 0.9), material="cardboard")
box((2.9, -1.5, 1.2), size=(0.7, 0.7, 0.6), material="wood")

# Antenna mast with a tip light and a crossbar.
cylinder((3.8, 1.2, 0.0), radius=0.05, height=3.2, material="metal_light", segments=8)
box((3.8, 1.2, 2.8), size=(0.6, 0.04, 0.04), material="metal")
sphere((3.8, 1.2, 3.3), radius=0.1, material="glow_white", segments=8, rings=4)

# Light pole with an orange lamp on top (top of pole at z = 2.2).
cylinder((-2.4, 2.0, 0.0), radius=0.05, height=2.7, material="metal_dark", segments=8)
box((-2.4, 2.0, 2.775), size=(0.3, 0.3, 0.15), material="glow_orange")

# Two vertical pipes.
cylinder((1.9, -2.3, 0.0), radius=0.08, height=2.4, material="metal", segments=8)
cylinder((2.5, -2.5, 0.0), radius=0.06, height=1.3, material="metal", segments=8)

# Plain flag on a pole (no logo).
cylinder((-5.0, -2.0, 0.0), radius=0.04, height=2.6, material="metal_light", segments=8)
box((-5.0, -1.7, 2.1), size=(0.04, 0.6, 0.4), material="sun_yellow")

# Solar panel on a short post.
cylinder((4.6, -1.6, 0.0), radius=0.06, height=0.9, material="metal_dark", segments=8)
box((4.6, -1.6, 1.4), size=(0.12, 1.6, 1.0), material="solar_panel")

# Join everything. Do not normalize: the site keeps its real size.
site = join_and_apply(ASSET_ID)

finish(ASSET_ID, max_tris=3000)

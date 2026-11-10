"""Vehicle: solar probe. A small unmanned probe with a dish on a long boom and two solar panels.

Run from the repository root:
    blender --background --python art/scripts/vehicle_solar.py
"""
import os
import sys
import math
import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "vehicle_solar"

reset_scene()

# Engine bell: a tapered tube at the bottom (wide end at the origin).
cone((0, 0, 0.0), radius=0.2, height=0.3, material="metal_dark", segments=10, radius_top=0.12)

# Bus: the main box body that holds the electronics.
box((0, 0, 0.75), size=(0.42, 0.42, 0.9), material="metal_light")

# Gold foil band around the bus.
cylinder((0, 0, 0.6), radius=0.22, height=0.05, material="sun_yellow", segments=8)

# Nose cone at the top (the nose points +Z, the direction of travel).
cone((0, 0, 1.2), radius=0.22, height=0.4, material="white", segments=10, radius_top=0.0)

# Red band just below the nose.
cylinder((0, 0, 1.12), radius=0.225, height=0.06, material="red", segments=10)

# Sensor eye on the -X side of the bus.
sphere((-0.22, 0, 1.0), radius=0.05, material="glow_cyan", segments=6, rings=3)

# Long boom along +X from the side of the bus.
cylinder((0.12, 0, 0.85), radius=0.025, height=0.85, material="metal", segments=6, rot=(0, 90, 0))

# Dish at the end of the boom. Its shallow bowl has correctly wound +X-facing triangles.
dish_segments = 16
dish_vertices = [(0.90, 0.0, 0.85)]
for i in range(dish_segments):
    angle = 2.0 * math.pi * i / dish_segments
    dish_vertices.append((1.02, 0.28 * math.cos(angle), 0.85 + 0.28 * math.sin(angle)))
dish_faces = [(0, 1 + i, 1 + ((i + 1) % dish_segments)) for i in range(dish_segments)]
dish_mesh = bpy.data.meshes.new("dish_face")
dish_mesh.from_pydata(dish_vertices, [], dish_faces)
dish_mesh.materials.append(get_material("white"))
dish_obj = bpy.data.objects.new("dish_face", dish_mesh)
bpy.context.scene.collection.objects.link(dish_obj)
torus((1.01, 0, 0.85), major_radius=0.26, minor_radius=0.025, material="metal_light",
      major_segments=16, minor_segments=6, rot=(0, 90, 0))
sphere((0.95, 0, 0.85), radius=0.045, material="glow_cyan", segments=8, rings=4)

# Two solar panels on the -Y and +Y sides, each on a short strut.
box((0, -0.55, 0.85), size=(0.04, 0.7, 0.5), material="solar_panel")
box((0, 0.55, 0.85), size=(0.04, 0.7, 0.5), material="solar_panel")
cylinder((0, -0.225, 0.85), radius=0.02, height=0.3, material="metal", segments=6, rot=(90, 0, 0))
cylinder((0, 0.225, 0.85), radius=0.02, height=0.3, material="metal", segments=6, rot=(-90, 0, 0))

# Join everything, then make the vehicle exactly 2 m tall with its bottom centre at the origin.
probe = join_and_apply(ASSET_ID)
normalize(probe, height=2.0)

finish(ASSET_ID, max_tris=1200)

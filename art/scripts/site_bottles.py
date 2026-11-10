"""Launch site: bottles. A grassy hill, one tree and a bicycle pump.

The ground top surface is at z = 0 and the launch point is the origin.
normalize() is not called, so the scene keeps its world coordinates.

Run from the repository root:
    blender --background --python art/scripts/site_bottles.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "site_bottles"

reset_scene()

# Dirt base with a grass top below the summit. The launch point remains at z = 0.
box((0, 0, -0.75), size=(12, 6, 0.5), material="wood_dark")
box((0, 0, -0.52), size=(12, 6, 0.04), material="grass")

# One broad, gentle hill fills the slab and rises to the launch point at the origin.
HILL_CZ = -0.5
HILL_RX = 7.0
HILL_RY = 4.1
HILL_RZ = 0.5
sphere((0, 0, HILL_CZ), radius=2.0, material="grass", segments=16, rings=8,
       scale=(HILL_RX / 2.0, HILL_RY / 2.0, HILL_RZ / 2.0))


def hill_surface_z(x, y):
    """Approximate the ellipsoid surface so props rest on the hill."""
    edge = (x / HILL_RX) ** 2 + (y / HILL_RY) ** 2
    return HILL_CZ + HILL_RZ * (max(0.0, 1.0 - edge) ** 0.5)


# Tree on the left side of the slope, rooted at the local ground height.
tree_ground = hill_surface_z(-3.5, -1.0)
cylinder((-3.5, -1.0, tree_ground), radius=0.18, height=2.0, material="wood", segments=8)
sphere((-3.5, -1.0, tree_ground + 2.75), radius=1.1, material="grass_dark", segments=10, rings=5)

# Bicycle pump at the front-right, with its base on the hill.
pump_ground = hill_surface_z(1.8, -1.2)
box((1.8, -1.2, pump_ground + 0.02), size=(0.36, 0.18, 0.04), material="black")
cylinder((1.8, -1.2, pump_ground + 0.04), radius=0.05, height=0.8, material="metal_light", segments=8)
box((1.8, -1.2, pump_ground + 0.86), size=(0.2, 0.06, 0.04), material="black")

# A short fence piece follows the back slope.
fence_ground = hill_surface_z(2.4, 2.0)
for x in (1.3, 3.5):
    post_ground = hill_surface_z(x, 2.0)
    box((x, 2.0, post_ground + 0.45), size=(0.10, 0.10, 0.9), material="wood_dark")
box((2.4, 2.0, fence_ground + 0.30), size=(2.2, 0.06, 0.08), material="wood")
box((2.4, 2.0, fence_ground + 0.68), size=(2.2, 0.06, 0.08), material="wood")

# Three simple flowers add colour without crowding the launch point.
for x, y, petal in ((-2.1, -1.6, "sun_yellow"), (-1.1, -1.8, "red"), (-0.8, 1.0, "sun_yellow")):
    flower_ground = hill_surface_z(x, y)
    cylinder((x, y, flower_ground), radius=0.018, height=0.22, material="grass_dark", segments=6)
    sphere((x, y, flower_ground + 0.25), radius=0.07, material=petal, segments=8, rings=4, scale=(1.0, 1.0, 0.65))

# A small wooden bench beside the fence, seated on the same slope.
bench_ground = hill_surface_z(-0.6, 1.9)
box((-0.6, 1.9, bench_ground + 0.38), size=(1.0, 0.10, 0.10), material="wood")
box((-0.6, 1.75, bench_ground + 0.63), size=(1.0, 0.10, 0.42), material="wood_dark")
for x in (-0.98, -0.22):
    box((x, 1.9, bench_ground + 0.18), size=(0.08, 0.12, 0.36), material="wood_dark")

# Join everything into one object. Do not normalize: the scene keeps its world size.
site = join_and_apply(ASSET_ID)

finish(ASSET_ID, max_tris=1500)

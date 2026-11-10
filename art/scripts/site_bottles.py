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

# Ground: a dirt block with a grass top. The grass top is at z = 0.
box((0, 0, -0.6), size=(12, 6, 1.0), material="wood_dark")
box((0, 0, -0.05), size=(12, 6, 0.1), material="grass")

# Grassy hill: a squashed sphere on the right side. It stays clear of the origin.
sphere((3.0, 0.6, 0.1), radius=2.0, material="grass", segments=12, rings=6, scale=(1.4, 1.1, 0.6))

# One tree on the left: a trunk and a round canopy.
cylinder((-3.5, -1.0, 0.0), radius=0.18, height=2.0, material="wood", segments=8)
sphere((-3.5, -1.0, 3.0), radius=1.1, material="grass_dark", segments=10, rings=5)

# Bicycle pump near the front-right of the origin: a black foot, a metal barrel and a handle.
box((1.8, -1.2, 0.02), size=(0.36, 0.18, 0.04), material="black")
cylinder((1.8, -1.2, 0.04), radius=0.05, height=0.8, material="metal_light", segments=8)
box((1.8, -1.2, 0.86), size=(0.2, 0.06, 0.04), material="black")

# Join everything into one object. Do not normalize: the scene keeps its world size.
site = join_and_apply(ASSET_ID)

finish(ASSET_ID, max_tris=1500)

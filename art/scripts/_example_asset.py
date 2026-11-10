"""Example asset: a small rocket. Copy this structure for every asset script.

Run from the repository root:
    blender --background --python art/scripts/_example_asset.py
"""
import math  # lib_style does not export math; import it yourself when you need it
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "_example_asset"

reset_scene()

# Body: cylinders and cones grow upward from the centre of their bottom.
cylinder((0, 0, 0.3), radius=0.25, height=1.2, material="white", segments=12)
cone((0, 0, 1.5), radius=0.25, height=0.5, material="red", segments=12)

# Engine bell: a tapered tube (radius_top > 0).
cone((0, 0, 0.0), radius=0.2, height=0.3, material="metal_dark", segments=10, radius_top=0.12)

# A coloured band: a thin, slightly wider cylinder.
cylinder((0, 0, 1.1), radius=0.26, height=0.08, material="deep_blue", segments=12)

# Window: a squashed sphere on the side of the body (-Y faces the camera).
sphere((0, -0.24, 1.25), radius=0.08, material="glow_cyan", segments=8, rings=4, scale=(1, 0.4, 1))

# Three fins around the body. ring_positions gives the position and the angle for each one.
for pos, angle in ring_positions(3, radius=0.24, z=0.3, start_deg=90):
    fin(pos, length=0.3, height=0.45, thickness=0.04, material="red", rot=(0, 0, angle))

# A ring near the base (torus lies flat in XY).
torus((0, 0, 0.32), major_radius=0.27, minor_radius=0.03, material="metal", major_segments=12, minor_segments=4)

# A small box detail (pos is the centre of the box).
box((0.26, 0, 0.8), size=(0.04, 0.1, 0.3), material="metal_light")

# Join everything, then make the vehicle exactly 2 m tall with its bottom centre at the origin.
rocket = join_and_apply(ASSET_ID)
normalize(rocket, height=2.0)

finish(ASSET_ID, max_tris=400)

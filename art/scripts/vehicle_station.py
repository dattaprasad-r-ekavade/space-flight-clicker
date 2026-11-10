"""Vehicle: station. A habitat module with a docking nose, a thruster bell and two solar panels.

Run from the repository root:
    blender --background --python art/scripts/vehicle_station.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "vehicle_station"

reset_scene()

# Habitat core: a white cylinder standing along +Z.
cylinder((0, 0, 0.3), radius=0.22, height=1.4, material="white", segments=12)

# Docking nose cone on top (nose points +Z).
cone((0, 0, 1.7), radius=0.22, height=0.4, material="metal_light", segments=12)

# Thruster bell at the bottom (tapered tube).
cone((0, 0, 0.0), radius=0.15, height=0.3, material="metal_dark", segments=10, radius_top=0.1)

# Coloured band around the habitat.
cylinder((0, 0, 0.9), radius=0.23, height=0.06, material="deep_blue", segments=12)

# Window: a squashed sphere on the -Y side (faces the camera).
sphere((0, -0.22, 1.2), radius=0.05, material="glow_cyan", segments=8, rings=4, scale=(1, 0.4, 1))

# Truss arm across the habitat at mid height (long axis along X).
box((0, 0, 1.0), size=(2.0, 0.06, 0.06), material="metal")

# Two solar panels, one on each side of the truss. Thin in Y, lying in the XZ plane.
for side in (-1, 1):
    box((side * 1.25, 0, 1.0), size=(0.5, 0.02, 0.5), material="solar_panel")

# Join everything, then make the station exactly 2 m tall with its bottom centre at the origin.
station = join_and_apply(ASSET_ID)
normalize(station, height=2.0)

finish(ASSET_ID, max_tris=1000)

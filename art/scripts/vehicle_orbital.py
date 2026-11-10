"""Vehicle: orbital. Two-stage rocket with four side boosters. Generic shape.

Run from the repository root:
    blender --background --python art/scripts/vehicle_orbital.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "vehicle_orbital"

reset_scene()

# Stage 1 body (white) with a deep blue band near the base.
cylinder((0, 0, 0.3), radius=0.3, height=1.3, material="white", segments=16)
cylinder((0, 0, 0.9), radius=0.31, height=0.1, material="deep_blue", segments=16)

# Stage 1 engine bell: tapered tube at the very bottom.
cone((0, 0, 0.0), radius=0.22, height=0.3, material="metal_dark", segments=16, radius_top=0.14)

# Interstage ring between the stages.
cylinder((0, 0, 1.6), radius=0.24, height=0.3, material="metal_light", segments=16)

# Stage 2 body (white) with one window.
cylinder((0, 0, 1.9), radius=0.22, height=0.9, material="white", segments=16)
sphere((0, -0.2, 2.3), radius=0.07, material="glow_cyan", segments=8, rings=4, scale=(1, 0.4, 1))

# Nose cone (red).
cone((0, 0, 2.8), radius=0.22, height=0.6, material="red", segments=16)

# Four stage 1 fins. The fin root sits on the body and points outward.
for pos, angle in ring_positions(4, radius=0.25, z=0.3, start_deg=0):
    fin(pos, length=0.4, height=0.9, thickness=0.04, material="red", rot=(0, 0, angle))

# Four side boosters, each with a bell, a body and a small nose cap.
for pos, angle in ring_positions(4, radius=0.45, z=0.0, start_deg=45):
    x, y, _ = pos
    cone((x, y, 0.0), radius=0.12, height=0.2, material="metal_dark", segments=10, radius_top=0.08)
    cylinder((x, y, 0.2), radius=0.12, height=1.4, material="white", segments=10)
    cone((x, y, 1.6), radius=0.12, height=0.3, material="red", segments=10)

# Join everything, then make the vehicle exactly 2 m tall with its bottom centre at the origin.
rocket = join_and_apply(ASSET_ID)
normalize(rocket, height=2.0)

finish(ASSET_ID, max_tris=1000)

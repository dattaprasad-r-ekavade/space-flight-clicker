"""Vehicle: galaxy. A sleek FTL ship with a ring drive. Nose points +Z, height 2 m.

Run from the repository root:
    blender --background --python art/scripts/vehicle_galaxy.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "vehicle_galaxy"

reset_scene()

# Engine bell: a flared cone at the bottom (wide base, narrow top).
cone((0, 0, 0.0), radius=0.22, height=0.32, material="metal_dark", segments=12, radius_top=0.15)

# Exhaust glow: a thin orange disc inside the bell.
cylinder((0, 0, 0.04), radius=0.14, height=0.02, material="glow_orange", segments=12)

# Main hull: a slim white cylinder.
cylinder((0, 0, 0.3), radius=0.17, height=1.0, material="white", segments=12)

# Blue hull band just below the ring drive.
cylinder((0, 0, 0.9), radius=0.18, height=0.05, material="deep_blue", segments=12)

# Nose: a long pointed cone (tip at about z = 2.2 before normalize).
cone((0, 0, 1.3), radius=0.17, height=0.9, material="white", segments=12)

# Cockpit: a flattened glass dome on the -Y side (the preview camera side).
sphere((0, -0.13, 1.5), radius=0.09, material="glass", segments=8, rings=4, scale=(1, 0.5, 1.2))

# Ring drive: a flat metal torus around the hull (torus lies in XY).
torus((0, 0, 0.8), major_radius=0.36, minor_radius=0.035, material="metal_light",
      major_segments=16, minor_segments=6)

# Three glowing drive pods on the ring.
for pos, _ang in ring_positions(3, radius=0.36, z=0.8, start_deg=0):
    sphere(pos, radius=0.05, material="glow_cyan", segments=8, rings=4)

# Three struts that join the ring to the hull. Each strut points radially.
for pos, angle in ring_positions(3, radius=0.265, z=0.8, start_deg=0):
    box(pos, size=(0.2, 0.03, 0.03), material="metal", rot=(0, 0, angle))

# Three swept red fins at the lower hull, between the struts.
for pos, angle in ring_positions(3, radius=0.1, z=0.2, start_deg=60):
    fin(pos, length=0.42, height=0.55, thickness=0.03, material="red", rot=(0, 0, angle))

# Join everything, then make the ship exactly 2 m tall with its bottom centre at the origin.
ship = join_and_apply(ASSET_ID)
normalize(ship, height=2.0)

finish(ASSET_ID, max_tris=1500)

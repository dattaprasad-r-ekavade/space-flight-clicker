"""Vehicle: black_hole. Armoured final craft with a glowing core.

Run from the repository root:
    blender --background --python art/scripts/vehicle_black_hole.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "vehicle_black_hole"

reset_scene()

# Hull: a dark metal drum. Bottom at z=0.4, top at z=1.5.
cylinder((0, 0, 0.4), radius=0.2, height=1.1, material="metal_dark", segments=10)

# Nose: a tapered cone that points +Z.
cone((0, 0, 1.5), radius=0.2, height=0.45, material="metal_light", segments=10)

# Canopy: a squashed glass dome on the upper nose, facing -Y.
sphere((0, -0.1, 1.55), radius=0.09, material="glass", segments=8, rings=4, scale=(1, 0.7, 0.8))

# Collar ring where the nose meets the hull.
torus((0, 0, 1.5), major_radius=0.21, minor_radius=0.025, material="metal_light",
      major_segments=10, minor_segments=4)

# Four armour plates on the diagonals. The front (-Y) stays open for the core pod.
for pos, angle in ring_positions(4, radius=0.25, z=0.8, start_deg=45):
    box(pos, size=(0.06, 0.22, 0.7), material="metal", rot=(0, 0, angle))

# Glowing core: a cyan pod set into the front of the hull.
sphere((0, -0.2, 0.95), radius=0.13, material="glow_cyan", segments=10, rings=6)

# Core frame: a small dark box that holds the pod.
box((0, -0.24, 0.95), size=(0.12, 0.06, 0.32), material="black")

# Four engine nozzles under the hull, each with an orange glow disc in the bell.
for pos, angle in ring_positions(4, radius=0.12, z=0.0, start_deg=45):
    cone(pos, radius=0.1, height=0.45, material="metal_dark", segments=8, radius_top=0.06)
    cylinder((pos[0], pos[1], 0.0), radius=0.05, height=0.02, material="glow_orange", segments=8)

# Four black stabiliser fins around the hull, between the armour plates.
for pos, angle in ring_positions(4, radius=0.2, z=0.45, start_deg=0):
    fin(pos, length=0.3, height=0.5, thickness=0.03, material="black", rot=(0, 0, angle))

# Joined craft, exactly 2 m tall, bottom centre at the origin.
craft = join_and_apply(ASSET_ID)
normalize(craft, height=2.0)

finish(ASSET_ID, max_tris=1500)

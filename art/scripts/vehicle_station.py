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

# Short, wide habitat module instead of a rocket body.
cylinder((0, 0, 0.18), radius=0.42, height=0.72, material="white", segments=12)

# Broad service belt around the module and a front-facing window.
cylinder((0, 0, 0.48), radius=0.44, height=0.10, material="deep_blue", segments=12)
sphere((0, -0.405, 0.66), radius=0.085, material="glow_cyan", segments=8, rings=4,
       scale=(1.0, 0.42, 1.0))

# A visible docking port on top: dark recessed centre surrounded by a metal ring.
cylinder((0, 0, 0.90), radius=0.27, height=0.13, material="metal_light", segments=12)
cylinder((0, 0, 1.03), radius=0.15, height=0.02, material="black", segments=12)
torus((0, 0, 1.075), major_radius=0.19, minor_radius=0.045, material="metal_light",
      major_segments=16, minor_segments=6)

# Four compact thrusters under the wide module.
for pos, angle in ring_positions(4, radius=0.27, z=0.0, start_deg=45):
    cone(pos, radius=0.10, height=0.25, material="metal_dark", segments=8, radius_top=0.06)

# Broad solar wings on short trusses emphasize the station silhouette.
for side in (-1, 1):
    box((side * 0.82, 0, 0.58), size=(0.78, 0.05, 0.58), material="solar_panel")
    box((side * 0.48, 0, 0.58), size=(0.24, 0.08, 0.07), material="metal")
    box((side * 1.17, 0, 0.58), size=(0.24, 0.08, 0.07), material="metal")

# Join everything, then make the station exactly 2 m tall with its bottom centre at the origin.
station = join_and_apply(ASSET_ID)
normalize(station, height=2.0)

finish(ASSET_ID, max_tris=1000)

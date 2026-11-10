"""Launch site: sounding. Desert pad, rail launcher, small hut.

The ground top surface is at z = 0. The launch point is the origin.
Do not call normalize on this asset.

Run from the repository root:
    blender --background --python art/scripts/site_sounding.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "site_sounding"

reset_scene()

# Desert ground: top surface at z = 0. Box spans x -6..6, y -3..3.
box((0, 0, -0.25), size=(12.0, 6.0, 0.5), material="sand")

# Launch pad: a flat metal slab, 1 cm above the ground, centred on the origin.
box((0, 0, 0.005), size=(2.4, 2.4, 0.01), material="metal_light")
# Pad marking: a thin yellow stripe on the pad.
box((0, 0, 0.012), size=(2.0, 0.08, 0.005), material="sun_yellow")

# Rail launcher, on the -X side of the pad.
# Two uprights, five metres tall.
box((-2.6, -0.4, 2.5), size=(0.12, 0.12, 5.0), material="metal")
box((-2.6, 0.4, 2.5), size=(0.12, 0.12, 5.0), material="metal")
# Crossbars between the uprights.
for z in (1.0, 2.5, 4.0):
    box((-2.6, 0.0, z), size=(0.12, 0.92, 0.12), material="metal_dark")
# Launch rail arm, reaching out over the pad at 4.6 m height.
box((-1.5, 0.0, 4.6), size=(2.4, 0.3, 0.2), material="metal_dark")
# Two rail guides on the arm.
box((-1.5, -0.1, 4.75), size=(2.4, 0.06, 0.06), material="metal_light")
box((-1.5, 0.1, 4.75), size=(2.4, 0.06, 0.06), material="metal_light")
# Base plates for the uprights.
box((-2.6, -0.4, 0.03), size=(0.5, 0.5, 0.06), material="metal_dark")
box((-2.6, 0.4, 0.03), size=(0.5, 0.5, 0.06), material="metal_dark")

# Small hut, on the +X side. Walls span x 2.4..4.8, y -2.5..-0.7, z 0..1.8.
box((3.6, -1.6, 0.9), size=(2.4, 1.8, 1.8), material="wood")
# Flat roof, slightly larger than the walls.
box((3.6, -1.6, 1.85), size=(2.7, 2.1, 0.1), material="metal_dark")
# Door on the -Y face.
box((3.3, -2.52, 0.5), size=(0.6, 0.04, 1.0), material="wood_dark")
# Window on the -Y face.
box((4.0, -2.52, 1.2), size=(0.6, 0.04, 0.5), material="glass")
# Antenna on the roof.
cylinder((4.5, -1.0, 1.9), radius=0.03, height=1.2, material="metal", segments=6)

# A small boxy field truck with a cab, windscreen, and chunky wheels.
box((0.65, -2.0, 0.40), size=(2.0, 1.0, 0.55), material="deep_blue")
box((1.15, -2.0, 0.87), size=(0.92, 0.92, 0.42), material="orange")
box((1.15, -2.48, 0.88), size=(0.65, 0.035, 0.25), material="glass")
box((-0.25, -2.0, 0.50), size=(0.22, 1.04, 0.22), material="metal_light")
for x in (-0.05, 1.35):
    for y in (-2.48, -1.52):
        cylinder((x, y, 0.20), radius=0.20, height=0.12, material="black", segments=10,
                 rot=(90, 0, 0))

# Cargo crates are stacked near the back edge of the pad.
box((4.8, 1.9, 0.35), size=(0.75, 0.75, 0.70), material="cardboard")
box((5.45, 1.75, 0.24), size=(0.55, 0.55, 0.48), material="wood")
box((4.8, 1.50, 0.36), size=(0.78, 0.04, 0.06), material="wood_dark")

# Tracking dish on a separate mast; the pale dish face is angled toward the sky.
cylinder((-4.4, 1.35, 0.0), radius=0.07, height=2.0, material="metal_dark", segments=8)
cone((-4.4, 1.35, 2.0), radius=0.58, height=0.18, material="metal_light", segments=12,
     radius_top=0.10, rot=(25, 0, 0))
sphere((-4.4, 1.10, 2.22), radius=0.07, material="glow_cyan", segments=8, rings=4)
box((-4.4, 1.35, 0.08), size=(0.65, 0.65, 0.16), material="metal_dark")

# Two low-poly desert rocks frame the truck without crowding the launcher.
sphere((-4.6, -2.0, 0.34), radius=0.50, material="mars_red", segments=10, rings=5,
       scale=(1.0, 0.85, 0.65))
sphere((-3.9, -1.65, 0.22), radius=0.32, material="sand", segments=8, rings=4,
       scale=(1.1, 0.9, 0.7))

# Join everything. The origin stays at the world origin. No normalize.
site = join_and_apply(ASSET_ID)

finish(ASSET_ID, max_tris=2000)

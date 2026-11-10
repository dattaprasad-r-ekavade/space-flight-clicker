"""Launch site: orbital. A ground slab, a launch pad ring, a lattice tower, a fuel tank and props.

The ground top surface is at z = 0. The launch point is the origin. Nothing stands within 1.5 m
of the origin, so the vehicle has room. No normalize() here: the site is built at real scale.

Run from the repository root:
    blender --background --python art/scripts/site_orbital.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "site_orbital"

reset_scene()

# Ground slab: 12 m wide (x), 6 m deep (y), top surface at z = 0.
box((0, 0, -0.25), size=(12.0, 6.0, 0.5), material="sand")

# Launch pad ring: a flat torus around the clear zone. Inner edge is 2.2 m from the origin.
torus((0, 0, 0.1), major_radius=2.3, minor_radius=0.1, material="metal_light",
      major_segments=20, minor_segments=8)

# Launch tower at the back left (x = -3.6, y = 1.8).
TX, TY = -3.6, 1.8
box((TX, TY, 0.15), size=(1.4, 1.4, 0.3), material="metal_dark")
for dx, dy in ((-0.5, -0.5), (0.5, -0.5), (-0.5, 0.5), (0.5, 0.5)):
    cylinder((TX + dx, TY + dy, 0.0), radius=0.1, height=8.6, material="metal", segments=8)
for level in (1.5, 3.5, 5.5, 7.5):
    box((TX, TY - 0.5, level), size=(1.0, 0.06, 0.06), material="metal_light")
    box((TX, TY + 0.5, level), size=(1.0, 0.06, 0.06), material="metal_light")
    box((TX - 0.5, TY, level), size=(0.06, 1.0, 0.06), material="metal_light")
    box((TX + 0.5, TY, level), size=(0.06, 1.0, 0.06), material="metal_light")
box((TX, TY, 8.7), size=(1.6, 1.6, 0.2), material="metal")
cylinder((TX, TY, 8.8), radius=0.04, height=0.9, material="red", segments=8)
sphere((TX, TY, 9.75), radius=0.06, material="glow_white", segments=8, rings=4)

# Fuel tank at the back right (x = 3.5, y = 1.5): base, body, orange band, dome.
FX, FY = 3.5, 1.5
box((FX, FY, 0.1), size=(1.8, 1.8, 0.2), material="metal_dark")
cylinder((FX, FY, 0.2), radius=0.7, height=2.4, material="white", segments=16)
cylinder((FX, FY, 1.0), radius=0.73, height=0.15, material="orange", segments=16)
cone((FX, FY, 2.6), radius=0.7, height=0.45, material="white", segments=16)

# Props. Heights vary. Each one stays outside the 1.5 m clear zone.
# Crates.
box((2.6, -1.4, 0.3), size=(0.6, 0.6, 0.6), material="cardboard")
box((3.2, -1.9, 0.25), size=(0.5, 0.5, 0.5), material="wood")

# Light pole with a lamp.
cylinder((-2.0, -2.2, 0.0), radius=0.04, height=1.6, material="metal_dark", segments=8)
sphere((-2.0, -2.2, 1.7), radius=0.12, material="glow_white", segments=8, rings=4)

# Standing pipe.
cylinder((5.0, -0.5, 0.0), radius=0.09, height=2.2, material="metal", segments=10)

# Generator box with a vent.
box((-4.2, -1.8, 0.35), size=(0.8, 0.6, 0.7), material="black")
cylinder((-4.2, -1.8, 0.7), radius=0.12, height=0.3, material="metal_light", segments=8)

# Two rocks.
sphere((-5.0, 0.8, 0.1), radius=0.35, material="metal", segments=10, rings=6, scale=(1.0, 0.8, 0.6))
sphere((1.2, -2.4, 0.1), radius=0.3, material="metal", segments=12, rings=8, scale=(1.2, 1.0, 0.7))

# Flag pole with a plain blue flag (no logo).
cylinder((5.0, 2.2, 0.0), radius=0.03, height=2.5, material="white", segments=8)
box((5.3, 2.2, 2.2), size=(0.6, 0.02, 0.4), material="deep_blue")

# Join everything into one object. No normalize: the site stays at real scale.
site = join_and_apply(ASSET_ID)

finish(ASSET_ID, max_tris=2500)

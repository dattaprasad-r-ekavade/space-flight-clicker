"""Launch site: moon. A flat grey surface with two domes, a mast and small props.

The ground top surface is at z = 0. The launch point is the origin.
The 1.5 m area around the origin is kept clear. normalize() is not used here.

Run from the repository root:
    blender --background --python art/scripts/site_moon.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "site_moon"

reset_scene()

# Ground: 12 m wide (X), 6 m deep (Y). The top surface is at z = 0.
box((0, 0, -0.25), size=(12.0, 6.0, 0.5), material="moon_grey")

# Dome A: a large glass dome. The lower half sits under the ground.
sphere((-3.5, 1.0, 0.0), radius=1.4, material="glass", segments=24, rings=12)
# White base rim at the foot of dome A.
torus((-3.5, 1.0, 0.05), major_radius=1.4, minor_radius=0.06, material="white",
      major_segments=24, minor_segments=4)

# Dome B: a smaller glass dome.
sphere((3.5, -0.5, 0.0), radius=1.0, material="glass", segments=24, rings=12)
torus((3.5, -0.5, 0.05), major_radius=1.0, minor_radius=0.05, material="white",
      major_segments=24, minor_segments=4)

# Mast: a tall pole with two crossbars and a tip.
cylinder((4.8, 2.0, 0.0), radius=0.06, height=6.0, material="metal_light", segments=12)
box((4.8, 2.0, 4.0), size=(1.0, 0.05, 0.05), material="metal")
box((4.8, 2.0, 5.4), size=(0.7, 0.05, 0.05), material="metal")
cylinder((4.8, 2.0, 6.0), radius=0.02, height=1.5, material="black", segments=6)
sphere((4.8, 2.0, 6.0), radius=0.12, material="red", segments=8, rings=4)

# Prop 1: a stack of two crates (heights 0.8 and 1.4).
box((-4.6, -1.6, 0.4), size=(0.8, 0.8, 0.8), material="cardboard")
box((-4.6, -1.6, 1.1), size=(0.6, 0.6, 0.6), material="wood")

# Prop 2: a pipe on two posts, running along X.
cylinder((-3.8, -2.2, 0.0), radius=0.08, height=0.5, material="metal_dark", segments=8)
cylinder((-1.8, -2.2, 0.0), radius=0.08, height=0.5, material="metal_dark", segments=8)
cylinder((-3.8, -2.2, 0.5), radius=0.1, height=2.0, material="metal", segments=12, rot=(0, 90, 0))

# Prop 3: a light on a post (post 1.2 m, light at 1.3 m).
cylinder((4.5, -2.0, 0.0), radius=0.06, height=1.2, material="metal_dark", segments=8)
sphere((4.5, -2.0, 1.3), radius=0.15, material="glow_orange", segments=8, rings=4)

# Prop 4: a shorter light on a post (post 0.8 m, light at 0.9 m).
cylinder((1.8, 2.3, 0.0), radius=0.05, height=0.8, material="metal_dark", segments=8)
sphere((1.8, 2.3, 0.9), radius=0.12, material="glow_white", segments=8, rings=4)

# Prop 5: a flag on a 3 m pole, with a plain red pennant. No logo.
cylinder((-5.2, 2.0, 0.0), radius=0.04, height=3.0, material="white", segments=8)
fin((-5.2, 2.0, 2.4), length=0.9, height=0.6, thickness=0.03, material="red", rot=(0, 0, 0))

# Prop 6: two rocks on the ground (different sizes).
sphere((2.6, -1.0, 0.0), radius=0.45, material="metal", segments=12, rings=6, scale=(1.0, 0.8, 0.6))
sphere((-2.0, -0.4, 0.0), radius=0.3, material="metal_dark", segments=12, rings=6, scale=(1.0, 0.9, 0.7))

# Build the single launch site object. Its origin is the world origin, and the ground top is z = 0.
site = join_and_apply(ASSET_ID)

finish(ASSET_ID, max_tris=2500)

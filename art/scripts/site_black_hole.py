"""Launch site: black_hole. A research station on an irregular asteroid.

The launch point is the origin. The flat top of the asteroid is at z = 0.
A small metal landing pad sits on the top. Nothing stands within 1.5 m of the origin.
This script does not call normalize: the asset is built at its real scale.

Run from the repository root:
    blender --background --python art/scripts/site_black_hole.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "site_black_hole"

reset_scene()

# Asteroid: overlapping squashed spheres. Each sphere top is at or below z = 0.
# Main body: centre -1.56, radius 2.6, z scale 0.6 -> top exactly at z = 0.
sphere((0, 0, -1.56), radius=2.6, material="space_dark", segments=16, rings=8, scale=(1, 1, 0.6))
sphere((1.8, -1.0, -1.2), radius=1.6, material="moon_grey", segments=16, rings=8, scale=(1, 1, 0.5))
sphere((-1.6, 1.0, -1.0), radius=1.4, material="moon_grey", segments=16, rings=8, scale=(1, 1, 0.5))
sphere((0.5, 1.6, -0.9), radius=1.0, material="space_purple", segments=16, rings=8, scale=(1, 1, 0.5))
sphere((-2.2, -1.2, -0.9), radius=0.9, material="space_purple", segments=12, rings=6, scale=(1, 1, 0.6))
sphere((3.6, 0.6, -0.8), radius=1.0, material="space_dark", segments=12, rings=6, scale=(1, 1, 0.5))
sphere((4.3, -1.4, -0.9), radius=1.0, material="space_dark", segments=12, rings=6, scale=(1, 1, 0.5))
sphere((-4.6, 1.6, -0.3), radius=0.6, material="moon_grey", segments=12, rings=6, scale=(1, 0.9, 0.7))

# Landing pad: top at z = 0, centred on the origin (1.2 m square, 0.1 m thick).
box((0, 0, -0.05), size=(1.2, 1.2, 0.1), material="metal_light")
for sx, sy in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
    # Flush cyan marker lights on the pad corners. Top at z = 0.
    box((0.45 * sx, 0.45 * sy, -0.01), size=(0.12, 0.12, 0.02), material="glow_cyan")

# Habitat module: box with a glass dome and a door on its +X face.
box((-3.6, -0.6, 0.4), size=(2.0, 1.4, 1.6), material="metal_light")
sphere((-3.6, -0.6, 1.2), radius=0.7, material="glass", segments=16, rings=8, scale=(1, 1, 0.6))
box((-2.6, -0.6, 0.3), size=(0.08, 0.5, 0.9), material="metal_dark")

# Supply crates: two stacked crates.
box((3.0, -1.4, 0.15), size=(0.9, 0.9, 0.9), material="cardboard")
box((2.9, -1.5, 0.9), size=(0.7, 0.7, 0.6), material="wood")

# Antenna mast with a tip light and a crossbar.
cylinder((3.8, 1.2, -0.3), radius=0.05, height=3.2, material="metal_light", segments=8)
box((3.8, 1.2, 2.2), size=(0.6, 0.04, 0.04), material="metal")
sphere((3.8, 1.2, 2.95), radius=0.1, material="glow_white", segments=8, rings=4)

# Light pole with an orange lamp on top (top of pole at z = 2.2).
cylinder((-2.4, 2.0, -0.5), radius=0.05, height=2.7, material="metal_dark", segments=8)
box((-2.4, 2.0, 2.275), size=(0.3, 0.3, 0.15), material="glow_orange")

# Two vertical pipes.
cylinder((1.9, -2.3, -0.4), radius=0.08, height=2.4, material="metal", segments=8)
cylinder((2.5, -2.5, -0.4), radius=0.06, height=1.3, material="metal", segments=8)

# Plain flag on a pole (no logo).
cylinder((-5.0, -2.0, -0.3), radius=0.04, height=2.6, material="metal_light", segments=8)
box((-5.0, -1.7, 1.9), size=(0.04, 0.6, 0.4), material="sun_yellow")

# Solar panel on a short post.
cylinder((4.6, -1.6, -0.4), radius=0.06, height=0.9, material="metal_dark", segments=8)
box((4.6, -1.6, 0.9), size=(0.12, 1.6, 1.0), material="solar_panel")

# Join everything. Do not normalize: the site keeps its real size.
site = join_and_apply(ASSET_ID)

finish(ASSET_ID, max_tris=3000)

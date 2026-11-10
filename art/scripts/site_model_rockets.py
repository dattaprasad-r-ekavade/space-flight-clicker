"""Launch site: model_rockets. A backyard with a fence and a launch rod on a tripod.

The ground top surface is at z = 0. The launch point is the origin.
Do not call normalize on this site.

Run from the repository root:
    blender --background --python art/scripts/site_model_rockets.py
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "site_model_rockets"

reset_scene()

# Lawn: 12 m wide (X), 6 m deep (Y). The top face is at z = 0.
box((0, 0, -0.25), size=(12.0, 6.0, 0.5), material="grass")

# Back fence along +Y: posts, then two rails.
BACK_Y = 2.9
back_xs = [-5.9 + i * 1.475 for i in range(9)]
for x in back_xs:
    box((x, BACK_Y, 0.75), size=(0.1, 0.1, 1.5), material="wood_dark")
box((0, BACK_Y, 0.5), size=(11.8, 0.04, 0.08), material="wood")
box((0, BACK_Y, 1.1), size=(11.8, 0.04, 0.08), material="wood")

# Side fences along X = +-5.9: posts, then two rails each.
SIDE_X = 5.9
side_ys = [-2.9 + i * 1.45 for i in range(5)]
for side in (-1, 1):
    for y in side_ys:
        box((side * SIDE_X, y, 0.75), size=(0.1, 0.1, 1.5), material="wood_dark")
    box((side * SIDE_X, 0, 0.5), size=(0.04, 5.8, 0.08), material="wood")
    box((side * SIDE_X, 0, 1.1), size=(0.04, 5.8, 0.08), material="wood")

# Two bushes against the back fence. Centre at z = 0.45 with radius 0.45 sits on the ground.
sphere((-4.5, 2.3, 0.45), radius=0.45, material="grass_dark", segments=8, rings=4, scale=(1, 1, 0.8))
sphere((4.3, 2.2, 0.45), radius=0.45, material="grass_dark", segments=8, rings=4, scale=(1, 1, 0.8))

# Launch tripod: three legs meet at (0, 0, 1.2). Base radius 0.5 m.
LEG_R = 0.5
LEG_H = 1.2
leg_len = math.sqrt(LEG_H ** 2 + LEG_R ** 2)
lean_deg = math.degrees(math.atan2(LEG_R, LEG_H))
for pos, angle in ring_positions(3, radius=LEG_R, z=0.0, start_deg=0.0):
    # Lean inward: tilt the leg toward +X, then turn it to face the centre.
    cylinder(pos, radius=0.025, height=leg_len, material="metal_dark", segments=6,
             rot=(0, lean_deg, angle + 180.0))

# Launch rod on the tripod, centred on the origin. Vehicle stands on the origin.
cylinder((0, 0, 0.0), radius=0.02, height=2.4, material="metal_light", segments=8)

# Join everything. Keep the ground at z = 0 and the origin at the launch point.
site = join_and_apply(ASSET_ID)

finish(ASSET_ID, max_tris=1500)

"""Launch site: orbit station. A floating platform with a truss and a docking ring.

The deck top surface is at z = 0. The launch point is the origin, where the vehicle stands.
Nothing above the deck comes within 1.5 m of the origin, so the vehicle has room.
Do not call normalize() on a launch site.

Run from the repository root:
    blender --background --python art/scripts/site_station.py
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "site_station"

reset_scene()

# Deck: the platform the vehicle stands on. Top surface at z = 0.
box((0, 0, -0.25), (5.0, 4.0, 0.5), "metal_dark")

# Side pads with a bridge to the deck (one at each side).
box((4.0, -1.0, -0.25), (1.6, 1.6, 0.5), "metal_dark")
box((2.9, -1.0, -0.25), (0.8, 0.4, 0.3), "metal")
box((-4.6, 1.2, -0.25), (1.2, 1.2, 0.5), "metal_dark")
box((4.6, 1.6, -0.25), (1.2, 1.2, 0.5), "metal_dark")

# Docking ring at z = 5, held by four posts on the 2.5 m circle.
torus((0, 0, 5.0), major_radius=2.5, minor_radius=0.12, material="metal_light",
      major_segments=32, minor_segments=10)
for pos, angle in ring_positions(4, radius=2.5, z=0.0, start_deg=45):
    cylinder(pos, radius=0.1, height=5.0, material="metal", segments=12)

# Truss bars around the posts at two heights. Their closest point to the origin is 1.7 m away.
for z in (1.0, 2.5):
    box((0, 1.768, z), (3.54, 0.1, 0.1), "metal")
    box((0, -1.768, z), (3.54, 0.1, 0.1), "metal")
    box((1.768, 0, z), (0.1, 3.54, 0.1), "metal")
    box((-1.768, 0, z), (0.1, 3.54, 0.1), "metal")

# Prop 1 and 2: two stacked crates at the back-left of the deck (heights 0.6 m and 1.15 m).
box((-1.9, -1.4, 0.3), (0.6, 0.6, 0.6), "cardboard")
box((-1.9, -1.4, 0.85), (0.5, 0.5, 0.5), "wood")

# Prop 3: a small crate at the front-left corner.
box((-1.9, 1.4, 0.2), (0.4, 0.4, 0.4), "wood")

# Prop 4: an antenna mast on the right pad, with a dish and a red tip.
cylinder((4.0, -1.0, 0.0), radius=0.07, height=8.5, material="white", segments=12)
box((4.0, -1.0, 7.0), (0.9, 0.08, 0.08), "white")
sphere((4.0, -1.0, 8.5), radius=0.5, material="metal_light", segments=16, rings=6, scale=(1, 1, 0.35))
sphere((4.0, -1.0, 8.9), radius=0.1, material="red", segments=12, rings=6)

# Prop 5 and 6: two light pylons with glowing tips at different heights.
cylinder((-4.6, 1.2, 0.0), radius=0.05, height=2.5, material="black", segments=12)
sphere((-4.6, 1.2, 2.6), radius=0.12, material="glow_white", segments=10, rings=6)
cylinder((4.6, 1.6, 0.0), radius=0.05, height=1.6, material="black", segments=12)
sphere((4.6, 1.6, 1.7), radius=0.12, material="glow_orange", segments=10, rings=6)

# Prop 7: a flag on a short pole near the deck edge (no logo).
cylinder((2.0, -1.7, 0.0), radius=0.03, height=2.0, material="metal_light", segments=8)
box((2.35, -1.7, 1.7), (0.7, 0.02, 0.4), "red")

# Join everything. The origin stays at the world origin (z = 0 is the deck top).
station = join_and_apply(ASSET_ID)

finish(ASSET_ID, max_tris=2500)

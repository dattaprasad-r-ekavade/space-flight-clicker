"""Vehicle: bottles. A glass bottle with a cork and a rolled note lying against its base.

Run from the repository root:
    blender --background --python art/scripts/vehicle_bottles.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "vehicle_bottles"

reset_scene()

# Bottle body: a straight lower section, a tapered shoulder, and a narrow neck. Nose points +Z.
cylinder((0, 0, 0.0), radius=0.3, height=0.9, material="glass", segments=12)
cone((0, 0, 0.9), radius=0.3, height=0.5, material="glass", segments=12, radius_top=0.1)
cylinder((0, 0, 1.4), radius=0.1, height=0.6, material="glass", segments=12)

# Cork: a short wooden-tan plug that sits on top of the neck.
cylinder((0, 0, 2.0), radius=0.12, height=0.2, material="cardboard", segments=10)

# Rolled note: a paper cylinder lying on its side against the front of the base.
# rot=(0, 90, 0) turns the cylinder so that its length runs along X. pos is its bottom end.
cylinder((-0.25, -0.38, 0.1), radius=0.1, height=0.5, material="paper", segments=10, rot=(0, 90, 0))

# Red tie band around the middle of the rolled note.
cylinder((-0.02, -0.38, 0.1), radius=0.105, height=0.04, material="red", segments=10, rot=(0, 90, 0))

# Join everything, then make the vehicle exactly 2 m tall with its bottom centre at the origin.
bottle = join_and_apply(ASSET_ID)
normalize(bottle, height=2.0)

finish(ASSET_ID, max_tris=300)

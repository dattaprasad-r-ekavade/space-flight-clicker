"""Memory bottle skins: six variants of the bottle, each with its own colours and one shape change.
Writes game/assets/models/bottle_skin_1.glb ... bottle_skin_6.glb and matching previews.

Run from the repository root:
    blender --background --python art/scripts/bottle_skins.py
"""
import math  # lib_style does not export math; import it yourself when you need it
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *


def _bottle(x, body, cork, segs=12, body_r=0.3, body_h=0.9, shoulder_h=0.5,
            neck_r=0.1, neck_h=0.6, cork_r=0.12, cork_h=0.2):
    """Base bottle at x: straight body, tapered shoulder, neck, cork. Returns the top height."""
    cylinder((x, 0.0, 0.0), radius=body_r, height=body_h, material=body, segments=segs)
    cone((x, 0.0, body_h), radius=body_r, height=shoulder_h, material=body, segments=segs, radius_top=neck_r)
    neck_z = body_h + shoulder_h
    cylinder((x, 0.0, neck_z), radius=neck_r, height=neck_h, material=body, segments=segs)
    top = neck_z + neck_h
    cylinder((x, 0.0, top), radius=cork_r, height=cork_h, material=cork, segments=segs)
    return top + cork_h


def build_skin(index):
    asset_id = f"bottle_skin_{index}"
    reset_scene()

    if index == 1:
        # Ribbon: a red band on the neck with two red tails.
        _bottle(0.0, "glass", "cardboard")
        cylinder((0.0, 0.0, 1.6), radius=0.105, height=0.08, material="red", segments=12)
        fin((0.08, 0.0, 1.45), length=0.3, height=0.3, thickness=0.03, material="red", rot=(0, 0, 0))
        fin((-0.08, 0.0, 1.45), length=0.3, height=0.3, thickness=0.03, material="red", rot=(0, 0, 180))

    elif index == 2:
        # Star cork: five small cones pointing out from a wooden cork.
        _bottle(0.0, "sun_yellow", "wood")
        for pos, angle in ring_positions(5, radius=0.1, z=2.05, start_deg=0):
            cone(pos, radius=0.05, height=0.1, material="wood_dark", segments=8, rot=(90, 0, angle + 90))

    elif index == 3:
        # Tall thin neck.
        _bottle(0.0, "sky_blue", "white", neck_r=0.07, neck_h=1.0, cork_r=0.09, cork_h=0.2)

    elif index == 4:
        # Round ball-shaped body with a short neck.
        sphere((0.0, 0.0, 0.45), radius=0.45, material="orange", segments=12, rings=6)
        cylinder((0.0, 0.0, 0.8), radius=0.1, height=0.7, material="orange", segments=12)
        cylinder((0.0, 0.0, 1.5), radius=0.12, height=0.2, material="wood", segments=12)

    elif index == 5:
        # Two small bottles side by side.
        for x in (-0.22, 0.22):
            _bottle(x, "grass", "cardboard", segs=10, body_r=0.18, body_h=0.7, shoulder_h=0.35,
                    neck_r=0.07, neck_h=0.5, cork_r=0.085, cork_h=0.15)

    elif index == 6:
        # Crystal: six-sided faceted body with a glowing cyan band and tip.
        top = _bottle(0.0, "glass", "space_purple", segs=6)
        torus((0.0, 0.0, 0.45), major_radius=0.33, minor_radius=0.025,
              material="glow_cyan", major_segments=6, minor_segments=4)
        sphere((0.0, 0.0, top), radius=0.1, material="glow_cyan", segments=6, rings=3)

    else:
        raise ValueError(f"unknown skin index {index}")

    obj = join_and_apply(asset_id)
    normalize(obj, height=2.0)
    finish(asset_id, max_tris=400)


for skin_index in range(1, 7):
    build_skin(skin_index)

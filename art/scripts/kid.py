"""Kid character: a simple stylised child, about 1.2 m tall, feet at z = 0, facing -Y.

Three objects are exported: `body` (head, hair, torso, legs, shoes), `arm_l` and `arm_r`.
Each arm has its origin at its shoulder so Godot can rotate it for a pump motion.

Run from the repository root:
    blender --background --python art/scripts/kid.py
"""
import math  # lib_style does not export math; import it yourself when you need it
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lib_style import *

ASSET_ID = "kid"

SHOULDER_X = 0.21
SHOULDER_Z = 0.80

reset_scene()

# Large round head, close to one third of the child's total height.
head = sphere((0, 0, 1.02), radius=0.22, material="skin", segments=12, rings=6)
# Full dark hair cap with two low-poly locks forming a soft fringe.
hair = sphere((0, 0.015, 1.16), radius=0.22, material="wood_dark", segments=12, rings=6,
              scale=(1.0, 0.95, 0.52))
fringe = sphere((0, -0.19, 1.09), radius=0.18, material="wood_dark", segments=8, rings=4,
                scale=(1.0, 0.35, 0.42))
eye_l = sphere((-0.075, -0.212, 1.00), radius=0.015, material="black", segments=6, rings=3)
eye_r = sphere((0.075, -0.212, 1.00), radius=0.015, material="black", segments=6, rings=3)

# Rounded red t-shirt, eight-sided like the rest of the low-poly character.
torso = cylinder((0, 0, 0.58), radius=0.18, height=0.30, material="red", segments=8)

# Shorts: deep blue.
shorts = box((0, 0, 0.50), size=(0.34, 0.20, 0.14), material="deep_blue")

# Legs: skin, two tubes under the shorts.
leg_l = cylinder((0.08, 0, 0.07), radius=0.045, height=0.29, material="skin", segments=10)
leg_r = cylinder((-0.08, 0, 0.07), radius=0.045, height=0.29, material="skin", segments=10)

# Shoes: small black boxes at the foot of each leg.
shoe_l = box((0.08, -0.02, 0.035), size=(0.11, 0.20, 0.07), material="black")
shoe_r = box((-0.08, -0.02, 0.035), size=(0.11, 0.20, 0.07), material="black")

# Arms: each arm is a tube with a round hand. They are joined separately below.
arm_l_parts = [
    cylinder((SHOULDER_X, 0, 0.42), radius=0.05, height=0.40, material="skin", segments=10),
    sphere((SHOULDER_X, 0, 0.40), radius=0.05, material="skin", segments=8, rings=4),
]
arm_r_parts = [
    cylinder((-SHOULDER_X, 0, 0.42), radius=0.05, height=0.40, material="skin", segments=10),
    sphere((-SHOULDER_X, 0, 0.40), radius=0.05, material="skin", segments=8, rings=4),
]

# Body: everything except the arms, one object.
join_and_apply("body", objects=[
    head, hair, fringe, eye_l, eye_r, torso, shorts, leg_l, leg_r, shoe_l, shoe_r,
])

# Arms: one object each. The origin moves to the shoulder, so the arm turns around it in Godot.
for name, parts, shoulder_x in (
    ("arm_l", arm_l_parts, SHOULDER_X),
    ("arm_r", arm_r_parts, -SHOULDER_X),
):
    arm = join_and_apply(name, objects=parts)
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.context.scene.cursor.location = (shoulder_x, 0.0, SHOULDER_Z)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)

finish(ASSET_ID, max_tris=800)

"""Balance tool for the Lead (task T018).

Edit the tables below, then run from the repository root:
    python tools/balance.py            # write the JSON files and simulate all profiles
    python tools/balance.py casual     # simulate one profile

It writes base_cost and base_rev into game/data/divisions.json, and all costs into
game/data/research.json, then runs game/tools/sim_economy.gd and prints the event times.
"""
import json
import os
import subprocess
import sys

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
GODOT = os.environ.get("GODOT", r"D:\Godot\Godot_v4.5.1-stable_win64_console.exe")
DIV = os.path.join(REPO, "game", "data", "divisions.json")
RES = os.path.join(REPO, "game", "data", "research.json")

IDS = ["bottles", "model_rockets", "sounding", "orbital", "station", "moon", "solar", "galaxy", "black_hole"]

# Cost of level 1 of each division.
BASE_COST = [5, 500, 3.0e4, 2.2e6, 3.2e7, 3.0e8, 9.0e9, 3.0e11, 1.5e13]
# Seconds that one level needs to pay for itself at level 1 (no multipliers). base_rev is derived.
PAYBACK_S = [7.5, 60, 300, 3000, 15000, 40000, 60000, 80000, 100000]

# Research costs, as a multiple of a division's base_cost.
DIV_RESEARCH = [500, 50000]
# (research id, stage index whose base_cost it uses, multiple)
OTHER_RESEARCH = [
    ("global_1", 1, 200), ("global_2", 3, 200), ("global_3", 4, 200), ("global_4", 6, 200), ("global_5", 7, 200),
    ("flight_1", 2, 300), ("flight_2", 5, 300), ("flight_3", 7, 300),
    ("pump_1", 0, 100), ("pump_2", 1, 100), ("pump_3", 2, 100),
]


def sig(x, digits=3):
    return float(f"{x:.{digits}g}")


def write_data():
    divs = json.load(open(DIV, encoding="utf-8"))
    by_id = {d["id"]: d for d in divs}
    for i, did in enumerate(IDS):
        d = by_id[did]
        d["base_cost"] = sig(BASE_COST[i])
        d["base_rev"] = sig(BASE_COST[i] * d["base_flight_s"] / PAYBACK_S[i])
    json.dump(divs, open(DIV, "w", encoding="utf-8"), indent="\t")

    nodes = json.load(open(RES, encoding="utf-8"))
    other = {rid: (stage, mult) for rid, stage, mult in OTHER_RESEARCH}
    for n in nodes:
        if n["group"] == "division":
            tier = int(n["id"].rsplit("_", 1)[1]) - 1
            n["cost"] = sig(BASE_COST[IDS.index(n["division"])] * DIV_RESEARCH[tier])
        elif n["id"] in other:
            stage, mult = other[n["id"]]
            n["cost"] = sig(BASE_COST[stage] * mult)
            n["requires_stage"] = IDS[stage]
    json.dump(nodes, open(RES, "w", encoding="utf-8"), indent="\t")


def simulate(profile):
    out = subprocess.run(
        [GODOT, "--headless", "--path", os.path.join(REPO, "game"), "-s", "res://tools/sim_economy.gd", "--", profile],
        capture_output=True, text=True,
    ).stdout
    unlocks = [ln.split("  UNLOCK ")[0].strip() for ln in out.splitlines() if "UNLOCK" in ln]
    first_mgr = next((ln.split("  ")[0] for ln in out.splitlines() if "MANAGER bottles" in ln), "-")
    summary = next((ln for ln in out.splitlines() if ln.startswith("SUMMARY")), "no summary")
    echoes = next((ln.strip() for ln in out.splitlines() if "echoes" in ln), "")
    print(f"[{profile}] first manager {first_mgr}")
    for i, stamp in enumerate(unlocks):
        print(f"   stage {i + 2} {IDS[i + 1]:<14} {stamp}")
    print(f"   {summary}\n   {echoes}")


if __name__ == "__main__":
    write_data()
    for prof in (sys.argv[1:] or ["casual", "active", "life2_casual", "life5_casual"]):
        simulate(prof)

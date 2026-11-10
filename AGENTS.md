# Instructions for Codex

This repository is a Godot 4.5.1 game built from small task cards.

1. Read `conventions.md` in full before any work. Its rules apply to you.
2. You are given one task id. Your card is `tasks/<id>.md`. Do exactly that card.
3. Do not read `build_plan.md`. Read `game_doc.md` only at the sections your card names.
4. Change only the files listed under **Files** on the card. Other agents work in this tree at the same time.
5. Run `powershell -ExecutionPolicy Bypass -File tools/verify.ps1` before you finish (code cards only).
6. Do not commit, and do not run `git` commands that change the tree (no checkout, reset, stash, or clean).
7. End with the report format from the end of `conventions.md`.

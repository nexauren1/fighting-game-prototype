# Hunter's Rise — Fighting Game Prototype

Prototype of a stylized fighting game built to grow one milestone at a time.

## v0.4 — Playable combat test

Implemented:
- Home
- Character Select
- Arena Select
- Battle Setup
- Settings
- Back/forward navigation
- Placeholder hunter slots
- Placeholder arena slot
- Neon District visual preview
- Reusable 3D fighter preview in Character Select
- Character selection now flows into Battle Setup
- ENTER FIGHT opens a playable 3D combat scene
- Procedural fighters with three combat styles
- Light, heavy and special attacks
- Block, dash, jump, health and KO/rematch flow
- Neon District combat test arena

## Next milestone

1. Test and tune the procedural combat in Godot
2. Replace the procedural fighter preview with the first final 3D character
3. Replace the second slot with the second final 3D character
4. Upgrade Neon District from prototype geometry to a detailed 3D arena
5. Add animation-driven combat and better hit feedback
6. Add controller mappings and polish the match flow

## Combat controls

Player 1: A/D move, W jump, F light, G heavy, H special, R block, T dash, 1/2/3 style.

Player 2: Left/Right move, Up jump, J light, K heavy, L special, I block, O dash, 7/8/9 style.

Escape returns to Battle Setup. Enter or R rematches after the round ends.

## Run

Open the project in Godot 4.x and run the main scene.

The current UI is intentionally procedural so the project remains lightweight while the core game flow is being designed.

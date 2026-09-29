# Hunter's Rise — Neon District

A compact, self-contained Godot 4.x 3D fighting-game prototype.

## Flow

Home → Character Select → Place Select → Arena

This follows the practical pattern used in Godot's beginner 3D workflow: build the player, camera and input foundation first, then layer the game area, animation, UI and combat.

## Two characters

- Rex — cyan technical fighter.
- Zara — pink phase fighter.

Both are reusable 3D CharacterBody3D scenes generated from fighter.gd.

## Arena

Neon District is a city backdrop around a dedicated combat deck:

- skyline buildings and windows
- streets and markings
- neon edge lighting
- pillars and billboards
- planters
- obstacles
- central combat surface
- floor and boundary collisions
- directional and neon lighting

## Movement and combat

Player-controlled fighter:

- analog movement on mobile
- WASD on desktop
- Light / Heavy / Special / Block
- dash
- health and KO
- camera follow
- CPU opponent

Character animation is procedural and state-based:

- idle breathing
- walk cycle
- light attack
- heavy attack
- special attack
- guard pose
- hit reaction
- KO pose

## Mobile controls

The battle HUD creates one virtual analog stick plus four multitouch buttons:

1. LIGHT
2. HEAVY
3. SPECIAL
4. BLOCK

Godot Button supports multitouch input, and touch emulation can be enabled for desktop testing.

## Desktop controls

- WASD — move
- F — light
- G — heavy
- H — special
- R — block
- T — dash
- ESC — Home
- ENTER — rematch after KO

## Project structure

- main.tscn / main.gd — menus and flow
- fighter.tscn / fighter.gd — reusable 3D fighter
- battle.tscn / battle.gd — match logic, HUD, CPU and touch controls
- arena.gd — city and combat area
- virtual_joystick.gd — touch analog control
- .github/workflows/godot-check.yml — headless Godot validation

## Godot version

The project targets Godot 4.x and the CI check uses Godot 4.7.2, a stable release in the official Godot archive.

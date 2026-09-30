# Rigged humanoid character assets

Rex and Zara are now external GLB character assets rather than procedural geometry generated inside `fighter.gd`.

Each GLB contains:
- a skinned humanoid mesh;
- a reusable humanoid skeleton;
- embedded animation clips: Idle, Walk, Light1, Light2, Light3, Heavy, Special, Block, Hit, KO and Dash;
- no root-motion dependency, so gameplay movement remains authoritative in `battle.gd`.

## Runtime contract

`fighter.gd` loads the correct GLB at setup time, finds its `AnimationPlayer`, and maps the existing combat states to the embedded clips.

The collision, movement, damage, combo, Overdrive, block/perfect-block, CPU, camera, hit feedback and KO logic remain in the existing gameplay controller.

These assets were authored outside Godot specifically for this prototype and are committed as self-contained GLBs so the Godot project imports them directly without a modeling tool at runtime.

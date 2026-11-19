# Visual direction and factory cutscene

## Core direction
The game uses a consistent 2.5D isometric perspective. Dave is the playable character, dressed in purple, with a thoughtful, perplexed expression. He may turn toward the camera and break the fourth wall. Martin has a distinct silhouette and readable facial expressions. Avoid mixing flat top-down sprites with isometric environments.

## Boardroom fidelity
- Isometric floor, walls and doorways, with readable depth and collision.
- Conference table, chairs, research board, Halvefords order, dashboard, coffee machine.
- Character idle/walk/interact/fourth-wall animations.
- Mobile-friendly touch targets and dialogue panels.

## Narrative sequence
1. Explore and inspect the research and order.
2. Speak to Martin and choose Speed, Comfort or Cost.
3. Lock the choice for this playthrough. Martin acknowledges it on later interactions.
4. Transition to the factory assembly line with a short camera pan or fade.
5. Reveal the operational impact over several beats, not one text box.
6. Dave comments to camera; player returns to the boardroom.
7. Dashboard and NPC dialogue update. Restart Scenario is a deliberate replay action.

## Factory variants
- Speed: assembly accelerates; brake installation is skipped; delivery rises but safety collapses.
- Comfort: unsolicited premium suspension causes delays, cost growth and complexity.
- Cost: basic brakes ship, premium braking is subscription-based; customer trust suffers.

## Next implementation milestones
1. Replace code-drawn characters and props with consistent sprite sheets.
2. Build an isometric factory tilemap with conveyor animation and workers.
3. Use a Godot AnimationPlayer for camera, machinery, timing and character reactions.
4. Add an explicit Restart Scenario button and optional save-state persistence.
5. Playtest keyboard, mouse and touch controls, including narrow mobile screens.

## Status
First factory sequence is currently an illustrated placeholder with three dialogue beats. The full animation and fidelity work above is not yet implemented.

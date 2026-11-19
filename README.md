# Agile Adventures 4

A Godot 4 prototype of Dave's organizational coaching adventure.

## Current prototype
- **3D diorama boardroom** with an orthographic isometric camera, modeled furniture, lighting and shadows
- Dave as the controllable character, Martin as an NPC
- Arrow keys/WASD to walk; E near an object to interact
- Mouse/touch to select objects or move toward a point
- Halvefords' 1,200-bicycle Christmas order, research, dialogue and three choices
- Decision locked after selection
- Separate 3D factory reveal for Speed, Comfort or Cost
- Return to boardroom with updated dashboard and Martin dialogue

## Run locally
Install Godot 4.4.1, import `project.godot`, press F5.

## Web deployment
The Actions workflow exports the Godot web build. In Settings → Pages select GitHub Actions as deployment source.

## Visual fidelity
This is a **procedural 3D blockout**, not the finished high-fidelity diorama. The reference aesthetic requires authored 3D assets, refined materials, character models and animation. The factory reveal is still dialogue-driven, not a cinematic animation. The build has not yet been playtested in the Godot editor.

## Next steps
1. Validate the Godot build and interaction behavior.
2. Replace blockout geometry with detailed low-poly / stylized 3D assets.
3. Model Dave and Martin with expressive rigs and fourth-wall animations.
4. Add camera transitions and an animated factory conveyor sequence.
5. Improve mobile controls, navigation around furniture and replay UX.

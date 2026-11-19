# Agile Adventures 4: The Boardroom

A small playable Godot 4 prototype. Dave is the purple-clad playable coach. Explore a boardroom, question Martin's market research for Halvefords, choose Speed, Comfort or Cost, then inspect the dashboard.

## Run locally
Install Godot 4.4.1, import `project.godot`, and press F5.

## Controls
- Arrow keys / WASD: move Dave
- E or Enter near an object: interact
- Click or tap an object: inspect it
- Click or tap the floor: walk there (simple direct movement, not full pathfinding)
- Space or dialogue buttons: advance

## Browser deployment
The GitHub Actions workflow exports the game for Web and deploys it to GitHub Pages. In repository Settings → Pages, choose **GitHub Actions** as the build and deployment source.

Expected URL after successful deployment: https://rstebbens.github.io/AgileAventures4/

## Status
This is an untested first prototype. Visuals are placeholder code-drawn 2D, not yet true isometric tiles or animated sprites. Mobile controls and collision/pathfinding need refinement.

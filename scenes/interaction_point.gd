extends Marker3D
## Attach to an approach marker inside a reusable interactive prop.
@export var interaction_id: String = ""
@export var prompt_text: String = ""
@export var highlight_mesh: NodePath
@export var highlight_color: Color = Color(1.0, 0.78, 0.25, 0.22)
@export_range(0.1, 5.0, 0.05) var activation_distance: float = 1.85
@export_multiline var inspection_text: String = ""

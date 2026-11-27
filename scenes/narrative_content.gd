extends RefCounted

var data: Dictionary = {}

func load_content() -> bool:
	var file := FileAccess.open("res://content/halvefords.json", FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	data = parsed
	for key in ["dialogue", "details", "results", "factory"]:
		if not data.get(key) is Dictionary:
			return false
	return true

func lines(id: String) -> Array[String]:
	var result: Array[String] = []
	result.assign(data.get("dialogue", {}).get(id, []))
	if result.is_empty():
		push_error("Missing dialogue: " + id)
		result.append("Missing narrative content: " + id)
	return result

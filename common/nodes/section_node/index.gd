extends NodeIndexer


func _init() -> void:
	name = "section"
	display_name = "Section"
	description = "Runs a section, then carries on from wherever it stopped."
	category = "Flow"
	icon_path = ""
	node_script = preload("section_node.gd")

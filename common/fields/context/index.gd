extends FieldIndexer


func _init() -> void:
	name = "context"
	display_name = "Context"
	description = "Port-only type carrying story flow between nodes. Has no editor widget."
	color = MonologuePalette.FLOW
	is_port_only = true

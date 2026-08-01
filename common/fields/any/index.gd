extends FieldIndexer


func _init() -> void:
	name = "any"
	display_name = "Any"
	description = "Port-only type that accepts a connection from any other field type."
	color = Color("87b26c")
	is_port_only = true
	compatible_types = ["*"]

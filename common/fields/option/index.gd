extends FieldIndexer


func _init() -> void:
	name = "option"
	display_name = "Option"
	description = "Port-only type linking an option node to a choice node's option list."
	color = Color("e89145")
	is_port_only = true

extends FoldableContainer

@onready var _vbox: VBoxContainer = %VBox


func add_control(
	node: Node,
	force_readable_name: bool = false,
	internal: InternalMode = InternalMode.INTERNAL_MODE_DISABLED
) -> void:
	_vbox.add_child(node, force_readable_name, internal)

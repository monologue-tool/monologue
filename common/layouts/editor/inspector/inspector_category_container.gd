extends FoldableContainer

@onready var _vbox: VBoxContainer = %VBox


func add_control(
	node: Node,
	force_readable_name: bool = false,
	internal: InternalMode = InternalMode.INTERNAL_MODE_DISABLED
) -> void:
	_vbox.add_child(node, force_readable_name, internal)


func is_empty() -> bool:
	return _vbox.get_child_count() <= 0

## A foldable container for grouping inspector properties by category.
##
## Provides a collapsible section in the inspector for organizing related
## properties together under a category name.
extends FoldableContainer

## Reference to the vertical box containing property controls.
@onready var _vbox: VBoxContainer = %VBox


## Adds a control to this category container.
##
## [param node] The node to add as a child.
## [br][br]
## [param force_readable_name] Whether to force a readable name. Default is false.
## [br][br]
## [param internal] The internal mode for the child. Default is INTERNAL_MODE_DISABLED.
func add_control(
	node: Node,
	force_readable_name: bool = false,
	internal: InternalMode = InternalMode.INTERNAL_MODE_DISABLED
) -> void:
	_vbox.add_child(node, force_readable_name, internal)

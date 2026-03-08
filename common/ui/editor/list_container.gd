extends BoxContainer

var _dropdown: OptionButton


func _ready() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)
	update()

func update() -> void:
	var selected_cache: int = 0
	if _dropdown != null:
		selected_cache = _dropdown.selected
		_dropdown.queue_free()
	
	_dropdown = OptionButton.new()
	_dropdown.item_selected.connect(_on_item_selected)
	add_child(_dropdown)
	move_child(_dropdown, 0)
	
	for child: Control in get_children():
		if not child is PanelContainer or child == _dropdown:
			continue
			
		_dropdown.add_item(child.name)
		child.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_on_item_selected(selected_cache)
	
func _on_item_selected(index: int) -> void:
	var node_name: String = _dropdown.get_item_text(index)
	var node: PanelContainer = get_node_or_null(node_name)
	if not node:
		return
		
	for child: Node in get_children():
		if child == _dropdown:
			continue
			
		if child is PanelContainer:
			child.hide() 
	
	node.show()


func _on_child_entered_tree(node: Node) -> void:
	if not node is PanelContainer: return
	update()

func _on_child_exiting_tree(node: Node) -> void:
	if not node is PanelContainer: return
	update()

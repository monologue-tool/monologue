extends Tree


@onready var create_btn: Button = %CreateButton
@onready var window: GraphNodePicker = $"../../../.."

## The data to build the tree
## An oject can contain keys with name "text", "value", icon" and "children".
func _get_data() -> Array:
	return [
		{"text": "Narration", "children": [
			{"text": "Sentence", "icon": "text.svg"},
			{"text": "Choice", "icon": "choice.svg"},
		]},
		{"text": "Logic", "children": [
			{"text": "Action", "icon": "action.svg"},
			{"text": "Condition", "icon": "condition.svg"},
			{"text": "Random", "icon": "dice.svg"},
			{"text": "Setter", "icon": "toggle.svg"},
		]},
		{"text": "Flow", "children": [
			{"text": "Event", "icon": "calendar.svg"},
			{"text": "Bridge", "icon": "link.svg"},
			{"text": "EndPath", "icon": "exit.svg"},
			{"text": "Wait", "icon": "time.svg"},
		]},
		{"text": "Audio and Visuals", "children": [
			{"text": "Audio", "icon": "recording.svg"},
			{"text": "Background", "icon": "picture.svg"},
		]},
		{"text": "Helpers", "children": [
			{"text": "Comment", "icon": "comment.svg"},
			{"text": "Reroute", "icon": "path.svg"},
		]},
		{"text": "Custom nodes", "button_icon": "plus.svg", "button_id": 1,"children": _get_custom_nodes()}
	]

var _first_item_found: bool = false


func _load() -> void:
	clear()
	var root = create_item()
	_recusive_load_data(_get_data(), root)
	deselect_all()


func _get_custom_nodes() -> Array:
	var all_custom_nodes: Array[MonologueGraphNode] = window.switcher.current.get_all_custom_nodes()
	var data: Array = []
	
	for custom_node in all_custom_nodes:
		data.append({
			"text": custom_node.custom_node_name.value
		})
	
	return data


func _recusive_load_data(items: Array, tree_parent: TreeItem) -> void:
	for obj: Dictionary in items:
		var tree_item: TreeItem = create_item(tree_parent)
		tree_item.collapsed = true

		if obj.has("text"):
			tree_item.set_text(0, obj.get("text"))
		if obj.has("icon"):
			var icon_texture = load("res://ui/assets/icons/" + obj.get("icon"))
			tree_item.set_icon(0, icon_texture)
		if obj.has("button_icon"):
			var icon_texture = load("res://ui/assets/icons/" + obj.get("button_icon"))
			tree_item.add_button(0, icon_texture, obj.get("button_id", 1))
		if obj.has("children"):
			_recusive_load_data(obj.get("children"), tree_item)


func _create() -> void:
	var node_type = get_selected().get_text(0)
	if get_selected().get_parent().get_text(0) == "Custom nodes":
		GlobalSignal.emit("add_custom_graph_node", [node_type, window])
		return
	GlobalSignal.emit("add_graph_node", [node_type, window])


func _on_item_activated() -> void:
	var item: TreeItem = get_selected()
	if item.get_child_count() > 0:
		item.collapsed = !item.collapsed
	else:
		_create()
		window.close()


func _on_item_selected() -> void:
	var item: TreeItem = get_selected()
	create_btn.disabled = item.get_child_count() > 0


func _on_search_bar_text_changed(new_text: String) -> void:
	if not new_text.lstrip(" "):
		_recursive_show_item(get_root())
		return
	
	_first_item_found = false
	_recursive_item_match(new_text, get_root())


func _recursive_item_match(text: String, item: TreeItem) -> bool:
	var match_text: bool = false
	
	if item.get_child_count() > 0:
		for child in item.get_children():
			var child_match: bool = _recursive_item_match(text, child)
			if child_match: match_text = true
	elif item.get_text(0).containsn(text):
		match_text = true
		if not _first_item_found:
			item.select(0)
			_first_item_found = true
	
	item.visible = match_text
	if match_text:
		item.collapsed = false
	
	return match_text


func _recursive_show_item(item: TreeItem) -> void:
	item.visible = true
	if not get_root() == item:
		item.collapsed = true
	for child in item.get_children():
		_recursive_show_item(child)

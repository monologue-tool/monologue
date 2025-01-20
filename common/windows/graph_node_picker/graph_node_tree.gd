extends Tree


@onready var create_btn: Button = %CreateButton
@onready var window: GraphNodePicker = $"../../../.."

## The data to build the tree
## An oject can contain keys with name "text", "value", icon" and "children".
var _data =  [
		{"text": "Narration", "children": [
			{"text": "Sentence", "icon": "text.svg"},
			{"text": "Choice", "icon": "choice.svg"},
			{"text": "Character", "icon": "text.svg"},
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
		]}
	]

var _first_item_found: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var root = create_item()
	_recusive_load_data(_data, root)
	deselect_all()


func _recusive_load_data(items: Array, tree_parent: TreeItem) -> void:
	for obj: Dictionary in items:
		var tree_item = create_item(tree_parent)
		tree_item.collapsed = true
		
		if obj.has("text"):
			tree_item.set_text(0, obj.get("text"))
		if obj.has("icon"):
			var icon_texture = load("res://ui/assets/icons/" + obj.get("icon"))
			tree_item.set_icon(0, icon_texture)
		if obj.has("children"):
			_recusive_load_data(obj.get("children"), tree_item)


func _create() -> void:
	var node_type = get_selected().get_text(0)
	GlobalSignal.emit("add_graph_node", [node_type, window])


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

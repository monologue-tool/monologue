class_name GraphNodePicker extends MonologueWindow

## What the description panel shows when nothing is picked yet.
const NO_SELECTION_HINT: String = "Pick a node type to read what it does."

@onready var node_tree: GraphNodeTree = %Tree
@onready var search_bar: LineEdit = %SearchBar
@onready var description_label: RichTextLabel = %Description

var from_node: String
var from_port: int
## Slot type of that port, or 0 when the picker was not opened from one. The tree
## offers only the types this can reach.
var source_port_type_id: int = 0
var release: Variant = null
## Release position adjusted to the graph's scroll and zoom.
var graph_release: Variant = null
var center: Variant = null


func _ready() -> void:
	super._ready()
	hide()
	force_native = true
	EventBus.enable_picker_mode.connect(_on_enable_picker_mode)
	node_tree.type_highlighted.connect(_on_type_highlighted)
	_on_type_highlighted(null)


## Shows what the highlighted type is for. The tree only carries names, so the reading
## matter lives here where there is room for it.
func _on_type_highlighted(indexer: NodeIndexer) -> void:
	if indexer == null:
		description_label.text = "[color=#%s]%s[/color]" % [
			ThemeLayout.text_muted_color.to_html(false), NO_SELECTION_HINT
		]
		return

	description_label.text = "[b]%s[/b]\n[color=#%s]%s[/color]" % [
		indexer.get_display_name(),
		ThemeLayout.text_muted_color.to_html(false),
		indexer.description,
	]


func _on_enable_picker_mode(
	node: String = "",
	port: int = -1,
	mouse_pos: Variant = null,
	graph_release_pos: Variant = null,
	center_pos: Variant = null,
	center_window: bool = false
) -> void:
	open_for_node(node, port, mouse_pos, graph_release_pos, center_pos, center_window)


func close() -> void:
	hide()


func flush() -> void:
	from_node = ""
	from_port = -1
	source_port_type_id = 0
	release = null
	graph_release = null
	center = null


## True when the picker was dragged out of a port, in which case the created node is
## expected to come back wired.
func has_source_port() -> bool:
	return not from_node.is_empty() and from_port >= 0


func open_for_node(
	node: String = "",
	port: int = -1,
	mouse_pos: Variant = null,
	graph_release_pos: Variant = null,
	center_pos: Variant = null,
	_center_window: bool = false
) -> void:
	flush()
	from_node = node
	from_port = port
	release = mouse_pos
	graph_release = graph_release_pos
	center = center_pos
	source_port_type_id = _resolve_source_port_type()

	if node_tree:
		node_tree.reload_tree()

	popup()
	move_to_center()

	var root_window: Window = get_tree().get_root()
	if root_window:
		current_screen = root_window.current_screen

	grab_focus()
	if search_bar:
		search_bar.clear()
		search_bar.grab_focus()


## Reads the slot type of the port the wire came from, so the tree can rule out types
## that could never accept it.
func _resolve_source_port_type() -> int:
	if not has_source_port():
		return 0

	var project: MonologueProject = ProjectManager.current_project
	if project == null:
		return 0

	var source: InspectableNode = null
	for storyline: StorylineDocument in project.storylines:
		source = storyline.get_node(from_node)
		if source:
			break
	if source == null or not is_instance_valid(source.graph_view):
		return 0

	return (source.graph_view as GraphNode).get_output_port_type(from_port)


func _on_close_requested() -> void:
	close()


func _on_cancel_button_pressed() -> void:
	close()


func _on_create_button_pressed() -> void:
	if node_tree.create_selected_descriptor():
		close()


func _on_search_submitted(_text: String) -> void:
	if node_tree.create_selected_descriptor():
		close()


func _on_visibility_changed() -> void:
	super._on_visibility_changed()
	var root: Window = get_tree().get_root()
	if root:
		current_screen = root.current_screen

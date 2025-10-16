class_name MonologueGraphEdit extends CustomGraphEdit

signal node_view_selected(node: InspectableNode)

var characters := Property.new("characters", {}, "character", {})
var variables := Property.new("variables", {}, "variable", {})

var storyline_id: String


func _ready() -> void:
	super._ready()


func refresh() -> void:
	var storyline: StorylineDocument = StorylineManager.get_storyline(storyline_id)

	for child: GraphElement in get_all_graph_nodes():
		child.queue_free()

	for node: InspectableNode in storyline.nodes:
		add_graph_node_view(node)


func add_graph_node_view(node: InspectableNode) -> void:
	var new_node: GraphNode = GraphNode.new()
	new_node.title = node.get_title()
	build_graph_node_view_content(new_node, node)
	new_node.node_selected.connect(_on_node_view_selected.bind(node))
	add_child(new_node)


func build_graph_node_view_content(graph_node: GraphNode, node: InspectableNode) -> void:
	var rows: Array = node.get_rows()

	for row: GraphNodeRow in rows:
		var hbox: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		var idx: int = rows.find(row)
		label.text = row.get_content()

		hbox.add_child(label)

		graph_node.add_child(hbox)
		graph_node.set_slot(
			idx,
			row._enable_left_port,
			0,
			Color.WHITE,
			row._enable_right_port,
			0,
			Color.WHITE,
			null,
			null,
			true
		)


func _on_node_view_selected(node: InspectableNode) -> void:
	node_view_selected.emit(node)


func get_all_graph_nodes() -> Array:
	return get_children().filter(func(child) -> bool: return child is GraphNode)

@icon("res://ui/assets/icons/choice.svg")
class_name ChoiceNode  extends MonologueGraphNode


var option_scene = preload("res://nodes/option_node/option_node.tscn")
var options := Property.new(LIST, {}, [])

## Temporary ID storage for first-time loading of base options in project load.
var _base_id_list: Array = []


func _ready():
	node_type = "NodeChoice"
	super._ready()
	options.setters["add_callback"] = add_option
	options.setters["get_callback"] = get_children
	options.callers["set_label_visible"] = [false]
	options.connect("preview", _refresh)
	
	if get_child_count() <= 0:
		options.value.append(add_option()._to_dict())
		options.value.append(add_option()._to_dict())


func add_option(reference: Dictionary = {}) -> OptionNode:
	var new_option = option_scene.instantiate()
	add_child(new_option, true)
	new_option.set_count(new_option.get_index() + 1)
	
	if reference:
		new_option._from_dict(reference)
		var value = reference.get("Option", reference.get("Sentence", ""))
		if value is Dictionary:
			var switcher = GlobalVariables.language_switcher
			var locale = str(switcher.get_current_language())
			value = value.get(locale, "")
		new_option.preview_label.text = value
		link_option(new_option)
	
	var is_first = get_child_count() <= 1
	set_slot(get_child_count() - 1, is_first, 0, Color("ffffff"), true,
			0, Color("ffffff"), LEFT_SLOT, RIGHT_SLOT, false)
	return new_option


func clear_children():
	for child in get_children():
		remove_child(child)
		child.queue_free()


func get_option_by_id(option_id: String) -> OptionNode:
	for node in get_children():
		if node.id.value == option_id:
			return node
	return null


func link_option(option: OptionNode, link: bool = true):
	var index = option.get_index()
	if option.next_id.value is String:  # non-connections are -1 (int)
		var next_node = get_parent().get_node_by_id(option.next_id.value)
		if next_node:
			if link:
				get_parent().connect_node(name, index, next_node.name, 0)
			else:
				get_parent().disconnect_node(name, index, next_node.name, 0)


func reload_preview() -> void:
	# reset options.value so that it can react to language switching
	#for i in get_child_count():
		#var option_node: OptionNode = get_child(i)
		#options.value[i]["Option"].merge(option_node.option.to_raw_value(), true)
	_refresh(options.value)


## Update the NextID of this choice node on the given port.
func update_next_id(from_port: int, next_node: MonologueGraphNode):
	var option_node = get_child(from_port)
	var next_value = -1
	if next_node:
		next_value = next_node.id.value
	option_node.next_id.value = next_value
	options.value[from_port] = option_node._to_dict()
	options.propagate(options.value, false)


func _from_dict(dict: Dictionary) -> void:
	_base_id_list = dict.get("OptionsID", [])
	if _base_id_list.size() > 0:
		options.value = []
		clear_children()
	_load_position(dict)
	# overridden to prevent _update() from happening too early here


func _load_connections(_data: Dictionary, _key: String = "") -> void:
	# called after _load_nodes() in MonologueControl, this is used to
	# load embedded OptionNodes which automatically forms the connections
	for option_id in _base_id_list:
		var reference = get_parent().base_options[option_id]
		var loaded_option = add_option(reference)
		options.value.append(loaded_option._to_dict())


func _refresh(new_options_list: Array):
	# disconnect all outbound connections
	for connection in get_parent().get_all_outbound_connections(name):
		var from_port = connection.get("from_port")
		var to_node = connection.get("to_node")
		get_parent().disconnect_node(name, from_port, to_node, 0)
	clear_children()
	
	for new_option_data in new_options_list:
		add_option(new_option_data)
	_update()


func _to_fields(dict: Dictionary) -> void:
	var child_options =  get_children().filter(func(c): return c is OptionNode)
	dict["OptionsID"] = child_options.map(func(o): return o.id.value)

class_name OptionNode extends MonologueGraphNode


var option := Localizable.new(TEXT, { "minimum_size": Vector2(200, 100) })
var enable_by_default := Property.new(CHECKBOX, {}, true)
var one_shot := Property.new(CHECKBOX, {}, false)
var next_id := Property.new(LINE, {}, -1)

@onready var choice_node = get_parent()
@onready var count_label = $VBox/CountLabel
@onready var preview_label = $VBox/PreviewLabel


func _ready() -> void:
	node_type = "NodeOption"
	super._ready()
	option.connect("preview", _on_text_preview)
	option.connect("change", update_parent)
	one_shot.connect("change", update_parent)
	enable_by_default.connect("change", update_parent)
	next_id.visible = false
	get_titlebar_hbox().get_child(0).hide()


func display() -> void:
	get_graph_edit().set_selected(get_parent())


func get_graph_edit() -> MonologueGraphEdit:
	return choice_node.get_graph_edit()


func set_count(number: int) -> void:
	count_label.text = "Option %d" % number


func update_parent(_old_value = "", _new_value = "") -> void:
	var old_option = choice_node.options.value[get_index()]
	var new_options = choice_node.options.value.duplicate(true)
	new_options[get_index()] = old_option.merged(_to_dict(), true)
	choice_node.options.value = new_options


func _from_dict(dict: Dictionary) -> void:
	option.value = dict.get("Sentence", "")
	enable_by_default.value = dict.get("Enable", false)
	super._from_dict(dict)


func _on_text_preview(text: Variant) -> void:
	preview_label.text = str(text)


func _to_next(dict: Dictionary, key: String = "NextID") -> void:
	dict[key] = next_id.value

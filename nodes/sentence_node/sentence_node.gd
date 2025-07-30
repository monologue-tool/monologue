@icon("res://ui/assets/icons/text.svg")
class_name SentenceNode extends MonologueGraphNode

var speaker := Property.new(DROPDOWN, {"store_index": true}, 0)
var display_name := Property.new(LINE)
var sentence := Localizable.new(TEXT)
var voiceline := Localizable.new(FILE, {"filters": FilePicker.AUDIO})

@onready var _preview = $TextLabelPreview


func _ready():
	node_type = "NodeSentence"
	sentence.connect("preview", _on_text_preview)
	voiceline.setters["base_path"] = get_graph_edit().file_path
	super._ready()
	_update()


func reload_preview() -> void:
	_preview.text = sentence.value


func _on_text_preview(text: Variant):
	_preview.text = str(text)


func _update():
	super._update()

	var characters: Array = get_graph_edit().get_characters()
	speaker.callers["set_items"] = [characters, "Character/Name", "EditorIndex"]
	if speaker.value is String:
		speaker.value = 0
	reload_preview()


func _get_field_groups() -> Array:
	return [{"Speaker": ["speaker", "display_name"]}]

@icon("res://ui/assets/icons/text.svg")
class_name SentenceNode extends MonologueGraphNode


var speaker         := Property.new(DROPDOWN, { "store_index": true })
var display_name    := Property.new(LINE, { "is_sublabel": true })
var display_variant := Property.new(LINE, { "is_sublabel": true })
var sentence        := Property.new(TEXT)
var voiceline       := Property.new(FILE, { "filters": FilePicker.AUDIO })

@onready var _preview = $MainContainer/TextLabelPreview


func _ready():
	node_type = "NodeSentence"
	super._ready()
	sentence.connect("preview", _on_text_preview)
	voiceline.setters["base_path"] = get_graph_edit().file_path


func _from_dict(dict: Dictionary):
	# special handling for backwards compatibility v2.x
	speaker.value = dict.get("SpeakerID", 0)
	display_name.value = dict.get("DisplaySpeakerName", "")
	voiceline.value = dict.get("VoicelinePath", "")
	super._from_dict(dict)


func _on_text_preview(text: Variant):
	_preview.text = str(text)


func _update():
	_preview.text = sentence.value
	speaker.callers["set_items"] = [get_graph_edit().speakers, "Reference", "ID"]
	super._update()


func _get_field_groups() -> Array:
	return [{"Character": ["speaker", "display_name", "display_variant"]}]

class_name AudioNode extends MonologueGraphNode


var loop   := Property.new(TOGGLE, {}, false)
var volume := Property.new(SLIDER, { "suffix": "db", "minimum": -80, "maximum": 24, "step": 0.25 })
var pitch  := Property.new(SLIDER, { "default": 1, "minimum": 0, "maximum": 4, "step": 0.1 })
var audio  := Property.new(FILE, { "filters": FilePicker.AUDIO })

@onready var _audio_label = $HBox/AudioLabel
@onready var _loop_label = $HBox/LoopLabel


func _ready():
	node_type = "NodeAudio"
	super._ready()
	audio.connect("preview", _on_audio_preview)
	audio.setters["base_path"] = get_parent().file_path
	loop.connect("preview", _on_loop_preview)
	_update()


func _on_audio_preview(audio_path: Variant):
	_audio_label.text = str(audio_path).get_file() if audio_path else "nothing"


func _on_loop_preview(is_loop: Variant):
	_loop_label.visible = bool(is_loop)


func _update():
	_on_audio_preview(audio.value)
	_loop_label.visible = loop.value
	super._update()

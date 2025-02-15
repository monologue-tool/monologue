class_name WaitNode extends MonologueGraphNode


var time := Property.new(SPINBOX, { "minimum": 0, "maximum": 120 })

@onready var wait_label := $HBox/WaitLabel


func _ready() -> void:
	node_type = "NodeWait"
	super._ready()
	time.connect("preview", _on_wait_preview)


func _on_wait_preview(value: Variant):
	wait_label.text = str(value)


func _update():
	wait_label.text = str(int(time.value))
	super._update()

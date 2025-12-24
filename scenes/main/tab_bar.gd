extends PanelContainer

@warning_ignore("unused_private_class_variable")
var _static_container: bool = true


func _ready() -> void:
	StorylineManager.storyline_changed.connect(_on_storyline_changed)


func _on_storyline_changed() -> void:
	pass

extends VBoxContainer


@onready var portrait_option_obj := preload("res://common/layouts/character_edit/portrait_option.tscn")
@onready var portrait_vbox := %PortraitVBox


func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_add_button_pressed() -> void:
	var new_portrait := portrait_option_obj.instantiate()
	portrait_vbox.add_child(new_portrait)
	new_portrait.connect("pressed", _on_portrait_option_pressed.bind(new_portrait))
	new_portrait.connect("set_to_default", _on_portrait_option_set_to_default.bind(new_portrait))
	
	if portrait_vbox.get_child_count() <= 1:
		new_portrait.set_default()

func _on_portrait_option_pressed(portrait_option: CharacterEditPortraitOption) -> void:
	pass


func _on_portrait_option_set_to_default(portrait_option: CharacterEditPortraitOption) -> void:
	for portrait in portrait_vbox.get_children():
		if portrait is not CharacterEditPortraitOption:
			continue
		
		if portrait == portrait_option:
			continue
		
		portrait.release_default()

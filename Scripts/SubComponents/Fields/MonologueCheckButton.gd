class_name MonologueCheckButton extends MonologueField


var check_button: CheckButton


func build() -> MonologueField:
	check_button = CheckButton.new()
	check_button.connect("toggled", update_value)
	check_button.set_pressed_no_signal(value)
	hbox.add_child(check_button, true)
	return self


func set_value(new_value: Variant) -> void:
	var boolify = new_value if new_value is bool else false
	super.set_value(boolify)
	if check_button:
		check_button.set_pressed_no_signal(boolify)

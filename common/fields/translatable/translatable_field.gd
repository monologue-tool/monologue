extends TextField

var _values: Dictionary = {}

@onready var localization_option: OptionButton = %LocalizationOption


func _ready() -> void:
	super._ready()
	localization_option.item_selected.connect(_on_localization_option_selected)
	EventBus.load_languages.connect(_on_load_languages)
	EventBus.refresh.connect(_on_language_refresh)
	var project: MonologueProject = ProjectManager.current_project
	if project:
		_populate_option(project.get_collection_value("languages"))


func _populate_option(languages: Array) -> void:
	if languages.size() <= 1:
		localization_option.hide()
	
	localization_option.clear()
	for lang: Dictionary in languages:
		var code: String = lang.get("code", {}).get("value", "")
		if code.is_empty():
			code = lang.get("code", "en")
		localization_option.add_item(code)
		localization_option.set_item_metadata(localization_option.item_count - 1, code)
	_sync_option_to_global()


func _sync_option_to_global() -> void:
	var project: MonologueProject = ProjectManager.current_project
	var active: String = project.active_language_code if project else "en"
	for i: int in localization_option.item_count:
		if localization_option.get_item_metadata(i) == active:
			localization_option.select(i)
			return
	if localization_option.item_count > 0:
		localization_option.select(0)


func _current_language_code() -> String:
	var project: MonologueProject = ProjectManager.current_project
	var code: String = project.active_language_code if project else "en"
	return code if not code.is_empty() else "en"


func set_value(value: Variant) -> void:
	if not is_node_ready():
		await ready
	_values = (value if value is Dictionary else {_current_language_code(): str(value)}).duplicate()
	_refresh_widget_text()


func _refresh_widget_text() -> void:
	var text: String = _values.get(_current_language_code(), "")
	if text_edit.text != text:
		text_edit.text = text
	if line_edit.text != text:
		line_edit.text = text


func get_value() -> Variant:
	return _values.duplicate()


func set_editable(is_editable: bool) -> void:
	super.set_editable(is_editable)
	localization_option.disabled = not is_editable


func _on_text_changed(new_text: String) -> void:
	_values[_current_language_code()] = new_text
	emit_value_changed(_values.duplicate())


func _on_text_submitted(submitted_text: String) -> void:
	_values[_current_language_code()] = submitted_text
	emit_value_committed(_values.duplicate())


func _on_focus_exited() -> void:
	if not is_inside_tree():
		return
	_values[_current_language_code()] = line_edit.text
	emit_value_committed(_values.duplicate())


func _on_textarea_changed() -> void:
	_values[_current_language_code()] = text_edit.text
	emit_value_changed(_values.duplicate())


func _on_textarea_focus_exited() -> void:
	if not is_inside_tree():
		return
	_values[_current_language_code()] = text_edit.text
	emit_value_committed(_values.duplicate())


func _on_load_languages(languages: Array, _graph: MonologueGraphEdit) -> void:
	_populate_option(languages)
	_refresh_widget_text()


func _on_language_refresh() -> void:
	_sync_option_to_global()
	_refresh_widget_text()


func _on_localization_option_selected(idx: int) -> void:
	var code: String = localization_option.get_item_metadata(idx)
	var project: MonologueProject = ProjectManager.current_project
	if project and project.active_language_code == code:
		return
	if project:
		project.active_language_code = code
	EventBus.refresh.emit()

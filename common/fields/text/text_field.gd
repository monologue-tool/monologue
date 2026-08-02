## Edits text. The only text widget: `text` and `textarea` both use it, and it shows a
## language selector exactly when the property it is bound to is translated.
##
## A translated property holds {language_code: text}; a plain one holds a String. Which
## of the two is never guessed from the value — the property says so.
class_name TextField
extends Field

var _is_multiline: bool = false
var _is_preview: bool = false
var _is_translatable: bool = false
## Every translation of the current value. Holds one entry under "" when the property
## is plain, so the rest of the widget has one shape to work with.
var _values: Dictionary = {}

@onready var line_edit: LineEdit = %LineEdit
@onready var text_edit: TextEdit = %TextEdit
@onready var localization_option: OptionButton = %LocalizationOption


func _ready() -> void:
	super._ready()
	line_edit.text_changed.connect(_on_text_changed)
	line_edit.text_submitted.connect(_on_text_submitted)
	line_edit.focus_exited.connect(_on_focus_exited)
	text_edit.text_changed.connect(_on_textarea_changed)
	text_edit.focus_exited.connect(_on_textarea_focus_exited)
	localization_option.item_selected.connect(_on_localization_option_selected)
	EventBus.load_languages.connect(_on_load_languages)
	EventBus.refresh.connect(_on_language_refresh)


func _on_initialize() -> void:
	_is_multiline = settings.get(PropertySettings.KEY_MULTILINE, false)
	_is_translatable = settings.get(PropertySettings.KEY_TRANSLATABLE, false) == true

	var placeholder: String = str(settings.get(PropertySettings.KEY_PLACEHOLDER, ""))
	text_edit.placeholder_text = placeholder
	line_edit.placeholder_text = placeholder

	var rows: int = settings.get(PropertySettings.KEY_ROWS, 4)
	_apply_textarea_height.call_deferred(text_edit, rows)

	if not _is_preview:
		line_edit.visible = not _is_multiline
		text_edit.visible = _is_multiline

	localization_option.visible = _is_translatable and not _is_preview
	if _is_translatable:
		var project: MonologueProject = ProjectManager.current_project
		if project:
			_populate_languages(project.get_collection_value("languages"))


func _apply_textarea_height(te: TextEdit, rows: int) -> void:
	var reset_te: bool = not te.text
	if reset_te:
		te.text = " "

	var sb: StyleBox = te.get_theme_stylebox("normal")
	var padding: float = (sb.content_margin_bottom + sb.content_margin_top) if sb else 8.0
	te.custom_minimum_size.y = te.get_line_height() * rows + padding

	if reset_te:
		te.text = ""


# --- value ------------------------------------------------------------------------


func set_value(value: Variant) -> void:
	if not is_node_ready():
		await ready

	if _is_translatable:
		_values = (value as Dictionary).duplicate() if value is Dictionary else {}
	else:
		_values = {"": str(value) if value != null else ""}
	_refresh_text()


func get_value() -> Variant:
	if _is_translatable:
		return _values.duplicate()
	return _values.get("", "")


func set_editable(is_editable: bool) -> void:
	line_edit.editable = is_editable
	text_edit.editable = is_editable
	localization_option.disabled = not is_editable


func set_preview() -> void:
	_is_preview = true
	if not is_node_ready():
		await ready

	line_edit.show()
	text_edit.hide()
	localization_option.hide()
	line_edit.theme_type_variation = "LineEditListItemPreview"


func display_issues(issues: Array[ValidationIssue]) -> void:
	super.display_issues(issues)
	if issues.is_empty():
		line_edit.remove_theme_color_override("font_color")
		text_edit.remove_theme_color_override("font_color")
		return

	var color: Color = ThemeLayout.fail_color
	line_edit.add_theme_color_override("font_color", color)
	text_edit.add_theme_color_override("font_color", color)


func prefers_vertical_layout(p_settings: Dictionary) -> bool:
	return p_settings.get(PropertySettings.KEY_MULTILINE, false)


## The slot the text is read from and written to: the project's active language for a
## translated property, and the single unnamed slot for a plain one.
func _current_key() -> String:
	if not _is_translatable:
		return ""
	var project: MonologueProject = ProjectManager.current_project
	var code: String = project.active_language_code if project else "en"
	return code if not code.is_empty() else "en"


func _refresh_text() -> void:
	var text: String = str(_values.get(_current_key(), ""))
	if line_edit.text != text:
		line_edit.text = text
	if text_edit.text != text:
		text_edit.text = text


func _write(text: String) -> void:
	_values[_current_key()] = text


# --- languages --------------------------------------------------------------------


func _populate_languages(languages: Array) -> void:
	localization_option.clear()
	for language: Variant in languages:
		if language is not Dictionary:
			continue
		var code: String = str((language as Dictionary).get("code", ""))
		if code.is_empty():
			continue
		localization_option.add_item(code)
		localization_option.set_item_metadata(localization_option.item_count - 1, code)

	# One language is no choice at all, so the selector stays out of the way.
	localization_option.visible = _is_translatable and not _is_preview and languages.size() > 1
	_select_active_language()


func _select_active_language() -> void:
	var active: String = _current_key()
	for index: int in localization_option.item_count:
		if localization_option.get_item_metadata(index) == active:
			localization_option.select(index)
			return
	if localization_option.item_count > 0:
		localization_option.select(0)


func _on_localization_option_selected(index: int) -> void:
	var code: String = str(localization_option.get_item_metadata(index))
	var project: MonologueProject = ProjectManager.current_project
	if project == null or project.active_language_code == code:
		return
	project.active_language_code = code
	EventBus.refresh.emit()


func _on_load_languages(languages: Array, _graph: MonologueGraphEdit) -> void:
	if _is_translatable:
		_populate_languages(languages)
	_refresh_text()


func _on_language_refresh() -> void:
	if _is_translatable:
		_select_active_language()
	_refresh_text()


# --- input ------------------------------------------------------------------------


func _on_text_changed(new_text: String) -> void:
	_write(new_text)
	emit_value_changed(get_value())


func _on_text_submitted(submitted_text: String) -> void:
	_write(submitted_text)
	emit_value_committed(get_value())


func _on_focus_exited() -> void:
	if not is_inside_tree():
		return
	_write(line_edit.text)
	emit_value_committed(get_value())


func _on_textarea_changed() -> void:
	_write(text_edit.text)
	emit_value_changed(get_value())


func _on_textarea_focus_exited() -> void:
	if not is_inside_tree():
		return
	_write(text_edit.text)
	emit_value_committed(get_value())

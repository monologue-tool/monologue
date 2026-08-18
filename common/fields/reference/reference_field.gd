## Picks another object and stores its id.
##
## The label comes from the target every time the list is drawn, so renaming the target
## updates every reference to it. An id the scope no longer holds is shown as broken and
## kept as it is: nothing is ever silently swapped for a different object.
class_name ReferenceField extends Field

const MISSING_PREFIX: String = "[!] Missing: "
const EMPTY_LABEL: String = "<none>"
## How the empty entry reads when the collection has an item to fall back to.
const DEFAULT_LABEL: String = "Default (%s)"

var _value: String = ""
var _is_listening: bool = false

@onready var option_button: OptionButton = %OptionButton


func _ready() -> void:
	super._ready()
	option_button.item_selected.connect(_on_item_selected)
	Field.fit_dropdown(option_button)


func set_value(value: Variant) -> void:
	if not is_node_ready():
		await ready

	_value = str(value) if value != null else ""
	_populate()


func get_value() -> Variant:
	return _value


func set_editable(is_editable: bool) -> void:
	option_button.disabled = not is_editable


func _on_initialize() -> void:
	super._on_initialize()
	_listen_to_project()
	_populate()


## Rebuilds the list whenever the project changes, since a target may have been
## renamed, added or deleted.
func _listen_to_project() -> void:
	var project: MonologueProject = _get_project()
	if project == null or _is_listening:
		return
	project.content_changed.connect(_on_project_changed)
	_is_listening = true


func _on_project_changed() -> void:
	if is_node_ready():
		_populate()


func _populate() -> void:
	if not is_node_ready():
		return

	option_button.clear()

	if settings.get(PropertySettings.KEY_ALLOW_EMPTY, true):
		_add_entry(_empty_label(), "")

	var selected_index: int = -1
	for candidate: Dictionary in _list_candidates():
		_add_entry(str(candidate.get("label", "")), str(candidate.get("id", "")))
		if candidate.get("id", "") == _value:
			selected_index = option_button.item_count - 1

	if selected_index == -1 and not _value.is_empty():
		selected_index = _add_missing_entry()

	if selected_index == -1 and _value.is_empty():
		selected_index = 0 if option_button.item_count > 0 else -1

	option_button.selected = selected_index


func _add_entry(label: String, target_id: String) -> void:
	option_button.add_item(label)
	option_button.set_item_metadata(option_button.item_count - 1, target_id)


## Adds the broken entry for a target that is no longer there, and returns its index.
## Disabled so it cannot be chosen, but selected so the id stays visible and stored.
func _add_missing_entry() -> int:
	_add_entry(MISSING_PREFIX + _value, _value)
	var index: int = option_button.item_count - 1
	option_button.set_item_disabled(index, true)
	return index


func _list_candidates() -> Array[Dictionary]:
	var property: Property = _binding.property if _binding else null
	if property == null:
		return []

	return ReferenceResolver.list_candidates(
		_get_project(), _scope(), _binding.owner, _label_property()
	)


## What choosing nothing actually means: the name of the item the collection falls back
## to, so an empty reference says what will happen rather than that nothing was picked.
func _empty_label() -> String:
	if _binding == null or _binding.property == null:
		return EMPTY_LABEL

	var fallback: String = ReferenceResolver.describe_default(
		_get_project(), _scope(), _binding.owner, _label_property()
	)
	return DEFAULT_LABEL % fallback if not fallback.is_empty() else EMPTY_LABEL


func _scope() -> String:
	return str(
		_binding.property.get_settings_value(PropertySettings.KEY_REFERENCE_SCOPE, "")
	)


func _label_property() -> String:
	return str(
		_binding.property.get_settings_value(
			PropertySettings.KEY_LABEL_PROPERTY, ReferenceResolver.DEFAULT_LABEL_PROPERTY
		)
	)


func _get_project() -> MonologueProject:
	return ProjectManager.current_project


func _on_item_selected(index: int) -> void:
	var target_id: String = str(option_button.get_item_metadata(index))
	if target_id == _value:
		return
	_value = target_id
	emit_value_committed(_value)


func _exit_tree() -> void:
	var project: MonologueProject = _get_project()
	if _is_listening and project and project.content_changed.is_connected(_on_project_changed):
		project.content_changed.disconnect(_on_project_changed)
	_is_listening = false

class_name ConditionField extends Field

const VARIABLES_COLLECTION: String = "variables"
const OPERATORS_BY_TYPE: Dictionary = {
	"bool": ["==", "!="],
	"int": ["==", "!=", ">", ">=", "<", "<="],
	"float": ["==", "!=", ">", ">=", "<", "<="],
	"string": ["==", "!=", "contains", "fuzzy"],
}
const FIELD_TYPE_BY_VARIABLE_TYPE: Dictionary = {
	"bool": "bool",
	"int": "int",
	"float": "float",
	"string": "text",
}
const MISSING_VARIABLE_LABEL: String = "⚠ Missing variable (%s)"

@onready var variable_dropdown: OptionButton = %VariableDropdown
@onready var operator_dropdown: OptionButton = %OperatorDropdown
@onready var value_container: Container = %OperatorContainer

var _variables: Dictionary = {}
var _value_field: Field
## Variables as they were when the list was last read. Comparing against the project
## avoids rebuilding the dropdown on every keystroke in the value beside it.
var _variables_source: Array = []


func _on_initialize() -> void:
	Field.fit_dropdown(variable_dropdown)
	Field.fit_dropdown(operator_dropdown)
	_load_variables()

	if not variable_dropdown.item_selected.is_connected(_on_variable_item_selected):
		variable_dropdown.item_selected.connect(_on_variable_item_selected)
	if not operator_dropdown.item_selected.is_connected(_on_operator_item_selected):
		operator_dropdown.item_selected.connect(_on_operator_item_selected)


func set_value(value: Variant) -> void:
	if not is_node_ready():
		await ready

	var data: Dictionary = value if value is Dictionary else {}
	var variable: String = str(data.get("variable", ""))

	_load_variables()
	_select_variable(variable)
	_refresh_operator_options(variable)
	_set_operator(data.get("operator", ""))
	_rebuild_value_field(variable, data.get("value"))


func get_value() -> Variant:
	return {
		"variable":
		(
			variable_dropdown.get_item_metadata(variable_dropdown.selected)
			if variable_dropdown.selected >= 0
			else ""
		),
		"operator": operator_dropdown.get_item_text(operator_dropdown.selected),
		"value": _value_field.get_value() if _value_field else null,
	}


func set_editable(is_editable: bool) -> void:
	variable_dropdown.disabled = !is_editable
	operator_dropdown.disabled = !is_editable
	if _value_field:
		_value_field.set_editable(is_editable)


## Refills the variable dropdown, skipping the work when the project's variables have
## not moved since last time.
func _load_variables(force: bool = false) -> void:
	var project: MonologueProject = ProjectManager.current_project
	if project == null:
		return

	var entries: Array = project.get_collection_value(VARIABLES_COLLECTION)
	if not force and entries == _variables_source and not _variables.is_empty():
		return

	_variables_source = entries.duplicate(true)
	_variables.clear()
	variable_dropdown.clear()

	for entry: Variant in entries:
		if not entry is Dictionary:
			continue
		var entry_dict: Dictionary = entry
		var entry_id: String = str(entry_dict.get("id", ""))
		var entry_name: String = str(entry_dict.get("name", "<undefined>"))
		var entry_type: String = str(entry_dict.get("type", "string"))
		if not entry_name.is_empty():
			_variables[entry_id] = {"name": entry_name, "type": entry_type}

	for id: String in _variables.keys():
		var variable_name: String = _variables[id].get("name", "<undefined>")
		variable_dropdown.add_item(variable_name)
		variable_dropdown.set_item_metadata(variable_dropdown.item_count - 1, id)


func _select_variable(variable_id: String) -> void:
	if variable_id.is_empty():
		return

	for item_idx: int in variable_dropdown.item_count:
		if variable_dropdown.get_item_metadata(item_idx) == variable_id:
			variable_dropdown.selected = item_idx
			return

	_add_missing_variable(variable_id)


## Shows a variable the project no longer has, and keeps it selected. Leaving nothing
## selected would drop the id and turn the condition into a comparison against blank.
func _add_missing_variable(variable_id: String) -> void:
	variable_dropdown.add_item(MISSING_VARIABLE_LABEL % variable_id)
	var index: int = variable_dropdown.item_count - 1
	variable_dropdown.set_item_metadata(index, variable_id)
	variable_dropdown.set_item_disabled(index, true)
	variable_dropdown.selected = index


func _on_variable_item_selected(_new_variable: Variant) -> void:
	var variable_id: String = variable_dropdown.get_item_metadata(variable_dropdown.selected)
	_refresh_operator_options(variable_id)
	_rebuild_value_field(variable_id, null)
	emit_value_committed(get_value())


func _on_operator_item_selected(_new_operator: Variant) -> void:
	emit_value_committed(get_value())


func _on_value_field_changed(_new_value: Variant) -> void:
	emit_value_changed(get_value())


func _on_value_field_committed(_new_value: Variant) -> void:
	emit_value_committed(get_value())


func _refresh_operator_options(variable_id: String) -> void:
	var variable_type: String = _variables.get(variable_id, {}).get("type", "string")
	var operators: Array = OPERATORS_BY_TYPE.get(variable_type, OPERATORS_BY_TYPE["string"])
	var current_operator: String = (
		operator_dropdown.get_item_text(operator_dropdown.selected)
		if operator_dropdown.selected >= 0
		else ""
	)

	operator_dropdown.clear()
	for operator: String in operators:
		operator_dropdown.add_item(operator)

	if operators.has(current_operator):
		_set_operator(current_operator)
	elif operators.size() > 0:
		operator_dropdown.selected = 0


func _set_operator(operator_string: String) -> void:
	for item_idx: int in operator_dropdown.item_count:
		if operator_dropdown.get_item_text(item_idx) == operator_string:
			operator_dropdown.selected = item_idx
			return


func _rebuild_value_field(variable_id: String, value: Variant) -> void:
	var variable_type: String = _variables.get(variable_id, {}).get("type", "string")
	var field_type: String = FIELD_TYPE_BY_VARIABLE_TYPE.get(variable_type, "string")

	if _value_field:
		if _value_field.value_committed.is_connected(_on_value_field_committed):
			_value_field.value_committed.disconnect(_on_value_field_committed)
		_value_field.queue_free()
		_value_field = null

	var new_field: Control = FieldWidgetFactory.create_or_placeholder(field_type)
	if new_field == null:
		return

	value_container.add_child(new_field)
	new_field.size_flags_horizontal = SIZE_EXPAND_FILL

	if new_field is Field:
		_value_field = new_field
		# Deliberately no binding: this widget belongs to the condition, not to a
		# property of its own. Handing it the condition's binding made it read the
		# condition's settings and write the condition's value.
		_value_field.initialize()
		_value_field.value_changed.connect(_on_value_field_changed)
		_value_field.value_committed.connect(_on_value_field_committed)
		var initial_value: Variant = (
			value if value != null else _default_value_for_type(variable_type)
		)
		_value_field.set_value(initial_value)


func _default_value_for_type(variable_type: String) -> Variant:
	match variable_type:
		"bool":
			return false
		"int":
			return 0
		"float":
			return 0.0
		"string":
			return ""
	return null

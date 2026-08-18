class_name CollectionField extends BaseListField

## How many referrers the delete confirmation spells out before summarising the rest.
const MAX_LISTED_REFERRERS: int = 8

var _collection_name: String = ""
## True while the fallback is handed from one item to another. Letting the items' own writes
## through would land the repair before the edit that caused it, swallowing its undo step.
var _is_repairing_default: bool = false


func _on_initialize() -> void:
	super._on_initialize()
	var property: Property = _binding.property if _binding else null
	if not property:
		Log.warn("CollectionField has no binding; nothing to show.")
		return

	var collection: Variant = property.get_settings_value("collection")
	if not collection or not MonologueRegistry.get_instance().get_collection(str(collection)):
		Log.error("Can't find collection %s." % str(collection))
		return
	_collection_name = collection

	if not property.connection_changed.is_connected(_on_connection_changed):
		property.connection_changed.connect(_on_connection_changed)


func set_value(value: Variant) -> void:
	if not _binding or not _binding.owner:
		return

	var need_rebuild: bool = true

	if value is not Array:
		value = []

	var outdated_childrens: Array = get_items().duplicate()
	for item_data: Dictionary in value:
		if item_data is not Dictionary:
			continue

		var child_found: bool = false
		for child: CollectionItem in outdated_childrens:
			var dict_match := false
			var item_id: Variant = item_data.get("id")
			var child_id: Variant = child.get_property_value("id")

			if item_id != null and child_id != null:
				dict_match = (item_id == child_id)
			else:
				dict_match = (item_data == child._to_dict())

			if dict_match:
				child._from_dict(item_data)
				outdated_childrens.erase(child)
				child_found = true
				break

		if not child_found:
			var item: CollectionItem = _create_new_list_item(item_data)
			_binding.owner.add_property_children(_binding.property.name, item)

	for child: CollectionItem in outdated_childrens:
		_binding.owner.remove_property_children(_binding.property.name, child)

	for child: CollectionItem in get_items():
		if child.property_changed.is_connected(_on_item_property_changed):
			continue

		child.property_changed.connect(_on_item_property_changed.bind(child))

	for i in range(value.size()):
		var item_data: Dictionary = value[i]
		for child: CollectionItem in get_items():
			if child._to_dict() == item_data:
				_binding.owner.move_property_child(_binding.property.name, child, i)
				break

	if need_rebuild:
		_rebuild_ui()


func get_value() -> Variant:
	var result: Array = []
	for item: InspectableObject in get_items():
		result.append(item._to_dict())
	return result


func _create_new_list_item(from_data: Dictionary = {}) -> CollectionItem:
	var item: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		_collection_name, _binding.owner.history
	)
	item._from_dict(from_data)

	return item


func _on_item_property_changed(_property_name: String, _item: CollectionItem) -> void:
	if _is_repairing_default:
		return
	_binding.property.value = get_value()


func supports_default_item() -> bool:
	var indexer: CollectionIndexer = MonologueRegistry.get_instance().get_collection(
		_collection_name
	)
	return indexer != null and indexer.has_default_item()


## Points the list at one item and clears the flag on every other. Written straight to the
## properties, since undoing half the switch would leave two defaults or none.
func set_default_item(index: int) -> void:
	if not _is_valid_index(index):
		return

	_flag_default(get_items()[index])
	emit_value_committed(get_value())
	_rebuild_ui()


## Deleting the default hands the role to the first item left. True when something changed.
func _ensure_one_default() -> bool:
	if not supports_default_item():
		return false

	var items: Array = get_items()
	if items.is_empty():
		return false

	var flagged: Array = items.filter(
		func(item: CollectionItem) -> bool: return item.is_default_item()
	)
	if flagged.size() == 1:
		return false

	_flag_default(flagged[0] if not flagged.is_empty() else items[0])
	return true


## One change, so the list is never briefly left with two defaults or none.
func _flag_default(chosen: CollectionItem) -> void:
	_is_repairing_default = true
	for item: CollectionItem in get_items():
		var flag: Property = item.get_property("is_default")
		if flag:
			flag.set_value(item == chosen)
	_is_repairing_default = false


func _on_add_button() -> void:
	add_item()


func _on_edit_item(index: int) -> void:
	var item: CollectionItem = get_items()[index]
	var selection: Array[InspectableObject] = [item]
	EventBus.request_objects_inspection.emit(selection)


func _on_duplicate_item(index: int) -> void:
	var children: Array = get_items()
	if not _is_valid_index(index):
		return

	var item_data: Dictionary = children[index]._to_dict()
	var new_item: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		_collection_name, _binding.owner.history
	)
	new_item._from_dict(item_data)
	_make_item_unique(new_item)

	# Being the fallback is the list's business, not the item's. A copy of the default
	# is a second item, never a second default.
	var flag: Property = new_item.get_property("is_default")
	if flag:
		flag.set_value(false)

	_binding.owner.add_property_children(_binding.property.name, new_item)
	emit_value_committed(get_value())
	_rebuild_ui()


## Gives a freshly copied item its own value for every property that must differ from
## its siblings: a new id, and a numbered suffix for anything else.
func _make_item_unique(item: CollectionItem) -> void:
	for prop: Property in item.get_properties():
		if not prop.get_settings_value(PropertySettings.KEY_UNIQUE, false):
			continue

		if prop.name == "id":
			prop.value = IDGen.generate_object_id(item.get_type())

		var base_val: String = str(prop.value)
		var regex := RegEx.new()
		regex.compile(r"^(.*?)(\d+)$")
		var result := regex.search(base_val)
		var name_base: String = base_val + " "
		var attempt: int = 1

		if result:
			name_base = result.get_string(1)
			attempt = int(result.get_string(2)) + 1

		while _value_exists_in_list(prop.name, prop.value):
			if prop.name == "id":
				prop.value = IDGen.generate_object_id(item.get_type())
			else:
				prop.value = "%s%d" % [name_base, attempt]
				attempt += 1


## Deletes the item, asking first when something still points at it. The references
## are never rewritten either way: they keep the id and start reporting it as missing.
func _on_delete_item(index: int) -> void:
	if not _is_valid_index(index):
		return

	var item: CollectionItem = get_items()[index]
	var referrers: Array[ReferenceSite] = _referrers_of(item)
	if referrers.is_empty():
		_delete_item(item)
		return

	EventBus.ask_dialog.emit(
		_on_delete_confirmed.bind(item),
		"Delete %s?" % _describe(item),
		_describe_referrers(referrers),
		"Delete anyway",
		"Keep",
		"Cancel"
	)


func _on_delete_confirmed(response: int, item: CollectionItem) -> void:
	if response == Prompt.CONFIRMED and is_instance_valid(item):
		_delete_item(item)


func _delete_item(item: CollectionItem) -> void:
	_binding.owner.remove_property_children(_binding.property.name, item)
	_ensure_one_default()

	emit_value_committed(get_value())
	_rebuild_ui()


func _referrers_of(item: CollectionItem) -> Array[ReferenceSite]:
	var project: MonologueProject = ProjectManager.current_project
	if project == null:
		return []
	return project.get_object_registry().get_referrers(str(item.get_property_value("id")))


static func _describe(item: CollectionItem) -> String:
	var item_name: String = str(item.get_property_value("name"))
	return item_name if not item_name.is_empty() else item.get_type()


static func _describe_referrers(referrers: Array[ReferenceSite]) -> String:
	var lines: PackedStringArray = [
		"%d place(s) still point at it, and will show it as missing:" % referrers.size()
	]
	for site: ReferenceSite in referrers.slice(0, MAX_LISTED_REFERRERS):
		lines.append("  - %s (%s)" % [site, site.document_name])
	if referrers.size() > MAX_LISTED_REFERRERS:
		lines.append("  - and %d more" % (referrers.size() - MAX_LISTED_REFERRERS))
	return "\n".join(lines)


func reorder_item(from_index: int, to_index: int) -> void:
	var children: Array = get_items()
	if from_index < 0 or from_index >= children.size():
		return
	if to_index < 0 or to_index >= children.size():
		return

	_binding.owner.move_property_child(_binding.property.name, children[from_index], to_index)
	emit_value_committed(get_value())
	_rebuild_ui()


func _is_valid_index(index: int) -> bool:
	return index >= 0 and index < get_items().size()


func add_item() -> void:
	var new_item: CollectionItem = _create_new_list_item()
	_make_item_unique(new_item)
	_binding.owner.add_property_children(_binding.property.name, new_item)
	# The first item of an empty list becomes its fallback. Later ones change nothing.
	_ensure_one_default()

	emit_value_committed(get_value())
	_rebuild_ui()


func _value_exists_in_list(pname: String, pvalue: Variant) -> bool:
	for item: InspectableObject in get_items():
		var prop: Property = item.get_property(pname)
		if prop and prop.value == pvalue:
			return true
	return false


func _on_connection_changed() -> void:
	_rebuild_ui()


func _populate_external_items() -> void:
	var externals: Array[Dictionary] = _binding.owner.get_external_list_items(
		_binding.property.name
	)

	for ext_data: Dictionary in externals:
		var item_idx: int = items_container.get_child_count()
		var container: PanelContainer = _create_item_container(not item_idx % 2)
		CollectionItemHelper.populate_external_item_view(
			container, ext_data.get("name", "<unknown>")
		)
		items_container.add_child(container)

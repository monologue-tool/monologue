## Turns a reference scope into the list of objects a reference may point at, and an
## id into the label to show for it.
##
## Scopes:
## [codeblock]
## "characters"      a project collection, by name
## "self:portraits"  a collection property of the object holding the reference
## "storylines"      the project's storylines
## "node:option"     nodes of one type, in the storyline the owner belongs to
## [/codeblock]
##
## Resolution is done every time it is needed rather than cached, so renaming the
## target is enough for every reference to it to show the new name.
class_name ReferenceResolver

const SELF_PREFIX: String = "self:"
const NODE_PREFIX: String = "node:"
const STORYLINES_SCOPE: String = "storylines"
const DEFAULT_LABEL_PROPERTY: String = "name"


## Every candidate in [param scope], as {"id": String, "label": String}, in the order
## they are stored.
static func list_candidates(
	project: MonologueProject,
	scope: String,
	owner: InspectableObject = null,
	label_property: String = DEFAULT_LABEL_PROPERTY
) -> Array[Dictionary]:
	if project == null or scope.is_empty():
		return []

	if scope == STORYLINES_SCOPE:
		return _list_storylines(project)
	if scope.begins_with(NODE_PREFIX):
		return _list_nodes(project, scope.trim_prefix(NODE_PREFIX), owner)
	if scope.begins_with(SELF_PREFIX):
		return _list_own_items(owner, scope.trim_prefix(SELF_PREFIX), label_property)
	return _list_collection(project, scope, label_property)


## The label to show for [param target_id], or "" when the scope holds no such object.
static func resolve_label(
	project: MonologueProject,
	scope: String,
	target_id: String,
	owner: InspectableObject = null,
	label_property: String = DEFAULT_LABEL_PROPERTY
) -> String:
	if target_id.is_empty():
		return ""

	for candidate: Dictionary in list_candidates(project, scope, owner, label_property):
		if candidate.get("id", "") == target_id:
			return str(candidate.get("label", ""))
	return ""


## True when the scope still holds the object. A false answer is what makes a
## reference render as broken instead of quietly pointing somewhere else.
static func exists(
	project: MonologueProject, scope: String, target_id: String, owner: InspectableObject = null
) -> bool:
	if target_id.is_empty():
		return false

	for candidate: Dictionary in list_candidates(project, scope, owner):
		if candidate.get("id", "") == target_id:
			return true
	return false


static func _list_collection(
	project: MonologueProject, collection_name: String, label_property: String
) -> Array[Dictionary]:
	var collection: CollectionDocument = project.get_collection(collection_name)
	if collection == null:
		return []
	return _list_records(
		collection.get_value(), _resolve_label_property(collection_name, label_property)
	)


static func _list_own_items(
	owner: InspectableObject, property_name: String, label_property: String
) -> Array[Dictionary]:
	if owner == null:
		return []

	var property: Property = owner.get_property(property_name)
	if property == null:
		return []

	var value: Variant = property.get_value()
	if value is not Array:
		return []

	var collection_name: String = str(
		property.get_settings_value(PropertySettings.KEY_COLLECTION, "")
	)
	return _list_records(value, _resolve_label_property(collection_name, label_property))


## Which property labels an item: what the reference declared, or failing that what the
## collection itself declares. Options are labelled by their text, characters by name.
static func _resolve_label_property(collection_name: String, declared: String) -> String:
	if not declared.is_empty() and declared != DEFAULT_LABEL_PROPERTY:
		return declared

	var indexer: CollectionIndexer = MonologueRegistry.get_instance().get_collection(
		collection_name
	)
	if indexer and not indexer.label_property.is_empty():
		return indexer.label_property
	return declared if not declared.is_empty() else DEFAULT_LABEL_PROPERTY


static func _list_storylines(project: MonologueProject) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for storyline: StorylineDocument in project.storylines:
		candidates.append({"id": storyline.id, "label": storyline.name})
	return candidates


static func _list_nodes(
	project: MonologueProject, node_type: String, owner: InspectableObject
) -> Array[Dictionary]:
	var storyline: StorylineDocument = _get_storyline_of(project, owner)
	if storyline == null:
		return []

	var candidates: Array[Dictionary] = []
	var position: int = 0
	for node: InspectableNode in storyline.nodes:
		if not node_type.is_empty() and node.get_type() != node_type:
			continue
		position += 1
		var title: String = Util.to_label(
			node.get_property_value("title"), project.active_language_code
		)
		if title.is_empty():
			title = "%s %d" % [Util.to_readable_name(node.get_type()), position]
		candidates.append({"id": node.get_id(), "label": title})
	return candidates


## Reads {"id": ..., "<label_property>": ...} out of stored collection items.
##
## An item with nothing in its label property is named after its type and position
## rather than its id, which would mean nothing to the person choosing from the list.
static func _list_records(records: Array, label_property: String) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for index: int in records.size():
		var record: Variant = records[index]
		if record is not Dictionary:
			continue
		var record_dict: Dictionary = record
		var record_id: String = _read(record_dict, "id")
		if record_id.is_empty():
			continue

		var label: String = _read(record_dict, label_property)
		if label.is_empty():
			var type_name: String = str(record_dict.get("$type", "item"))
			label = "%s %d" % [Util.to_readable_name(type_name), index + 1]
		candidates.append({"id": record_id, "label": label})
	return candidates


static func _get_storyline_of(
	project: MonologueProject, owner: InspectableObject
) -> StorylineDocument:
	if owner is StorylineDocument:
		return owner
	if owner is InspectableNode:
		return project.get_storyline((owner as InspectableNode).storyline_id)
	return null


## Reads one stored property out of an item, rendered as text. Handles translatable
## values, which are a dictionary of languages rather than a plain string.
static func _read(record: Dictionary, key: String) -> String:
	var raw: Variant = record.get(key)
	if raw is not Dictionary:
		return ""

	var project: MonologueProject = ProjectManager.current_project
	return Util.to_label(
		(raw as Dictionary).get("value"), project.active_language_code if project else ""
	)

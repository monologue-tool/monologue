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
	return _list_records(collection.get_value(), label_property)


static func _list_own_items(
	owner: InspectableObject, property_name: String, label_property: String
) -> Array[Dictionary]:
	if owner == null:
		return []

	var property: Property = owner.get_property(property_name)
	if property == null:
		return []

	var value: Variant = property.get_value()
	return _list_records(value, label_property) if value is Array else []


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
	for node: InspectableNode in storyline.nodes:
		if not node_type.is_empty() and node.get_type() != node_type:
			continue
		var title: String = str(node.get_property_value("title"))
		var node_id: String = node.get_id()
		candidates.append({"id": node_id, "label": title if not title.is_empty() else node_id})
	return candidates


## Reads {"id": ..., "<label_property>": ...} out of stored collection items.
static func _list_records(records: Array, label_property: String) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for record: Variant in records:
		if record is not Dictionary:
			continue
		var record_dict: Dictionary = record
		var record_id: String = _read(record_dict, "id")
		if record_id.is_empty():
			continue
		var label: String = _read(record_dict, label_property)
		candidates.append({"id": record_id, "label": label if not label.is_empty() else record_id})
	return candidates


static func _get_storyline_of(
	project: MonologueProject, owner: InspectableObject
) -> StorylineDocument:
	if owner is StorylineDocument:
		return owner
	if owner is InspectableNode:
		return project.get_storyline((owner as InspectableNode).storyline_id)
	return null


static func _read(record: Dictionary, key: String) -> String:
	var raw: Variant = record.get(key)
	if raw is Dictionary:
		return str((raw as Dictionary).get("value", ""))
	return ""

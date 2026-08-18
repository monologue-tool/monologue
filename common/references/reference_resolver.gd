## Turns a reference scope into the list of objects a reference may point at, and an
## id into the label to show for it.
##
## Scopes:
## [codeblock]
## "characters"         a project collection, by name
## "self:portraits"     a collection property of the object holding the reference
## "ref:who:portraits"  a collection held by whatever another property points at
## "storylines"         the project's storylines
## "node:option"        nodes of one type, in the storyline the owner belongs to
## [/codeblock]
##
## In the "ref:" form the last segment names both the property on the target and the
## collection it holds. That is how a node offers the portraits of the one character it names
## instead of every portrait in the project.
##
## Nothing is cached. Renaming a target is enough for every reference to show the new name.
class_name ReferenceResolver

const SELF_PREFIX: String = "self:"
const NODE_PREFIX: String = "node:"
const REF_PREFIX: String = "ref:"
const STORYLINES_SCOPE: String = "storylines"
const DEFAULT_LABEL_PROPERTY: String = "name"
## Property a collection item marks itself with when it is the one to fall back to.
const DEFAULT_FLAG_PROPERTY: String = "is_default"


## Every candidate in [param scope], as {"id": String, "label": String}, in stored order.
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
	if scope.begins_with(REF_PREFIX):
		return _list_referenced_items(
			project, owner, scope.trim_prefix(REF_PREFIX), label_property
		)
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


## The kind of thing a scope points at: "character", "portrait", "storyline". Labels a
## reference port, which would otherwise read "reference" whatever it accepts. "" for a scope
## nothing is registered for.
static func describe_scope(scope: String, owner: InspectableObject = null) -> String:
	if scope.is_empty():
		return ""
	if scope == STORYLINES_SCOPE:
		return "storyline"
	if scope.begins_with(NODE_PREFIX):
		return scope.trim_prefix(NODE_PREFIX)

	var collection_name: String = scope
	if scope.begins_with(SELF_PREFIX):
		collection_name = _own_collection_name(owner, scope.trim_prefix(SELF_PREFIX))
	elif scope.begins_with(REF_PREFIX):
		collection_name = _referenced_collection_name(scope.trim_prefix(REF_PREFIX))

	var indexer: CollectionIndexer = MonologueRegistry.get_instance().get_collection(
		collection_name
	)
	return indexer.get_item_type() if indexer else ""


## One property read off the object a reference points at, as text. Empty when the reference
## resolves to nothing. For a widget that has to follow its target, like the value beside a
## variable taking the shape that variable declares.
static func resolve_property(
	project: MonologueProject,
	scope: String,
	target_id: String,
	property_name: String,
	owner: InspectableObject = null
) -> String:
	if target_id.is_empty() or property_name.is_empty():
		return ""

	for record: Dictionary in _records_in(project, scope, owner):
		if _read(record, "id") == target_id:
			return _read(record, property_name)
	return ""


## The id of the item [param scope] falls back to when a reference is left empty, or ""
## when the collection has no fallback or nothing is marked.
static func find_default(
	project: MonologueProject, scope: String, owner: InspectableObject = null
) -> String:
	for record: Variant in _records_in(project, scope, owner):
		if record is Dictionary and (record as Dictionary).get(DEFAULT_FLAG_PROPERTY) == true:
			return _read(record, "id")
	return ""


## What an empty reference to [param scope] resolves to, as text. "Ease" for a curve falling
## back to the default one, "" when there is nothing to fall back to.
static func describe_default(
	project: MonologueProject,
	scope: String,
	owner: InspectableObject = null,
	label_property: String = DEFAULT_LABEL_PROPERTY
) -> String:
	var default_id: String = find_default(project, scope, owner)
	if default_id.is_empty():
		return ""
	return resolve_label(project, scope, default_id, owner, label_property)


## True when the scope still holds the object. False makes a reference render as broken
## instead of quietly pointing somewhere else.
static func exists(
	project: MonologueProject, scope: String, target_id: String, owner: InspectableObject = null
) -> bool:
	if target_id.is_empty():
		return false

	for candidate: Dictionary in list_candidates(project, scope, owner):
		if candidate.get("id", "") == target_id:
			return true
	return false


## The stored items a scope covers, before labelling. Only collection scopes have records.
## Storylines and nodes are live objects and answer nothing here.
static func _records_in(
	project: MonologueProject, scope: String, owner: InspectableObject
) -> Array:
	if project == null or scope.is_empty():
		return []

	if scope.begins_with(SELF_PREFIX):
		var property: Property = (
			owner.get_property(scope.trim_prefix(SELF_PREFIX)) if owner else null
		)
		var value: Variant = property.get_value() if property else null
		return value if value is Array else []

	if scope.begins_with(REF_PREFIX):
		return _referenced_records(project, owner, scope.trim_prefix(REF_PREFIX))

	var collection: CollectionDocument = project.get_collection(scope)
	return collection.get_value() if collection else []


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

	var collection_name: String = _own_collection_name(owner, property_name)
	return _list_records(value, _resolve_label_property(collection_name, label_property))


## Items held by whatever another property points at. [param body] is what follows "ref:".
static func _list_referenced_items(
	project: MonologueProject,
	owner: InspectableObject,
	body: String,
	label_property: String
) -> Array[Dictionary]:
	var collection_name: String = _referenced_collection_name(body)
	return _list_records(
		_referenced_records(project, owner, body),
		_resolve_label_property(collection_name, label_property)
	)


## Follows the sibling property to its target, then reads the list the target keeps under the
## named property. Empty while the sibling points at nothing, which is how a fresh node is.
static func _referenced_records(
	project: MonologueProject, owner: InspectableObject, body: String
) -> Array:
	var segments: PackedStringArray = body.split(":")
	if segments.size() < 2 or owner == null:
		return []

	var pointer: Property = owner.get_property(segments[0])
	if pointer == null:
		return []

	var target_id: String = str(pointer.get_value())
	if target_id.is_empty():
		return []

	var target_scope: String = str(
		pointer.get_settings_value(PropertySettings.KEY_REFERENCE_SCOPE, "")
	)
	for record: Variant in _records_in(project, target_scope, owner):
		if record is not Dictionary or _read(record, "id") != target_id:
			continue
		var items: Variant = (record as Dictionary).get(segments[1])
		return items if items is Array else []
	return []


## The collection a "ref:" scope ends up in. The last segment names it, and names the
## property holding it on the target.
static func _referenced_collection_name(body: String) -> String:
	var segments: PackedStringArray = body.split(":")
	return segments[1] if segments.size() >= 2 else ""


## Which collection a "self:<property>" scope ends up in, read from the property holding it.
static func _own_collection_name(owner: InspectableObject, property_name: String) -> String:
	if owner == null:
		return ""

	var property: Property = owner.get_property(property_name)
	if property == null:
		return ""
	return str(property.get_settings_value(PropertySettings.KEY_COLLECTION, ""))


## Which property labels an item. What the reference declared, or what the collection
## declares. Options are labelled by their text, characters by name.
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
		var label: String = Util.to_label(
			node.get_property_value("label"), project.active_language_code
		)
		if label.is_empty():
			label = "%s %d" % [node.get_id(), position]
		candidates.append({"id": node.get_id(), "label": label})
	return candidates


## Reads {"id": ..., "<label_property>": ...} out of stored collection items.
##
## An item with nothing in its label property is named after its type and position. An id
## would mean nothing to the person choosing from the list.
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


## Reads one stored property out of an item, as text. Handles translatable values, which are
## a dictionary of languages instead of a plain string.
static func _read(record: Dictionary, key: String) -> String:
	if not record.has(key):
		return ""

	var project: MonologueProject = ProjectManager.current_project
	return Util.to_label(record[key], project.active_language_code if project else "")

# gdlint: disable=max-public-methods
## Identity map of a project plus the reverse index of everything that points at
## something else. Owned by [MonologueProject]. Headless.
##
## Two kinds of object live in a project: ones that exist as instances (documents and
## graph nodes) and ones that are stored as plain dictionaries inside a collection
## property (characters, portraits, variables). Both get an id here;
## [method get_object] answers for the first, [method get_record] for the second.
##
## Reference extraction never asks an object what it points at. It asks the field type,
## through [method FieldIndexer.extract_references], so a new composite field is one
## method and no node class has to know it exists.
class_name ProjectObjectRegistry extends RefCounted

signal object_registered(object: InspectableObject)
signal object_unregistered(object: InspectableObject)
signal references_changed(target_id: String)

const ID_PROPERTY: String = "id"
const COLLECTION_TYPE: String = "collection"

## Live objects, by id.
var _by_id: Dictionary[String, InspectableObject] = {}
## Dictionary-backed collection items, by id.
var _records_by_id: Dictionary[String, Dictionary] = {}
## Every id in the project, live or stored. This is what uniqueness is checked against.
var _known_ids: Dictionary[String, bool] = {}
## target_id -> Array[ReferenceSite]
var _referrers: Dictionary[String, Array] = {}
## owner_id -> Array[ReferenceSite]
var _sites_by_owner: Dictionary[String, Array] = {}
## One instance per collection type, kept to read the property schema of items that
## only exist as dictionaries.
var _prototypes: Dictionary[String, CollectionItem] = {}
var _history: CommandManager


# --- identity -------------------------------------------------------------------


## Returns an id that nothing else in the project uses. Keeps [param preferred_id] when
## it is free, and allocates a fresh one when it is taken.
func allocate_id(type_name: String, preferred_id: String = "") -> String:
	if not preferred_id.is_empty() and not _known_ids.has(preferred_id):
		_known_ids[preferred_id] = true
		return preferred_id

	if not preferred_id.is_empty():
		Log.warn("Id '%s' is already in use; a fresh one was allocated." % preferred_id)

	var fresh: String = IDGen.generate_object_id(type_name)
	while _known_ids.has(fresh):
		fresh = IDGen.generate_object_id(type_name)
	_known_ids[fresh] = true
	return fresh


## Adds an object to the identity map and returns the id it ended up with, which
## differs from the one it arrived with only when that id was already taken.
func register(object: InspectableObject) -> String:
	if object == null:
		return ""

	var current_id: String = str(object.get_property_value(ID_PROPERTY))
	var allocated_id: String = allocate_id(object.get_type(), current_id)
	if allocated_id != current_id:
		var id_property: Property = object.get_property(ID_PROPERTY)
		if id_property:
			id_property.value = allocated_id

	_by_id[allocated_id] = object
	object_registered.emit(object)
	return allocated_id


## Drops an object from the identity map. Referrers are left untouched: they keep the
## id they always had, and start reporting it as missing instead.
func unregister(object: InspectableObject) -> void:
	if object == null:
		return

	var object_id: String = str(object.get_property_value(ID_PROPERTY))
	_by_id.erase(object_id)
	_known_ids.erase(object_id)
	_forget_sites_of(object_id)
	object_unregistered.emit(object)
	references_changed.emit(object_id)


func get_object(object_id: String) -> InspectableObject:
	return _by_id.get(object_id)


## Returns the stored dictionary of a collection item, or an empty one when the id
## belongs to a live object or to nothing at all.
func get_record(object_id: String) -> Dictionary:
	return _records_by_id.get(object_id, {})


func has_id(object_id: String) -> bool:
	return _known_ids.has(object_id)


func get_all_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for object_id: String in _known_ids:
		ids.append(object_id)
	return ids


# --- reverse index --------------------------------------------------------------


## Records every reference held by one live object.
func index_object(object: InspectableObject, document_name: String = "") -> void:
	if object == null:
		return

	var owner_id: String = str(object.get_property_value(ID_PROPERTY))
	if owner_id.is_empty():
		return

	for property: Property in object.get_properties():
		_index_value(owner_id, property, property.get_value(), document_name)


## Every place pointing at [param target_id].
func get_referrers(target_id: String) -> Array[ReferenceSite]:
	var sites: Array[ReferenceSite] = []
	sites.assign(_referrers.get(target_id, []))
	return sites


## Every reference held by [param owner_id].
func get_references_from(owner_id: String) -> Array[ReferenceSite]:
	var sites: Array[ReferenceSite] = []
	sites.assign(_sites_by_owner.get(owner_id, []))
	return sites


## Every reference whose target no longer exists.
func find_dangling() -> Array[ReferenceSite]:
	var dangling: Array[ReferenceSite] = []
	for target_id: String in _referrers:
		if _known_ids.has(target_id):
			continue
		dangling.append_array(get_referrers(target_id))
	return dangling


# --- building -------------------------------------------------------------------


## Discards everything and walks the project again. Cheap enough to run whenever the
## project reports a change, which is what [MonologueProject] does.
func rebuild(project: MonologueProject) -> void:
	clear()
	if project == null:
		return

	_history = project.command_manager
	for document: InspectableDocument in project.get_all_documents():
		_index_document(document)


func clear() -> void:
	_by_id.clear()
	_records_by_id.clear()
	_known_ids.clear()
	_referrers.clear()
	_sites_by_owner.clear()


func _index_document(document: InspectableDocument) -> void:
	if document == null:
		return

	var document_name: String = document.get_document_name()
	register(document)
	index_object(document, document_name)

	if document is StorylineDocument:
		for node: InspectableNode in (document as StorylineDocument).nodes:
			register(node)
			index_object(node, document_name)
			_index_connections(node, document_name)


## Walks one property value, recursing into collection items, which are stored as
## dictionaries rather than instances.
func _index_value(
	owner_id: String, property: Property, value: Variant, document_name: String
) -> void:
	if property.type == COLLECTION_TYPE:
		var collection_name: String = str(
			property.get_settings_value(PropertySettings.KEY_COLLECTION, "")
		)
		if value is Array and not collection_name.is_empty():
			for entry: Variant in value:
				if entry is Dictionary:
					_index_record(entry, collection_name, document_name)
		return

	var indexer: FieldIndexer = MonologueRegistry.get_instance().get_field(property.type)
	if indexer == null:
		return

	for target_id: String in indexer.extract_references(value):
		if not target_id.is_empty():
			_add_site(ReferenceSite.create(owner_id, property.name, target_id, document_name))


## Registers one stored collection item and everything it points at.
func _index_record(record: Dictionary, collection_name: String, document_name: String) -> void:
	var prototype: CollectionItem = _get_prototype(collection_name)
	if prototype == null:
		return

	var owner_id: String = _read_record_value(record, ID_PROPERTY, "")
	if owner_id.is_empty():
		return

	if _known_ids.has(owner_id):
		Log.warn("Two objects share the id '%s'; references to it are ambiguous." % owner_id)

	_records_by_id[owner_id] = record
	_known_ids[owner_id] = true

	for property: Property in prototype.get_properties():
		var raw: Variant = record.get(property.name)
		var value: Variant = (raw as Dictionary).get("value") if raw is Dictionary else null
		_index_value(owner_id, property, value, document_name)


## Records the graph wires leaving a node. Only outgoing ones, so each wire is listed
## once.
func _index_connections(node: InspectableNode, document_name: String) -> void:
	var owner_id: String = node.get_id()
	for property: Property in node.get_properties():
		for connection: Dictionary in property.connected_to:
			var target_id: String = str(connection.get("node_id", ""))
			if target_id.is_empty():
				continue
			_add_site(
				ReferenceSite.create(
					owner_id,
					property.name,
					target_id,
					document_name,
					ReferenceSite.KIND_CONNECTION
				)
			)


func _add_site(site: ReferenceSite) -> void:
	var existing: Array = _referrers.get_or_add(site.target_id, [])
	for other: ReferenceSite in existing:
		if other.matches(site):
			return

	existing.append(site)
	var owned: Array = _sites_by_owner.get_or_add(site.owner_id, [])
	owned.append(site)
	references_changed.emit(site.target_id)


func _forget_sites_of(owner_id: String) -> void:
	for site: ReferenceSite in get_references_from(owner_id):
		var siblings: Array = _referrers.get(site.target_id, [])
		siblings.erase(site)
		if siblings.is_empty():
			_referrers.erase(site.target_id)
	_sites_by_owner.erase(owner_id)


## Returns a throwaway item of the given collection type, used only to read which
## properties items of that type have and what field type each one is.
func _get_prototype(collection_name: String) -> CollectionItem:
	if _prototypes.has(collection_name):
		return _prototypes[collection_name]

	var prototype: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		collection_name, _history
	)
	if prototype:
		_prototypes[collection_name] = prototype
	return prototype


static func _read_record_value(record: Dictionary, key: String, fallback: String) -> String:
	var raw: Variant = record.get(key)
	if raw is Dictionary:
		return str((raw as Dictionary).get("value", fallback))
	return fallback

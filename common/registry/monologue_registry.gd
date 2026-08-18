## Single source of truth for every type Monologue knows about.
##
## Headless by construction: this class never touches the SceneTree, a Control or an
## autoload, so model code and unit tests can use it without booting the editor.
## Widget creation lives in [FieldWidgetFactory] instead.
##
## Access it with [method get_instance]; the first call installs the built-in plugins.
## [codeblock]
## var registry := MonologueRegistry.get_instance()
## var indexer := registry.get_field("text")
## var node := registry.create_node("sentence", history)
## [/codeblock]
class_name MonologueRegistry extends RefCounted

signal indexer_registered(indexer: MonologueIndexer)
signal registry_changed

## Loaded at runtime rather than preloaded: the core plugin pulls in node and item
## scripts, which reach back to this class, and a preload cycle would not resolve.
const CORE_PLUGIN_PATH: String = "res://common/plugins/core/core_plugin.gd"

static var _instance: MonologueRegistry

## object_type -> name -> MonologueIndexer.
## Nested rather than flat because names collide across object types: "text" and
## "option" each name more than one kind of thing.
var _by_type: Dictionary[StringName, Dictionary] = {}
var _plugins: Array[MonologuePlugin] = []
## Fast reverse lookup for port compatibility checks, which run on every graph refresh.
var _field_by_type_id: Dictionary[int, FieldIndexer] = {}
## 1-based. GraphNode treats slot type 0 as its own default, so 0 is kept free to mean
## "not a registered field type".
var _next_field_type_id: int = 1
## Port type ids for reference targets, keyed by scope. Drawn from the same counter as
## field types, which is what keeps a "characters" port from matching any other port.
var _reference_type_ids: Dictionary[String, int] = {}
var _installing_plugin: String = ""


func _init() -> void:
	for object_type: StringName in MonologueObjectType.ALL:
		_by_type[object_type] = {}


## Returns the shared registry, installing the built-in plugins on first call.
static func get_instance() -> MonologueRegistry:
	if _instance == null:
		# Assigned before bootstrapping so that anything reached during installation
		# which calls get_instance() sees the same partially-filled registry instead
		# of recursing.
		_instance = MonologueRegistry.new()
		_instance._install_builtin_plugins()
	return _instance


## Drops the shared registry so the next [method get_instance] rebuilds it. Tests only.
static func reset_instance() -> void:
	_instance = null


func _install_builtin_plugins() -> void:
	var script: Variant = load(CORE_PLUGIN_PATH)
	if script is GDScript:
		install((script as GDScript).new())
	else:
		push_error("Could not load the core plugin at %s." % CORE_PLUGIN_PATH)


# --- plugins --------------------------------------------------------------------


func install(plugin: MonologuePlugin) -> void:
	if plugin == null:
		push_warning("Attempted to install a null plugin.")
		return
	var plugin_name: String = plugin.get_plugin_name()
	if plugin_name.is_empty():
		push_warning("Attempted to install a plugin with no name.")
		return
	for installed: MonologuePlugin in _plugins:
		if installed.get_plugin_name() == plugin_name:
			push_warning("Plugin '%s' is already installed." % plugin_name)
			return

	_plugins.append(plugin)
	_installing_plugin = plugin_name
	plugin.register(self)
	_installing_plugin = ""
	registry_changed.emit()


## Removes a plugin and every type it registered.
func uninstall(plugin_name: String) -> void:
	var plugin: MonologuePlugin = null
	for installed: MonologuePlugin in _plugins:
		if installed.get_plugin_name() == plugin_name:
			plugin = installed
			break
	if plugin == null:
		return

	plugin.unregister(self)
	_plugins.erase(plugin)
	for object_type: StringName in MonologueObjectType.ALL:
		var bucket: Dictionary = _by_type[object_type]
		for indexer_name: String in bucket.keys():
			var indexer: MonologueIndexer = bucket[indexer_name]
			if indexer.source_plugin == plugin_name:
				if indexer is FieldIndexer:
					_field_by_type_id.erase((indexer as FieldIndexer).type_id)
				bucket.erase(indexer_name)
	registry_changed.emit()


func get_installed_plugins() -> Array[MonologuePlugin]:
	return _plugins.duplicate()


# --- registration ---------------------------------------------------------------


## Adds one indexer. Returns false and warns when the indexer is invalid or its name is
## already taken *within its own object type*.
func register(indexer: MonologueIndexer) -> bool:
	if indexer == null:
		push_warning("Attempted to register a null indexer.")
		return false

	var error: String = indexer.validate_registration()
	if not error.is_empty():
		push_warning("Rejected indexer: %s" % error)
		return false

	var object_type: StringName = indexer.get_object_type()
	var bucket: Dictionary = _by_type[object_type]
	if bucket.has(indexer.name):
		push_warning("A %s named '%s' is already registered." % [object_type, indexer.name])
		return false

	indexer.source_plugin = _installing_plugin
	if indexer is FieldIndexer:
		var field: FieldIndexer = indexer
		field.type_id = _next_field_type_id
		_next_field_type_id += 1
		_field_by_type_id[field.type_id] = field

	bucket[indexer.name] = indexer
	indexer_registered.emit(indexer)
	return true


# --- lookup ---------------------------------------------------------------------


func has(object_type: StringName, indexer_name: String) -> bool:
	return _by_type.get(object_type, {}).has(indexer_name)


func get_indexer(object_type: StringName, indexer_name: String) -> MonologueIndexer:
	return _by_type.get(object_type, {}).get(indexer_name)


func get_field(field_name: String) -> FieldIndexer:
	return get_indexer(MonologueObjectType.FIELD, field_name) as FieldIndexer


func get_node(node_name: String) -> NodeIndexer:
	return get_indexer(MonologueObjectType.NODE, node_name) as NodeIndexer


func get_collection(collection_name: String) -> CollectionIndexer:
	return get_indexer(MonologueObjectType.COLLECTION, collection_name) as CollectionIndexer


## All indexers of one object type, sorted by display name.
func list(object_type: StringName) -> Array[MonologueIndexer]:
	var result: Array[MonologueIndexer] = []
	result.assign(_by_type.get(object_type, {}).values())
	result.sort_custom(_sort_by_display_name)
	return result


## Unique category names for one object type, sorted.
## Categories starting with "_" are internal and hidden unless [param include_internal].
func list_categories(object_type: StringName, include_internal: bool = false) -> PackedStringArray:
	var categories: PackedStringArray = []
	for indexer: MonologueIndexer in _by_type.get(object_type, {}).values():
		if indexer.category.begins_with("_") and not include_internal:
			continue
		if indexer.category in categories:
			continue
		categories.append(indexer.category)
	categories.sort()
	return categories


func list_by_category(object_type: StringName, category: String) -> Array[MonologueIndexer]:
	var result: Array[MonologueIndexer] = []
	for indexer: MonologueIndexer in _by_type.get(object_type, {}).values():
		if indexer.category == category:
			result.append(indexer)
	result.sort_custom(_sort_by_display_name)
	return result


# --- factories ------------------------------------------------------------------


func create_node(node_name: String, history: CommandManager) -> InspectableNode:
	var indexer: NodeIndexer = get_node(node_name)
	if indexer == null:
		push_warning("No node type registered as '%s'." % node_name)
		return null
	return indexer.instantiate(history) as InspectableNode


func create_collection_item(collection_name: String, history: CommandManager) -> CollectionItem:
	var indexer: CollectionIndexer = get_collection(collection_name)
	if indexer == null:
		push_warning("No collection type registered as '%s'." % collection_name)
		return null
	return indexer.instantiate(history) as CollectionItem


# --- graph ports ----------------------------------------------------------------


func get_field_type_id(field_name: String) -> int:
	var indexer: FieldIndexer = get_field(field_name)
	return indexer.type_id if indexer else 0


## Port type id for references aimed at [param scope], allocated on first use.
##
## Every reference field shares one field type, so without this a character reference
## and an ease reference would look interchangeable to the graph. Two ports match only
## when they point at the same kind of thing.
func get_reference_type_id(scope: String) -> int:
	if scope.is_empty():
		return 0
	if _reference_type_ids.has(scope):
		return _reference_type_ids[scope]

	var type_id: int = _next_field_type_id
	_next_field_type_id += 1
	_reference_type_ids[scope] = type_id
	return type_id


func is_compatible(type_id_a: int, type_id_b: int) -> bool:
	if type_id_a == type_id_b:
		return true
	return _accepts(type_id_a, type_id_b) or _accepts(type_id_b, type_id_a)


func _accepts(from_type_id: int, to_type_id: int) -> bool:
	var indexer: FieldIndexer = _field_by_type_id.get(from_type_id)
	if indexer == null:
		return false
	for compatible_name: String in indexer.compatible_types:
		if compatible_name == "*":
			return true
		if get_field_type_id(compatible_name) == to_type_id:
			return true
	return false


## Teaches a GraphEdit every compatible (type_id, type_id) pair.
##
## Without this, compatible_types is dead configuration: GraphEdit refuses a drag
## between differing slot types *before* emitting connection_request, so
## [method is_compatible] would only ever be consulted for identical types.
func apply_connection_types(graph_edit: GraphEdit) -> void:
	if graph_edit == null:
		return
	var fields: Array[MonologueIndexer] = list(MonologueObjectType.FIELD)
	for from_field: FieldIndexer in fields:
		for to_field: FieldIndexer in fields:
			if from_field.type_id == to_field.type_id:
				continue
			if is_compatible(from_field.type_id, to_field.type_id):
				graph_edit.add_valid_connection_type(from_field.type_id, to_field.type_id)

		# A reference port is not a field type, so the loop above never reaches one. A field
		# that accepts anything has to be told about them by name, and they are handed out as
		# they are first asked for -- which is why this is worth calling again after a redraw.
		if "*" not in from_field.compatible_types:
			continue
		for reference_type_id: int in _reference_type_ids.values():
			graph_edit.add_valid_connection_type(from_field.type_id, reference_type_id)
			graph_edit.add_valid_connection_type(reference_type_id, from_field.type_id)


static func _sort_by_display_name(a: MonologueIndexer, b: MonologueIndexer) -> bool:
	return a.get_display_name().naturalnocasecmp_to(b.get_display_name()) < 0

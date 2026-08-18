## A story flattened into the shape the runtime walks. Built once and never changed:
## everything that moves lives in [MonologueState], so two players can share one graph and
## rewinding is restoring a state rather than rebuilding anything.
##
## Knows the shape of the format and no node type whatsoever.
class_name MonologueStoryGraph extends RefCounted

## No id, property name or item id can contain a pipe, so an edge key needs no escaping.
const KEY_SEPARATOR: String = "|"
## Marks a sub-port standing for something computed rather than stored. Must match
## NodeConnection.EXTERNAL_PREFIX in the editor; a test holds the two together.
const EXTERNAL_PREFIX: String = "ext_"
## Editor bookkeeping, which stops at the door.
const RESERVED_KEYS: PackedStringArray = ["$type", "_editor_settings"]

## node_id -> {"type": String, "storyline": String, "props": Dictionary}
var nodes: Dictionary = {}
## storyline_id -> {"name": String, "entry": node_id}
var storylines: Dictionary = {}
## edge key -> PackedStringArray of the node ids it leads to
var out_edges: Dictionary = {}
## edge key -> Array of {"node": String, "property": String, "item": String}
var in_edges: Dictionary = {}
## collection name -> {record id: record}
var collections: Dictionary = {}

var entry_storyline: String = ""
var languages: PackedStringArray = []
var problems: Array[MonologueProblem] = []


static func of(source: MonologueSource) -> MonologueStoryGraph:
	var graph: MonologueStoryGraph = MonologueStoryGraph.new()
	graph.problems.append_array(source.problems)
	if not source.is_readable:
		return graph

	graph._index(source)
	return graph


static func key(node_id: String, property: String, item_id: String = "") -> String:
	return node_id + KEY_SEPARATOR + property + KEY_SEPARATOR + item_id


## Several targets is legal in the file and the caller decides what to do about it.
func successors(node_id: String, property: String, item_id: String = "") -> PackedStringArray:
	return out_edges.get(key(node_id, property, item_id), PackedStringArray())


func sources(node_id: String, property: String, item_id: String = "") -> Array:
	return in_edges.get(key(node_id, property, item_id), [])


func has_node(node_id: String) -> bool:
	return nodes.has(node_id)


func type_of(node_id: String) -> String:
	return str((nodes.get(node_id, {}) as Dictionary).get("type", ""))


func storyline_of(node_id: String) -> String:
	return str((nodes.get(node_id, {}) as Dictionary).get("storyline", ""))


func props(node_id: String) -> Dictionary:
	return (nodes.get(node_id, {}) as Dictionary).get("props", {})


## Empty when nothing carries that id, which is how a reference to something deleted reads.
func record(collection: String, record_id: String) -> Dictionary:
	if record_id.is_empty():
		return {}
	return (collections.get(collection, {}) as Dictionary).get(record_id, {})


func entry_of(storyline_id: String) -> String:
	return str((storylines.get(storyline_id, {}) as Dictionary).get("entry", ""))


## How a jump finds a waypoint, since the editor stores the name written on the node rather
## than its id. Walked rather than indexed: an index would have to be told which properties
## are worth indexing, which is the runtime deciding things about node types.
func find_by(storyline_id: String, key_name: String, value: Variant) -> PackedStringArray:
	var found: PackedStringArray = []
	for node_id: String in nodes:
		if storyline_of(node_id) != storyline_id:
			continue
		if props(node_id).get(key_name) == value:
			found.append(node_id)
	return found


func has_errors() -> bool:
	for problem: MonologueProblem in problems:
		if problem.is_error():
			return true
	return false


func _index(source: MonologueSource) -> void:
	languages = _languages_of(source)
	for collection_name: String in source.collections():
		var by_id: Dictionary = {}
		for record_data: Variant in source.records(collection_name):
			if record_data is not Dictionary:
				continue
			var record_id: String = str((record_data as Dictionary).get("id", ""))
			if not record_id.is_empty():
				by_id[record_id] = record_data
		collections[collection_name] = by_id

	var documents: Dictionary = source.storylines()
	for document_name: String in documents:
		_index_storyline(document_name, documents[document_name])

	if storylines.is_empty():
		problems.append(
			MonologueProblem.warning(&"no_storyline", "This story has no readable storyline.")
		)
	entry_storyline = _resolve_entry(source)


## In the order the project stores them; the first is what a story falls back to.
static func _languages_of(source: MonologueSource) -> PackedStringArray:
	var codes: PackedStringArray = []
	for record_data: Variant in source.records("languages"):
		if record_data is Dictionary:
			var code: String = str((record_data as Dictionary).get("code", "")).strip_edges()
			if not code.is_empty():
				codes.append(code)
	return codes


func _index_storyline(document_name: String, document: Dictionary) -> void:
	var storyline_id: String = str(document.get("id", ""))
	if storyline_id.is_empty():
		problems.append(
			MonologueProblem.error(
				&"storyline_without_id", "A storyline has no id and cannot be reached."
			).in_document(document_name)
		)
		return

	storylines[storyline_id] = {
		"name": document_name, "entry": str(document.get("root_node_id", ""))
	}

	for node: Dictionary in _nodes_of(document, document_name):
		nodes[str(node["id"])] = {
			"type": str(node["$type"]),
			"storyline": storyline_id,
			"props": _strip_reserved(node),
		}

	_index_connections(document, storyline_id)


func _nodes_of(document: Dictionary, document_name: String) -> Array[Dictionary]:
	var usable: Array[Dictionary] = []
	for candidate: Variant in document.get("nodes", []):
		if candidate is not Dictionary:
			continue
		var node: Dictionary = candidate
		if str(node.get("id", "")).is_empty() or str(node.get("$type", "")).is_empty():
			problems.append(
				MonologueProblem.error(
					&"node_without_identity", "A node has no id or no type; it was left out."
				).in_document(document_name)
			)
			continue
		usable.append(node)
	return usable


static func _strip_reserved(node: Dictionary) -> Dictionary:
	var kept: Dictionary = node.duplicate()
	for reserved: String in RESERVED_KEYS:
		kept.erase(reserved)
	return kept


## The item id is taken verbatim: the editor stores it beside the property name rather than
## glued to it, so nothing here parses a composite "choices:option-XXXX" string.
func _index_connections(document: Dictionary, storyline_id: String) -> void:
	for candidate: Variant in document.get("connections", []):
		if candidate is not Dictionary:
			continue
		var wire: Dictionary = candidate
		var from_node: String = str(wire.get("from_node_id", ""))
		var to_node: String = str(wire.get("to_node_id", ""))
		if from_node.is_empty() or to_node.is_empty():
			continue

		if not nodes.has(from_node) or not nodes.has(to_node):
			problems.append(
				MonologueProblem.error(
					&"broken_connection", "A wire points at a node that is not in this storyline."
				).at(from_node, storyline_id)
			)
			continue

		var from_key: String = key(
			from_node, str(wire.get("from_property", "")), str(wire.get("from_item_id", ""))
		)
		var targets: PackedStringArray = out_edges.get(from_key, PackedStringArray())
		targets.append(to_node)
		out_edges[from_key] = targets

		var to_key: String = key(
			to_node, str(wire.get("to_property", "")), str(wire.get("to_item_id", ""))
		)
		var incoming: Array = in_edges.get(to_key, [])
		incoming.append({
			"node": from_node,
			"property": str(wire.get("from_property", "")),
			"item": str(wire.get("from_item_id", "")),
		})
		in_edges[to_key] = incoming


## Reporting the guess matters: a story that starts somewhere the author did not choose looks
## like a bug in the game.
func _resolve_entry(source: MonologueSource) -> String:
	var declared: String = source.entry_point()
	if storylines.has(declared):
		return declared

	if storylines.is_empty():
		return ""

	var first: String = str(storylines.keys()[0])
	if not declared.is_empty():
		problems.append(
			MonologueProblem.warning(
				&"unknown_entry_point",
				"The story begins at '%s', which does not exist; '%s' was used instead."
				% [declared, storylines[first]["name"]]
			)
		)
	elif storylines.size() > 1:
		problems.append(
			MonologueProblem.warning(
				&"no_entry_point",
				"No storyline is marked as the beginning; '%s' was used."
				% storylines[first]["name"]
			)
		)
	return first

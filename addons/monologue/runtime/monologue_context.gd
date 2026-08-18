## Everything a behaviour is given: its own data, its wires, the run so far, and the player.
class_name MonologueContext extends RefCounted

## Types that stand for a value rather than a moment. A wire out of one, into a property
## port, replaces what the node had stored.
const VALUE_TYPES: PackedStringArray = ["bool", "int", "float", "text"]
const MAX_VALUE_DEPTH: int = 32

var session: MonologueSession
var id: String = ""
var type: String = ""
var storyline: String = ""
var data: Dictionary = {}

var graph: MonologueStoryGraph:
	get: return session.graph
var state: MonologueState:
	get: return session.state
var player: MonologuePlayer:
	get: return session.player
var language: String:
	get: return session.language


func _init(p_session: MonologueSession, node_id: String) -> void:
	session = p_session
	id = node_id
	type = p_session.graph.type_of(node_id)
	storyline = p_session.graph.storyline_of(node_id)
	data = p_session.graph.props(node_id)


## [param fallback] is what a file written before this property existed reads as.
func value(key: String, fallback: Variant = null) -> Variant:
	var wires: Array = graph.sources(id, key)
	if not wires.is_empty():
		var wired: Variant = _value_behind(str((wires[0] as Dictionary)["node"]), 0)
		if wired != null:
			return wired

	var stored: Variant = data.get(key)
	return fallback if stored == null else stored


## A collection property: what the author stored in it, then whatever was wired into its
## port. A choice's options come from both, and so do a call's exits.
##
## An external item is a node of its own, and is handed back carrying the id its sub-port is
## keyed by rather than its node id -- so a behaviour reads either kind the same way, and
## leaves through [method next] the same way.
func items(key: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []

	var stored: Variant = data.get(key)
	if stored is Array:
		for candidate: Variant in stored:
			if candidate is Dictionary:
				found.append(candidate)

	for wire: Dictionary in graph.sources(id, key):
		var source: String = str(wire.get("node", ""))
		if source.is_empty():
			continue
		# Duplicated because the graph is built once and read by everything.
		var external: Dictionary = graph.props(source).duplicate()
		external["id"] = MonologueStoryGraph.EXTERNAL_PREFIX + source
		found.append(external)

	return found


## One of this node's own properties, as the text a reader sees.
## One record out of a list held inside another: the one named, or the one marked as the
## fallback, or the first there is. A character's portrait and a location's variation are
## both chosen this way, and a behaviour bringing its own kind of list should not have to
## write it a third time.
func pick(items_of: Variant, item_id: String) -> Dictionary:
	var fallback: Dictionary = {}
	if items_of is not Array:
		return fallback

	for record: Variant in items_of:
		if record is not Dictionary:
			continue
		if str(record.get("id", "")) == item_id:
			return record
		if fallback.is_empty() or record.get("is_default") == true:
			fallback = record
	return fallback


func text(key: String) -> String:
	return label(value(key))


## Any stored value as the text a reader sees, in the language this run plays. What a
## behaviour needs for text it dug out itself -- an option's, a character's -- since
## [method text] only reaches this node's own properties.
func label(of_value: Variant) -> String:
	return MonologueText.to_label(of_value, language)


## The single id behind a port, or empty. [param property] defaults to the port a node type
## names after itself.
##
## The usual case, and only that: a behaviour wanting to choose among several exits reads
## [method MonologueStoryGraph.successors] through [member graph], and one going somewhere it
## worked out for itself hands [method BehaviourResult.progress] whatever id it likes.
func next(property: String = "", item: String = "") -> String:
	var port: String = property if not property.is_empty() else type
	var found: PackedStringArray = graph.successors(id, port, item)
	if found.is_empty():
		return ""

	# TODO: Maybe redirect to a random branch. (need visual cue in the editor)
	if found.size() > 1:
		note(
			&"ambiguous_flow",
			"'%s' leads to %d places at once; the first was taken." % [port, found.size()]
		)
	return found[0]


## Whatever the game brought under that name, or null. The deliberate hole in this class:
## what a behaviour can do is bounded by what the game offers, not by the methods here.
func service(service_name: String) -> Object:
	return session.services.get_service(service_name)


func sources(property: String = "") -> Array:
	return graph.sources(id, property if not property.is_empty() else type)


## Falls back to what the project declared, so a variable added since a save was written
## reads as its default rather than as null.
func get_var(variable_id: String) -> Variant:
	if state.variables.has(variable_id):
		return state.variables[variable_id]
	return graph.record("variables", variable_id).get("value")


## Coerced to the type the project declared, so putting text into a number is not something
## a story can express by accident.
func set_var(variable_id: String, of_value: Variant) -> void:
	match str(graph.record("variables", variable_id).get("type", "")):
		"bool": state.variables[variable_id] = bool(of_value)
		"int": state.variables[variable_id] = int(of_value)
		"float": state.variables[variable_id] = float(of_value)
		"string": state.variables[variable_id] = str(of_value)
		_: state.variables[variable_id] = of_value


func test(condition: Variant) -> bool:
	if condition is not Dictionary:
		return true

	var check: Dictionary = condition
	return MonologueCondition.holds(
		get_var(str(check.get("variable", ""))),
		str(check.get("operator", "==")),
		check.get("value")
	)


func note(code: StringName, message: String) -> void:
	session.problems.append(MonologueProblem.warning(code, message).at(id, storyline))


func fault(code: StringName, message: String) -> void:
	session.problems.append(MonologueProblem.error(code, message).at(id, storyline))


## Null when the far end is not a value at all, and quietly: every flow port has wires into
## it too, and asking one of those for a value is the normal case.
func _value_behind(source_id: String, depth: int) -> Variant:
	if depth > MAX_VALUE_DEPTH:
		note(&"value_cycle", "A value wire loops back on itself.")
		return null

	var source_type: String = graph.type_of(source_id)
	if source_type == "reroute":
		var behind: Array = graph.sources(source_id, "reroute")
		if behind.is_empty():
			return null
		return _value_behind(str((behind[0] as Dictionary)["node"]), depth + 1)

	if source_type in VALUE_TYPES:
		return graph.props(source_id).get(source_type)

	return null

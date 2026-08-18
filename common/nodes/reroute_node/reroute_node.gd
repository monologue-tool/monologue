## Passes the story straight through. Carries nothing of its own. It exists so a long
## wire can be bent around the rest of the graph instead of crossing it.
##
## It takes in anything and gives back only what it was given: its outgoing side is typed
## after whatever is plugged into its incoming one, so a reroute cannot be used to turn one
## kind of thing into another on the way past.
class_name RerouteNode extends InspectableNode

## How many reroutes deep a type is followed before it is given up on. A reroute wired in a
## circle carries nothing, and asking forever is worse than answering that.
const MAX_HOPS: int = 32


func initialize_properties() -> void:
	define_property(Property.new("reroute")
		.set_type("any")
		.main_property()
		.exposed()
		.exported())


func get_type() -> String:
	return "reroute"


func carried_port(property: Property, hops: int = 0) -> Dictionary:
	if not property.is_main_property() or hops >= MAX_HOPS:
		return {}

	var wires: Array[Dictionary] = property.connected_from
	if wires.is_empty():
		return {}

	var source: InspectableNode = _source_of(wires[0])
	if source == null:
		return {}

	var given: Property = source.get_property(str(wires[0].get("property_name", "")))
	if given == null:
		return {}
	return NodePort.of(source, given, hops + 1)


## What a reroute hands on is what it was given, so rewiring what feeds it can leave it
## handing something else on to a port that was never able to take it. The wire looks the
## same as it did, which is why this has to be said out loud.
func validate_object(result: ValidationResult, context: ValidationContext) -> void:
	var property: Property = get_main_property()
	var carried: Dictionary = carried_port(property)
	if carried.is_empty() or context.project == null:
		return

	var storyline: StorylineDocument = context.project.get_storyline(storyline_id)
	if storyline == null:
		return

	var registry: MonologueRegistry = MonologueRegistry.get_instance()
	for wire: Dictionary in property.connected_to:
		var target: InspectableNode = storyline.get_node(str(wire.get("node_id", "")))
		if target == null:
			continue

		var taken: Property = target.get_property(str(wire.get("property_name", "")))
		if taken == null:
			continue

		# What the far end takes in, not what it hands on: if it is another reroute, what it
		# hands on is what this one just gave it, and the two would always agree.
		var into: Dictionary = NodePort.declared(target, taken)
		if registry.is_compatible(int(carried["type_id"]), int(into["type_id"])):
			continue

		result.add(
			ValidationIssue.error(
				"This carries %s into a port that takes %s."
				% [str(carried["label"]), str(into["label"])],
				&"rerouted_into_the_wrong_type"
			).at(self, property.name)
		)


func _source_of(wire: Dictionary) -> InspectableNode:
	var project: MonologueProject = ProjectManager.current_project
	if project == null:
		return null

	var storyline: StorylineDocument = project.get_storyline(storyline_id)
	return storyline.get_node(str(wire.get("node_id", ""))) if storyline else null

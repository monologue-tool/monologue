class_name ExampleTemplate extends DefaultTemplate

const STEP: Vector2 = Vector2(260.0, 140.0)


func setup_default_storyline(storyline: StorylineDocument) -> void:
	_node(storyline, "root", 0, 0, "start")


func setup_collection(project: MonologueProject) -> void:
	super.setup_collection(project)

	var cast: String = _first_item(project, "characters")
	var gold: String = _add_item(project, "variables", {
		"name": "gold", "type": "int", "value": 0
	})
	var alarm: String = _add_item(project, "variables", {
		"name": "alarm", "type": "bool", "value": false
	})
	var who: String = _add_item(project, "variables", {
		"name": "player_name", "type": "string", "value": ""
	})
	var key: String = _add_item(project, "items", {"name": "Key"})

	var epilogue: StorylineDocument = StorylineDocument.new("epilogue", project.command_manager)
	_build_epilogue(epilogue, cast)
	project.storylines.append(epilogue)

	_build_main(project.storylines[0], cast, gold, alarm, who, key, epilogue.id)


func _build_main(
	line: StorylineDocument,
	cast: String,
	gold: String,
	alarm: String,
	who: String,
	key: String,
	epilogue_id: String
) -> void:
	var root: InspectableNode = _find(line, "root")

	var greeting: InspectableNode = _say(line, cast, 1, 0, "greeting", "[greeting]")
	var pause: InspectableNode = _node(line, "wait", 2, 0, "a beat")
	var seconds: InspectableNode = _node(line, "float", 2, 2, "how long")
	seconds.get_property("float").set_value(0.5)
	_expose(pause, "seconds")

	var earn: InspectableNode = _node(line, "variable", 3, 0, "gold goes up")
	earn.get_property("target").set_value(gold)
	earn.get_property("operator").set_value("+")
	earn.get_property("value").set_value(3)

	var mark: InspectableNode = _node(line, "checkpoint", 4, 0, "checkpoint")

	var fork: InspectableNode = _node(line, "choice", 5, 0, "the fork")
	var stored: Array[String] = _stored_options(fork, cast, 2)
	var extra: InspectableNode = _node(line, "option", 5, 3, "an option of its own")
	extra.get_property("speaker").set_value(cast)
	extra.get_property("text").set_value({"en": "[wired-in option]"})

	var take: InspectableNode = _node(line, "inventory", 6, -1, "give a key")
	take.get_property("who").set_value(cast)
	take.get_property("item").set_value(key)
	take.get_property("operation").set_value("Give")
	take.get_property("quantity").set_value(1)
	var bend: InspectableNode = _node(line, "reroute", 7, -1, "")

	var ask_gold: InspectableNode = _node(line, "condition", 6, 1, "rich enough")
	ask_gold.get_property("test").set_value({"variable": gold, "operator": ">=", "value": 3})
	var rich: InspectableNode = _say(line, cast, 7, 0, "rich", "[condition passed]")
	var poor: InspectableNode = _say(line, cast, 7, 2, "poor", "[condition failed]")

	var wired: InspectableNode = _say(line, cast, 6, 3, "wired branch", "[wired-in branch]")

	var hub: InspectableNode = _node(line, "waypoint", 9, 0, "hub")
	hub.get_property("label").set_value("hub")

	# The three stage nodes carry no asset: a template ships no images and no sound, and each
	# of them says so and carries on rather than stopping the run.
	var scenery: InspectableNode = _node(line, "background", 10, 0, "a place")
	var actor: InspectableNode = _node(line, "character", 11, 0, "someone joins")
	actor.get_property("who").set_value(cast)
	actor.get_property("action").set_value("Join")
	actor.get_property("position").set_value("Center")
	var music: InspectableNode = _node(line, "audio", 12, 0, "some music")
	music.get_property("loop").set_value(true)

	var entry: InspectableNode = _node(line, "function", 14, 3, "a function")
	var inside: InspectableNode = _say(line, cast, 15, 3, "inside", "[inside the function]")
	var invoke: InspectableNode = _node(line, "call", 13, 0, "call it")
	invoke.get_property("target").set_value(entry.get_id())

	var prompt: InspectableNode = _node(line, "input", 14, 0, "who are you")
	prompt.get_property("text").set_value({"en": "[prompt]"})
	prompt.get_property("variable").set_value(who)
	var press: InspectableNode = _node(line, "wait_input", 15, 0, "wait for a press")
	var tell: InspectableNode = _node(line, "action", 16, 0, "tell the game")
	tell.get_property("name").set_value("example_action")
	tell.get_property("arguments").set_value(["first", "second"])
	var leave: InspectableNode = _node(line, "storyline", 17, 0, "to the epilogue")
	leave.get_property("target").set_value(epilogue_id)

	var watch: InspectableNode = _node(line, "event", 0, 5, "when the alarm goes")
	watch.get_property("test").set_value({"variable": alarm, "operator": "==", "value": true})
	var alarmed: InspectableNode = _say(line, cast, 1, 5, "alarmed", "[the event fired]")
	var stop: InspectableNode = _node(line, "end", 2, 5, "cut short")

	_wire(line, root, greeting)
	_wire(line, greeting, pause)
	_wire(line, seconds, pause, "float", "seconds")
	_wire(line, pause, earn)
	_wire(line, earn, mark)
	_wire(line, mark, fork)

	_wire(line, fork, take, "choices", "", stored[0])
	_wire(line, take, bend)
	_wire(line, bend, hub)

	_wire(line, fork, ask_gold, "choices", "", stored[1])
	_wire(line, ask_gold, rich, "pass")
	_wire(line, ask_gold, poor, "fail")
	_wire(line, rich, hub)
	_wire(line, poor, hub)

	_wire(line, extra, fork, "option", "choices")
	_wire(line, fork, wired, "choices", "", MonologueStoryGraph.EXTERNAL_PREFIX + extra.get_id())
	_wire(line, wired, hub)

	_wire(line, hub, scenery)
	_wire(line, scenery, actor)
	_wire(line, actor, music)
	_wire(line, music, invoke)

	_wire(line, entry, inside)
	_wire(line, invoke, prompt, "exits", "", MonologueStoryGraph.EXTERNAL_PREFIX + inside.get_id())

	_wire(line, prompt, press)
	_wire(line, press, tell)
	_wire(line, tell, leave)

	_wire(line, watch, alarmed)
	_wire(line, alarmed, stop)


## Somewhere real for the storyline node to go. Its line arrives down a wire from a text node
## rather than being stored on it, which is the other way a value reaches a property.
func _build_epilogue(line: StorylineDocument, cast: String) -> void:
	var root: InspectableNode = _node(line, "root", 0, 0, "start")
	var last: InspectableNode = _say(line, cast, 1, 0, "the last word", "")
	var wording: InspectableNode = _node(line, "text", 1, 2, "said down a wire")
	wording.get_property("text").set_value({"en": "[line from a text node]"})
	_expose(last, "line")
	var stop: InspectableNode = _node(line, "end", 2, 0, "the end")

	_wire(line, root, last)
	_wire(line, wording, last, "text", "line")
	_wire(line, last, stop)


func _node(
	line: StorylineDocument, node_type: String, column: int, row: int, named: String
) -> InspectableNode:
	var node: InspectableNode = MonologueRegistry.get_instance().create_node(
		node_type, line.history
	)
	node.get_property("editor_position").set_value([STEP.x * column, STEP.y * row])
	if not named.is_empty():
		node.get_property("label").set_value(named)
	line.register_node(node)
	return node


func _say(
	line: StorylineDocument, speaker: String, column: int, row: int, named: String, said: String
) -> InspectableNode:
	var node: InspectableNode = _node(line, "sentence", column, row, named)
	node.get_property("speaker").set_value(speaker)
	if not said.is_empty():
		node.get_property("line").set_value({"en": said})
	return node


## Leaves and arrives by each end's own flow port unless told otherwise, which is what a node
## type names after itself.
func _wire(
	line: StorylineDocument,
	from_node: InspectableNode,
	to_node: InspectableNode,
	from_port: String = "",
	to_port: String = "",
	from_item: String = ""
) -> void:
	line.add_connection(
		NodeConnection.create(
			from_node.get_id(),
			from_port if not from_port.is_empty() else from_node.get_type(),
			to_node.get_id(),
			to_port if not to_port.is_empty() else to_node.get_type(),
			from_item
		)
	)


## A wire can only land on a port that is open, and a property stays closed until something
## asks for it. The editor opens one when an author drags a wire onto it. A template says so.
func _expose(node: InspectableNode, property_name: String) -> void:
	node.set_property_settings_value(property_name, PropertySettings.KEY_EXPOSED, true)


func _stored_options(choice: InspectableNode, speaker: String, count: int) -> Array[String]:
	var records: Array[Dictionary] = []
	var ids: Array[String] = []

	for index: int in range(count):
		var option: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
			"options", choice.history
		)
		option.set_property_value("speaker", speaker)
		option.set_property_value("text", {"en": "[option %d]" % (index + 1)})
		records.append(option._to_dict())
		ids.append(str(option.get_property_value("id")))

	choice.get_property("choices").set_value(records)
	_expose(choice, "choices")
	return ids


func _add_item(
	project: MonologueProject, collection_name: String, values: Dictionary
) -> String:
	var item: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		collection_name, project.command_manager
	)
	for property_name: String in values:
		item.set_property_value(property_name, values[property_name])

	var document: CollectionDocument = project.get_collection(collection_name)
	var records: Array = document.get_value().duplicate(true)
	records.append(item._to_dict())
	document.set_property_value(collection_name, records)
	return str(item.get_property_value("id"))


func _first_item(project: MonologueProject, collection_name: String) -> String:
	var records: Array = project.get_collection_value(collection_name)
	return str((records[0] as Dictionary).get("id", "")) if not records.is_empty() else ""


func _find(line: StorylineDocument, node_type: String) -> InspectableNode:
	for node: InspectableNode in line.nodes:
		if node.get_type() == node_type:
			return node
	return null

extends GdUnitTestSuite

## What the runtime addon is allowed to assume about a node type, checked here so it is the
## editor that fails rather than a story that stops halfway.
##
## Every check walks the registry instead of listing type names. A list is the contents of
## today, and adding a node type would break it without anything being wrong.
##
## The addon is a separate product reading the same format. Nothing here loads it.

var _registry: MonologueRegistry
var _history: CommandManager


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_registry = MonologueRegistry.get_instance()
	_history = CommandManager.new()


func after_test() -> void:
	MonologueRegistry.reset_instance()


func _each_node() -> Array[NodeIndexer]:
	var indexers: Array[NodeIndexer] = []
	indexers.assign(_registry.list(MonologueObjectType.NODE))
	return indexers


static func _has_input_port(node: InspectableNode) -> bool:
	return node.get_main_property().get_settings_value(PropertySettings.KEY_EXPOSED, false) == true


func test_every_type_is_coherent_about_what_the_runtime_will_do_with_it() -> void:
	for indexer: NodeIndexer in _each_node():
		var node: InspectableNode = indexer.instantiate(_history) as InspectableNode

		# A type with no input port is read, not entered. Declaring it is what tells
		# "no behaviour yet" apart from "no behaviour ever".
		if not indexer.enterable:
			assert_bool(_has_input_port(node)).override_failure_message(
				"Node '%s' is declared unenterable but its main property has an input port."
				% indexer.name
			).is_false()

		# Filled in per group as behaviours land. A path that resolves to nothing is worse
		# than no path, because it reads as done.
		if not indexer.runtime_uid.is_empty():
			assert_bool(ResourceLoader.exists(indexer.runtime_uid)).override_failure_message(
				"Node '%s' points its behaviour at '%s', which does not exist."
				% [indexer.name, indexer.runtime_uid]
			).is_true()


func test_a_type_declaring_no_way_out_is_where_a_section_stops_looking() -> void:
	# The two halves of the same fact: is_terminal_by_design reads the schema, and
	# find_terminations is what acts on it. They have to agree for every type at once,
	# because a section node grows one exit per disagreement.
	for indexer: NodeIndexer in _each_node():
		var storyline: StorylineDocument = StorylineDocument.new("main", _history)
		var node: InspectableNode = storyline.create_node(indexer.name)
		if not _has_input_port(node):
			continue

		var start: InspectableNode = storyline.create_node("root")
		storyline.add_connection(
			NodeConnection.create(
				start.get_id(), "root", node.get_id(), node.get_main_property().name
			)
		)

		var terminal: bool = StorylineDocument.is_terminal_by_design(node)
		var nothing_to_come_back_through: bool = (
			storyline.find_terminations(start.get_id()).is_empty()
		)
		assert_bool(nothing_to_come_back_through).override_failure_message(
			"'%s' is %sterminal by design, and find_terminations disagrees."
			% [indexer.name, "" if terminal else "not "]
		).is_equal(terminal)


func test_a_section_grows_one_exit_per_place_its_chain_runs_out() -> void:
	# Walked from the section's root, which is where playing one begins.
	var section: StorylineDocument = StorylineDocument.new("detour", _history)
	var start: InspectableNode = section.create_node("root")
	var sentence: InspectableNode = section.create_node("sentence")
	section.add_connection(
		NodeConnection.create(start.get_id(), "root", sentence.get_id(), "sentence")
	)

	var exits: Array[InspectableNode] = section.find_terminations(start.get_id())
	assert_int(exits.size()).is_equal(1)
	assert_str(exits[0].get_id()).is_equal(sentence.get_id())

	# An End stops the story rather than handing it back, so the chain grows no exit.
	var ending: InspectableNode = section.create_node("end")
	section.add_connection(
		NodeConnection.create(sentence.get_id(), "sentence", ending.get_id(), "end")
	)

	assert_array(section.find_terminations(start.get_id())).is_empty()

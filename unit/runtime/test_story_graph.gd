extends GdUnitTestSuite

## The runtime reading what the editor writes.
##
## Every case here goes through a real project and a real file: the point is not that the
## builder works on hand-made dictionaries, it is that the two halves agree on a format
## neither of them owns. A test that built the JSON by hand would keep passing after the
## editor changed what it writes.

var _project: MonologueProject
var _path: String


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_path = "%s/story_%d.mnlp" % [create_temp_dir("mnlp"), randi()]
	_project = auto_free(MonologueProject.new())
	await _project.ready


func after_test() -> void:
	MonologueRegistry.reset_instance()


## Saves the project and reads it back the way a game would.
func _round_trip() -> MonologueStoryGraph:
	ProjectWriter.write_project(_project, _path)
	return MonologueStoryGraph.of(MonologueSource.open(_path))


func _storyline() -> StorylineDocument:
	return _project.storylines[0]


func _node_of_type(storyline: StorylineDocument, type_name: String) -> InspectableNode:
	for node: InspectableNode in storyline.nodes:
		if node.get_type() == type_name:
			return node
	return null


func test_a_saved_storyline_projects_whole() -> void:
	var storyline: StorylineDocument = _storyline()
	var root: InspectableNode = _node_of_type(storyline, "root")
	var sentence: InspectableNode = _node_of_type(storyline, "sentence")
	var narrator: String = str(_project.get_collection_value("characters")[0]["id"])

	var graph: MonologueStoryGraph = _round_trip()

	assert_int(graph.nodes.size()).is_equal(storyline.nodes.size())
	for node: InspectableNode in storyline.nodes:
		assert_str(graph.type_of(node.get_id())).is_equal(node.get_type())
		assert_str(graph.storyline_of(node.get_id())).is_equal(storyline.id)

	assert_str(graph.entry_of(storyline.id)).is_equal(root.get_id())
	assert_array(graph.successors(root.get_id(), "root")).contains([sentence.get_id()])
	assert_array(graph.sources(sentence.get_id(), "sentence")).is_not_empty()
	assert_array(graph.languages).contains(["en"])
	assert_str(str(graph.record("characters", narrator).get("name"))).is_equal("Narrator")

	# Editor bookkeeping stops at the door; the node's own id is the author's data.
	var props: Dictionary = graph.props(root.get_id())
	assert_bool(props.has("$type")).is_false()
	assert_bool(props.has("_editor_settings")).is_false()
	assert_bool(props.has("id")).is_true()

	# Asking about something nobody wrote answers empty rather than raising.
	assert_array(graph.successors("nobody", "nothing")).is_empty()
	assert_dict(graph.record("characters", "character-GONE")).is_empty()


func test_a_folder_reads_the_same_as_an_archive() -> void:
	ProjectWriter.write_project(_project, _path)
	var from_archive: MonologueStoryGraph = MonologueStoryGraph.of(
		MonologueSource.open(_path)
	)

	var folder: String = "%s/unpacked_%d" % [create_temp_dir("mnlp_dir"), randi()]
	_project.compact = false
	ProjectWriter.write_project(_project, folder)
	var from_folder: MonologueStoryGraph = MonologueStoryGraph.of(
		MonologueSource.open(folder)
	)

	assert_int(from_folder.nodes.size()).is_equal(from_archive.nodes.size())
	assert_str(from_folder.entry_storyline).is_equal(from_archive.entry_storyline)


func test_a_story_the_addon_cannot_play_is_reported_not_raised() -> void:
	var missing: MonologueSource = MonologueSource.open("res://nowhere/story.mnlp")
	assert_bool(missing.is_readable).is_false()
	assert_str(String(missing.problems[0].code)).is_equal("story_not_found")

	ProjectWriter.write_project(_project, _path)
	_project.manifest.get_property("format_version").set_value(
		MonologueSource.SUPPORTED_FORMAT_VERSION + 1
	)
	ProjectWriter.write_project(_project, _path)

	var newer: MonologueSource = MonologueSource.open(_path)
	assert_bool(newer.is_readable).is_false()
	assert_str(String(newer.problems[0].code)).is_equal("future_format")


func test_the_addon_reaches_for_nothing_the_editor_owns() -> void:
	# The guarantee that a game can play a story with Monologue not installed, and what keeps
	# the editor's own loading being able to route through the addon without entangling it.
	#
	# Two constants are held together here rather than shared, because the addon cannot read
	# the editor's: the external sub-port prefix, and the format version the two agree on.
	assert_str(MonologueStoryGraph.EXTERNAL_PREFIX).is_equal(NodeConnection.EXTERNAL_PREFIX)
	assert_int(MonologueSource.SUPPORTED_FORMAT_VERSION).override_failure_message(
		"The addon reads up to format %d while the editor writes %d."
		% [MonologueSource.SUPPORTED_FORMAT_VERSION, ManifestDocument.FORMAT_VERSION]
	).is_equal(ManifestDocument.FORMAT_VERSION)

	var owned: PackedStringArray = [
		"ProjectManager", "EventBus", "Log.", "ConfigManager", "App.",
		"ValidationResult", "ValidationIssue", "MonologueProject.", "InspectableObject",
	]

	for file_name: String in ["monologue_source.gd", "monologue_story_graph.gd", "monologue_text.gd"]:
		var source: String = FileAccess.get_file_as_string(
			"res://addons/monologue/reader/".path_join(file_name)
		)
		assert_str(source).override_failure_message(
			"'%s' could not be read, so this check proves nothing." % file_name
		).is_not_empty()

		for singleton: String in owned:
			assert_bool(source.contains(singleton)).override_failure_message(
				"'%s' reaches for '%s'; it must not." % [file_name, singleton]
			).is_false()


func test_a_sub_port_and_a_name_both_survive_into_the_graph() -> void:
	# What a choice behaviour reads: each stored option's id is the item id on the wire
	# leaving it, so answering with that id leads where it should.
	var storyline: StorylineDocument = _storyline()
	var choice: InspectableNode = _node_of_type(storyline, "choice")
	var option_node: InspectableNode = _node_of_type(storyline, "option")
	var target: InspectableNode = storyline.create_node("sentence")
	var option_id: String = str((choice.get_property_value("choices") as Array)[0]["id"])
	storyline.add_connection(
		NodeConnection.create(choice.get_id(), "choices", target.get_id(), "sentence", option_id)
	)

	# How a jump finds a waypoint: the editor stores the name, not an id. UniqueRule never
	# fires for node labels, so finding both of a pair is what lets WaypointNode say so
	# rather than one jump quietly going astray.
	for _twin: int in 2:
		storyline.create_node("waypoint").get_property("label").set_value("same")

	var graph: MonologueStoryGraph = _round_trip()

	assert_array(graph.successors(choice.get_id(), "choices", option_id)).contains(
		[target.get_id()]
	)
	var wired: Array = graph.sources(choice.get_id(), "choices")
	assert_int(wired.size()).is_equal(1)
	assert_str(str(wired[0]["node"])).is_equal(option_node.get_id())

	assert_int(graph.find_by(storyline.id, "label", "same").size()).is_equal(2)
	assert_array(graph.find_by(storyline.id, "label", "nowhere")).is_empty()

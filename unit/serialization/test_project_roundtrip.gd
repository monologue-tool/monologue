extends GdUnitTestSuite

## Saving and loading is the only irreversible thing Monologue does. Everything here works
## on real .mnlp archives and real folders in a temp directory.

var _project: MonologueProject
var _path: String


func before_test() -> void:
	_path = "%s/roundtrip_%d.mnlp" % [create_temp_dir("mnlp"), randi()]
	_project = auto_free(MonologueProject.new())
	await _project.ready


func _save() -> ValidationResult:
	return ProjectWriter.write_project(_project, _path)


func _load() -> MonologueProject:
	var loaded: MonologueProject = await MonologueProject.from_path(_path)
	if loaded:
		auto_free(loaded)
	return loaded


func _write_raw(archive_path: String, entries: Dictionary) -> void:
	var writer: ZIPPacker = ZIPPacker.new()
	writer.open(archive_path, ZIPPacker.APPEND_CREATE)
	for entry_path: String in entries:
		writer.start_file(entry_path)
		writer.write_file(str(entries[entry_path]).to_utf8_buffer())
		writer.close_file()
	writer.close()


func _wire_count(project: MonologueProject) -> int:
	var wires: int = 0
	for node: InspectableNode in project.storylines[0].nodes:
		for property: Property in node.get_properties():
			wires += property.connected_to.size()
	return wires


func test_a_project_comes_back_whole() -> void:
	_project.manifest.set_property_value("author", "Atomic Junky")
	_project.storylines[0].nodes[0].get_property("notes").set_settings_value(
		PropertySettings.KEY_EXPOSED, true
	)
	var node_ids: Array[String] = []
	for node: InspectableNode in _project.storylines[0].nodes:
		node_ids.append(node.get_id())
	var wires: int = _wire_count(_project)
	assert_int(wires).override_failure_message(
		"The default storyline should come pre-wired; this test proves nothing otherwise."
	).is_greater(0)

	assert_bool(_save().is_valid()).is_true()
	var loaded: MonologueProject = await _load()

	assert_object(loaded).is_not_null()
	assert_int(loaded.collections.size()).is_equal(_project.collections.size())
	assert_str(loaded.manifest.get_property_value("author")).is_equal("Atomic Junky")
	assert_int(loaded.manifest.get_property_value("format_version")).is_equal(
		ManifestDocument.FORMAT_VERSION
	)

	var loaded_ids: Array[String] = []
	for node: InspectableNode in loaded.storylines[0].nodes:
		loaded_ids.append(node.get_id())
	assert_array(loaded_ids).contains_exactly_in_any_order(node_ids)
	assert_int(_wire_count(loaded)).is_equal(wires)

	# The user's own settings ride along beside the values.
	assert_bool(
		loaded.storylines[0].get_node(node_ids[0]).get_property("notes").get_settings_value(
			PropertySettings.KEY_EXPOSED, false
		)
	).is_true()


func test_a_project_saved_as_a_folder_comes_back_the_same() -> void:
	# The unpacked form is what makes a project diffable, so it has to survive the same trip
	# the archive does. DirAccess.get_files() only ever listed the top level, which is why a
	# folder used to load with its manifest and nothing else.
	var folder: String = "%s/unpacked_%d" % [create_temp_dir("mnlp_dir"), randi()]
	_project.compact = false

	assert_bool(ProjectWriter.write_project(_project, folder).is_valid()).is_true()
	var source: MonologueSource = MonologueSource.open(folder)
	assert_bool(source.is_archive).is_false()
	assert_dict(source.manifest()).is_not_empty()
	assert_array(source.storylines().keys()).contains(["main"])

	var loaded: MonologueProject = await MonologueProject.from_path(folder)
	assert_object(loaded).is_not_null()
	auto_free(loaded)

	assert_bool(loaded.compact).is_false()
	assert_int(loaded.storylines.size()).is_equal(_project.storylines.size())
	assert_int(loaded.storylines[0].nodes.size()).is_equal(_project.storylines[0].nodes.size())


func test_saving_again_replaces_the_file_rather_than_growing_it() -> void:
	# ZIPPacker opened with APPEND_CREATE appends to an existing file, so every save used to
	# add another copy of every document to the same zip.
	_save()
	var first_size: int = FileAccess.get_file_as_bytes(_path).size()

	_project.manifest.set_property_value("author", "second pass")
	_save()

	assert_int(FileAccess.get_file_as_bytes(_path).size()).is_between(first_size-20, first_size+20)
	assert_bool(FileAccess.file_exists(_path + ProjectWriter.TEMP_SUFFIX)).is_false()
	assert_bool(FileAccess.file_exists(_path + ProjectWriter.BACKUP_SUFFIX)).is_false()

	var loaded: MonologueProject = await _load()
	assert_str(loaded.manifest.get_property_value("author")).is_equal("second pass")


func test_one_damaged_document_does_not_cost_the_rest_of_the_project() -> void:
	# The whole point of reporting instead of raising.
	_write_raw(
		_path,
		{
			"manifest.mnlf": JSON.stringify(_project.manifest._to_dict()),
			"collections/characters.mnlf": JSON.stringify(
				_project.get_collection("characters")._to_dict()
			),
			"storylines/main.mnlf": "{{{ truncated",
		}
	)

	var loaded: MonologueProject = await _load()

	assert_object(loaded).is_not_null()
	assert_array(loaded.load_issues.with_code(&"unreadable_json")).is_not_empty()
	assert_int(loaded.storylines.size()).is_equal(0)
	assert_object(loaded.get_collection("characters")).is_not_null()

	# What is not a JSON object at all is named rather than guessed at, and a project with
	# no manifest is not a project.
	var shapes: ValidationResult = ValidationResult.ok()
	assert_dict(ProjectReader.parse_object("{not json", "broken.json", shapes)).is_empty()
	assert_array(shapes.with_code(&"unreadable_json")).is_not_empty()
	ProjectReader.parse_object("[1, 2, 3]", "list.json", shapes)
	assert_array(shapes.with_code(&"unexpected_json_shape")).is_not_empty()

	var headless: String = "%s/headless.mnlp" % create_temp_dir("mnlp")
	_write_raw(headless, {"storylines/main.mnlf": "{}"})
	assert_object(await MonologueProject.from_path(headless)).is_null()


func test_a_node_this_editor_cannot_build_is_reported_and_left_out() -> void:
	var storyline: StorylineDocument = _project.storylines[0]
	var data: Dictionary = storyline._to_dict()
	var nodes: Array = data["nodes"]
	nodes.append({"$type": "teleporter", "id": "teleporter-XYZ"})
	nodes.append({"id": "nameless-XYZ"})

	storyline._from_dict(data)

	var codes: Array[StringName] = []
	for issue: ValidationIssue in storyline.load_issues:
		codes.append(issue.code)
	assert_array(codes).contains([&"unknown_node_type", &"node_without_type"])
	assert_object(storyline.get_node("teleporter-XYZ")).is_null()


func test_a_file_from_another_version_of_monologue_is_refused_by_name() -> void:
	# A manifest predating the field is treated as current: it was written before the
	# format started counting.
	var manifest: Dictionary = _project.manifest._to_dict()
	manifest.erase("format_version")
	assert_int(ProjectReader.read_format_version(manifest)).is_equal(
		ManifestDocument.FORMAT_VERSION
	)

	for case: Array in [[1, &"future_format"], [-1, &"unsupported_format"]]:
		var stamped: Dictionary = _project.manifest._to_dict()
		stamped["format_version"] = ManifestDocument.FORMAT_VERSION + (case[0] as int)
		var path: String = "%s/versioned_%d.mnlp" % [create_temp_dir("mnlp"), case[0]]
		_write_raw(path, {"manifest.mnlf": JSON.stringify(stamped)})

		var result: ValidationResult = ValidationResult.ok()
		var probe: MonologueProject = auto_free(MonologueProject.new())
		await probe.ready
		var is_usable: bool = ProjectReader.read_into(
			probe, MonologueSource.open(path), result
		)

		assert_bool(is_usable).override_failure_message(
			"A file %d version away was accepted." % case[0]
		).is_false()
		assert_array(result.with_code(case[1] as StringName)).is_not_empty()


func test_a_renamed_storyline_does_not_leave_the_one_it_used_to_be_behind() -> void:
	# A folder is written in place, so nothing takes away a file that stopped being written.
	# Left alone, renaming would read back as two storylines: the new one, and the old one
	# still sitting there under its old name.
	var folder: String = "%s/unpacked" % create_temp_dir("tree")
	_project.compact = false
	_project.add_new_storyline()
	assert_bool(ProjectWriter.write_project(_project, folder).is_valid()).is_true()

	var renamed: StorylineDocument = _project.storylines[1]
	assert_bool(_project.rename_storyline(renamed, "chapter_two")).is_true()
	assert_bool(ProjectWriter.write_project(_project, folder).is_valid()).is_true()

	var written: PackedStringArray = DirAccess.get_files_at(
		folder.path_join(MonologueSource.STORYLINES)
	)
	assert_int(written.size()).override_failure_message(
		"The folder holds %s; the storyline it used to be was left behind." % str(written)
	).is_equal(2)
	assert_array(written).contains(["chapter_two.mnlf"])

	var loaded: MonologueProject = await MonologueProject.from_path(folder)
	auto_free(loaded)
	assert_int(loaded.storylines.size()).is_equal(2)


func test_a_name_another_document_already_has_is_refused_rather_than_made_unique() -> void:
	# Two documents of one name write to one file, and whichever went second would be all
	# there was left of the two.
	var storyline: StorylineDocument = _project.storylines[0]
	var was: String = storyline.name

	assert_bool(_project.rename_storyline(storyline, "characters")).override_failure_message(
		"A storyline took the name of a collection."
	).is_false()
	assert_bool(_project.rename_storyline(storyline, "   ")).is_false()
	assert_str(storyline.name).is_equal(was)

	_project.add_new_storyline()
	assert_bool(
		_project.rename_storyline(_project.storylines[1], was)
	).override_failure_message("Two storylines ended up with one name.").is_false()

	assert_bool(_project.rename_storyline(storyline, "prologue")).is_true()
	assert_str(storyline.name).is_equal("prologue")
	assert_bool(_project.is_dirty).is_true()

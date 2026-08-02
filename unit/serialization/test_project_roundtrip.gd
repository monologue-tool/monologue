# gdlint: disable=max-public-methods
extends GdUnitTestSuite

## Saving and loading is the only irreversible thing Monologue does, so it gets the
## most tests. Everything here works on real .mnlp archives in a temp directory.

var _project: MonologueProject
var _path: String


func before_test() -> void:
	_path = "%s/roundtrip_%d.mnlp" % [create_temp_dir("mnlp"), randi()]
	_project = auto_free(MonologueProject.new())
	await _project.ready


func _save() -> ValidationResult:
	return ProjectWriter.write_project(_project, _path)


func _load() -> MonologueProject:
	var loaded: MonologueProject = await MonologueProject.from_file_path(_path)
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


func test_a_saved_project_can_be_read_back() -> void:
	assert_bool(_save().is_valid()).is_true()

	var loaded: MonologueProject = await _load()

	assert_object(loaded).is_not_null()
	assert_int(loaded.storylines.size()).is_equal(_project.storylines.size())
	assert_int(loaded.collections.size()).is_equal(_project.collections.size())


func test_property_values_survive_the_trip() -> void:
	_project.manifest.set_property_value("author", "Atomic Junky")
	_project.manifest.set_property_value("description", "A test project.")
	_save()

	var loaded: MonologueProject = await _load()

	assert_str(loaded.manifest.get_property_value("author")).is_equal("Atomic Junky")
	assert_str(loaded.manifest.get_property_value("description")).is_equal("A test project.")


func test_nodes_survive_the_trip() -> void:
	var storyline: StorylineDocument = _project.storylines[0]
	var original_ids: Array[String] = []
	for node: InspectableNode in storyline.nodes:
		original_ids.append(node.get_id())
	_save()

	var loaded: MonologueProject = await _load()

	var loaded_ids: Array[String] = []
	for node: InspectableNode in loaded.storylines[0].nodes:
		loaded_ids.append(node.get_id())
	assert_array(loaded_ids).contains_exactly_in_any_order(original_ids)


func test_connections_survive_the_trip() -> void:
	var storyline: StorylineDocument = _project.storylines[0]
	var connected: int = 0
	for node: InspectableNode in storyline.nodes:
		for property: Property in node.get_properties():
			connected += property.connected_to.size()
	assert_int(connected).override_failure_message(
		"The default storyline should come pre-wired; this test proves nothing otherwise."
	).is_greater(0)
	_save()

	var loaded: MonologueProject = await _load()

	var loaded_connected: int = 0
	for node: InspectableNode in loaded.storylines[0].nodes:
		for property: Property in node.get_properties():
			loaded_connected += property.connected_to.size()
	assert_int(loaded_connected).is_equal(connected)


func test_user_setting_overrides_survive_the_trip() -> void:
	var node: InspectableNode = _project.storylines[0].nodes[0]
	node.get_property("notes").set_settings_value(PropertySettings.KEY_EXPOSED, true)
	_save()

	var loaded: MonologueProject = await _load()

	var loaded_node: InspectableNode = loaded.storylines[0].get_node(node.get_id())
	assert_bool(
		loaded_node.get_property("notes").get_settings_value(PropertySettings.KEY_EXPOSED, false)
	).is_true()


func test_saving_twice_does_not_grow_the_archive() -> void:
	# ZIPPacker opened with APPEND_CREATE appends to an existing file, so every save
	# used to add another copy of every document to the same zip.
	_save()
	var first_size: int = FileAccess.get_file_as_bytes(_path).size()

	_save()
	var second_size: int = FileAccess.get_file_as_bytes(_path).size()

	assert_int(second_size).is_equal(first_size)


func test_saving_leaves_no_temporary_files_behind() -> void:
	_save()

	assert_bool(FileAccess.file_exists(_path + ProjectWriter.TEMP_SUFFIX)).is_false()
	assert_bool(FileAccess.file_exists(_path + ProjectWriter.BACKUP_SUFFIX)).is_false()


func test_a_second_save_replaces_rather_than_accumulates_documents() -> void:
	_save()
	_project.manifest.set_property_value("author", "second pass")
	_save()

	var loaded: MonologueProject = await _load()

	assert_str(loaded.manifest.get_property_value("author")).is_equal("second pass")


func test_malformed_json_is_reported_instead_of_crashing() -> void:
	var result: ValidationResult = ValidationResult.ok()

	var data: Dictionary = ProjectReader.parse_object("{not json", "broken.json", result)

	assert_dict(data).is_empty()
	assert_array(result.with_code(&"unreadable_json")).is_not_empty()


func test_json_that_is_not_an_object_is_reported() -> void:
	var result: ValidationResult = ValidationResult.ok()

	ProjectReader.parse_object("[1, 2, 3]", "list.json", result)

	assert_array(result.with_code(&"unexpected_json_shape")).is_not_empty()


func test_a_project_without_a_manifest_is_refused_cleanly() -> void:
	_write_raw(_path, {"storylines/main.json": "{}"})

	assert_object(await _load()).is_null()


func test_a_corrupt_storyline_does_not_stop_the_project_loading() -> void:
	# The whole point of reporting instead of raising: one damaged document must not
	# cost the user the rest of the project.
	_write_raw(
		_path,
		{
			"manifest.json": JSON.stringify(_project.manifest._to_dict()),
			"collections/characters.json": JSON.stringify(
				_project.get_collection("characters")._to_dict()
			),
			"storylines/main.json": "{{{ truncated",
		}
	)

	var loaded: MonologueProject = await _load()

	assert_object(loaded).is_not_null()
	assert_array(loaded.load_issues.with_code(&"unreadable_json")).is_not_empty()
	assert_int(loaded.storylines.size()).is_equal(0)
	# The collection that was fine came through untouched.
	assert_object(loaded.get_collection("characters")).is_not_null()


func test_an_unknown_node_type_is_reported_and_skipped() -> void:
	var storyline: StorylineDocument = _project.storylines[0]
	var data: Dictionary = storyline._to_dict()
	var nodes: Array = data["nodes"]
	nodes.append({"$type": "teleporter", "id": "teleporter-XYZ"})

	storyline._from_dict(data)

	assert_array(
		storyline.load_issues.filter(
			func(issue: ValidationIssue) -> bool: return issue.code == &"unknown_node_type"
		)
	).is_not_empty()
	assert_object(storyline.get_node("teleporter-XYZ")).is_null()


func test_a_node_without_a_type_is_reported() -> void:
	var storyline: StorylineDocument = _project.storylines[0]
	var data: Dictionary = storyline._to_dict()
	var nodes: Array = data["nodes"]
	nodes.append({"id": "nameless-XYZ"})

	storyline._from_dict(data)

	assert_array(
		storyline.load_issues.filter(
			func(issue: ValidationIssue) -> bool: return issue.code == &"node_without_type"
		)
	).is_not_empty()


func test_the_manifest_records_the_format_version() -> void:
	assert_int(_project.manifest.get_property_value("format_version")).is_equal(
		ManifestDocument.FORMAT_VERSION
	)

	_save()
	var loaded: MonologueProject = await _load()

	assert_int(loaded.manifest.get_property_value("format_version")).is_equal(
		ManifestDocument.FORMAT_VERSION
	)


func test_a_file_from_a_newer_monologue_is_refused_with_an_explanation() -> void:
	var manifest_data: Dictionary = _project.manifest._to_dict()
	manifest_data["format_version"] = ManifestDocument.FORMAT_VERSION + 1
	_write_raw(_path, {"manifest.json": JSON.stringify(manifest_data)})

	var result: ValidationResult = ValidationResult.ok()
	var probe: MonologueProject = auto_free(MonologueProject.new())
	await probe.ready
	var reader: ZIPReader = ZIPReader.new()
	reader.open(_path)
	var is_usable: bool = ProjectReader.read_into(probe, reader, result)
	reader.close()

	assert_bool(is_usable).is_false()
	assert_array(result.with_code(&"future_format")).is_not_empty()


func test_a_file_from_an_unsupported_older_format_is_refused() -> void:
	var manifest_data: Dictionary = _project.manifest._to_dict()
	manifest_data["format_version"] = 1
	_write_raw(_path, {"manifest.json": JSON.stringify(manifest_data)})

	var result: ValidationResult = ValidationResult.ok()
	var probe: MonologueProject = auto_free(MonologueProject.new())
	await probe.ready
	var reader: ZIPReader = ZIPReader.new()
	reader.open(_path)
	var is_usable: bool = ProjectReader.read_into(probe, reader, result)
	reader.close()

	assert_bool(is_usable).is_false()
	assert_array(result.with_code(&"unsupported_format")).is_not_empty()


func test_a_manifest_predating_the_version_field_is_treated_as_current() -> void:
	var manifest_data: Dictionary = _project.manifest._to_dict()
	manifest_data.erase("format_version")

	assert_int(ProjectReader.read_format_version(manifest_data)).is_equal(
		ManifestDocument.FORMAT_VERSION
	)

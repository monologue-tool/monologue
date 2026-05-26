extends Node

@warning_ignore_start("unused_signal")
signal load_project(path: String)
signal test_trigger

signal refresh
signal add_graph_node(descriptor_name: String, window: Window)
signal request_node_selection(node: InspectableNode, storyline_id: String, skip_history: bool)
signal request_object_inspection(object: InspectableObject)
signal request_storyline_inspection(storyline: StorylineDocument)
signal select_new_node
signal inspector_property_changed(object: InspectableObject, property_name: String, is_undo: bool)

signal save_file_request(callable: Callable, filter_list: PackedStringArray, root_subdir: String, options: Array[Dictionary])
signal open_file_request(callable: Callable, filter_list: PackedStringArray, root_subdir: String, options: Array[Dictionary])
signal open_files_request(callable: Callable, filter_list: PackedStringArray, root_subdir: String, options: Array[Dictionary])
signal open_dir_request(callable: Callable, root_subdir: String, options: Array[Dictionary])

signal load_languages(languages: Array, graph: MonologueGraphEdit)
signal show_languages(can_see: bool)
signal enable_language_switcher
signal disable_language_switcher
signal language_deleted

signal show_welcome
signal hide_welcome
signal enable_picker_mode(
	node: GraphNode, port: int, release: Vector2, graph_release: Vector2, center: Vector2
)
signal show_inspector(visible: bool)
signal show_project_explorer(visible: bool)
signal show_console(visible: bool)
signal graph_snap(enabled: bool)
signal graph_show_grid(visible: bool)

signal expand_text_edit(text_edit: TextEdit)
signal show_dimmer
signal hide_dimmer

signal window_out
signal ask_dialog(callback: Callable, header: String, description: String, confirm_text: String, deny_text: String, cancel_text: String)

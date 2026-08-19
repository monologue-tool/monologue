extends Node

@warning_ignore_start("unused_signal")
signal load_project(path: String)
signal test_trigger

signal refresh
signal refresh_graph
signal add_graph_node(descriptor_name: String, window: Window)
## Selections travel as Array[InspectableObject] everywhere, even when they only hold
## nodes: GDScript typed arrays are invariant, so mixing the two element types means a
## conversion at every boundary.
signal request_nodes_selection(
	nodes: Array[InspectableObject], storyline_id: String, skip_history: bool
)
signal request_objects_inspection(objects: Array[InspectableObject])
signal request_storyline_inspection(storyline: StorylineDocument)
signal select_new_node
## A document was added or renamed, so anything drawing the tree is out of date.
signal storylines_changed
signal storyline_deleted

signal save_file_request(
	callable: Callable,
	filter_list: PackedStringArray,
	root_subdir: String,
	options: Array[Dictionary]
)
signal open_file_request(
	callable: Callable,
	filter_list: PackedStringArray,
	root_subdir: String,
	options: Array[Dictionary]
)
signal open_files_request(
	callable: Callable,
	filter_list: PackedStringArray,
	root_subdir: String,
	options: Array[Dictionary]
)
signal open_dir_request(callable: Callable, root_subdir: String, options: Array[Dictionary])

signal load_languages(languages: Array, graph: MonologueGraphEdit)
signal show_languages(can_see: bool)
signal enable_language_switcher
signal disable_language_switcher
signal language_deleted

signal show_welcome
signal hide_welcome
## Opens the window listing every translatable line in the project.
signal open_localization
## Opens the node picker. [param node] is a graph view name, empty when the picker was
## not dragged out of a port. The three positions are null in that case, and
## [param center_window] puts the picker in the middle of the screen instead.
signal enable_picker_mode(
	node: String,
	port: int,
	release: Variant,
	graph_release: Variant,
	center: Variant,
	center_window: bool
)
signal show_inspector(visible: bool)
signal show_project_explorer(visible: bool)
signal show_console(visible: bool)
signal show_status_bar(visible: bool)
signal graph_snap(enabled: bool)
signal graph_show_grid(visible: bool)

signal expand_text_edit(text_edit: TextEdit)
signal show_dimmer
signal hide_dimmer

signal window_out
signal ask_dialog(
	callback: Callable,
	header: String,
	description: String,
	confirm_text: String,
	deny_text: String,
	cancel_text: String
)

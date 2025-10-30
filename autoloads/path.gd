## Path manipulation utilities singleton.
##
## Provides cross-platform path manipulation functions for converting between
## absolute and relative paths, and handling path separators correctly across
## different operating systems.
extends Node


## Returns the appropriate path separator for the current platform.
##
## Returns "\\" for Windows systems, "/" for all other systems.
func get_separator() -> String:
	return "\\" if OS.has_feature("windows") else "/"


## Splits a file path into its directory components.
##
## Normalizes path separators to forward slashes and splits on them.
## Removes the file name from the path before splitting.
## [br][br]
## [param path] The file path to split.
## [br][br]
## Returns an array of directory names in the path.
func split_path(path: String) -> PackedStringArray:
	var splt_path: String = path.replace(path.get_file(), "")
	splt_path = splt_path.replace("\\", "/")
	splt_path = splt_path.replace("//", "/")
	return splt_path.split("/", false)


## Converts an absolute path to a relative path based on a root file location.
##
## Calculates the relative path from the root file's directory to the target path.
## Uses ".." for parent directory navigation as needed.
## [br][br]
## [param path] The absolute path to convert to relative.
## [br][br]
## [param root_file_path] The absolute path of the root/reference file.
## [br][br]
## Returns the relative path from root to target, or the original path if conversion is not possible.
func absolute_to_relative(path: String, root_file_path: String) -> String:
	var root_array: PackedStringArray = split_path(root_file_path)
	var path_array: PackedStringArray = split_path(path)
	if not path.is_absolute_path() or root_array.size() <= 0 or root_array[0] != path_array[0]:
		return path
	var back = []
	var forward = []
	var max_path_size = max(root_array.size(), path_array.size())
	for i in max_path_size:
		var root_index = root_array[i] if i < root_array.size() else ""
		var path_index = path_array[i] if i < path_array.size() else ""
		if root_index == path_index:
			continue
		if root_index:
			back.append("..")
		if path_index:
			forward.append(path_index)
	var final_path = back + forward
	final_path.append(path.get_file())
	var relative_path = ""
	for step in final_path:
		relative_path = relative_path.path_join(step)
	return relative_path


## Converts a relative path to an absolute path based on a root file location.
##
## Resolves a relative path (including ".." parent references) into an absolute path
## using the root file's directory as the starting point. Handles Windows drive letters
## and Unix-style root paths correctly.
## [br][br]
## [param path] The relative path to convert to absolute.
## [br][br]
## [param root_file_path] The absolute path of the root/reference file.
## [br][br]
## Returns the absolute path, or the original path if it's already absolute.
func relative_to_absolute(path: String, root_file_path: String) -> String:
	if path.is_absolute_path():
		return path
	var root_array: PackedStringArray = split_path(root_file_path)
	var path_array: PackedStringArray = split_path(path)
	var back_count = path.count("..")
	var core_path = Array(root_array).slice(0, root_array.size() - back_count)
	var to_file = Array(path_array).slice(back_count)
	var final_path = Array(core_path) + to_file
	final_path.append(path.get_file())
	var absolute_path = ""
	for step in final_path:
		absolute_path = absolute_path.path_join(step)
	# Prepend "/" for Linux root if not a Windows drive letter
	var drive_matcher = RegEx.new()
	drive_matcher.compile("[a-zA-Z]:")
	var drive_result = root_array.size() > 0 and drive_matcher.search(root_array[0])
	if not drive_result:
		absolute_path = "/" + absolute_path
	return absolute_path

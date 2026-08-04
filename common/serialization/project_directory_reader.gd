## Presents an unpacked project folder the way [ZIPReader] presents an archive, so
## [ProjectReader] reads either without knowing which one it was handed.
##
## [method DirAccess.get_files] lists one directory and returns bare names, which is why
## a folder used to load with its manifest and nothing else: every collection and every
## storyline sits one level down.
class_name ProjectDirectoryReader extends RefCounted

var _root: String = ""


func _init(root: String) -> void:
	_root = root


## Every file under the folder, as paths relative to it, the way an archive lists its
## entries.
func get_files() -> PackedStringArray:
	var files: PackedStringArray = []
	_collect("", files)
	return files


func file_exists(path: String) -> bool:
	return FileAccess.file_exists(_root.path_join(path))


func read_file(path: String) -> PackedByteArray:
	var file: FileAccess = FileAccess.open(_root.path_join(path), FileAccess.READ)
	if file == null:
		return PackedByteArray()
	return file.get_buffer(file.get_length())


func _collect(relative: String, files: PackedStringArray) -> void:
	var directory: DirAccess = DirAccess.open(_root.path_join(relative))
	if directory == null:
		return

	for file_name: String in directory.get_files():
		files.append(relative.path_join(file_name))
	for directory_name: String in directory.get_directories():
		_collect(relative.path_join(directory_name), files)

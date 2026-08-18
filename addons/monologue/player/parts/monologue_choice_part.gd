@abstract class_name MonologueChoicePart extends Control

@warning_ignore("unused_signal")
signal option_picked

var picked: String = ""


## [param options] is [{"key", "text", "speaker", "one_shot"}], in the order the author wrote
## them. A part ignoring a key it has never seen still works.
@abstract func show_options(options: Array[Dictionary]) -> void
@abstract func clear() -> void

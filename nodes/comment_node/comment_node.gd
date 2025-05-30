@icon("res://ui/assets/icons/comment.svg")
class_name CommentNode extends MonologueGraphNode


@onready var comment_edit = $CommentEdit


func _ready() -> void:
	node_type = "NodeComment"
	super._ready()


func _from_dict(dict: Dictionary) -> void:
	comment_edit.text = dict.get("Comment")
	super._from_dict(dict)


func _to_fields(dict: Dictionary) -> void:
	super._to_fields(dict)
	dict["Comment"] = comment_edit.text

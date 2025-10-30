## Abstract base class for storyline objects that can be positioned.
##
## Extends InspectableObject to add position tracking for objects that
## exist in a 2D space within the storyline (e.g., positioned in a graph view).
@abstract
class_name InspectableStorylineObject extends InspectableObject


## Initializes the storyline object with a position property.
func _init() -> void:
	define_property("position", Vector2.ZERO, "vector2", {})
	super._init()


## Builds and returns preview controls for displaying this object in the graph.
##
## Must be implemented by subclasses to provide their visual representation.
## [br][br]
## Returns an array of Control nodes for preview display.
@abstract func build_graph_preview() -> Array[Control]

## Structures a before/after change in a node's property.
class_name PropertyChange
extends RefCounted

## Name of property/variable to change.
var property: String
## Value before change.
var before: Variant
## Value after change.
var after: Variant


func _init(property_name, old, new):
	property = property_name
	before = old
	after = new

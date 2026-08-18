## Everything a validator is allowed to look at.
##
## Passed to every [ValidationRule] and to every function declared with
## [method Property.validate]. New information goes here rather than into the rule
## signatures, so adding it never touches the existing rules.
class_name ValidationContext extends RefCounted

enum Phase {
	LIVE,  ## The user is typing. The value has NOT been written yet.
	COMMIT,  ## The value was just written.
	AUDIT,  ## A full sweep of the project, on demand or after loading.
}

## The value being judged. During LIVE this is a candidate, not what is stored.
var value: Variant
var property: Property
var object: InspectableObject
var project: MonologueProject
var phase: Phase = Phase.COMMIT


static func for_property(
	target_property: Property,
	target_object: InspectableObject,
	candidate_value: Variant,
	target_phase: Phase = Phase.COMMIT
) -> ValidationContext:
	var context: ValidationContext = ValidationContext.new()
	context.property = target_property
	context.object = target_object
	context.value = candidate_value
	context.phase = target_phase
	return context


## The other items in the same collection as [member object]. Empty when this object
## is not part of one. Used by [UniqueRule].
func siblings() -> Array[InspectableObject]:
	var result: Array[InspectableObject] = []
	if object == null:
		return result
	var parent: InspectableObject = object.get_parent_object()
	if parent == null:
		return result
	for sibling: Variant in parent.get_property_children(object.get_parent_property_name()):
		if sibling is InspectableObject and sibling != object:
			result.append(sibling)
	return result


func setting(key: String, fallback: Variant = null) -> Variant:
	return property.get_settings_value(key, fallback) if property else fallback


## Convenience for building an issue already pinned to where it was found.
func issue_at(issue: ValidationIssue) -> ValidationIssue:
	return issue.at(object, property.name if property else "")

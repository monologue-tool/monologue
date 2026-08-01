## Creates and binds [Field] widgets from field type names.
##
## This is the UI half of the field system: [MonologueRegistry] stays free of Control,
## and everything that instantiates a scene lives here. Nothing under `common/` outside
## `common/ui/` may call this.
class_name FieldWidgetFactory


## Returns a new widget for [param field_name], or null when the type is unknown or is
## a port-only pseudo-type with no editor widget.
static func create(field_name: String) -> Field:
	var indexer: FieldIndexer = MonologueRegistry.get_instance().get_field(field_name)
	if indexer == null:
		return null
	var field: Field = indexer.instantiate() as Field
	if field == null:
		return null
	# Duplicated so that a widget mutating its settings cannot corrupt the type-level
	# defaults shared by every other instance.
	field.settings = indexer.default_settings.duplicate(true)
	return field


## Never returns null: an unknown type degrades to a visible placeholder rather than an
## empty row, so a typo in a property declaration is obvious in the inspector.
static func create_or_placeholder(field_name: String) -> Control:
	var field: Field = create(field_name)
	if field:
		return field
	var warn_label: Label = Label.new()
	warn_label.theme_type_variation = "WarnLabel"
	warn_label.text = "Unknown property type '%s'" % field_name
	return warn_label


## Connects [param property] to every object in [param owners]. One owner is the
## ordinary case; several means the field edits them together, as one undo step.
## An empty list makes the widget detached -- see [method bind_detached].
##
## The field must already be in the tree, since binding immediately pushes the current
## value into it. Use [method bind_deferred] when binding right after add_child().
static func bind(
	property: Property, field: Field, owners: Array[InspectableObject] = []
) -> FieldBinding:
	if not property or not is_instance_valid(field):
		return null
	if not field.is_inside_tree():
		push_warning("Cannot bind '%s': the field is not in the tree yet." % property.name)
		return null
	var indexer: FieldIndexer = MonologueRegistry.get_instance().get_field(property.type)
	if indexer == null:
		push_warning("No field type registered as '%s'." % property.type)
		return null
	var binding: FieldBinding = FieldBinding.new(property, field, indexer, owners)
	binding.initialize()
	return binding


## Binds on the next idle frame, once [param field] has entered the tree.
static func bind_deferred(
	property: Property, field: Field, owners: Array[InspectableObject] = []
) -> void:
	FieldWidgetFactory.bind.call_deferred(property, field, owners)


## Convenience for the common single-object case.
##
## A null owner produces a detached binding, which for a list or collection field means
## it has no children to read and silently shows nothing -- so say something.
static func bind_one(property: Property, field: Field, owner: InspectableObject) -> void:
	var owners: Array[InspectableObject] = []
	if owner:
		owners.append(owner)
	elif property and property.type in ["list", "collection"]:
		push_warning(
			"Binding '%s' with no owner: a %s field needs one to read its items from."
			% [property.name, property.type]
		)
	FieldWidgetFactory.bind_deferred(property, field, owners)


## Binds without any model owner: the widget will never write to an
## [InspectableObject] and never records an undo entry on its own.
##
## Used by [ListField], whose items are throwaway view-model properties -- the parent
## list commits the whole array as one change instead.
static func bind_detached(property: Property, field: Field) -> void:
	FieldWidgetFactory.bind_deferred(property, field, [] as Array[InspectableObject])

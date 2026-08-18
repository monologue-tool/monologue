## Every known Property setting, as a typed KEY_* constant.
class_name PropertySettings

# Display

const KEY_VISIBLE_IN_GRAPH: String = "visible_in_graph"
const KEY_VISIBLE_IN_INSPECTOR: String = "visible_in_inspector"
## Defaults to "General".
const KEY_CATEGORY: String = "category"
## Overrides the label. Falls back to the property name when empty.
const KEY_LABEL: String = "label"
const KEY_TOOLTIP: String = "tooltip"
const KEY_EXPAND: String = "expand"
const KEY_FLAT: String = "flat"

# Editing

## False hides the property entirely, unless it is read-only or has a port.
const KEY_EDITABLE: String = "editable"
## Shown but frozen. Wins over KEY_EDITABLE: a read-only property is always shown.
const KEY_READ_ONLY: String = "read_only"
## Unique among sibling items of the same ListField. Checked on commit.
const KEY_UNIQUE: String = "unique"
## Non-empty and non-zero. Checked on commit.
const KEY_REQUIRED: String = "required"
## Protects the list item carrying this property from deletion.
const KEY_PROTECT: String = "protect"
## Sibling property deciding whether this one may be edited, as
## { "property": String, "values": Array }. Absent when nothing gates it.
const KEY_ENABLED_BY: StringName = &"enabled_by"
## Same shape as KEY_ENABLED_BY, but hides the property instead of greying it out.
const KEY_SHOWN_BY: StringName = &"shown_by"

# Validation

## Field-type rules applied on commit, such as { "min_length": 1, "max_length": 64 }.
const KEY_VALIDATION: StringName = "validation"

# Ports

## Shows the input port, on the left.
const KEY_EXPOSED: StringName = &"exposed"
## Shows the output port, on the right.
const KEY_EXPORT: StringName = &"export"
## Whether the user may toggle the input port from the inspector.
const KEY_EXPOSABLE: StringName = &"exposable"
const KEY_IS_MAIN_PROPERTY: StringName = &"is_main_property"

# Field-type-specific

## (list) Collection to draw items from.
const KEY_COLLECTION: StringName = &"collection"
## (list) Field type of each standard item.
const KEY_ITEM_TYPE: StringName = &"item_type"
## (port) "normal" or "large".
const KEY_PORT_SIZE: StringName = &"port_size"
## (int / float) Declared together with KEY_MAX_VALUE. A number missing either one is
## unbounded and drags freely.
const KEY_MIN_VALUE: StringName = &"min_value"
const KEY_MAX_VALUE: StringName = &"max_value"
## (int / float) Increment between two values, and how many decimals are shown.
const KEY_STEP: StringName = &"step"
## (int / float) True for int, false for float.
const KEY_ROUNDED: StringName = &"rounded"
## (int / float) Unit shown after the number, such as "s" or "dB".
const KEY_SUFFIX: StringName = &"suffix"
## (int / float) Text shown before the number.
const KEY_PREFIX: StringName = &"prefix"
## (dropdown) Static options offered to the user.
const KEY_OPTIONS: StringName = &"options"
## (dropdown) Dynamic options: a collection name, or "self:<property>".
const KEY_SOURCE: StringName = &"source"
## (reference) Where the target may be found. A collection name, "self:<property>",
## "storylines", or "node:<type>". See [ReferenceResolver].
const KEY_REFERENCE_SCOPE: StringName = &"reference_scope"
## (reference) Property of the target read to label it. Defaults to "name".
const KEY_LABEL_PROPERTY: StringName = &"label_property"
## (reference) Whether "nothing selected" is an accepted value.
const KEY_ALLOW_EMPTY: StringName = &"allow_empty"
## (text) Translations keyed by language code, rather than a plain String. On for `text`,
## off for `textarea`, switched per property with [method Property.plain].
const KEY_TRANSLATABLE: StringName = &"translatable"
## (text) Renders a TextEdit instead of a LineEdit.
const KEY_MULTILINE: StringName = &"multiline"
## (text) Ghost text shown while the field is empty.
const KEY_PLACEHOLDER: StringName = &"placeholder"
## (textarea) Visible rows, which set the minimum height.
const KEY_ROWS: StringName = &"rows"
## (dynamic) Sibling property whose value picks the active variant.
const KEY_CASE_PROPERTY: StringName = &"case_property"
## (dynamic) case value -> { type, default, coerce? }.
const KEY_CASES: StringName = &"cases"
## (file) Filters for the file dialog, such as ["*.png", "*.jpg"]. Empty shows all files.
const KEY_FILE_FILTERS: StringName = &"file_filters"

# Defaults

## Field-type-specific keys are left out: they have no meaningful global default.
const DEFAULTS: Dictionary = {
	KEY_VISIBLE_IN_GRAPH: true,
	KEY_VISIBLE_IN_INSPECTOR: true,
	KEY_EDITABLE: true,
	KEY_READ_ONLY: false,
	KEY_EXPOSABLE: true,
	KEY_EXPOSED: false,
	KEY_EXPORT: false,
	KEY_CATEGORY: "General",
	KEY_LABEL: "",
	KEY_EXPAND: true,
	KEY_FLAT: false,
}

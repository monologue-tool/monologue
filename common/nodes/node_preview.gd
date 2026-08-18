## The pieces a node's preview is built from.
##
## A preview is any [Control] the node cares to build, so this is not the only way to make
## one. It is the set of parts most of them need.
##
## Everything that reads a value trims it. A reference pointing at nothing reads as nothing.
## Nothing here reports an id.
class_name NodePreview

## How tall one line of preview is, and the shortest the view will draw one.
const LINE_HEIGHT: float = 18.0
## How much of one piece of free text survives, leaving room for what frames it.
const MAX_PIECE: int = 26


# --- controls ---------------------------------------------------------------------


## One line of BBCode. Runs off its own edge instead of wrapping, and the view clips it.
static func line(bbcode: String) -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = bbcode
	label.fit_content = false
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_contents = true
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.theme_type_variation = "GraphNodeViewPreviewLabel"
	label.custom_minimum_size.y = LINE_HEIGHT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


static func row(pieces: Array) -> HBoxContainer:
	var box: HBoxContainer = HBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	box.custom_minimum_size.y = LINE_HEIGHT
	for piece: Variant in pieces:
		if piece is Control:
			box.add_child(piece)
	return box


## The stage seen from above. One mark per place, the taken one lit.
static func stage(taken: String, places: Array, tint: Color) -> Control:
	var strip: HBoxContainer = HBoxContainer.new()
	strip.mouse_filter = Control.MOUSE_FILTER_PASS
	strip.add_theme_constant_override("separation", 2)

	for place: Variant in places:
		var mark: ColorRect = ColorRect.new()
		mark.mouse_filter = Control.MOUSE_FILTER_PASS
		mark.custom_minimum_size = Vector2(8.0, LINE_HEIGHT - 8.0)
		mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mark.color = tint if str(place) == taken else Color(tint, 0.2)
		strip.add_child(mark)

	return strip


# --- text -------------------------------------------------------------------------


## A line the author wrote is not markup, however many brackets are in it.
static func plain(text: String) -> String:
	return text.replace("[", "[lb]")


## One line, no longer than [param budget], ending in an ellipsis when it was cut.
static func trim(text: String, budget: int = MAX_PIECE) -> String:
	var flat: String = text.strip_edges().replace("\n", " ")
	if flat.length() <= budget:
		return flat
	return "%s…" % flat.substr(0, budget - 1).strip_edges(false, true)


## What a reference property points at, by name. Pointing at nothing, or at something gone,
## reads as nothing. A property that is not a reference reads as its own value.
static func named(node: InspectableNode, property_name: String) -> String:
	var property: Property = node.get_property(property_name)
	if property == null:
		return ""

	var scope: String = _scope_of(property)
	if scope.is_empty():
		return trim(str(property.get_value()))

	var project: MonologueProject = ProjectManager.current_project
	if project == null:
		return ""
	return trim(ReferenceResolver.resolve_label(project, scope, str(property.get_value()), node))


## The same name, wearing the colour whatever it points at carries. Ready for [method line].
static func tinted(node: InspectableNode, property_name: String) -> String:
	var written: String = named(node, property_name)
	if written.is_empty():
		return ""
	return "[color=#%s]%s[/color]" % [tint(node, property_name).to_html(false), plain(written)]


## The colour of whatever a reference points at, white when it carries none.
static func tint(node: InspectableNode, property_name: String) -> Color:
	var property: Property = node.get_property(property_name)
	var project: MonologueProject = ProjectManager.current_project
	if property == null or project == null:
		return Color.WHITE

	var written: String = ReferenceResolver.resolve_property(
		project, _scope_of(property), str(property.get_value()), "color", node
	)
	return Color(written) if written.is_valid_html_color() else Color.WHITE


## A translated property as the reader sees it in [param language].
static func said(node: InspectableNode, property_name: String, language: String) -> String:
	return trim(Util.to_label(node.get_property_value(property_name), language))


## A condition as it reads, such as "gold >= 3". Empty when it names no variable.
static func condition(test: Variant) -> String:
	if test is not Dictionary:
		return ""

	var check: Dictionary = test
	var project: MonologueProject = ProjectManager.current_project
	if project == null:
		return ""

	var variable: String = ReferenceResolver.resolve_label(
		project, "variables", str(check.get("variable", ""))
	)
	if variable.is_empty():
		return ""
	return "%s %s %s" % [
		trim(variable), str(check.get("operator", "==")), literal(check.get("value"))
	]


## A stored value as it would be written. A string in quotes, a boolean as a word.
static func literal(value: Variant) -> String:
	if value is String:
		return '"%s"' % trim(value)
	if value is bool:
		return "true" if value else "false"
	return str(value)


static func file(path: String) -> String:
	return trim(path.get_file())


## A duration written as short as it reads: "2s", "0.5s".
static func seconds(value: float) -> String:
	var written: String = String.num(value, 2)
	if written.contains("."):
		written = written.rstrip("0").rstrip(".")
	return "%ss" % written


## [param count] of [param thing], named in the plural when there is not exactly one.
static func counted(count: int, thing: String) -> String:
	return "%d %s%s" % [count, thing, "" if count == 1 else "s"]


static func _scope_of(property: Property) -> String:
	return str(property.get_settings_value(PropertySettings.KEY_REFERENCE_SCOPE, ""))

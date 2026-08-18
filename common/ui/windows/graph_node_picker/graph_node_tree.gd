## The list of node types the picker offers, grouped by category.
##
## Each row carries a pastille tinted with the type's own colour, the same colour the
## node has in the graph, so a type is recognisable before its name is read. The
## description of the selected type is shown by the picker, not here.
class_name GraphNodeTree
extends Tree

## Stands in for the icon of a type that declares none, so every row has a pastille.
const PASTILLE_ICON: String = "res://ui/assets/icons/dot_icon.png"

const NAME_COLUMN: int = 0

## Carries the highlighted type, or null when the selection is a category or nothing.
signal type_highlighted(indexer: NodeIndexer)

@onready var create_btn: Button = %CreateButton
@onready var window: GraphNodePicker = $"../../.."

var _fallback_icon: Texture2D
var _first_match: TreeItem


func _ready() -> void:
	_fallback_icon = load(PASTILLE_ICON)
	set_column_expand(NAME_COLUMN, true)
	reload_tree()


## Rebuilds the list. When the picker was dragged out of a port, only the types that
## port can actually reach are offered.
func reload_tree() -> void:
	clear()
	_first_match = null
	var root: TreeItem = create_item()
	create_btn.disabled = true

	var registry: MonologueRegistry = MonologueRegistry.get_instance()
	var accepted: PackedStringArray = _accepted_type_names(registry)

	for category: String in registry.list_categories(MonologueObjectType.NODE):
		var offered: Array[MonologueIndexer] = []
		for indexer: MonologueIndexer in registry.list_by_category(
			MonologueObjectType.NODE, category
		):
			# A storyline creates its own singletons, so offering one here would only
			# ever produce a second root.
			if (indexer as NodeIndexer).is_singleton:
				continue
			if accepted.is_empty() or indexer.name in accepted:
				offered.append(indexer)
		if offered.is_empty():
			continue

		var category_item: TreeItem = create_item(root)
		category_item.set_text(NAME_COLUMN, category)
		category_item.set_selectable(NAME_COLUMN, false)
		category_item.set_custom_color(NAME_COLUMN, ThemeLayout.text_muted_color)
		category_item.collapsed = true
		for indexer: MonologueIndexer in offered:
			_create_indexer_item(category_item, indexer)

	if root.get_child_count() == 0:
		_add_placeholder(root, "Nothing here accepts that connection")

	deselect_all()
	type_highlighted.emit(null)


## Machine names this picker will offer, or empty for "no restriction". A picker opened
## from a port only lists types with somewhere for that port to land.
func _accepted_type_names(registry: MonologueRegistry) -> PackedStringArray:
	var source_type_id: int = window.source_port_type_id if window else 0
	if source_type_id <= 0:
		return PackedStringArray()

	var accepted: PackedStringArray = []
	for indexer: MonologueIndexer in registry.list(MonologueObjectType.NODE):
		var node: InspectableNode = (indexer as NodeIndexer).instantiate(CommandManager.new())
		if node and _accepts(registry, node, source_type_id):
			accepted.append(indexer.name)

	return accepted


static func _accepts(
	registry: MonologueRegistry, node: InspectableNode, source_type_id: int
) -> bool:
	for property: Property in node.get_properties():
		if not property.get_settings_value(PropertySettings.KEY_EXPOSABLE, false):
			continue
		var type_id: int = registry.get_field_type_id(property.type)
		if type_id > 0 and registry.is_compatible(source_type_id, type_id):
			return true
	return false


func _add_placeholder(parent: TreeItem, text: String) -> void:
	var placeholder: TreeItem = create_item(parent)
	placeholder.set_text(NAME_COLUMN, text)
	placeholder.set_selectable(NAME_COLUMN, false)
	placeholder.set_custom_color(NAME_COLUMN, ThemeLayout.text_muted_color)


func _create_indexer_item(parent: TreeItem, indexer: MonologueIndexer) -> void:
	var item: TreeItem = create_item(parent)
	item.set_text(NAME_COLUMN, indexer.get_display_name())
	item.set_tooltip_text(NAME_COLUMN, indexer.description)

	var icon: Texture2D = indexer.get_icon()
	item.set_icon(NAME_COLUMN, icon if icon else _fallback_icon)
	item.set_icon_modulate(NAME_COLUMN, indexer.get_color())

	item.set_metadata(NAME_COLUMN, indexer.name)


## The type a row stands for, or null for a category or a placeholder.
func _indexer_of(item: TreeItem) -> NodeIndexer:
	if item == null:
		return null
	var type_name: Variant = item.get_metadata(NAME_COLUMN)
	if type_name == null:
		return null
	return MonologueRegistry.get_instance().get_node(String(type_name))


func _create() -> bool:
	var selected: TreeItem = get_selected()
	if selected == null:
		return false
	var descriptor_name: Variant = selected.get_metadata(NAME_COLUMN)
	if descriptor_name == null:
		return false

	EventBus.add_graph_node.emit(String(descriptor_name), window)
	deselect_all()
	return true


func create_selected_descriptor() -> bool:
	return _create()


func _on_item_activated() -> void:
	var item: TreeItem = get_selected()
	if item == null:
		return
	if item.get_child_count() > 0:
		item.collapsed = not item.collapsed
		return
	if _create():
		window.close()


func _on_item_selected() -> void:
	var item: TreeItem = get_selected()
	var indexer: NodeIndexer = _indexer_of(item)
	create_btn.disabled = indexer == null
	type_highlighted.emit(indexer)


# --- search -----------------------------------------------------------------------


func _on_search_bar_text_changed(new_text: String) -> void:
	var query: String = new_text.strip_edges()
	if query.is_empty():
		_show_all(get_root())
		return

	_first_match = null
	_filter(query, get_root())
	if _first_match:
		_first_match.select(NAME_COLUMN)


## A category is shown when any of its types matches. A type matches on its name, its
## description or the category it sits in, so "flow" and "variable" both find something.
func _filter(query: String, item: TreeItem) -> bool:
	if item.get_child_count() > 0:
		var any_child_matches: bool = false
		for child: TreeItem in item.get_children():
			if _filter(query, child):
				any_child_matches = true
		if item != get_root():
			item.visible = any_child_matches
			item.collapsed = false
		return any_child_matches

	var matches: bool = _matches(query, item)
	item.visible = matches
	if matches and _first_match == null:
		_first_match = item
	return matches


func _matches(query: String, item: TreeItem) -> bool:
	var haystack: PackedStringArray = [item.get_text(NAME_COLUMN)]

	var indexer: NodeIndexer = _indexer_of(item)
	if indexer:
		haystack.append(indexer.name)
		haystack.append(indexer.description)

	var parent: TreeItem = item.get_parent()
	if parent and parent != get_root():
		haystack.append(parent.get_text(NAME_COLUMN))

	for candidate: String in haystack:
		if candidate.containsn(query):
			return true
	return false


## Clears the filter and folds the categories back, the state the picker opens in.
func _show_all(item: TreeItem) -> void:
	item.visible = true
	if item != get_root():
		item.collapsed = true
	for child: TreeItem in item.get_children():
		_show_all(child)

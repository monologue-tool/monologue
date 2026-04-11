extends PanelContainer

enum Actions { DELETE_ITEM, NEW_STORYLINE }

@onready var tree: Tree = %ProjectTree

@onready var folder_icon: DPITexture = preload("res://ui/assets/icons/folder.svg")
@onready var delete_icon: DPITexture = preload("res://ui/assets/icons/trash.svg")
@onready var add_icon: DPITexture = preload("res://ui/assets/icons/plus.svg")

var _collapsed_cache: Dictionary[String, bool] = {}


func _ready() -> void:
	ProjectManager.project_loaded.connect(rebuild_tree)
	tree.item_selected.connect(_on_tree_item_selected)
	tree.item_edited.connect(_on_tree_item_edited)
	tree.item_collapsed.connect(_on_tree_item_collapsed)
	tree.button_clicked.connect(_on_tree_button_pressed)
	
	# FIXME: It's an ugly fix
	delete_icon.set_size_override(Vector2(18, 18))
	add_icon.set_size_override(Vector2(18, 18))
	
	rebuild_tree()


func rebuild_tree() -> void:
	tree.clear()
	
	var project: MonologueProject = ProjectManager.current_project
	if not project:
		return
	
	var root_item: TreeItem = tree.create_item()
	if not root_item:
		return
	root_item.set_text(0, "<Unsaved Project>")
	root_item.set_icon(0, folder_icon)
	root_item.set_selectable(0, false)
	
	var manifest_item: TreeItem = tree.create_item(root_item)
	manifest_item.set_text(0, "manifest")
	manifest_item.set_meta("document", project.manifest)
	var collections_item: TreeItem = tree.create_item(root_item)
	collections_item.set_text(0, "Collections")
	collections_item.set_meta("name", "collections")
	collections_item.set_icon(0, folder_icon)
	collections_item.collapsed = _collapsed_cache.get("collections", true)
	var storylines_item: TreeItem = tree.create_item(root_item)
	storylines_item.set_text(0, "Storylines")
	storylines_item.set_meta("name", "storylines")
	storylines_item.set_icon(0, folder_icon)
	storylines_item.collapsed = _collapsed_cache.get("storylines", false)
	storylines_item.add_button(0, add_icon, Actions.NEW_STORYLINE)
	
	for collection: CollectionDocument in project.collections:
		var collection_item: TreeItem = collections_item.create_child()
		collection_item.set_text(0, collection.name)
		collection_item.set_meta("document", collection)

	
	for storyline: StorylineDocument in project.storylines:
		var storyline_item: TreeItem = storylines_item.create_child()
		storyline_item.set_text(0, storyline.name)
		storyline_item.set_meta("document", storyline)
		storyline_item.add_button(0, delete_icon, Actions.DELETE_ITEM)


func _on_tree_item_selected() -> void:
	var item: TreeItem = tree.get_selected()
	
	var document: InspectableDocument = item.get_meta("document")
	if document == null:
		return
	
	if document is StorylineDocument:
		item.set_editable.call_deferred(0, true)
		EventBus.request_storyline_inspection.emit(document)
		return
	
	EventBus.request_object_inspection.emit(document)


func _on_tree_item_edited() -> void:
	var item: TreeItem = tree.get_edited()
	var new_name: String = item.get_text(0)
	item.set_editable(0, false)
	var document: InspectableDocument = item.get_meta("document")
	if not document or not ProjectManager.current_project.is_valid_storyline_name(new_name):
		rebuild_tree()
		return
	
	document.name = new_name


func _on_tree_button_pressed(_item: TreeItem, _column: int, id: int, mouse_button_index: int) -> void:
	if not mouse_button_index == MOUSE_BUTTON_LEFT:
		return
	
	match id:
		Actions.NEW_STORYLINE:
			ProjectManager.current_project.add_new_storyline()
	
	rebuild_tree()


func _on_tree_item_collapsed(item: TreeItem) -> void:
	var item_name: Variant = item.get_meta("name")
	if not item_name:
		return
	
	_collapsed_cache[item_name] = item.collapsed


func _on_minimize_button_pressed() -> void:
	tree.visible = !tree.visible

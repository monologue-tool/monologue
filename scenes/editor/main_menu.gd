extends MenuButton

@onready var search_icon = preload("res://ui/assets/icons/search.svg")


func _ready() -> void:
	var popup: PopupMenu = get_popup()
	popup.transparent = true
	popup.transparent_bg = true

	# Search item
	popup.add_icon_item(search_icon, "Search...")
	popup.set_item_shortcut(0, create_shortcut("Show searchbar"))
	popup.add_separator()

	# File item
	var file_submenu: PopupMenu = create_popup_menu()
	file_submenu.add_item("New file")
	file_submenu.add_item("Open file")
	file_submenu.add_separator()
	file_submenu.add_item("Save file")
	file_submenu.add_item("Save file as")
	file_submenu.set_item_shortcut(3, create_shortcut("Save"))
	popup.add_submenu_node_item("File", file_submenu)

	# Edit item
	var edit_submenu: PopupMenu = create_popup_menu()
	edit_submenu.add_item("Undo")
	edit_submenu.add_item("Redo")
	edit_submenu.add_separator()
	edit_submenu.add_item("Preferences")
	edit_submenu.set_item_shortcut(0, create_shortcut("Undo"))
	edit_submenu.set_item_shortcut(1, create_shortcut("Redo"))
	popup.add_submenu_node_item("Edit", edit_submenu)

	# View item
	var view_submenu: PopupMenu = create_popup_menu()
	view_submenu.add_check_item("Pixel grid")
	view_submenu.add_check_item("Snap to grid")
	view_submenu.add_separator()
	view_submenu.add_item("Zoom in")
	view_submenu.add_item("Zoom out")
	view_submenu.add_item("Zoom to 100%")
	view_submenu.add_item("Zoom to fit")
	view_submenu.add_item("Zoom to selection")
	popup.add_submenu_node_item("View", view_submenu)

	# Node item
	var node_submenu: PopupMenu = create_popup_menu()
	node_submenu.add_item("Add node")
	node_submenu.add_item("Arrange nodes")
	node_submenu.set_item_shortcut(0, create_shortcut("Add node"))
	popup.add_submenu_node_item("Node", node_submenu)
	popup.add_separator()

	# Exit item
	popup.add_item("Exit")
	popup.set_item_shortcut(7, create_shortcut("Exit"))


func create_popup_menu() -> PopupMenu:
	var popup: PopupMenu = PopupMenu.new()
	popup.transparent = true
	popup.transparent_bg = true
	return popup


func create_shortcut(action_name: StringName) -> Shortcut:
	var _shortcut := Shortcut.new()
	var inputevent := InputEventAction.new()
	inputevent.action = action_name
	_shortcut.events.append(inputevent)
	return _shortcut


func _on_about_to_popup() -> void:
	var popup: PopupMenu = get_popup()
	await get_tree().process_frame
	popup.position.y -= (get_window().size.y - floor(global_position.y)) + 5

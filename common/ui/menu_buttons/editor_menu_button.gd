@abstract
class_name EditorMenuButton extends Button

var _menu: PopupMenu
var _callbacks: Dictionary = {}

func _ready() -> void:
	_menu = PopupMenu.new()
	add_child(_menu)
	_menu.id_pressed.connect(_on_id_pressed)
	toggled.connect(_on_pressed)
	_menu.visibility_changed.connect(_on_menu_visibility_changed)
	toggle_mode = true

@abstract
func _build_menu() -> void

func _rebuild_menu() -> void:
	for child in _menu.get_children():
		child.queue_free()
	_menu.clear()
	_callbacks.clear()
	_build_menu()


func _on_pressed(toggled_on: bool) -> void:
	if not toggled_on:
		_menu.hide()
		return
	_show_menu()

func _on_menu_visibility_changed() -> void:
	if _menu.visible:
		return
	set_pressed_no_signal(false)

func _show_menu() -> void:
	_rebuild_menu()
	var rect: Rect2 = get_global_rect()
	rect.position.y += size.y
	_menu.popup_on_parent(rect)

func add_row(label: String, callback: Callable = Callable(), accel: Key = KEY_NONE) -> void:
	var id := _menu.item_count
	_menu.add_item(label, id, accel)
	if callback.is_valid():
		_callbacks[id] = callback

# Callback receives the new bool value.
func add_check_row(label: String, checked := false, callback: Callable = Callable()) -> void:
	var id := _menu.item_count
	_menu.add_check_item(label, id)
	_menu.set_item_checked(_menu.get_item_index(id), checked)
	if callback.is_valid():
		_callbacks[id] = callback

func add_separator(label: String = "") -> void:
	_menu.add_separator(label)

# Returns the submenu PopupMenu to populate.
func add_submenu_row(label: String) -> PopupMenu:
	var submenu := PopupMenu.new()
	submenu.name = label.replace(" ", "_") + "_" + str(_menu.item_count)
	_menu.add_child(submenu)
	_menu.add_submenu_item(label, submenu.name)
	return submenu

func _on_id_pressed(id: int) -> void:
	set_pressed_no_signal(false)
	var idx := _menu.get_item_index(id)
	if _menu.is_item_checkable(idx):
		var checked := not _menu.is_item_checked(idx)
		_menu.set_item_checked(idx, checked)
		if id in _callbacks:
			_callbacks[id].call(checked)
	elif id in _callbacks:
		_callbacks[id].call()

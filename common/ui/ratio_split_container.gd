## A split container that holds its divider at a share of the width rather than at a
## number of pixels, so resizing the window leaves the layout looking the way it did.
##
## Works either way round: [member SplitContainer.vertical] decides which extent the
## share is taken along, so one script covers the horizontal and the vertical splits.
class_name RatioSplitContainer extends SplitContainer

## How many correction passes one request is allowed.
const SETTLE_PASSES: int = 3
## How far off the divider may sit before it is worth moving, in pixels.
const TOLERANCE: float = 1.0

## Share of the space the two panes have between them that goes to the first one.
@export_range(0.0, 100.0, 0.1, "suffix:%") var split_percent: float = 50.0:
	set = set_split_percent

## True while the container is moving its own divider, so the moves it makes are not read
## back as though the user had made them.
var _is_applying: bool = false
## True from the moment a drag is seen until the share has been read off it. A resize
## arriving in between must not pull the divider back to where it used to be.
var _is_dragging: bool = false
## True once something has actually chosen a share: the scene file, the inspector, or
## code. Until then the container adopts whatever offset it was laid out with, so putting
## this script on a split that already sits where it should does not move it.
var _percent_is_chosen: bool = false
var _passes_left: int = 0
var _is_scheduled: bool = false


func _ready() -> void:
	resized.connect(_on_layout_changed)
	visibility_changed.connect(_on_layout_changed)
	dragged.connect(_on_dragged)
	child_order_changed.connect(_watch_panes)
	_watch_panes()

	if _percent_is_chosen:
		_schedule_apply()
	else:
		_read_percent.call_deferred()


func set_split_percent(value: float) -> void:
	split_percent = clampf(value, 0.0, 100.0)
	_percent_is_chosen = true
	if not _is_applying and is_node_ready():
		_schedule_apply()


func get_effective_percent() -> float:
	var usable: float = _usable_extent()
	var first: float = _first_extent()
	if usable <= 0.0 or first < 0.0:
		return split_percent
	return clampf(first / usable * 100.0, 0.0, 100.0)


## Asks for the divider to be put back, over the next few frames.
func _schedule_apply(passes: int = SETTLE_PASSES) -> void:
	_passes_left = maxi(_passes_left, passes)
	if _is_scheduled:
		return
	_is_scheduled = true
	_apply_pass.call_deferred()


func _apply_pass() -> void:
	_is_scheduled = false
	_passes_left -= 1

	if not _move_towards_percent() or _passes_left <= 0:
		_passes_left = 0
		return

	_is_scheduled = true
	_apply_pass.call_deferred()


## Moves the divider one step towards the wanted share. Returns whether it is still off,
## which is what asks for another pass.
func _move_towards_percent() -> bool:
	if not is_inside_tree() or collapsed or _is_dragging:
		return false

	var usable: float = _usable_extent()
	var first: float = _first_extent()
	if usable <= 0.0 or first < 0.0:
		return false

	var target: float = usable * split_percent * 0.01
	if absf(target - first) < TOLERANCE:
		return false

	_is_applying = true
	split_offset += int(round(target - first))
	clamp_split_offset()
	_is_applying = false
	return true


func _on_layout_changed() -> void:
	if _is_applying:
		return
	_schedule_apply()


## The user moved the divider, so the share follows it rather than the other way round.
## Read on the next frame: the panes are still their old size when this fires.
func _on_dragged(_offset: int) -> void:
	_is_dragging = true
	_read_percent.call_deferred()


func _read_percent() -> void:
	_is_dragging = false

	var usable: float = _usable_extent()
	var first: float = _first_extent()
	if usable <= 0.0 or first < 0.0:
		return

	_is_applying = true
	split_percent = clampf(first / usable * 100.0, 0.0, 100.0)
	_is_applying = false


## Follows the panes, so that hiding one and showing it again puts the divider back at
## the share it had rather than wherever the container left it meanwhile.
func _watch_panes() -> void:
	for child: Node in get_children():
		var pane: Control = child as Control
		if pane and not pane.visibility_changed.is_connected(_on_layout_changed):
			pane.visibility_changed.connect(_on_layout_changed)


## The space the two panes share: everything except the divider between them.
func _usable_extent() -> float:
	var extent: float = size.y if vertical else size.x
	return maxf(extent - get_theme_constant("separation"), 0.0)


## Size of the first laid-out pane, or -1 when there are not two panes to split between,
## which is the state the container is in while one of them is hidden.
func _first_extent() -> float:
	var panes: Array[Control] = _panes()
	if panes.size() < 2:
		return -1.0
	return panes[0].size.y if vertical else panes[0].size.x


## The children the container actually lays out: the first two visible ones that are not
## floating free of it.
func _panes() -> Array[Control]:
	var panes: Array[Control] = []
	for child: Node in get_children():
		var pane: Control = child as Control
		if pane == null or not pane.visible or pane.top_level:
			continue
		panes.append(pane)
		if panes.size() == 2:
			break
	return panes

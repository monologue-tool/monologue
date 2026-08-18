class_name AdvancedHBoxContainer extends Container

@export var ratio: Array[float] = [1.0]:
	set(v):
		ratio = v
		queue_sort()

@export var force_ratio: bool = false:
	set(v):
		force_ratio = v
		queue_sort()


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort()
	elif what == NOTIFICATION_THEME_CHANGED:
		queue_sort()


func _sort() -> void:
	var children: Array[Control] = []
	for child in get_children():
		if child is Control and child.visible:
			children.append(child)

	if children.is_empty():
		return

	var sep: int = get_theme_constant("separation", "HBoxContainer")
	var available: float = size.x - sep * (children.size() - 1)

	var ratios: Array[float] = []
	for i in children.size():
		if i < ratio.size():
			ratios.append(maxf(ratio[i], 0.0))
		else:
			ratios.append(maxf(ratio[-1] if not ratio.is_empty() else 1.0, 0.0))

	var total: float = 0.0
	for r: float in ratios:
		total += r
	if total <= 0.0:
		return

	var final_sizes: Array[float] = []
	final_sizes.resize(children.size())

	if force_ratio:
		for i in children.size():
			final_sizes[i] = ratios[i] / total * available
	else:
		var locked: Array[bool] = []
		locked.resize(children.size())
		for i in children.size():
			locked[i] = false

		var remaining_space: float = available
		var remaining_ratio: float = total

		var changed: bool = true
		while changed:
			changed = false
			for i in children.size():
				if locked[i]:
					continue
				var allocated: float = ratios[i] / remaining_ratio * remaining_space
				var min_w: float = children[i].get_combined_minimum_size().x
				if allocated < min_w:
					final_sizes[i] = min_w
					remaining_space -= min_w
					remaining_ratio -= ratios[i]
					locked[i] = true
					changed = true

		for i in children.size():
			if not locked[i]:
				final_sizes[i] = (
					ratios[i] / remaining_ratio * remaining_space if remaining_ratio > 0.0 else 0.0
				)

	var x_offset: float = 0.0
	for i in children.size():
		children[i].position = Vector2(x_offset, 0.0)
		children[i].set_size.call_deferred(Vector2(final_sizes[i], size.y))
		x_offset += final_sizes[i] + sep


func _get_minimum_size() -> Vector2:
	var children: Array[Control] = []
	for child in get_children():
		if child is Control and child.visible:
			children.append(child)

	if children.is_empty():
		return Vector2.ZERO

	var sep: int = get_theme_constant("separation", "HBoxContainer")
	var min_w: float = 0.0
	var max_h: float = 0.0
	for child: Control in children:
		if not force_ratio:
			min_w += child.get_combined_minimum_size().x
		max_h = maxf(max_h, child.get_combined_minimum_size().y)

	if not force_ratio:
		min_w += sep * (children.size() - 1)
	return Vector2(min_w, max_h)

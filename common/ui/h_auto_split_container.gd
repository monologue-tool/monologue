class_name HAutoSplitContainer extends HSplitContainer

#var split_percents: Array[float] = []:
	#set(value):
		#split_percents = value
		#if not _dragging:
			#_percents_to_offsets()
#
#var _dragging := false
#
#func _ready() -> void:
	#resized.connect(_on_resized)
	#dragged.connect(_on_dragged)
	#_offsets_to_percents.call_deferred()
#
#func _percents_to_offsets() -> void:
	#var total := _total_width()
	#if total <= 0.0:
		#return
	#var offsets := split_offsets
	#for i in mini(split_percents.size(), offsets.size()):
		#offsets[i] = int(total * split_percents[i] / 100.0)
	#split_offsets = offsets
#
#func _offsets_to_percents() -> void:
	#var total := _total_width()
	#if total <= 0.0:
		#return
	#var new_percents: Array[float] = []
	#for offset in split_offsets:
		#new_percents.append(offset / total * 100.0)
	#split_percents = new_percents
#
#func _on_resized() -> void:
	#if not _dragging:
		#_percents_to_offsets()
#
#func _on_dragged(_offset: int) -> void:
	#_dragging = true
	#_offsets_to_percents()
	#_dragging = false
#
#func _total_width() -> float:
	#return size.x

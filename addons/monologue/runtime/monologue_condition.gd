class_name MonologueCondition

## Waiting for the FuzzySearch and FuzzySearchMatch classes coming in Godot 4.8
const FUZZY_THRESHOLD: float = 0.8


static func holds(left: Variant, operator: String, right: Variant) -> bool:
	match operator:
		"==": return _same(left, right)
		"!=": return not _same(left, right)
		">": return _as_number(left) > _as_number(right)
		">=": return _as_number(left) >= _as_number(right)
		"<": return _as_number(left) < _as_number(right)
		"<=": return _as_number(left) <= _as_number(right)
		"contains": return str(right) in str(left)
		"fuzzy": return _alike(str(left), str(right))
	return false


## Compares numbers as numbers even when one side was stored as text, which is how a value
## typed into the editor arrives.
static func _same(left: Variant, right: Variant) -> bool:
	if left is bool or right is bool:
		return bool(left) == bool(right)
	if _is_number(left) and _is_number(right):
		return is_equal_approx(_as_number(left), _as_number(right))
	return str(left) == str(right)


static func _alike(left: String, right: String) -> bool:
	return left.to_lower().similarity(right.to_lower()) >= FUZZY_THRESHOLD


static func _is_number(of_value: Variant) -> bool:
	return of_value is int or of_value is float


static func _as_number(of_value: Variant) -> float:
	if of_value is bool:
		return 1.0 if of_value else 0.0
	if _is_number(of_value):
		return float(of_value)
	return str(of_value).to_float()

class_name RandomPicker extends RefCounted
## Randomly choose a [Variant] based on given weight.[br]
## Usage:[br]
## 1. Create the object[br]
## 2. Call [method set_pool][br]
## 3. Call [method pick] when you want to get randomized pick

## Selectively use linear or binary search algorithm based on the data size.[br]
## Note: Just a magic number from a limited testing, could miss by a lot.
const BINARY_SEARCH_THRESHOLD: int = 30

var _objects_cache: Array
var _values_cache: Array[int]
var _search_fn: Callable


func size() -> int:
	return _objects_cache.size()


func clear() -> void:
	_objects_cache.clear()
	_values_cache.clear()


## [param pool] expects the dictionary to be structured as such:[br]
## - key: the object itself as a [Variant][br]
## - value: weight of the obj as an [int]
func set_pool(pool: Dictionary) -> void:
	_objects_cache.clear()
	_values_cache.clear()

	var total = 0
	for key in pool.keys():
		var weight: int = pool[key]
		if weight == 0:
			continue

		total += weight

		_objects_cache.append(weakref(key) if key is RefCounted else key)
		_values_cache.append(total)

	_search_fn = (
		_search_linear if _objects_cache.size() < BINARY_SEARCH_THRESHOLD else _search_binary
	)


func pick() -> Variant:
	assert(_objects_cache.size() > 0, "There's nothing in the picker, check the weights.")

	var high_bound: int = _values_cache.back() - 1
	var random_value: int = randi_range(0, high_bound)

	var result_index: int = _search_fn.call(_values_cache, random_value)

	var result = _objects_cache[result_index]
	if result is WeakRef:
		return result.get_ref()

	return result


## Randomly pick with given [param n] count. Pick result is always unique, but not sorted[br]
## [param n] cannot be greater than the cache size. Check with [method size]
func pick_n(n: int) -> Array:
	assert(n > 0, "Attempted to pick negative count!")
	assert(n <= _objects_cache.size(), "Cannot pick more than cache size.")

	if n == 1:
		return [pick()]

	if n == _objects_cache.size():
		return _objects_cache

	var results: Array = []
	var remaining_objects: Array = _objects_cache.duplicate()
	var remaining_values: Array[int] = _values_cache.duplicate()

	for i in range(n):
		var random_value: int = randi_range(0, remaining_values.back() - 1)
		var search_fn = (
			_search_linear if remaining_objects.size() < BINARY_SEARCH_THRESHOLD else _search_binary
		)
		var result_index: int = search_fn.call(remaining_values, random_value)
		var result = remaining_objects[result_index]
		results.append(result.get_ref() if result is WeakRef else result)

		var weight: int = remaining_values[result_index]
		if result_index > 0:
			weight -= remaining_values[result_index - 1]

		remaining_objects.remove_at(result_index)
		remaining_values.remove_at(result_index)

		for j in range(result_index, remaining_values.size()):
			remaining_values[j] -= weight

	return results


func _search_linear(array: Array, value: int) -> int:
	for i in range(array.size()):
		if value < array[i]:
			return i

	assert(false, "It's a bug if this throws.")
	return -1


func _search_binary(array: Array, value: int) -> int:
	var low: int = 0
	var high: int = array.size() - 1
	while low <= high:
		var mid: int = floori(float(low) + float(high - low) / 2.0)
		var elem: int = array[mid]

		if value > elem:
			low = mid + 1
			continue

		if value == elem:
			return mid + 1

		var previous: int = mid - 1
		if previous == -1:
			return mid

		if value > array[previous]:
			return mid

		high = mid - 1

	assert(false, "It's a bug if this throws.")
	return -1

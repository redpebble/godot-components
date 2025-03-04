extends Node2D

signal item_selected(slot_index: int, item: MenuItem)

## The number of slots around the circumference
@export_custom(PROPERTY_HINT_NONE, "suffix:slots") var slots: int = 12
## The number of visible items on either side of the currently highlighted item.
@export_custom(PROPERTY_HINT_NONE, "suffix:items") var visible_items: int = 8
## The base radius of the helical menu, in pixels.
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var menu_radius: float = 300
## The scaling ratio of the menu items.
@export var item_scale_ratio: float = 1
## Rotate the menu instead of the cursor.
@export var static_cursor: bool = false
## Wrap the item list so that the last item is next to the first.
@export var wrap_item_list: bool = false

@onready var _angle_interval = 2*PI / slots
@onready var _item_scale = Vector2(item_scale_ratio, item_scale_ratio)

var _item_list: Array[MenuItem] = []
var _item_index: int = 0
var _slot_index: int = 0

var _visible_list = []
var _is_rotating = false
var _current_rotation = 0
var _saved_offset = 0
var _input_offset = 0

var _last_input_angle = 0
var _input_direction = 0

var _delta = 0

func set_item_list(list: Array[MenuItem]):
	_item_list = list

func instantiate():
	$Cursor/Sprite.position.y = -(menu_radius - (200 * item_scale_ratio))
	$Cursor/Sprite.scale = _item_scale

	for item in _item_list:
		item.hide()
		call_deferred('add_child', item)
	_update_items()
	_update_cursor()

func _process(delta: float) -> void:
	_delta = delta

	var input_vector = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')
	var input_angle = _calc_input_angle(input_vector)
	_input_direction = _calc_rotation_direction(input_angle, _last_input_angle, PI)
	_last_input_angle = input_angle

	_update_menu(input_vector)

	if Input.is_action_just_pressed("ui_select"):
		_emit_item_selected()

func _update_menu(input_vector: Vector2):
	if input_vector == Vector2.ZERO || _at_list_edge():
		_current_rotation = _calc_slot_angle(_calc_nearest_slot_index(_current_rotation))
		_saved_offset = _current_rotation
		_is_rotating = false
		_update_items()
		_update_cursor()
		return

	var input_angle = _calc_input_angle(input_vector)
	if !_is_rotating:
		_input_offset = input_angle
		_is_rotating = true
	input_angle -= _input_offset
	input_angle += _saved_offset

	_current_rotation = input_angle
	_update_items()
	_update_cursor()

	var slot_angle = -input_angle if static_cursor else input_angle
	_highlight_slot(_calc_nearest_slot_index(slot_angle))

func _at_list_edge() -> bool:
	if wrap_item_list: return false
	if _input_direction == 0: return false
	if static_cursor:
		if _input_direction > 0 && _item_index > 0: return false
		if _input_direction < 0 && _item_index < _item_list.size()-1: return false
	else:
		if _input_direction < 0 && _item_index > 0: return false
		if _input_direction > 0 && _item_index < _item_list.size()-1: return false
	return true

func _update_items():
	_visible_list.clear()

	_update_item(_item_index, _slot_index)

	var idx_up = _item_index + 1
	var idx_down = _item_index - 1
	for i: int in visible_items + 1:
		if wrap_item_list:
			if idx_up >= _item_list.size(): idx_up = 0
			if idx_down < 0: idx_down = _item_list.size() - 1

		var d_radius = 0.7 * menu_radius / visible_items * (i+1)
		var d_scale = 1.0/(visible_items + 0.5) * (i+1)
		var d_alpha = d_scale

		if idx_up < _item_list.size():
			_update_item(idx_up, (_slot_index + (i+1)) % slots, d_radius * (1+i/20.0), d_scale, d_alpha)
		if idx_down >= 0:
			_update_item(idx_down, (_slot_index - (i+1)) % slots, -d_radius, -d_scale, d_alpha)

		idx_up += 1
		idx_down -= 1

	for i in _item_list.size():
		if !_visible_list.has(i): _hide_item(i)

	_set_highlight()

func _update_item(item_index, slot_index, d_radius = 0, d_scale = 0, d_alpha = 0):
	if item_index < 0 || item_index >= _item_list.size(): return
	var item = _item_list[item_index]
	var angle = _calc_slot_angle(slot_index)
	if static_cursor: angle += _current_rotation
	if !item.visible:
		item.rotation = angle
		item.get_content().rotation = -angle
		item.get_content().position.y = -menu_radius - d_radius
		item.get_content().scale = _item_scale * (1 + d_scale)
		item.get_content().modulate.a = 1 - d_alpha
	else:
		item.rotation = lerp_angle(item.rotation, angle, _delta * 10)
		item.get_content().rotation = lerp_angle(item.get_content().rotation, -angle, _delta * 10)
		item.get_content().position.y = lerpf(item.get_content().position.y, -menu_radius - d_radius, _delta * 8)
		item.get_content().scale = lerp(item.get_content().scale, _item_scale * (1 + d_scale), _delta * 10)
		item.get_content().modulate.a = lerpf(item.get_content().modulate.a, 1 - d_alpha, _delta * 5)
	_visible_list.append(item_index)
	item.show()

func _hide_item(item_index):
	if item_index < 0 || item_index >= _item_list.size(): return
	var item = _item_list[item_index]
	item.hide()

func _update_cursor():
	if static_cursor: return
	$Cursor.rotation = _current_rotation

func _calc_nearest_slot_index(angle: float): # this could be made more efficient
	angle = _normalize_angle(angle)
	var min_diff = PI
	var index = -1
	for i in slots:
		var diff = _calc_angle_diff(angle, _calc_slot_angle(i))
		if diff < min_diff:
			min_diff = diff
			index = i
	return index

func _highlight_slot(new_slot_index: int):
	if new_slot_index >= slots: return
	var d_index = _calc_rotation_vector(new_slot_index, _slot_index, slots)
	var new_item_index = _item_index + d_index
	if !wrap_item_list:
		if new_item_index < 0 || new_item_index >= _item_list.size():
			return
	else:
		new_item_index = posmod(new_item_index, _item_list.size())
	_item_index = new_item_index
	_slot_index = new_slot_index
	_update_items()

func _set_highlight():
	for item in _item_list:
		item.set_highlight(false)
	if _item_index < 0 || _item_index >= _item_list.size(): return
	_item_list[_item_index].set_highlight(true)

func _emit_item_selected():
	if _item_index < 0 || _item_index >= _item_list.size(): return
	item_selected.emit(_slot_index, _item_list[_item_index])

func _normalize_angle(angle: float):
	return fposmod(angle, 2*PI) # convert the coordinates to [0, 2PI]

func _calc_input_angle(input_vector: Vector2):
	var angle = input_vector.angle() + PI # input angle is [-PI, PI], but the menu is [0, 2PI]
	angle -= PI/2 # rotate coordinates so that 0 is "up"
	return _normalize_angle(angle)

func _calc_rotation_direction(a, b, mid):
	if a == b: return 0
	if abs(a - b) <= mid:
		return -1 if a < b else 1
	else:
		return -1 if b < a else 1

func _calc_rotation_vector(a, b, max_n):
	var mid = max_n / 2.0
	var d = abs(a - b)
	d = max_n - d if d > mid else d
	return d * _calc_rotation_direction(a, b, mid)

func _calc_angle_diff(a, b):
	return abs(_calc_rotation_vector(a, b, 2*PI))

func _calc_slot_angle(slot_index):
	return _angle_interval * slot_index
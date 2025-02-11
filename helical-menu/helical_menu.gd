extends Node2D

signal item_selected(index: int, item: MenuItem)

## The number of visible slots on the helical menu. Should be an odd number for ideal spacing.
@export_custom(PROPERTY_HINT_NONE, "suffix:slots") var num_slots: int = 11
## The base radius of the helical menu, in pixels.
@export_custom(PROPERTY_HINT_NONE, "suffix:px") var menu_radius: float = 300
## The scaling ratio of the menu items.
@export var item_scale_ratio: float = 1
## Rotate the menu instead of the cursor.
@export var static_cursor: bool = false
## When no input is detected, maintain the last highlighted item. When [member static_cursor] is enabled, this is always true.
@export var maintain_highlight: bool = false

@onready var _angle_interval = 2*PI / num_slots
@onready var _item_scale = Vector2(item_scale_ratio, item_scale_ratio)

var _item_list: Array[MenuItem] = []
var _slot_index: int = 0

# static cursor mode
var _is_rotating = false
var _current_rotation = 0
var _menu_offset = 0
var _input_offset = 0

func set_item_list(list: Array[MenuItem]):
	if list.size() > num_slots: list.resize(num_slots)
	_item_list = list

func instantiate():
	$Cursor/Sprite.position.y = -(menu_radius - (200 * item_scale_ratio))
	$Cursor/Sprite.scale = _item_scale

	if static_cursor:
		$Cursor.rotation = 0

	for item in _item_list:
		call_deferred('add_child', item)
	_update_items()

func _process(_delta: float) -> void:
	var input_vector = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')
	if static_cursor: _highlight_with_static_cursor(input_vector)
	else: _highlight_with_radial_cursor(input_vector)

	if Input.is_action_just_pressed("ui_select"): _emit_item_selected()

func _highlight_with_radial_cursor(input_vector: Vector2):
		if input_vector == Vector2.ZERO:
			$Cursor.hide()
			if !maintain_highlight: _un_highlight_all()
			return

		var input_angle = _get_input_angle(input_vector)
		$Cursor.show()
		$Cursor.rotation = input_angle
		_highlight_nearest_slot(input_angle)

func _highlight_with_static_cursor(input_vector: Vector2):
	if input_vector == Vector2.ZERO:
		_current_rotation = _get_nearest_slot_angle(_current_rotation)
		_update_items()
		_menu_offset = _current_rotation
		_is_rotating = false
		return

	var input_angle = _get_input_angle(input_vector)
	if !_is_rotating:
		_input_offset = input_angle
		_is_rotating = true
	input_angle -= _input_offset
	input_angle += _menu_offset

	_current_rotation = input_angle
	_update_items()

	_highlight_nearest_slot(-input_angle)

func _update_items():
	for i in num_slots:
		if i >= _item_list.size(): return
		var item = _item_list[i]
		var angle = _angle_interval * i + _current_rotation
		item.rotation = angle
		item.get_content().rotation = -angle
	
	_update_item_transform(_slot_index)

	var idx_up = _slot_index + 1
	var idx_down = _slot_index - 1
	var n = floor((num_slots - 1) / 2.0)
	for i in n:
		if idx_up >= num_slots: idx_up = 0
		if idx_down < 0: idx_down = num_slots - 1

		var d_radius = 0.5 * menu_radius / n * (i+1)
		var d_scale = .1 * (i+1)
		var d_alpha = 1/(n-0.5) * i

		_update_item_transform(idx_up, d_radius, d_scale, d_alpha)
		_update_item_transform(idx_down, -d_radius, -d_scale, d_alpha)

		idx_up += 1
		idx_down -= 1

func _update_item_transform(index, d_radius = 0, d_scale = 0, d_alpha = 0):
	var item = _item_list[index]
	item.get_content().position.y = -menu_radius - d_radius
	item.get_content().scale = _item_scale * (1 + d_scale)
	item.get_icon().modulate.a = 1 - d_alpha

func _highlight_nearest_slot(angle: float): # this could be made more efficient
	angle = _normalize_angle(angle)
	var min_diff = PI
	var index = -1
	for i in num_slots:
		var diff = _angle_diff(angle, i * _angle_interval)
		if diff < min_diff:
			min_diff = diff
			index = i
	if _slot_index != index: _highlight_slot(index)

func _get_nearest_slot_angle(angle: float) -> float: # this could be made more efficient
	angle = _normalize_angle(angle)
	var min_diff = PI
	var nearest_angle = 0
	for i in num_slots:
		var diff = _angle_diff(angle, i * _angle_interval)
		if diff < min_diff:
			min_diff = diff
			nearest_angle = i * _angle_interval
	return nearest_angle

func _highlight_slot(index: int):
	_un_highlight_all()
	if index >= num_slots: return
	_slot_index = index
	_update_items()
	if index >= _item_list.size(): return
	_item_list[index].set_highlight(true)

func _un_highlight_all():
	for item in _item_list:
		item.set_highlight(false)

func _emit_item_selected():
	if _slot_index == -1 || _slot_index >= _item_list.size(): return
	item_selected.emit(_slot_index, _item_list[_slot_index])

func _get_input_angle(input_vector: Vector2):
	var angle = input_vector.angle() + PI # input angle is [-PI, PI], but the menu is [0, 2PI]
	angle -= PI/2 # rotate coordinates so that 0 is "up"
	return _normalize_angle(angle)

func _normalize_angle(angle: float):
	return fposmod(angle, 2*PI) # convert the coordinates to [0, 2PI]

func _angle_diff(a, b):
	var d = abs(a - b)
	return 2*PI - d if d > PI else d

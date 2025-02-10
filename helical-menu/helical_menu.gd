extends Node2D

# TEST
@export var test_list_size: int = 15
var test_item_scene = preload("res://helical_menu_item.tscn")

@export var num_visible_items: int = 12
@export var radius: float = 300
@export var static_cursor: bool = false
@export var loop_list: bool = false

var angle_interval = 2*PI / num_visible_items
var item_list: Array[HelicalMenuItem] = []
var item_index: int = 0
var slot_index: int = 0

func _ready() -> void:
	for i in test_list_size:
		var item = test_item_scene.instantiate() as HelicalMenuItem
		item.set_modulate(Color(randf(), randf(), randf()))
		item.get_content().apply_scale(Vector2(pow(1.05, i) - .1, pow(1.05, i) - .1))
		item_list.append(item)
	instantiate()

func instantiate():
	for i in item_list.size():
		var item = item_list[i]
		var content = item.get_content()
		var angle = angle_interval * i
		item.rotation = angle
		content.position.y = -radius # so 0th item is "up"
		content.rotation = -angle
		
		call_deferred('add_child', item)

func _process(delta: float) -> void:
	var input_vector = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')
	var input_angle = input_vector.angle() + PI # input angle is [-PI, PI], but the menu is [0, 2PI]
	input_angle = fposmod(input_angle - PI/2, 2*PI) # rotate coordinates so that 0 is "up"
	if input_vector != Vector2.ZERO:
		var angle = fposmod(nearest_select_angle_to(input_angle) + PI/2, 2*PI) # rotate back to original orientation
		$TestCursor.rotation = angle - PI # convert back to [-PI, PI]

func nearest_select_angle_to(angle: float) -> float: # this could be made more efficient
	var min_diff = PI
	var nearest_angle = 0
	for i in num_visible_items:
		var diff = angle_diff(angle, i * angle_interval)
		if diff < min_diff:
			min_diff = diff
			nearest_angle = i * angle_interval
	return nearest_angle

func select_nearest_slot(angle: float): # this could be made more efficient
	var min_diff = PI
	var index = -1
	for i in num_visible_items:
		var diff = angle_diff(angle, i * angle_interval)
		if diff < min_diff:
			min_diff = diff
			index = i
	if slot_index != index: select_slot(index)

func select_slot(index: int):
	if index >= num_visible_items: return
	slot_index = index
	for item in item_list:
		item.get_content().position.y = -radius
	# TODO

func angle_diff(a, b):
	var d = abs(a - b)
	if d > PI: return 2*PI - d
	return d

extends Node2D

# TEST
@export var test_list_size: int = 15
var test_item_scene = preload("res://helical_menu_item.tscn")

@export var num_visible_items: int = 12
@export var radius: float = 300
@export var static_cursor: bool = false
@export var loop_list: bool = false

var item_list: Array[HelicalMenuItem] = []
var index: int = 0
var angle_interval = 2*PI / num_visible_items

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
		$TestCursor.rotation = angle - PI # convert back to original [-PI, PI] range

var item = 0

func nearest_select_angle_to(angle: float) -> float: # this could be made more efficient
	var nearest_angle = 0
	var min_diff = PI
	var new_item = -1
	for i in num_visible_items:
		var select_angle = i * angle_interval
		var diff = angle_diff(angle, select_angle)
		#if i == 10: print('%s %s %s'%[rad_to_deg(angle), rad_to_deg(select_angle), rad_to_deg(diff)])
		if diff < min_diff:
			min_diff = diff
			nearest_angle = select_angle
			new_item = i
	if item != new_item:
		item = new_item
		print('%s: %s'%[item, nearest_angle/PI])
	return nearest_angle

func angle_diff(a, b):
	var d = abs(a - b)
	if d > PI: return 2*PI - d
	return d

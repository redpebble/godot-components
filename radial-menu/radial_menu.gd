extends Node2D

# TESTING
var test_item_scene = preload("res://menu_item.tscn")

@export var num_slots: int = 12
@export var menu_radius: float = 300
@export var item_scale_ratio: float = 1
@export var static_cursor: bool = false
@export var maintain_highlight: bool = false

@onready var angle_interval = 2*PI / num_slots
@onready var item_scale = Vector2(item_scale_ratio, item_scale_ratio)

var item_list: Array[MenuItem] = []
var slot_index: int = -1

func _ready() -> void:
	# TESTING
	for i in num_slots:
		var item = test_item_scene.instantiate() as MenuItem
		item.get_icon().set_modulate(Color(randf(), randf(), randf()))
		item_list.append(item)
	instantiate()

func instantiate():
	$Cursor/Sprite.position.y = -(menu_radius - (200 * item_scale_ratio))
	$Cursor/Sprite.scale = item_scale
	for i in num_slots:
		if i >= item_list.size(): return
		var item = item_list[i]
		var content = item.get_content()
		var angle = angle_interval * i
		item.rotation = angle
		content.position.y = -menu_radius # so 0th item is "up"
		content.rotation = -angle
		content.scale = item_scale
		
		call_deferred('add_child', item)

func _process(delta: float) -> void:
	var input_vector = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')
	if input_vector == Vector2.ZERO:
		$Cursor.hide()
		if !maintain_highlight: un_highlight_all()
	else:
		var input_angle = input_vector.angle() + PI # input angle is [-PI, PI], but the menu is [0, 2PI]
		$Cursor.show()
		$Cursor.rotation = input_angle - PI/2
		input_angle = fposmod(input_angle - PI/2, 2*PI) # rotate coordinates so that 0 is "up"
		highlight_nearest_slot(input_angle)
		

func get_nearest_slot_angle(angle: float) -> float: # this could be made more efficient
	var min_diff = PI
	var nearest_angle = 0
	for i in num_slots:
		var diff = angle_diff(angle, i * angle_interval)
		if diff < min_diff:
			min_diff = diff
			nearest_angle = i * angle_interval
	return nearest_angle

func highlight_nearest_slot(angle: float): # this could be made more efficient
	var min_diff = PI
	var index = -1
	for i in num_slots:
		var diff = angle_diff(angle, i * angle_interval)
		if diff < min_diff:
			min_diff = diff
			index = i
	if slot_index != index: highlight_slot(index)

func highlight_slot(index: int):
	un_highlight_all()
	if index >= num_slots: return
	slot_index = index
	if index >= item_list.size(): return
	item_list[index].set_highlight(true)

func un_highlight_all():
	slot_index = -1
	for item in item_list:
		item.set_highlight(false)

func angle_diff(a, b):
	var d = abs(a - b)
	return 2*PI - d if d > PI else d

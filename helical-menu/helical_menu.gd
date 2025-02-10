extends Node2D

@export var num_visible_items: int = 12
@export var radius: float = 300
@export var static_cursor: bool = false
@export var loop_list: bool = false

var item_scene = preload("res://helical_menu_item.tscn")
var item_list: Array[HelicalMenuItem] = []
var index: int = 0

func _ready() -> void:
	for i in 15:
		var item = item_scene.instantiate()
		item.set_modulate(Color(randf(), randf(), randf()))
		item_list.append(item)
	instantiate()

func instantiate():
	var angle_interval = 2*PI / num_visible_items
	for i in item_list.size():
		var item = item_list[i]
		var content = item.get_content()
		var angle = angle_interval * i - PI/2
		item.rotation = angle
		content.position.x = radius
		content.rotation = -angle
		
		call_deferred('add_child', item)

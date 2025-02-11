extends Node2D

var test_item_scene = preload("res://menu_item.tscn")

func _ready() -> void:
	var item_list: Array[MenuItem] = []
	for i in $RadialMenu.num_slots:
		var item = test_item_scene.instantiate() as MenuItem
		item.get_icon().set_modulate(Color(randf(), randf(), randf()))
		item_list.append(item)
	$RadialMenu.set_item_list(item_list)
	$RadialMenu.instantiate()

func _on_radial_menu_item_selected(index: int, _item: MenuItem) -> void:
	print('item selected: %s'%[index])

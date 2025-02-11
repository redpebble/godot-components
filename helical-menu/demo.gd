extends Node2D

var test_item_scene = preload("res://menu_item.tscn")

func _ready() -> void:
	var item_list: Array[MenuItem] = []
	for i in 1000:
		var item = test_item_scene.instantiate() as MenuItem
		item.get_icon().set_modulate(Color(randf(), randf(), randf()))
		item.get_label().text = str(i)
		item_list.append(item)
	$HelicalMenu.set_item_list(item_list)
	$HelicalMenu.instantiate()

func _on_helical_menu_item_selected(slot_index: int, item: MenuItem) -> void:
	print('item selected: %s (%s)'%[item.get_label().text, slot_index])

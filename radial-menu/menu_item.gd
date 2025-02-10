class_name MenuItem
extends Node2D

func get_content() -> Node2D:
	return $Content

func get_icon() -> Sprite2D:
	return $Content/Icon

func set_highlight(b: bool):
	if b: $Content/Highlight.show()
	else: $Content/Highlight.hide()

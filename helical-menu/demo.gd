extends Node2D

func _process(delta: float) -> void:
	var input_vector = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down')
	if input_vector == Vector2.ZERO:
		$TestCursor.hide()
	else:
		$TestCursor.show()
		$TestCursor.rotation = input_vector.angle()

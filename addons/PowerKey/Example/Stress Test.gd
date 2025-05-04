extends VBoxContainer


func _on_button_add_pressed(type:String) -> void:
	var expression := ''
	match type:
		'assign':
			expression = 'A:text nonexistent_var'
		'link':
			expression = 'L:text nonexistent_var'
		'execute':
			expression = 'E var _test = 1+1'
	for i in range(1000):
		var new_node := Node.new()
		new_node.set_meta('PKExpressions', expression)
		$Host.add_child(new_node)
	$'Expression Count'.text = 'Expression Count: %s' % $Host.get_child_count()


func _on_button_clear_pressed() -> void:
	for child in $Host.get_children():
		child.free()
	$'Expression Count'.text = 'Expression Count: %s' % $Host.get_child_count()

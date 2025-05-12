extends MarginContainer
var example_scene := preload('res://addons/PowerKey/Example/Example.tscn')

var Current_pkexpressions:String

func _ready() -> void:
	_update_expression_count()


func _update_expression_count() -> void:
	%'PKExpression Count'.text = 'PKExp & Node Count: %s' % %Host.get_child_count()




func _on_button_add_expression_pressed(amount:int) -> void:
	for i in range(amount):
		var new_node := Node.new()
		new_node.set_meta('PKExpressions', Current_pkexpressions)
		%Host.add_child(new_node)
	_update_expression_count()

func _on_button_clear_expressions_pressed() -> void:
	for child in %Host.get_children():
		child.free()
	_update_expression_count()




func _on_button_add_scene_pressed() -> void:
	var new_scene := example_scene.instantiate()
	%'Scene Host/VBox'.add_child(new_scene)
	var new_separator := HSeparator.new()
	new_separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	%'Scene Host/VBox'.add_child(new_separator)

func _on_button_clear_scenes_pressed() -> void:
	for child in %'Scene Host/VBox'.get_children():
		child.queue_free()



func _on_pkexpression_editor_update(pk_expressions:String) -> void:
	Current_pkexpressions = pk_expressions

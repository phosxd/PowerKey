extends MarginContainer
var example_scene := preload('res://addons/PowerKey/Example/Example.tscn')

func _on_button_add_scene_pressed() -> void:
	var new_scene := example_scene.instantiate()
	%'Scene Host/VBox'.add_child(new_scene)
	var new_separator := HSeparator.new()
	new_separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	%'Scene Host/VBox'.add_child(new_separator)

func _on_button_clear_scenes_pressed() -> void:
	for child in %'Scene Host/VBox'.get_children():
		child.queue_free()

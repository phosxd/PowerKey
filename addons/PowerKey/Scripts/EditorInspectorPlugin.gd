extends EditorInspectorPlugin
const PKExpression_Editor := preload('res://addons/PowerKey/Editor/Editor Inspector/PKExpression Editor.tscn')

func _can_handle(object:Object) -> bool:
	return true if object is Node else false # Return true if is a Node.

func _parse_category(object:Object, category:String) -> void:
	if category == 'Node':
		# Create PKExpression Editor instance & initialize it.
		var PKExpEditor_instance := PKExpression_Editor.instantiate()
		var pk_expressions = object.get_meta('PKExpressions', false)
		if pk_expressions:
			PKExpEditor_instance.init(pk_expressions)
		# On PKExp Editor sends update signal, update the Node.
		PKExpEditor_instance.on_update.connect(func(raw_lines:String) -> void:
			object.set_meta('PKExpressions', raw_lines)
		)
		# Add PKExpression Editor to the inspector for this Node.
		self.add_custom_control(PKExpEditor_instance)

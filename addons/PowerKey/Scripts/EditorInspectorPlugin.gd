# This script is responsible for adding the "PKExpressions" dropdown option for Nodes in the Insector dock.

extends EditorInspectorPlugin
const PKExp_Dropdown := preload('res://addons/PowerKey/Editor/Inspector/PKExp Dropdown.tscn')


func _can_handle(object:Object) -> bool:
	return true if object is Node else false # Return true if is a Node.


func _parse_category(object:Object, category:String) -> void:
	if category == 'Node':
		# Create PKExpression Editor instance & initialize it.
		var dropdown_instance := PKExp_Dropdown.instantiate()
		var pkexps = object.get_meta('PKExpressions', false)
		var pkexps_parsed = object.get_meta('PKExpressions_parsed', Array([],TYPE_DICTIONARY,'',null))
		if pkexps:
			if typeof(pkexps) == TYPE_STRING_NAME:
				dropdown_instance.init(pkexps, pkexps_parsed)
			elif typeof(pkexps) == TYPE_STRING:
				dropdown_instance.init(StringName(pkexps), pkexps_parsed)
			
		# On PKExp Editor sends update signal, update the Node.
		dropdown_instance.on_update.connect(func(raw:StringName, parsed:Array[Dictionary]) -> void:
			# NOTE: Adding or removing metadata modifies Inspector controls, which closes the PKExpEditor dropdown. This is sort-of counteracted in the PKExpEditor Script.
			# If empty, remove data & return.
			if raw.strip_edges() == '':
				object.remove_meta('PKExpressions')
				if object.has_meta('PKExpressions_parsed'): object.remove_meta('PKExpressions_parsed')
				return
			# Update data.
			object.set_meta('PKExpressions', raw)
			if parsed.size() > 0:
				object.set_meta('PKExpressions_parsed', parsed)
			# If empty parsed data, try to remove it.
			else:
				if object.has_meta('PKExpressions_parsed'): object.remove_meta('PKExpressions_parsed')
		)
		
		# Add PKExpression Editor to the inspector for this Node.
		self.add_custom_control(dropdown_instance)

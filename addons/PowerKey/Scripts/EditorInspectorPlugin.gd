# This script is responsible for adding the "PKExpressions" dropdown option for Nodes in the Inspector dock.
extends EditorInspectorPlugin
const PKExp_Dropdown := preload('res://addons/PowerKey/Editor/Inspector/PKExp Dropdown.tscn')


func _can_handle(object:Object) -> bool: ## Determine what Object types this Inspector Plugin will handle.
	return true if object is Node else false # Return true if is a Node.


func _parse_category(object:Object, category:String) -> void: ## Parse a category in the Inspector window.
	if category != 'Node': return
	# Create PKExps Dropdown Editor instance & initialize it.
	var dropdown_instance := PKExp_Dropdown.instantiate()
	var pkexps = object.get_meta('PKExpressions', false)
	var pkexps_parsed = object.get_meta('PKExpressions_parsed', Array([],TYPE_DICTIONARY,'',null))
	if pkexps:
		# If pkexps is normal String, convert to StringName.
		if typeof(pkexps) == TYPE_STRING: pkexps = StringName(pkexps)
		# Initialize the PKExps Dropdown Editor.
		dropdown_instance.init(pkexps, pkexps_parsed)
		
	# On PKExp Editor sends update signal, update the Node.
	dropdown_instance.on_update.connect(func(raw:StringName, parsed:Array[Dictionary], _parse_time:float) -> void:
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
	
	# Add PKExpression Dropdown Editor to the inspector for this Node.
	self.add_custom_control(dropdown_instance)

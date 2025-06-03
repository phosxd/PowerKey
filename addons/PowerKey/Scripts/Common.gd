@tool
class_name PK_Common
## Holds functions and constants, that are used across various scripts.

## Dictionary or Array schemas. A `null` value represents something that can be anything.
const Schemas:Dictionary = {
	'config': {
		'latest': {
			'version': '1',
			'resources_script_path': '',
			'max_cached_pkexpressions': 3,
			'debug_print_any_pkexpression_processed': false,
		},
	},
	'translation_entry': [
		'',
		null,
		null,
	],
}


static func match_schema(object:Dictionary, schema:Dictionary) -> Dictionary[String,Variant]: ## Tests if the object matches the schema. Any mismatched values of the object will be set to the schema's default.
	var different:bool = false
	for key in schema:
		if key in object:
			if typeof(schema[key]) == typeof(object[key]) || schema[key] == null: continue
		object.set(key, schema[key])
		different = true

	return {
		'different': different,
		'object': object,
	}


static func match_array_schema(object:Array, schema:Array) -> Dictionary[String,Variant]: ## Tests if the object matches the schema. Any mismatched values of the object will be set to the schema's default.
	var duped_object := object.duplicate() # Use duplicated array so it doesn't affect the original array.
	var different:bool = false
	var object_size:int = duped_object.size()
	var index:int = -1
	for item in schema:
		index += 1
		if index < object_size:
			if typeof(item) == typeof(duped_object[index]) || item == null: continue
		duped_object.append(item)
		different = true

	return {
		'different': different,
		'object': duped_object,
	}




static func _get_value_error_helper_1(stopped_value, node:Node, raw_expression:String) -> void:
	printerr(PK_EE.Errors.pkexp_accessing_unsupported_builtin_type % [raw_expression, node.name, type_string(typeof(stopped_value))])
static func _get_value_error_helper_2(var_name:String, object_type:String, node:Node, raw_expression:String) -> void:
	printerr(PK_EE.Errors.pkexp_accessing_nonexistent_property_for_builtin_type % [raw_expression, node.name, var_name, object_type])


static func get_value(split_varpath:PackedStringArray, node:Node, raw_expression:String, resources): ## Gets the value of a variable in Resources Script. Returns Variant. If failed, reutrns null.
	if split_varpath[0] not in resources:
		_get_value_error_helper_2(split_varpath[0], type_string(typeof(resources)), node, raw_expression)
		return
	var variable = resources.get(split_varpath[0]) # Get top-level value from Resources.
	var variable_type:int
	for i in range(1,split_varpath.size()): # Iterate through all variable paths after the first index.
		# Return early if value is null.
		if variable == null:
			_get_value_error_helper_1(variable, node, raw_expression)
			return
		variable_type = typeof(variable)
		# Get next value from objects or dictionaries with dynamic set of properties.
		if variable_type in [TYPE_DICTIONARY,TYPE_OBJECT]:
			if split_varpath[i] not in variable:
				_get_value_error_helper_2(split_varpath[i], type_string(variable_type), node, raw_expression)
				return
			variable = variable[split_varpath[i]]
		# Get next value from built-in types with strict set of properties.
		elif variable_type in PK_EE.Valid_properties_for_builtin_type:
			if split_varpath[i] not in PK_EE.Valid_properties_for_builtin_type[variable_type]:
				_get_value_error_helper_2(split_varpath[i], type_string(variable_type), node, raw_expression)
				return
			variable = variable[split_varpath[i]]
		# Get next value from an Array.
		elif variable_type in PK_EE.Array_builtin_types:
			var index = int(split_varpath[i])
			if index == 0 && split_varpath[i] != '0' || index > variable.size()-1:
				_get_value_error_helper_2(split_varpath[i], type_string(variable_type), node, raw_expression)
				return
			variable = variable[index]
		# If other type, throw error.
		else:
			_get_value_error_helper_1(variable, node, raw_expression)
			return

	return variable

class_name PK_Parser extends Node
const ExpTypes := {
	'assign': 'A',
	'link': 'L',
	'execute': 'E',
}
const ExpTypes_require_property_name := ['assign','link']
const Comment_token := '#' ## Used to denote a commented line.
const Property_name_requester_token := ':' # Should NEVER be more than one character.
const Valid_property_name_characters := 'abcdefghijklmnopqrstuvwxyz0123456789_.'
const Valid_property_name_starting_characters := 'abcdefghijklmnopqrstuvwxyz_'
const Valid_assign_content_characters := 'abcdefghijklmnopqrstuvwxyz0123456789_.'
const Supported_pkexp_value_property_types := ['Dictionary','Object', 'Vector2']
const Errors := {
	'pkexp_parse_failed': 'PowerKey: Failed to process PKExpression "%s" for Node "%s" with reason "%s".',
	'pkexp_property_not_found': 'PowerKey: Failed to find property "%s" for Node "%s" in Resources Script ("%s").',
	'pkexp_property_not_found_in_node': 'PowerKey: Failed to find property "%s" in Node "%s".',
	'pkexp_accessing_unsupported_type': 'PowerKey: PKExpression "%s" for Node "%s" tried requesting property from an unsupported Type "%s", expected one of the following: %s.',
	'pkexp_accessing_nonexistent_value_on_vector2': 'PowerKey: PKExpression "%s" for Node "%s" tried accessing non-existent property "%s" from a "Vector2".',
}
const Parse_Errors := [
	'Invalid expression type',
	'Invalid starting character in property name',
	'Invalid character in property name',
	'Assign/Link expression content should only contain basic characters',
	'No expression type defined',
	'No content defined',
]
const Link_timer_name := '_pk_link_timer'
var Execute_script := GDScript.new()
var Execute_script_code_template := 'static func %s(S, PK) -> void:\n	S=S; PK=PK;\n%s'

var Config
var Resources
var cached_pkexpressions:Array[Array] = []

func init(config:Dictionary, resources) -> void:
	Config = config
	Resources = resources





# PKExpression functions.
# -----------------------
func parse_pkexp(text:String): ## Parses a PowerKey expression. Returns expression details. Returns null if invalid expression.
	# Check cache, return cached result is available.
	if not Engine.is_editor_hint():
		var cached:Dictionary
		for i in cached_pkexpressions:
			if i[0] != text: continue
			cached = i[1]
		if cached: return cached

	var error := 0
	var expression_type:String
	var property_name:String
	var content:String
	var stage := 'expression_type' ## The parsing stage.
	var expecting_flag := 0

	# If comment line, throw silent error.
	if text.begins_with(Comment_token):
		error = 999
		return {'error':error}


	for char in text:
		if stage == 'expression_type':
			# Set expression type.
			if char == Property_name_requester_token:
				stage = 'property_name'
				expecting_flag = 0
				# Throw error if not a valid expression type.
				if expression_type not in ExpTypes.values():
					error = 1
					break
			# Progress to content stage if not specifying "property_name".
			elif char == ' ':
				stage = 'content'
				expecting_flag = 0
				# Throw error if not a valid expression type.
				if expression_type not in ExpTypes.values():
					error = 1
					break
			# Add to expression_type.
			else:
				expression_type += char

		elif stage == 'property_name':
			# Progress to translation_key stage.
			if char == ' ':
				stage = 'content'
				expecting_flag = 0
			# Throw error if invalid start of property name.
			elif expecting_flag == 0 && char.to_lower() not in Valid_property_name_starting_characters:
				error = 2
				break
			# Throw error if invalid character.
			elif char.to_lower() not in Valid_property_name_characters:
				error = 3
				break
			# Look for start of property name.
			if expecting_flag == 0 && char.to_lower() in Valid_property_name_starting_characters:
				property_name += char
				expecting_flag = 1
			# Add to property name.
			elif expecting_flag == 1 && char.to_lower() in Valid_property_name_characters:
				property_name += char

		elif stage == 'content':
			# If expression type == assign.
			if expression_type in [ExpTypes.assign, ExpTypes.link]:
				# Throw error if invalid character for an "assign" expression.
				if char.to_lower() not in Valid_assign_content_characters:
					error = 4
					break
			# Add to content.
			content += char


	# Error checks.
	if error != 0: pass
	elif expression_type == '':
		error = 5
	elif expression_type not in ExpTypes.values():
		error = 1
	elif content == '':
		error = 6

	var result := {
		'error': error,
		'type': expression_type,
		'property_name': property_name,
		'content': content,
	}
	# Cache expression for reuse.
	if not Engine.is_editor_hint():
		cached_pkexpressions.append([text,result])
		if cached_pkexpressions.size() > Config.max_cached_pkexpressions:
			cached_pkexpressions.remove_at(0)
	# Return.
	return result




func process_pkexp(node:Node, raw_expression:String, parsed:Dictionary) -> void: ## Executes a parsed PowerKey expression on the Node.
	# Debug printing.
	if Config.debug_print_any_pkexpression_processed:
		print_rich('[b][color=gold]PowerKey Debug:[/color][/b] Now processing expression "[color=tomato]%s[/color]" on Node "[color=orange]%s[/color]" ("[color=dim_gray]%s[/color]").' % [raw_expression, node.name, node.get_instance_id()])

	match parsed.type:
		# Assign expression.
		ExpTypes.assign:
			if parsed.property_name == '': return # Return if no property name.
			var value = _get_value(parsed.content.split('.'), node, raw_expression)
			# Set value, regardless of whether or not the Node property or Resources property exists.
			_set_value(parsed.property_name.split('.'), node, value)

		# Link expression.
		ExpTypes.link:
			if parsed.property_name == '': return # Return if no property name.
			# Create new timer.
			var update_timer:Timer
			# Get timer already on Node, if it exists, use this instead.
			if node.has_node(Link_timer_name):
				var current_timer = node.get_node(Link_timer_name)
				update_timer = current_timer
			# If no timer already exists, create new one.
			else:
				update_timer = Timer.new()
				update_timer.name = Link_timer_name
				node.add_child(update_timer)
				update_timer.wait_time = 0.0000001 # Set time to effectively zero.
				update_timer.start()
			# Connect function to process every tick.
			var last_value
			var split_content:PackedStringArray = parsed.content.split('.')
			update_timer.timeout.connect(func():
				var value = _get_value(split_content, node, raw_expression)
				# Set value if different.
				if value != last_value:
					# Set value, regardless of whether or not the Node property or Resources property exists.
					_set_value(parsed.property_name.split('.'), node, value)
					last_value = value
			)

		# Execute expression.
		ExpTypes.execute:
			var func_name := '_PK_function'
			# Define code.
			var gd_code := Execute_script_code_template % [func_name, parsed.content.indent('	')]
			# Apply source code to script.
			if Execute_script.source_code != gd_code:
				Execute_script.source_code = gd_code
				Execute_script.reload()
			Execute_script.call(func_name, node, Resources)






# Utility functions.
func _get_value_error_helper_1(stopped_value, node:Node, raw_expression:String) -> void:
	printerr(Errors.pkexp_accessing_unsupported_type % [raw_expression, node.name, type_string(typeof(stopped_value)),', '.join(Supported_pkexp_value_property_types)])
func _get_value_error_helper_2(var_name, node:Node, raw_expression:String) -> void:
	printerr(Errors.pkexp_accessing_nonexistent_value_on_vector2 % [raw_expression, node.name, var_name])

func _get_value(split_varpath:PackedStringArray, node:Node, raw_expression:String): ## Gets the value of a variable in Resources Script. Returns Variant. If failed, reutrns null.
	var variable = Resources.get(split_varpath[0]) # Get top-level value from Resources.
	for i in range(1,split_varpath.size()):
		# Return early if value is null.
		if variable == null:
			_get_value_error_helper_1(variable, node, raw_expression)
			return
		# Get next value based on current value type.
		match typeof(variable):
			# If acessing property of a Dictionary or Object, proceed.
			TYPE_DICTIONARY, TYPE_OBJECT:
				variable = variable.get(split_varpath[i])
			# If acessing property of a Vector2, proceed.
			TYPE_VECTOR2:
				# If invalid access, return & throw error.
				if split_varpath[i] not in 'xy':
					_get_value_error_helper_2(split_varpath[i], node, raw_expression)
					return
				variable = variable[split_varpath[i]]
			# If other type, return & throw error.
			_:
				_get_value_error_helper_1(variable, node, raw_expression)
				return
	return variable


func _set_value(split_varpath:PackedStringArray, target:Node, value) -> void: ## Sets the value of a variable in the target.
	var split_varpath_size := split_varpath.size()
	# If top-level, set directly.
	if split_varpath_size < 2:
		target.set(split_varpath[0], value)
		return
	var variable = target.get(split_varpath[0]) # Get top-level variable from target.
	
	return
	# NOTE: This code is blocked off because it doesn't work properly yet. For now, only top-level setting is possible.
	for i in range(1,split_varpath.size()):
		# Set value on the variable.
		if split_varpath_size-1 == i:
			match typeof(variable):
				TYPE_DICTIONARY, TYPE_OBJECT:
					variable.set(split_varpath[i], value)
				TYPE_VECTOR2:
					if split_varpath[i] not in 'xy': return # Return if invalid property.
					variable[split_varpath[i]] = value
				_:
					target.set(split_varpath[i], value)
			return

		# Get next value based on current value type.
		match typeof(variable):
			# If acessing property of a Dictionary or Object, proceed.
			TYPE_DICTIONARY, TYPE_OBJECT:
				variable = variable.get(split_varpath[i])
			# If acessing property of a Vector2, proceed.
			TYPE_VECTOR2:
				if split_varpath[i] not in 'xy': return # Return if invalid property.
				variable = variable[split_varpath[i]]
			# If other type, return & throw error.
			_:
				return

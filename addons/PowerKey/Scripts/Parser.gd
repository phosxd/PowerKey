# This script handles all proccessing & parsing of PKExpressions.
# New instance should be created if used (call `.new`).

class_name PK_Parser extends Node
const ExpTypes:Dictionary[StringName,StringName] = {
	'assign': 'A',
	'link': 'L',
	'execute': 'E',
}
const ExpType_values:Array[String] = ['A','L','E'] ## Pre-compiled ExpType values as array.
const Lowercases:Dictionary[StringName,StringName] = {'A':'a','B':'b','C':'c','D':'d','E':'e','F':'f','G':'g','H':'h','I':'i','J':'j','K':'k','L':'l','M':'m','N':'n','O':'o','P':'p','Q':'q','S':'s','T':'t','U':'u','V':'v','W':'w','X':'x','Y':'y','Z':'z'} ## Performs better than using `.to_lower`.
const Comment_token:StringName = '#' ## Used to denote a commented line.
const Parameter_separator:StringName = ',' ## Used to separate expression parameters.
const Property_name_requester_token:StringName = ':' # Should NEVER be more than one character.
const Valid_property_name_characters:StringName = 'abcdefghijklmnopqrstuvwxyz0123456789_.'
const Valid_property_name_starting_characters:StringName = 'abcdefghijklmnopqrstuvwxyz_'
const Supported_pkexp_value_property_types:Array[StringName] = ['Dictionary','Object', 'Vector2']
const Errors:Dictionary[StringName,StringName] = {
	'pkexp_parse_failed': 'PowerKey PKExpression: (@char %s) Failed to parse expression "%s" for Node "%s" with reason "%s".',
	'pkexp_property_not_found': 'PowerKey PKExpression: (@char %s) Failed to find property "%s" for Node "%s" in Resources Script ("%s").',
	'pkexp_property_not_found_in_node': 'PowerKey PKExpression: (@char %s) Failed to find property "%s" in Node "%s".',
	'pkexp_accessing_unsupported_type': 'PowerKey PKExpression: (@char %s) Expression "%s" for Node "%s" tried requesting property from an unsupported Type "%s", expected one of the following: %s.',
	'pkexp_accessing_nonexistent_value_on_vector2': 'PowerKey PKExpression: (@char %s) Expression "%s" for Node "%s" tried accessing non-existent property "%s" from a "Vector2".',
}
const Parse_Errors:Array[StringName] = [
	'Invalid expression type',
	'Invalid starting character in variable path',
	'Invalid character in variable path',
	'Assign/Link expression content should only contain basic characters',
	'No expression type defined',
	'No content defined',
	'Parameter cannot be empty',
]
const Link_timer_name := '_pk_link_timer'
var Execute_script:Script = GDScript.new()
var Execute_script_code_template:StringName = 'static func %s(S, PK) -> void:\n	S=S; PK=PK;\n%s'

var Config
var Resources
var cached_pkexps:Dictionary[StringName,Dictionary] = {}
var cached_pkexps_order:Array[StringName] = []

func init(config:Dictionary, resources) -> void:
	Config = config
	Resources = resources





# PKExpression parsing functions.
# -------------------------------
func parse_pkexp(text:StringName): ## Parses a PowerKey expression. Returns expression details. Returns null if invalid expression.
	# Check cache, return cached result is available.
	if not Engine.is_editor_hint():
		if cached_pkexps.has(text):
			return cached_pkexps[text]
	# Define the parsing state & it's data.
	var ps:Dictionary[StringName,Variant] = { ## The parsing state.
		'error': 0, # Parse error. 0 = OK.
		'current_char': 0,
		'type': '', # The expression type.
		'parameters': [], # The expression parameters.
		'content': '', # The expression content.
		'stage': 'type', # The parsing stage.
		'buffers': [], # The current stage's temporary data.
	}
	# If comment line, throw silent error.
	if text.begins_with(Comment_token):
		ps.error = 999
		return ps

	for char in String(text):
		if ps.error != 0: break # Stop if there was an error during the previous iteration.
		ps.current_char += 1
		match ps.stage:
			'type': _parse_type(char, ps)
			'parameters': _parse_parameters(char, ps)
			'content': _parse_content(char, ps)

	# Error checks.
	if ps.error != 0: pass
	elif ps.type == '':
		ps.error = 5
	elif ps.type not in ExpType_values:
		ps.error = 1
	elif ps.content == '':
		ps.error = 6
	# Cache expression for reuse.
	if not Engine.is_editor_hint():
		cached_pkexps[text] = ps
		cached_pkexps_order.append(text)
		if cached_pkexps_order.size() > Config.max_cached_pkexpressions:
			var oldest_key:StringName = cached_pkexps_order.pop_front()
			cached_pkexps.erase(oldest_key)
	# Return the results.
	return ps


func _parse_type(char:String, ps:Dictionary) -> bool: ## Parses the "type" stage. Returns true if ready to progress to next stage.
	# Set expression type.
	if char == Property_name_requester_token:
		ps.stage = 'parameters'
		# Set up buffers.
		ps.buffers.clear()
		ps.buffers.append(0) # expecting flag
		ps.buffers.append('') # current parameter
		# Throw error if not a valid expression type.
		if ps.type not in ExpType_values:
			ps.error = 1
			return true
	# Progress to content stage if not specifying "property_name".
	elif char == ' ':
		ps.stage = 'content'
		ps.buffers.clear()
		ps.buffers.append(0) # expecting flag
		# Throw error if not a valid expression type.
		if ps.type not in ExpType_values:
			ps.error = 1
			return true
	# Add to expression_type.
	else:
		ps.type += char
	return false


func _parse_parameters(char:String, ps:Dictionary) -> bool: ## Parses the "parameters" stage. Returns true if ready to progress to next stage.
	if char == Parameter_separator:
		if ps.buffers[1] == '':
			ps.error = 7
			return true
		ps.parameters.append(StringName(ps.buffers[1]))
		# Reset buffers to stage's default.
		ps.buffers[0] = 0
		ps.buffers[1] = ''
		return true
	else:
		var res:Dictionary = _parse_variable_path(char, ps.buffers[0])
		# If error, throw.
		if res.error != 0:
			ps.error = res.error
			return true
		# Update buffers.
		ps.buffers[0] = res.expecting_flag
		ps.buffers[1] += res.char
		# Move to next stage.
		if res.end:
			if ps.buffers[1] == '':
				ps.error = 7
				return true
			ps.parameters.append(StringName(ps.buffers[1]))
			ps.stage = 'content'
			ps.buffers.clear()
			ps.buffers.append(0) # expecting flag
			return true
	return false


func _parse_content(char:String, ps:Dictionary) -> bool: ## Parses the "content" stage. Retruns true if ready to progress to the next stage.
	# If expression type == assign, handle properly.
	if ps.type in [ExpTypes.assign, ExpTypes.link]:
		var res:Dictionary = _parse_variable_path(char, ps.buffers[0])
		if res.error != 0:
			ps.error = res.error
			return true
		ps.buffers[0] = res.expecting_flag
		if res.end:
			return true
	# Add to content.
	ps.content += char
	return false


func _parse_variable_path(char:String, expecting_flag:int) -> Dictionary: ## Parses a variable path. Returns the error, whether or not it's finished, a character to add to the final String, & the next expecting flag.
	var result:Dictionary = {'error':0, 'end':false, 'char':'', 'expecting_flag':expecting_flag}
	var lower_char:StringName = Lowercases.get(char,char)
	# End current stage.
	if char == ' ':
		result.end = true
		return result
	# Throw error if invalid character.
	elif lower_char not in Valid_property_name_characters:
		result.error = 3
		return result
	# Throw error if invalid start of variable path.
	elif expecting_flag == 0 && lower_char not in Valid_property_name_starting_characters:
		result.error = 2
		return result
	# If start of variable path, add to, & change expecting flag.
	elif expecting_flag == 0 && lower_char in Valid_property_name_starting_characters:
		result.char += char
		result.expecting_flag = 1
	# Add to variable path.
	elif expecting_flag == 1 && lower_char in Valid_property_name_characters:
		result.char += char
	return result




# PKExpression processing functions.
# ----------------------------------
func process_pkexp(node:Node, raw_expression:String, parsed:Dictionary) -> void: ## Executes a parsed PowerKey expression on the Node.
	# Debug printing.
	if Config.debug_print_any_pkexpression_processed:
		print_rich('[b][color=gold]PowerKey Debug:[/color][/b] Now processing expression "[color=tomato]%s[/color]" on Node "[color=orange]%s[/color]" ("[color=dim_gray]%s[/color]").' % [raw_expression, node.name, node.get_instance_id()])

	match parsed.type:
		# Assign expression.
		ExpTypes.assign:
			if parsed.parameters.size() == 0: return # Return if no parameters.
			var node_property:StringName = parsed.parameters[0]
			var value = _get_value(parsed.content.split('.'), node, raw_expression)
			# Set value, regardless of whether or not the Node property or Resources property exists.
			_set_value(node_property.split('.'), node, value)

		# Link expression.
		ExpTypes.link:
			if parsed.parameters.size() == 0: return # Return if no parameters.
			var node_property:StringName = parsed.parameters[0]
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
					_set_value(node_property.split('.'), node, value)
					last_value = value
			)

		# Execute expression.
		ExpTypes.execute:
			var func_name:StringName = '_PK_function'
			# Define code.
			var gd_code:StringName = Execute_script_code_template % [func_name, parsed.content.indent('	')]
			# Apply source code to script.
			if Execute_script.source_code != gd_code:
				Execute_script.source_code = gd_code
				Execute_script.reload()
			Execute_script.call(func_name, node, Resources)



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
	var split_varpath_size:int = split_varpath.size()
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

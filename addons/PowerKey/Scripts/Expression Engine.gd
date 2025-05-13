# This script handles all proccessing & parsing of PKExpressions.
# New instance should be created if used (call `.new`).

class_name PK_EE extends Node
enum ExpTypes {ASSIGN,LINK,EXEC}
const ExpType_values:Array[StringName] = ['A','L','E'] ## ExpType values as Strings instead of enum int.
const Lowercases:Dictionary[StringName,StringName] = {'A':'a','B':'b','C':'c','D':'d','E':'e','F':'f','G':'g','H':'h','I':'i','J':'j','K':'k','L':'l','M':'m','N':'n','O':'o','P':'p','Q':'q','S':'s','T':'t','U':'u','V':'v','W':'w','X':'x','Y':'y','Z':'z'} ## Performs better than using `.to_lower`.
enum Parse_stages {TYPE,PARAMS,CONTENT} ## Each stage of parsing.
const Comment_token:StringName = '#' ## Used to denote a commented line.
const Parameter_separator:StringName = ',' ## Used to separate expression parameters.
const Parameters_denotator:StringName = ':' # Should NEVER be more than one character.
const Variable_path_characters:StringName = 'abcdefghijklmnopqrstuvwxyz0123456789_.'
const Variable_path_starting_characters:StringName = 'abcdefghijklmnopqrstuvwxyz_'
const Supported_pkexp_value_property_types:Array[StringName] = ['Dictionary','Object', 'Vector2']
const Errors:Dictionary[StringName,StringName] = {
	'pkexp_parse_failed': 'PowerKey PKExpression: (@char %s) Failed to parse expression "%s" for Node "%s" with reason "%s".',
	'pkexp_property_not_found': 'PowerKey PKExpression: (@char %s) Failed to find property "%s" for Node "%s" in Resources Script ("%s").',
	'pkexp_property_not_found_in_node': 'PowerKey PKExpression: (@char %s) Failed to find property "%s" in Node "%s".',
	'pkexp_accessing_unsupported_type': 'PowerKey PKExpression: (@char %s) Expression "%s" for Node "%s" tried requesting property from an unsupported Type "%s", expected one of the following: %s.',
	'pkexp_accessing_nonexistent_value_on_vector2': 'PowerKey PKExpression: (@char %s) Expression "%s" for Node "%s" tried accessing non-existent property "%s" from a "Vector2".',
}
const Parse_errors:Array[StringName] = [
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
const Execute_script_code_template:StringName = 'static func %s(S, PK) -> void:\n	S=S; PK=PK;\n%s'

var cached_pkexps:Dictionary[StringName,Dictionary] = {}
var cached_pkexps_order:Array[StringName] = []

var Config
var Resources

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
		'type': -1, # The expression type.
		'parameters': PackedStringArray(), # The expression parameters.
		'content': PackedStringArray(), # The expression content.
		'stage': Parse_stages.TYPE, # The parsing stage.
		'buffers': [null,'',null], # The current stage's temporary data.
	}
	# If comment line, throw silent error.
	if text.begins_with(Comment_token):
		ps.error = 999
		return ps

	#var start := Time.get_ticks_usec()
	for char in String(text):
		if ps.error != 0: break # Stop if there was an error during the previous iteration.
		ps.current_char += 1
		match ps.stage:
			Parse_stages.TYPE: _parse_type(char, ps)
			Parse_stages.PARAMS: _parse_parameters(char, ps)
			Parse_stages.CONTENT: _parse_content(char, ps)
	#print(Time.get_ticks_usec()-start)

	# Error checks.
	if ps.error != 0: pass
	elif ps.type == -1:
		ps.error = 5
	elif ps.content.size() == 0:
		ps.error = 6
	# Cache expression for reuse.
	if not Engine.is_editor_hint():
		if Config.max_cached_pkexpressions > 0:
			cached_pkexps[text] = ps
			cached_pkexps_order.append(text)
			# If over the max, delete oldest cache entry.
			if cached_pkexps_order.size() > Config.max_cached_pkexpressions:
				var oldest_key:StringName = cached_pkexps_order.pop_front()
				cached_pkexps.erase(oldest_key)
	# Return the results.
	return ps


func _parse_type(char:String, ps:Dictionary) -> bool: ## Parses the "type" stage. Returns true if ready to progress to next stage.
	# Set expression type.
	if char == Parameters_denotator:
		# Throw error if not a valid expression type.
		ps.type = ExpType_values.find(StringName(ps.buffers[1]))
		if ps.type == -1:
			ps.error = 1
			return true
		ps.stage = Parse_stages.PARAMS
		# Set up buffers.
		ps.buffers[0] = 0 # expecting flag
		ps.buffers[1] = '' # current parameter
	# Progress to content stage if not specifying any parameters.
	elif char == ' ':
		# Throw error if not a valid expression type.
		ps.type = ExpType_values.find(StringName(ps.buffers[1]))
		if ps.type == -1:
			ps.error = 1
			return true
		ps.stage = Parse_stages.CONTENT
		_reset_parse_state_buffers(ps)
		ps.buffers[0] = 0 # expecting flag
		ps.buffers[1] = ''
		
	# Add to expression_type.
	else:
		ps.buffers[1] += char
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
		var end:bool = _parse_variable_path(char, ps)
		# Move to next stage.
		if end:
			if ps.buffers[1] == '':
				ps.error = 7
				return true
			ps.parameters.append(StringName(ps.buffers[1]))
			ps.stage = Parse_stages.CONTENT
			_reset_parse_state_buffers(ps)
			ps.buffers[0] = 0 # expecting flag.
			ps.buffers[1] = '' # string 1.
			return true
	return false


func _parse_content(char:String, ps:Dictionary) -> bool: ## Parses the "content" stage. Retruns true if ready to progress to the next stage.
	# If expression type == assign, handle properly.
	if ps.type in [ExpTypes.ASSIGN, ExpTypes.LINK]:
		var end:bool = _parse_variable_path(char, ps)
		if end:
			ps.error = 3
			return true
	# Add to content.
	ps.content.append(char)
	return false


func _parse_variable_path(char:String, ps:Dictionary) -> bool: ## Parses a variable path.
	var lower_char:StringName = Lowercases.get(char,char)
	# End current stage.
	if char == ' ':
		return true
	# Throw error if invalid character.
	elif lower_char not in Variable_path_characters:
		ps.error = 3
		return true
	# Throw error if invalid start of variable path.
	elif ps.buffers[0] == 0 && lower_char not in Variable_path_starting_characters:
		ps.error = 2
		return true
	# If start of variable path, add to, & change expecting flag.
	elif ps.buffers[0] == 0 && lower_char in Variable_path_starting_characters:
		ps.buffers[1] += char # Add char.
		ps.buffers[0] = 1 # Set new expecting flag.
	# Add to variable path.
	elif ps.buffers[0] == 1 && lower_char in Variable_path_characters:
		ps.buffers[1] += char # Add char.
	return false


func _reset_parse_state_buffers(ps:Dictionary) -> void: ## Resets the parsing state's buffers to null.
	ps.buffers[0] = null
	ps.buffers[1] = null
	ps.buffers[2] = null





# PKExpression processing functions.
# ----------------------------------
func process_pkexp(node:Node, raw_expression:String, parsed:Dictionary) -> void: ## Executes a parsed PowerKey expression on the Node.
	# Debug printing.
	if Config.debug_print_any_pkexpression_processed:
		print_rich('[b][color=gold]PowerKey Debug:[/color][/b] Now processing expression "[color=tomato]%s[/color]" on Node "[color=orange]%s[/color]" ("[color=dim_gray]%s[/color]").' % [raw_expression, node.name, node.get_instance_id()])
	var string_content:String = ''.join(parsed.content)
	match parsed.type:
		# Assign expression.
		ExpTypes.ASSIGN:
			if parsed.parameters.size() == 0: return # Return if no parameters.
			var value = _get_value(string_content.split('.'), node, raw_expression)
			# Set value, regardless of whether or not the Node property or Resources property exists.
			_set_value(parsed.parameters[0].split('.'), node, value)

		# Link expression.
		ExpTypes.LINK:
			if parsed.parameters.size() == 0: return # Return if no parameters.
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
			var split_content:PackedStringArray = string_content.split('.')
			var split_node_property:PackedStringArray = parsed.parameters[0].split('.')
			update_timer.timeout.connect(func():
				var value = _get_value(split_content, node, raw_expression)
				# Set value if different.
				if value != last_value:
					# Set value, regardless of whether or not the Node property or Resources property exists.
					_set_value(split_node_property, node, value)
					last_value = value
			)

		# Execute expression.
		ExpTypes.EXEC:
			var func_name:StringName = '_PK_function'
			# Define code.
			var gd_code:StringName = Execute_script_code_template % [func_name, string_content.indent('	')]
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

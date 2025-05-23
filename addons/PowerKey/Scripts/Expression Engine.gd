# This script handles all proccessing & parsing of PKExpressions.
# New instance should be created if used (call `.new`).

class_name PK_EE extends Node
enum ExpTypes {ASSIGN,LINK,EXECUTE,EVAL}
const ExpType_values:Array[StringName] = ['A','L','E','V'] ## ExpType values as Strings instead of enum int.
const Lowercases:Dictionary[StringName,StringName] = {'A':'a','B':'b','C':'c','D':'d','E':'e','F':'f','G':'g','H':'h','I':'i','J':'j','K':'k','L':'l','M':'m','N':'n','O':'o','P':'p','Q':'q','S':'s','T':'t','U':'u','V':'v','W':'w','X':'x','Y':'y','Z':'z'} ## Performs better than using `.to_lower`.
const Digits:Array[StringName] = ['0','1','2','3','4','5','6','7','8','9']
enum Parse_stages {TYPE,PARAMS,CONTENT} ## Each stage of parsing.
var Parameter_counts:Dictionary = { ## The range of parameters each expression type can have.
	ExpTypes.ASSIGN: [1,1],
	ExpTypes.LINK: [1,2],
	ExpTypes.EXECUTE: [0,0],
	ExpTypes.EVAL: [1,1],
}
const Comment_token:StringName = &'#' ## Used to denote a commented line.
const Parameter_separator:StringName = &',' ## Used to separate expression parameters.
const Parameters_denotator:StringName = &':' # Should NEVER be more than one character.
const Variable_path_characters:StringName = &'abcdefghijklmnopqrstuvwxyz0123456789_.'
const Variable_path_starting_characters:StringName = &'abcdefghijklmnopqrstuvwxyz_'
const Array_builtin_types:Array[int] = [TYPE_ARRAY,TYPE_PACKED_BYTE_ARRAY,TYPE_PACKED_INT32_ARRAY,TYPE_PACKED_INT64_ARRAY,TYPE_PACKED_FLOAT32_ARRAY,TYPE_PACKED_FLOAT64_ARRAY,TYPE_PACKED_STRING_ARRAY,TYPE_PACKED_VECTOR2_ARRAY,TYPE_PACKED_VECTOR3_ARRAY,TYPE_PACKED_VECTOR4_ARRAY,TYPE_PACKED_COLOR_ARRAY]
const Valid_properties_for_builtin_type = {
	TYPE_VECTOR2: &'xy',
	TYPE_VECTOR2I: &'xy',
	TYPE_VECTOR3: &'xyz',
	TYPE_VECTOR3I: &'xyz',
	TYPE_VECTOR4: &'wxyz',
	TYPE_VECTOR4I: &'wxyz',
	TYPE_BASIS: &'xyz',
	TYPE_QUATERNION: &'wxyz',
	TYPE_PROJECTION: &'wxyz',
	TYPE_TRANSFORM2D: [&'origin',&'x',&'y'],
	TYPE_TRANSFORM3D: [&'basis',&'origin'],
	TYPE_PLANE: [&'d',&'normal',&'x',&'y',&'z'],
	TYPE_AABB: [&'end',&'posiiton',&'size'],
	TYPE_COLOR: [&'r',&'r8',&'g',&'g8',&'b',&'b8',&'a',&'a8',&'h',&'s',&'v',&'ok_hsl_h',&'ok_hsl_s',&'ok_hsl_l'],
}
enum CharHighlightModes {
	exp_type,
	neutral,
	variable_path,
	value,
}
const Errors:Dictionary[StringName,StringName] = {
	'pkexp_parse_failed': 'PowerKey PKExpression: (@char %s) Failed to parse expression "%s" for Node "%s" with reason "%s".',
	'pkexp_accessing_unsupported_builtin_type': 'PowerKey PKExpression: Expression "%s" for Node "%s" tried accessing property from an unsupported built-in type "%s".',
	'pkexp_accessing_nonexistent_property_for_builtin_type': 'PowerKey PKExpression: Expression "%s" for Node "%s" tried accessing non-existent property "%s" from a "%s".',
	'pkexp_setting_to_sublevel_variable': 'PowerKey PKExpression: Expression "%s" for Node "%s" tried setting a value to a sub-level variable. Only top-level setting is currently supported. Use an "Execute" expression to set values to sub-level variables via code.',
	'pkexp_process_failed': 'PowerKey PKExpression: Failed to process expression "%s" for Node "%s" with reason "%s".',
}
const Parse_errors:Array[StringName] = [
	'Invalid expression type',
	'Invalid starting character in variable path',
	'Invalid character in variable path',
	'Assign/Link expression content should only contain basic characters',
	'No expression type defined',
	'No content defined',
	'Parameter cannot be empty',
	'Invalid amount of parameters for this expression type',
	'Improperly formed float value',
	'Empty',
	'Improperly formed integer value',
	'Improper GDExpression',
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
	# If comment line, throw silent error.
	if text.begins_with(Comment_token):
		return {'error':999}
	if text.strip_edges() == '':
		return {'error':10,'current_char':0}
	# Check cache, return cached result is available.
	if not Engine.is_editor_hint():
		if cached_pkexps.has(text):
			return cached_pkexps[text]
	# Define the parsing state & it's data.
	var ps:Dictionary[StringName,Variant] = { ## The parsing state.
		'error': 0, # Parse error. 0 = OK.
		'current_char': 0,
		'char_highlight_data': PackedInt32Array(), # Represents the highlighting mode for each character in the raw text.
		'type': -1, # The expression type.
		'parameters': PackedStringArray(), # The expression parameters.
		'content': PackedStringArray(), # The expression content.
		'stage': Parse_stages.TYPE, # The parsing stage.
		'buffers': [null,null], # The current stage's temporary data.
	}
	# Set buffers.
	_reset_parse_state_buffers(ps)

	#var start := Time.get_ticks_usec()
	for char in String(text):
		if ps.error != 0: break # Stop if there was an error during the previous iteration.
		ps.current_char += 1
		match ps.stage:
			Parse_stages.TYPE: _parse_stage_type(char, ps)
			Parse_stages.PARAMS: _parse_stage_parameters(char, ps)
			Parse_stages.CONTENT: _parse_stage_content(char, ps)
	#print(Time.get_ticks_usec()-start)

	# Clear buffers.
	ps.buffers.clear()
	# Error checks.
	if ps.error != 0: pass
	elif ps.type == -1:
		ps.error = 5
	elif ps.content.size() == 0:
		ps.error = 6
	elif ps.type == ExpTypes.EVAL:
		var expression := Expression.new()
		var err:int = expression.parse(''.join(ps.content), ['S','PK'])
		if err != 0:
			ps.error = 11
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


func _parse_stage_type(char:String, ps:Dictionary) -> bool: ## Parses the "type" stage. Returns true if ready to progress to next stage.
	# If intending to specify parameters.
	if char == Parameters_denotator:
		ps.char_highlight_data.append(CharHighlightModes.neutral)
		# Throw error if not a valid expression type.
		ps.type = ExpType_values.find(StringName(ps.buffers[1]))
		if ps.type == -1:
			ps.error = 1
			return true
		# Next stage.
		ps.stage = Parse_stages.PARAMS
		_reset_parse_state_buffers(ps)
	# If not intending to specify any parameters.
	elif char == ' ':
		# Throw error if not a valid expression type.
		ps.type = ExpType_values.find(StringName(ps.buffers[1]))
		if ps.type == -1:
			ps.error = 1
			return true
		# Throw error if invalid amount of parameters.
		if 0 not in Parameter_counts[ps.type]:
			ps.error = 8
			return true
		# Next stage.
		ps.stage = Parse_stages.CONTENT
		_reset_parse_state_buffers(ps)
		
	# Add to expression_type.
	else:
		ps.char_highlight_data.append(CharHighlightModes.exp_type)
		ps.buffers[1] += char
	return false


func _parse_stage_parameters(char:String, ps:Dictionary) -> bool: ## Parses the "parameters" stage. Returns true if ready to progress to next stage.
	# Next parameter if char is a separator.
	if char == Parameter_separator:
		ps.char_highlight_data.append(CharHighlightModes.neutral)
		if ps.buffers[1] == '':
			ps.error = 7
			return true
		ps.parameters.append(StringName(ps.buffers[1]))
		_reset_parse_state_buffers(ps)
		return true
	# End if space.
	elif char == ' ':
		if ps.buffers[1] == '':
			ps.error = 7
			return true
		ps.parameters.append(StringName(ps.buffers[1]))
		ps.stage = Parse_stages.CONTENT
		_reset_parse_state_buffers(ps)
		return true
	# For "Assign", "Link", & "Eval" types on the first parameter.
	elif ps.type in [ExpTypes.ASSIGN,ExpTypes.LINK,ExpTypes.EVAL] && ps.parameters.size() == 0:
		_parse_variable_path(char, ps)
	# For "Link" types on the second parameter.
	elif ps.type == ExpTypes.LINK && ps.parameters.size() == 1:
		_parse_float(char, ps)
	# If expecting no more parameters, throw error.
	else:
		ps.error = 8
		return true
	return false


func _parse_stage_content(char:String, ps:Dictionary) -> bool: ## Parses the "content" stage. Retruns true if ready to progress to the next stage.
	# If expression type is assign or link, handle properly.
	if ps.type in [ExpTypes.ASSIGN, ExpTypes.LINK]:
		var end:bool = _parse_variable_path(char, ps)
		if end:
			ps.error = 3
			return true
	# If expression type is "Execute" or "Eval".
	elif ps.type == ExpTypes.EXECUTE:
		ps.char_highlight_data.append(-1) # Use -1 highlight mode (none).
	# Add to content.
	ps.content.append(char)
	return false


func _reset_parse_state_buffers(ps:Dictionary) -> void: ## Resets the parsing state's buffers.
	ps.buffers[0] = 0 # Expecting flag.
	ps.buffers[1] = '' # General purpose string.


# Basic parsing functions.
# ------------------------
func _parse_int(char:String, ps:Dictionary) -> bool: ## Parses a full number.
	# Stop if char is a space.
	if char == ' ':
		return true
	elif char not in Digits:
		ps.error = 11
		return true
	else:
		ps.char_highlight_data.append(CharHighlightModes.value)
		ps.buffers[1] += char
	return false


func _parse_float(char:String, ps:Dictionary) -> bool: ## Parses a floating point number.
	# Stop if char is a space.
	if char == ' ':
		return true
	# Add char if decimal point & if not added before.
	elif char == '.' && ps.buffers[0] == 0:
		ps.char_highlight_data.append(CharHighlightModes.value)
		ps.buffers[1] += char
		ps.buffers[0] = 1
	# Throw error if not a digit.
	elif char not in Digits:
		ps.error = 9
		return true
	# Add char.
	else:
		ps.char_highlight_data.append(CharHighlightModes.value)
		ps.buffers[1] += char
	return false


func _parse_variable_path(char:String, ps:Dictionary) -> bool: ## Parses a variable path.
	var lower_char:StringName = Lowercases.get(char,char)
	# End parsing if space.
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
		ps.char_highlight_data.append(CharHighlightModes.variable_path)
		ps.buffers[1] += char # Add char.
		ps.buffers[0] = 1 # Set new expecting flag.
	# Add char.
	elif ps.buffers[0] == 1 && lower_char in Variable_path_characters:
		ps.char_highlight_data.append(CharHighlightModes.variable_path)
		ps.buffers[1] += char
	return false




# PKExpression processing functions.
# ----------------------------------
func process_pkexp(node:Node, raw:StringName, parsed:Dictionary) -> void: ## Executes a parsed PowerKey expression on the Node.
	# Debug printing.
	if Config.debug_print_any_pkexpression_processed:
		print_rich('[b][color=gold]PowerKey Debug:[/color][/b] Now processing expression "[color=tomato]%s[/color]" on Node "[color=orange]%s[/color]" ("[color=dim_gray]%s[/color]").' % [raw, node.name, node.get_instance_id()])
	# Process expression.
	match parsed.type:
		ExpTypes.ASSIGN: _process_pkexp_assign(node, raw, parsed)
		ExpTypes.LINK: _process_pkexp_link(node, raw, parsed)
		ExpTypes.EXECUTE: _process_pkexp_execute(node, raw, parsed)
		ExpTypes.EVAL: _process_pkexp_eval(node, raw, parsed)


func _process_pkexp_assign(node:Node, raw:StringName, parsed:Dictionary) -> void: ## Process "Assign" type PKExpression.
	var value = PK_Common.get_value(''.join(parsed.content).split('.'), node, raw, Resources)
	# Set value, regardless of whether or not the Node property or Resources property exists.
	_set_value(parsed.parameters[0].split('.'), node, value, raw)


func _process_pkexp_link(node:Node, raw:StringName, parsed:Dictionary) -> void: ## Process "Link" type PKExpression.
	var frequency_param:float = 0.000001
	var param_count:int = parsed.parameters.size()
	if param_count == 2:
		var param:float = float(parsed.parameters[1])
		if param != 0.0: frequency_param = param
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
		update_timer.wait_time = frequency_param
		update_timer.start()
	# Connect function to process every tick.
	var last_value
	var split_content:PackedStringArray = ''.join(parsed.content).split('.')
	var split_node_property:PackedStringArray = parsed.parameters[0].split('.')
	update_timer.timeout.connect(func():
		var value = PK_Common.get_value(split_content, node, raw, Resources)
		# Set value if different.
		if value != last_value:
			# Set value, regardless of whether or not the Node property or Resources property exists.
			_set_value(split_node_property, node, value, raw)
			last_value = value
	)


func _process_pkexp_execute(node:Node, raw:String, parsed:Dictionary) -> void: ## Process "Execute" type PKExpression.
	var func_name:StringName = '_PK_function'
	# Define code.
	var gd_code:StringName = Execute_script_code_template % [func_name, ''.join(parsed.content).indent('	')]
	# Apply source code to script.
	if Execute_script.source_code != gd_code:
		Execute_script.source_code = gd_code
		Execute_script.reload()
	Execute_script.call(func_name, node, Resources)


func _process_pkexp_eval(node:Node, raw:String, parsed:Dictionary) -> void: ## Process "Eval" type PKExpression.
	var expression := Expression.new()
	var err:int = expression.parse(''.join(parsed.content), ['S','PK']) # Parse expression.
	# If parsing error, throw error
	if err != 0:
		printerr(Errors.pkexp_process_failed % [raw, node.name, error_string(err)])
		return
	var value = expression.execute([node,Resources], null, false) # Execute and save result
	# If error while executing, throw error
	if expression.has_execute_failed():
		printerr(Errors.pkexp_process_failed % [raw, node.name, expression.get_error_text()])
		return
	# Set value, regardless of whether or not the Node property exists.
	_set_value(parsed.parameters[0].split('.'), node, value, raw)





func _set_value(split_varpath:PackedStringArray, target:Node, value, raw_expression:String) -> void: ## Sets the value of a variable in the Node.
	var split_varpath_size:int = split_varpath.size()
	# If top-level, set directly.
	if split_varpath_size < 2:
		target.set(split_varpath[0], value)
		return
	# Throw error if not top-level.
	else:
		printerr(Errors.pkexp_setting_to_sublevel_variable % [raw_expression, target.name, ])


# WIP sub-level value setter.
# This is such a pain, why cant it be simple :(
# For this to work I'll need to implement a system that recursively sets values to a variable parent,
# which I really dont feel implementing right now, but I'll get to it eventually.
# Like for this thing to work I need to recursively search for the variable we are setting the value to,
# then we gotta move all the way back up through the variables, updating the value of them,
# just so we can set the value of one variable.
func __set_value(split_varpath:PackedStringArray, node:Node, value, raw_expression:String) -> void: ## Sets the value of a variable in the Node.
	var variable = node
	var variable_type:int
	for i in range(0,split_varpath.size()-1): # Iterate through all variable paths in between the first and last indices.
		# Return early if value is null.
		if variable == null:
			PK_Common._get_value_error_helper_1(variable, node, raw_expression)
			return
		# Update variable type.
		variable_type = typeof(variable)
		# Get next value from Objects or Dictionaries with dynamic set of properties.
		if variable_type in [TYPE_DICTIONARY,TYPE_OBJECT]:
			if split_varpath[i] not in variable:
				PK_Common._get_value_error_helper_2(split_varpath[i], type_string(variable_type), node, raw_expression)
				return
			variable = variable[split_varpath[i]]
		# Get next value from built-in types with strict set of properties.
		elif variable_type in Valid_properties_for_builtin_type:
			if split_varpath[i] not in Valid_properties_for_builtin_type[variable_type]:
				PK_Common._get_value_error_helper_2(split_varpath[i], type_string(variable_type), node, raw_expression)
				return
			variable = variable[split_varpath[i]]
		# Get next value from an Array.
		elif variable_type in Array_builtin_types:
			var index = int(split_varpath[i])
			if index == 0 && split_varpath[i] != '0' || index > variable.size()-1:
				PK_Common._get_value_error_helper_2(split_varpath[i], type_string(variable_type), node, raw_expression)
				return
			variable = variable[index]
		# If other type, throw error.
		else:
			PK_Common._get_value_error_helper_1(variable, node, raw_expression)
			return
	
	# Update variable type.
	variable_type = typeof(variable)

	# Set value on a Dictionary or Object.
	if variable_type in [TYPE_DICTIONARY,TYPE_OBJECT]:
		variable.set(split_varpath[-1], value)
	# Set value on built-in type with strict set of properties.
	elif variable_type in Valid_properties_for_builtin_type:
		if split_varpath[-1] not in Valid_properties_for_builtin_type[variable_type]:
			PK_Common._get_value_error_helper_2(split_varpath[-1], type_string(variable_type), node, raw_expression)
			return
		variable[split_varpath[-1]] = value
	# Set value on an Array.
	elif variable_type in Array_builtin_types:
		var index = int(split_varpath[-1])
		if index == 0 && split_varpath[-1] != '0' || index > variable.size()-1:
			PK_Common._get_value_error_helper_2(split_varpath[-1], type_string(variable_type), node, raw_expression)
			return
		variable[index] = value
	# If other type, throw error.
	else:
		PK_Common._get_value_error_helper_1(variable, node, raw_expression)
		return

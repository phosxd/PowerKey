class_name PK_Parser extends Node
const ExpTypes := {
	'assign': 'A',
	'link': 'L',
	'exec': 'E',
}
const ExpTypes_require_property_name := ['assign','link']
const Property_name_requester_token := ':' # Should NEVER be more than one character.
const Valid_property_name_characters := 'abcdefghijklmnopqrstuvwxyz0123456789_.'
const Valid_property_name_starting_characters := 'abcdefghijklmnopqrstuvwxyz_'
const Valid_assign_content_characters := 'abcdefghijklmnopqrstuvwxyz0123456789_.'
const Supported_pkexp_value_property_types := ['Dictionary','Object']
const Errors := {
	'pkexp_failed': 'PowerKey: PKExp failed to process expression "%s" for Node "%s".',
	'pkexp_property_not_found': 'PowerKey: PKExp failed to find property "%s" for Node "%s" in Resources Script ("%s").',
	'pkexp_property_not_found_in_node': 'PowerKey: PKExp failed to find property "%s" in Node "%s".',
	'pkexp_accessing_unsupported_type': 'PowerKey: Expression "%s" for Node "%s" tried requesting property from an unsupported Type "%s", expected one of the following: %s.',
	
}
var Config
var Resources

func init(config:Dictionary, resources) -> void:
	Config = config
	Resources = resources





# PKExpression functions.
# -----------------------
func parse_pkexp(text:String): ## Parses a PowerKey expression. Returns expression details. Returns null if invalid expression.
	var invalid := false
	var expression_type:String
	var property_name:String
	var content:String
	var stage := 'expression_type' ## The parsing stage.
	var buffer := ''
	var expecting_flag := 0
	
	for char in text:
		if stage == 'expression_type':
			# Set expression type.
			if char == Property_name_requester_token:
				stage = 'property_name'
				buffer = ''
				expecting_flag = 0
				# Throw error if not a valid expression type.
				if expression_type not in ExpTypes.values():
					invalid = true
					break
			# Progress to content stage if not specifying "property_name".
			elif char == ' ':
				stage = 'content'
				buffer = ''
				expecting_flag = 0
				# Throw error if not a valid expression type.
				if expression_type not in ExpTypes.values():
					invalid = true
					break
			# Add to expression_type.
			else:
				expression_type += char
		
		elif stage == 'property_name':
			# Progress to translation_key stage.
			if char == ' ':
				property_name = buffer
				stage = 'content'
				buffer = ''
				expecting_flag = 0
			# Throw error if invalid start of property name.
			elif expecting_flag == 0 && char.to_lower() not in Valid_property_name_starting_characters:
				invalid = true
				break
			# Throw error if invalid character.
			elif char.to_lower() not in Valid_property_name_characters:
				invalid = true
				break
			# Look for start of property name.
			if expecting_flag == 0 && char.to_lower() in Valid_property_name_starting_characters:
				buffer += char
				expecting_flag = 1
			# Add to property name.
			elif expecting_flag == 1 && char.to_lower() in Valid_property_name_characters:
				buffer += char
		
		elif stage == 'content':
			# If expression type == assign.
			if expression_type == ExpTypes.assign:
				# Throw error if invalid character for an "assign" expression.
				if char not in Valid_assign_content_characters:
					invalid = true
					break
			# Add to content.
			content += char
	
	
	# If invalid expression, return null.
	if invalid: return null
	if expression_type.length() == 0: return null
	if content.length() == 0: return null
	
	# Return results.
	var result := {
		'type': expression_type,
		'property_name': property_name,
		'content': content,
	}
	return result




func process_pkexp(node:Node, raw_expression:String, parsed:Dictionary) -> void: ## Executes a parsed PowerKey expression on the Node.
	# Debug printing.
	if Config.debug_print_any_pkexpression_processed:
		print_rich('[b][color=gold]PowerKey Debug:[/color][/b] Now processing expression "[color=tomato]%s[/color]" on Node "[color=orange]%s[/color]" ("[color=dim_gray]%s[/color]").' % [raw_expression, node.name, node.get_instance_id()])
	var split_content = parsed.content.split('.')
	
	# Assign expression.
	if parsed.type == ExpTypes.assign:
		if parsed.property_name.length() > 0:
			var value = _find_value(split_content, node, raw_expression)
			# Set value, regardless of whether or not the Node property or Resources property exists.
			node.set(parsed.property_name, value)
	
	
	# Link expression. EXPERIMENTAL.
	elif parsed.type == ExpTypes.link:
		if parsed.property_name.length() > 0:
			var processor := Node.new()
			var processor_script := GDScript.new()
			processor_script.source_code = """
extends Node
var last_value
var processor_func:Callable
func set_processor_func(new:Callable) -> void:
	processor_func = new
func _process(_delta:float) -> void:
	last_value = processor_func.call(last_value)
"""
			processor_script.reload()
			processor.set_script(processor_script)
			node.add_child(processor)
			# Set function to process every tick on the node.
			processor.set_processor_func(func(last_value):
				var value = _find_value(split_content, node, raw_expression)
				# Set value if different.
				if value != last_value:
					# Set value, regardless of whether or not the Node property or Resources property exists.
					node.set(parsed.property_name, value)
				return value
			)
	
	
	# Eval expression.
	elif parsed.type == ExpTypes.exec:
		var func_name := 'PK_function_%s' % randi_range(10000,99999) # Define unpredictable function name.
		var gd_code := "func %s(S, PK) -> void:\n%s" % [func_name, parsed.content.indent('	')] # Define code for the script.
		var new_script := GDScript.new()
		# Apply source code to script.
		new_script.source_code = gd_code
		new_script.reload()
		# Create RefCounted object to host the script.
		var host := RefCounted.new()
		host.set_script(new_script)
		# Run the code.
		host.call(func_name, node, Resources)






# Utility functions.
func _find_value(split_content:Array[String], node:Node, raw_expression:String): ## Finds the value of a variable in Resources Script. Returns Variant. If failed, reutrns null.
	var value = Resources.get(split_content[0]) # Get variable from Resources.
	var count := 0
	for i in split_content:
		if count > 0:
			# If acessing property of a Dictionary, proceed.
			if value is Dictionary:
				value = value.get(i)
			# If accessing property of an Object, proceed.
			elif value is Object:
				value = value.get(i)
			# If other type, return & throw error.
			else:
				printerr(Errors.pkexp_accessing_unsupported_type % [raw_expression,node.name,type_string(typeof(value)),', '.join(Supported_pkexp_value_property_types)])
				return
		count += 1
	return value

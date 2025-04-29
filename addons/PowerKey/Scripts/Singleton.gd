extends Node
const ExpTypes := {
	'assign': 'A',
	'eval': 'E',
}
const Property_name_requester_token := ':'
const Valid_property_name_characters := 'abcdefghijklmnopqrstuvwxyz0123456789_.'
const Valid_property_name_starting_characters := 'abcdefghijklmnopqrstuvwxyz_'
const Supported_pkexp_value_property_types := ['Dictionary','Object']
const Errors := {
	'pkexp_failed': 'PowerKey: PKExp failed to process expression "%s" for Node "%s".',
	'pkexp_property_not_found': 'PowerKey: PKExp failed to find property "%s" for Node "%s" in Resources Script ("%s").',
	'pkexp_property_not_found_in_node': 'PowerKey: PKExp failed to find property "%s" in Node "%s".',
	'pkexp_accessing_unsupported_type': 'PowerKey: Expression "%s" for Node "%s" tried requesting property from an unsupported Type "%s", expected one of the following: %s.',
	
}
@onready var PKConfig := PK_Config.new()
@onready var Config := PKConfig.load_config()
@onready var Resources_script = load(Config.resources_script_path) if FileAccess.file_exists(Config.resources_script_path) else null
var Resources


func _ready() -> void:
	# Add script to a Node, to call "_ready". & set Resources to new node.
	if Resources_script is Script:
		var new_node := Node.new()
		new_node.set_script(Resources_script)
		new_node.call('_ready')
		Resources = new_node
	# If no script, set Resources to empty Dictionary.
	else:
		Resources = {}
	# Setup hook.
	_hook_onto_nodes() # Hook onto all nodes currently in the tree.
	get_tree().node_added.connect(evaluate_node_tree) # Hook every new node.





# Useful functions.
# -----------------
func evaluate_node_tree(node:Node) -> void: ## Recursively evaluates all Nodes under the given Node.
	_recursive(node, func(_node:Node) -> void:
		evaluate_node(_node)
	)

func evaluate_node(node:Node) -> void: ## Evaluates PKExpressions present on the Node.
	var editor_desc := node.editor_description
	var lines := editor_desc.split('\n')
	for line in lines:
		if not line.begins_with(Config.activation_phrase): continue
		# Parse & process PKExpression.
		var text := line.trim_prefix(Config.activation_phrase)
		var parsed = _parse_pkexp(text)
		if parsed: _process_pkexp(node, line, parsed)
		else: printerr(Errors.pkexp_failed % [line,node.name])





# PKExpression functions.
# -----------------------
func _parse_pkexp(text:String): ## Parses a PowerKey expression. Returns expression details. Returns null if invalid expression.
	var invalid := false
	var expression_type:String
	var property_name:String
	var content:String
	var stage := 'expression_type' ## The parsing stage.
	var buffer := ''
	var expecting_flag := 0
	
	for char in text:
		if stage == 'expression_type':
			# Add to buffer.
			buffer += char
			# Set expression type.
			if not expression_type:
				for type in ExpTypes.values():
					if buffer == type:
						expression_type = type
						stage = 'look_for_property_name'
						buffer = ''
						expecting_flag = 0
						break
		
		elif stage == 'look_for_property_name':
			# Add to buffer.
			buffer += char
			# Progress to property_name stage.
			if buffer == Property_name_requester_token:
				stage = 'property_name'
				buffer = ''
				expecting_flag = 0
			# Progress to translation_key stage.
			elif char == ' ':
				stage = 'content'
				buffer = ''
				expecting_flag = 0
		
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



func _process_pkexp(node:Node, raw_expression:String, parsed:Dictionary) -> void: ## Executes a parsed PowerKey expression on the Node.
	var split_content = parsed.content.split('.')
	# Assign expression.
	if parsed.type == ExpTypes.assign:
		if parsed.property_name.length() > 0:
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
			# Set value, regardless of whether or not the Node property or Resources property exists.
			node.set(parsed.property_name, value)
	
	# Eval expression.
	elif parsed.type == ExpTypes.eval:
		pass
		








# Hook methods.
# -------------
func _hook_onto_nodes() -> void: ## Hook to all nodes in the project.
	evaluate_node_tree(get_tree().root)

func _recursive(node:Node, callback:Callable) -> void:
	for child in node.get_children():
		callback.call(child)
		_recursive(child,callback)

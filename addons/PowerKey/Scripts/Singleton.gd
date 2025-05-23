# This script is the core of the whole plugin during run-time, it can also be accessed by any other scripts in the project as the `PowerKey` singleton.

extends Node
var PKEE := PK_EE.new()
var PKConfig := PK_Config.new()
var Config := PKConfig.load_config()
@onready var Resources_script = load(Config.resources_script_path) if FileAccess.file_exists(Config.resources_script_path) else null
var Resources
var Resources_script_has_ready := false
var Resources_script_has_process := false


func _ready() -> void:
	# Add script to a Node, to call "_ready". & set Resources to new node.
	if Resources_script is Script:
		var new_node := Node.new()
		new_node.set_script(Resources_script)
		# Store "has_method" checks.
		Resources_script_has_ready = new_node.has_method('_ready')
		Resources_script_has_process = new_node.has_method('_process')
		# Call "_ready".
		if Resources_script_has_ready: new_node.call('_ready')
		# Update "Resources".
		Resources = new_node
	# If no script, set Resources to empty Dictionary.
	else:
		Resources = {}
		
	PKEE.init(Config,Resources) # Initialize Expresion Engine.
	_hook_onto_nodes() # Hook onto all nodes currently in the tree.




func _process(delta:float) -> void:
	if Resources_script_has_process:
		Resources.call('_process', delta)




# Evaluator functions.
# --------------------
func evaluate_node_tree(node:Node) -> void: ## Recursively evaluate all Nodes under the given Node.
	_recursive(node, func(_node:Node) -> void:
		evaluate_node_pkexps(_node)
		evaluate_node_tr(_node)
	)


func evaluate_node_tr(node:Node) -> void: ## Run translations on the Node.
	for tr_data:Dictionary in Config.translations:
		if PK_Common.match_schema(tr_data, PK_Common.Schemas.translation_entry).different: continue
		var property_value = node.get(tr_data.property)
		if property_value != Resources.get(tr_data.key): continue # If property value does not match key, pass.
		var value = PK_Common.get_value(tr_data.value.split('.'), node, '', Resources) # Get the value from Resources.
		node.set(tr_data.property, value) # Set the value on the Node.


func evaluate_node_pkexps(node:Node) -> void: ## Evaluate PKExpressions present on the Node.
	var pkexps = node.get_meta('PKExpressions', false)
	var pkexps_parsed = node.get_meta('PKExpressions_parsed', false)
	if not pkexps: return # Return if no metadata.
	var type_of_pkexps:int = typeof(pkexps)
	# If is a String, convert to StringName.
	if type_of_pkexps == TYPE_STRING:
		pkexps = StringName(pkexps)
	elif type_of_pkexps != TYPE_STRING_NAME: return # If not a StringName then return.
	if pkexps.strip_edges() == '': return # If empty, return.

	# Evaluate each line.
	var count:int = 0
	for line in pkexps.split('\n'):
		var parsed
		if pkexps_parsed && pkexps_parsed.size() > count: parsed = pkexps_parsed[count];
		else: parsed = PKEE.parse_pkexp(line) # Parse line.
		# If silent error, skip line.
		if parsed.error == 999:
			continue
		# If error, print error.
		elif parsed.error != 0:
			printerr(PK_EE.Errors.pkexp_parse_failed % [parsed.current_char, line, node.name, PK_EE.Parse_errors[parsed.error-1]])
		# If no errors, process expression.
		else:
			PKEE.process_pkexp(node, line, parsed)

		count += 1




# Hook methods.
# -------------
func _hook_onto_nodes() -> void: ## Hook to all nodes in the project.
	var tree:SceneTree = get_tree()
	# Hook to every new Node.
	tree.node_added.connect(func(node:Node) -> void:
		evaluate_node_pkexps(node)
	)
	# Hook to currently initialized Nodes.
	evaluate_node_tree(tree.root)


func _recursive(node:Node, callback:Callable) -> void:
	for child in node.get_children():
		callback.call(child)
		_recursive(child,callback)

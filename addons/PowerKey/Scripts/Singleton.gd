# This script is the core of the whole plugin during run-time, it can also be accessed by any other scripts in the project as the `PowerKey` singleton.

extends Node
var Parser := PK_Parser.new()
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
		
	Parser.init(Config,Resources) # Initialize Parser.
	_hook_onto_nodes() # Hook onto all nodes currently in the tree.





func _process(delta:float) -> void:
	if Resources is Node:
		if not Resources_script_has_process: return
		Resources.call('_process', delta)




# Evaluator functions.
# --------------------
func evaluate_node_tree(node:Node) -> void: ## Recursively evaluate all Nodes under the given Node.
	_recursive(node, func(_node:Node) -> void:
		evaluate_node(_node)
	)


func evaluate_node(node:Node) -> void: ## Evaluate PKExpressions present on the Node.
	var pkexpressions = node.get_meta('PKExpressions', false)
	
	if not pkexpressions: return
	if typeof(pkexpressions) != TYPE_STRING: return
	if pkexpressions.strip_edges() == '': return
	
	var lines:PackedStringArray = pkexpressions.split('\n')
	for line in lines:
		var parsed = Parser.parse_pkexp(line) # Parse line.
		# If silent error, skip line.
		if parsed.error == 999:
			continue
		# If error, print error.
		elif parsed.error != 0:
			printerr(PK_Parser.Errors.pkexp_parse_failed % [parsed.current_char, line, node.name, PK_Parser.Parse_Errors[parsed.error-1]])
		# If no errors, process expression.
		else:
			Parser.process_pkexp(node, line, parsed)




# Hook methods.
# -------------
func _hook_onto_nodes() -> void: ## Hook to all nodes in the project.
	var tree := get_tree()
	# Hook to every new Node.
	tree.node_added.connect(func(node:Node) -> void:
		evaluate_node(node)
	)
	# Hook to currently initialized Nodes.
	evaluate_node_tree(tree.root)

func _recursive(node:Node, callback:Callable) -> void:
	for child in node.get_children():
		callback.call(child)
		_recursive(child,callback)

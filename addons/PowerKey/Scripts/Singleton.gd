extends Node
var Parser := PK_Parser.new()
var PKConfig := PK_Config.new()
var Config := PKConfig.load_config()
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
		
	# Initialize Parser.
	Parser.init(Config,Resources)
	
	# Setup hook.
	_hook_onto_nodes() # Hook onto all nodes currently in the tree.





func _process(delta:float) -> void:
	if Resources is Node:
		Resources.call('_process', delta)




# Useful functions.
# -----------------
func evaluate_node_tree(node:Node) -> void: ## Recursively evaluates all Nodes under the given Node.
	_recursive(node, func(_node:Node) -> void:
		evaluate_node(_node)
	)

func evaluate_node(node:Node) -> void: ## Evaluates PKExpressions present on the Node.s
	var pkexpressions = node.get_meta('PKExpressions', false)
	if not pkexpressions: return
	var lines:PackedStringArray = pkexpressions.split('\n')
	for line in lines:
		# Parse line.
		var parsed = Parser.parse_pkexp(line)
		# If silent error, skip line.
		if parsed.error == 999:
			continue
		# If error, print error.
		elif parsed.error != 0:
			printerr(PK_Parser.Errors.pkexp_parse_failed % [line, node.name, PK_Parser.Parse_Errors[parsed.error-1]])
		# If no errors, process expression.
		else:
			Parser.process_pkexp(node, line, parsed)




# Hook methods.
# -------------
func _hook_onto_nodes() -> void: ## Hook to all nodes in the project.
	_recursive(get_tree().root, func(node:Node):
		_hook_node(node)
	)

func _hook_node(node:Node) -> void: ## Evaluates the node & hooks any new child nodes that get instantiated.
	# If not already hooked.
	if not node.child_entered_tree.is_connected(_hook_node):
		node.child_entered_tree.connect(_hook_node)
		# Evaluate PKExpressions on node.
		evaluate_node(node)

func _recursive(node:Node, callback:Callable) -> void:
	for child in node.get_children():
		callback.call(child)
		_recursive(child,callback)

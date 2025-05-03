extends Node
const Errors := {
	'pkexp_failed': 'PowerKey: PKExp failed to process expression "%s" for Node "%s".',
	'pkexp_property_not_found': 'PowerKey: PKExp failed to find property "%s" for Node "%s" in Resources Script ("%s").',
	'pkexp_property_not_found_in_node': 'PowerKey: PKExp failed to find property "%s" in Node "%s".',
	'pkexp_accessing_unsupported_type': 'PowerKey: Expression "%s" for Node "%s" tried requesting property from an unsupported Type "%s", expected one of the following: %s.',
	
}
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
	get_tree().node_added.connect(evaluate_node_tree) # Hook every new node.





func _process(delta:float) -> void:
	if Resources is Node:
		Resources.call('_process', delta)




# Useful functions.
# -----------------
func evaluate_node_tree(node:Node) -> void: ## Recursively evaluates all Nodes under the given Node.
	_recursive(node, func(_node:Node) -> void:
		evaluate_node(_node)
	)

func evaluate_node(node:Node) -> void: ## Evaluates PKExpressions present on the Node.
	var pkexpressions = node.get_meta('PKExpressions', false)
	if not pkexpressions: return
	var lines:PackedStringArray = pkexpressions.split('\n')
	for line in lines:
		# Parse & process PKExpression.
		var parsed = Parser.parse_pkexp(line)
		if parsed: Parser.process_pkexp(node, line, parsed)
		else: printerr(Errors.pkexp_failed % [line,node.name])




# Hook methods.
# -------------
func _hook_onto_nodes() -> void: ## Hook to all nodes in the project.
	evaluate_node_tree(get_tree().root)

func _recursive(node:Node, callback:Callable) -> void:
	for child in node.get_children():
		callback.call(child)
		_recursive(child,callback)

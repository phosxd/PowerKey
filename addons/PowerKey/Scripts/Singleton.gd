extends Node


func _ready() -> void:
	hook_onto_nodes() # Hook onto all nodes currently in the tree.
	get_tree().node_added.connect(hook_node) # Hook every new node.











# Hook methods.
# -------------
func hook_onto_nodes() -> void: ## Hook to all nodes in the tree.
	recursive(get_tree().root, func(node:Node) -> void:
		hook_node(node)
	)
func hook_node(node:Node) -> void: ## Hook a node.
	pass
func recursive(node:Node, callback:Callable) -> void:
	for child in node.get_children():
		callback.call(child)
		recursive(child,callback)

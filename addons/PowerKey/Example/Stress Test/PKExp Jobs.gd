extends PanelContainer
var Job_time:float = 0
var Job_timer_start:float = 0


func _ready() -> void:
	update_expression_count()
func update_expression_count() -> void:
	%'PKExpression Count'.text = 'PKExp & Node Count: %s' % %Host.get_child_count()

func start_job_timer() -> void:
	Job_timer_start = Time.get_ticks_usec()
func end_job_timer() -> void:
	Job_time = Time.get_ticks_usec()-Job_timer_start
	%'Job Time'.text = 'Job Time: %ss' % [Job_time/1000000]



# Add PKExps/Nodes button callbacks.
# ---------------------------------
func _on_button_add_expression_pressed(amount:int) -> void:
	start_job_timer()
	for i in range(amount):
		var new_node := Node.new()
		new_node.set_meta('PKExpressions', %'PKExp Editor'.Raw)
		%Host.add_child(new_node)
	end_job_timer()
	update_expression_count()

func _on_button_clear_expressions_pressed() -> void:
	start_job_timer()
	for child in %Host.get_children():
		child.free()
	end_job_timer()
	update_expression_count()

@tool
extends Window
enum ExpTypes {ASSIGN,LINK,EXECUTE}
const Assign_expression_template:String = 'A:%s %s'
const Link_expression_template:String = 'L:%s %s'
const Execute_expression_template:String = 'E %s'

signal finished(raw:String)

func init() -> void:
	%Result.init('',Array([],TYPE_DICTIONARY,'',null))


func _update_assign_expression_result(property, value) -> void:
	if not property: property = %'Assign Property LineEdit'.text
	if not value: value = %'Assign Value LineEdit'.text
	%Result.set_text(Assign_expression_template % [property, value])
func _update_link_expression_result(property, frequency, value) -> void:
	if not property: property = %'Link Property LineEdit'.text
	if not frequency: frequency = %'Link Frequency SpinBox'.value
	if not value: value = %'Link Value LineEdit'.text
	if frequency == 0.0: frequency = ''
	%Result.set_text(Link_expression_template % [','.join([property,frequency]).rstrip(','), value])
func _update_execute_expression_result(code) -> void:
	if not code: code = %'Execute Code TextEdit'.text
	%Result.set_text(Execute_expression_template % code)



# UI Callbacks.
# ------------
func _on_close_requested() -> void:
	self.queue_free()
func _on_button_cancel_pressed() -> void:
	_on_close_requested()

func _on_type_options_item_selected(index:int) -> void:
	var count:int = 0
	for child in %Details.get_children():
		if count == index: child.visible = true
		else: child.visible = false
		count += 1

func _on_assign_value_text_changed(new_text:String) -> void:
	_update_assign_expression_result(null, new_text)
func _on_assign_property_text_changed(new_text: String) -> void:
	_update_assign_expression_result(new_text, null)
func _on_link_value_text_changed(new_text: String) -> void:
	_update_link_expression_result(null, null, new_text)
func _on_link_frequency_value_changed(value: float) -> void:
	_update_link_expression_result(null, value, null)
func _on_link_property_text_changed(new_text: String) -> void:
	_update_link_expression_result(new_text, null, null)
func _on_execute_code_text_changed() -> void:
	var text = %'Execute Code TextEdit'.text.replace('\n',';')
	_update_execute_expression_result(text)


func _on_button_done_pressed() -> void:
	if not %Result.Invalid:
		finished.emit(%Result.Raw)
		_on_close_requested()

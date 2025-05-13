@tool
extends VBoxContainer
var PKEE := PK_EE.new()
const collapsed_icon := preload('res://addons/PowerKey/Editor/Editor Inspector/collapsed.svg')
const expanded_icon := preload('res://addons/PowerKey/Editor/Editor Inspector/expanded.svg')

var expanded := false
var PKExpressions:String

signal on_update(pk_expressions:StringName)



func _ready() -> void:
	var config := PK_Config.new().load_config()
	PKEE.init(config, {})
func init(pk_expressions:StringName) -> void:
	# Set PKExpressions.
	%'Text Editor'.text = String(pk_expressions)
	PKExpressions = pk_expressions
	_on_text_editor_text_changed()




func _update_validation_label(error:int, current_char=null) -> void:
	if error == 0:
		$'Content/Items/Validation/Label'.text = 'Looks good! No parsing errors found.'
	else:
		$'Content/Items/Validation/Label'.text = '(@char %s) Error "%s" while parsing expression.' % [current_char, PKEE.Parse_errors[error-1]]




func _on_dropdown_button_down() -> void:
	if expanded:
		expanded = false
		$'Dropdown Button Panel/Visuals/Icon'.texture = collapsed_icon
	else:
		expanded = true
		$'Dropdown Button Panel/Visuals/Icon'.texture = expanded_icon
	$Content.visible = expanded



func _on_text_editor_text_changed() -> void:
	# Update current PKExpressions.
	PKExpressions = %'Text Editor'.text
	on_update.emit(StringName(PKExpressions))
	
	# Ensure dropdown is expanded when typing.
	if not expanded:
		_on_dropdown_button_down()
	
	# Reset line color for first line.
	%'Text Editor'.set_line_background_color(0, Color(0,0,0,0))
	# Validate expressions, if not empty.
	var error := 0
	var current_char := 0
	# Count & parse each line.
	var line_index := -1
	for line in PKExpressions.split('\n'):
		line_index += 1
		%'Text Editor'.set_line_background_color(line_index, Color(0,0,0,0)) # Reset line color.
		if line.length() == 0: continue
		var parsed = PKEE.parse_pkexp(line) # Parse line.
		# If silent error, dim line & skip.
		if parsed.error == 999:
			%'Text Editor'.set_line_background_color(line_index, Color(0.3, 0.3, 0.3)) # Highlight line in Text Editor.
			continue
		# If failed to parse line, set error & highlight line.
		elif parsed.error != 0:
			error = parsed.error
			current_char = parsed.current_char
			%'Text Editor'.set_line_background_color(line_index, Color(1,0.3,0.3,0.5)) # Highlight line in Text Editor.
			break
	# Update validation label with error as mode.
	_update_validation_label(error, current_char)

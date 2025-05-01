@tool
extends VBoxContainer
var Parser := PK_Parser.new()
const collapsed_icon := preload('res://addons/PowerKey/Editor/Editor Inspector/collapsed.svg')
const expanded_icon := preload('res://addons/PowerKey/Editor/Editor Inspector/expanded.svg')

var expanded := false
var PKExpressions:String

signal on_update(pk_expressions:String)



func _ready() -> void:
	# Setup Parser.
	var config := PK_Config.new().load_config()
	Parser.init(config, {})
func init(pk_expressions:String) -> void:
	# Set PKExpressions.
	%'Text Editor'.text = pk_expressions
	PKExpressions = pk_expressions
	_on_text_editor_text_changed()




func _update_validation_label(mode:int) -> void:
	match int(mode):
		0:
			$'Content/Items/Validation/Label'.text = 'Looks good! No parsing errors found.'
		1:
			$'Content/Items/Validation/Label'.text = 'Something doen\'t look right. Double check your expressions!'




func _on_dropdown_button_down() -> void:
	if expanded:
		expanded = false
		$'Dropdown Button Panel/Visuals/Icon'.texture = collapsed_icon
	else:
		expanded = true
		$'Dropdown Button Panel/Visuals/Icon'.texture = expanded_icon
	$Content.visible = expanded



func _on_text_editor_text_changed() -> void:
	PKExpressions = %'Text Editor'.text
	on_update.emit(PKExpressions)
	# Reset line color for first line.
	%'Text Editor'.set_line_background_color(0, Color(0,0,0,0))
	# Validate expressions, if not empty.
	var error := 0
	# Count & parse each line.
	var line_count := 0
	for line in PKExpressions.split('\n'):
		%'Text Editor'.set_line_background_color(line_count, Color(0,0,0,0)) # Reset line color.
		if line.length() == 0: continue
		var result = Parser.parse_pkexp(line) # Parse line.
		# If failed to parse line, set error to true & highlight line.
		if not result:
			error = 1
			%'Text Editor'.set_line_background_color(line_count, Color(1,0.3,0.3,0.5)) # Highlight line in Text Editor.
		line_count += 1
	# Update validation label with error as mode.
	_update_validation_label(error)

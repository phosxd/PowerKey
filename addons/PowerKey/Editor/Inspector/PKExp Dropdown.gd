@tool
extends VBoxContainer
var PKEE := PK_EE.new()
const base_label_settings := preload('res://addons/PowerKey/Editor/Inspector/dropdown_label_settings.tres')
const base_icon_size := Vector2(13,0)
const collapsed_icon := preload('res://addons/PowerKey/Editor/Inspector/collapsed.svg')
const expanded_icon := preload('res://addons/PowerKey/Editor/Inspector/expanded.svg')

var expanded := false
var Raw:String
var Parsed:Array[Dictionary]

signal on_update(raw:StringName, parsed:Array[Dictionary], parse_time:float)



func _ready() -> void:
	var editor_scale := EditorInterface.get_editor_scale()
	# Scale label font size with Editor display scale.
	var new_label_settings:LabelSettings = base_label_settings.duplicate()
	new_label_settings.font_size = new_label_settings.font_size*editor_scale
	%Label.label_settings = new_label_settings
	# Scale icon size with Editor display scale.
	%Icon.custom_minimum_size = base_icon_size*editor_scale
	# Initialize other.
	var config := PK_Config.new().load_config()
	PKEE.init(config, {})

func init(raw:StringName, parsed:Array[Dictionary]) -> void:
	# Set PKExpressions.
	%'Text Editor'.text = raw
	%'Button Store Parsed'.button_pressed = true if parsed.size() > 0 else false
	Raw = raw
	Parsed = parsed
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
	Raw = %'Text Editor'.text
	# Ensure dropdown is expanded when typing.
	if not expanded:
		_on_dropdown_button_down()
	# Reset line color for first line.
	%'Text Editor'.set_line_background_color(0, Color(0,0,0,0))
	
	Parsed.clear() # Remove parsed expressions.
	var error := 0
	var current_char := 0
	var parse_time:float
	
	# Count & parse each line.
	var line_index := -1
	for line in Raw.split('\n'):
		line_index += 1
		%'Text Editor'.set_line_background_color(line_index, Color(0,0,0,0)) # Reset line color.
		if line.strip_edges() == '': continue # If empty, return.
		# Parse line & store parsed line in "Parsed".
		var start_time := Time.get_ticks_usec()
		var parsed = PKEE.parse_pkexp(line)
		parse_time += Time.get_ticks_usec()-start_time
		if %'Button Store Parsed'.button_pressed: Parsed.append(parsed)
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
	
	# Send signal.
	on_update.emit(StringName(Raw), Parsed, parse_time)



func _on_button_store_parsed_toggled(toggled_on:bool) -> void:
	if toggled_on:
		_on_text_editor_text_changed() # Re-parse the expressions.
	else:
		Parsed.clear() # Empty the array of Parsed expressions.
		on_update.emit(StringName(Raw), Parsed, 0)

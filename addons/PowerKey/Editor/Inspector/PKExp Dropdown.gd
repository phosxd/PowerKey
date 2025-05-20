@tool
extends VBoxContainer
var PKEE := PK_EE.new()
const base_icon_size := Vector2(13,0)
const base_builder_icon_size := 16
const collapsed_icon := preload('res://addons/PowerKey/Icons/collapsed.svg')
const expanded_icon := preload('res://addons/PowerKey/Icons/expanded.svg')

var expanded := false
var Invalid:bool = false
var Raw:String
var Parsed:Array[Dictionary]
var Stored_parsed:Array[Dictionary]

signal on_update(raw:StringName, stored_parsed:Array[Dictionary], parse_time:float)



func _ready() -> void:
	if Engine.is_editor_hint():
		# Scale items to Editor scale.
		var editor_settings := EditorInterface.get_editor_settings()
		var editor_scale := EditorInterface.get_editor_scale()
		%Label.push_font_size(editor_settings.get_setting('interface/editor/main_font_size')) # Set label font size to Editor font size.
		%Icon.custom_minimum_size = base_icon_size*editor_scale # Scale icon size with Editor display scale.
		%'Button Builder'.remove_theme_constant_override('icon_max_width') # Remove current override.
		%'Button Builder'.add_theme_constant_override('icon_max_width', base_builder_icon_size*editor_scale) # Add scaled override.

func init(raw:StringName, stored_parsed:Array[Dictionary]) -> void:
	# Initialize stuff.
	var config := PK_Config.new().load_config()
	PKEE.init(config, {})
	$'%Text Editor/Syntax Highlighter'.init(self)
	# Set PKExpressions.
	%'Text Editor'.text = raw
	%'Button Store Parsed'.button_pressed = true if stored_parsed.size() > 0 else false
	Raw = raw
	Stored_parsed = stored_parsed
	_on_text_editor_text_changed()

func set_text(text:String) -> void:
	%'Text Editor'.text = text
	_on_text_editor_text_changed()




func _update_validation_label(error:int, current_char=null) -> void:
	if error == 0:
		$'Content/Items/Validation/Label'.text = 'Looks good! No parsing errors found.'
	else:
		$'Content/Items/Validation/Label'.text = '(@char %s) Error "%s" while parsing expression.' % [current_char, PKEE.Parse_errors[error-1]]




func _on_dropdown_button_down() -> void:
	if expanded:
		expanded = false
		%Icon.texture = collapsed_icon
	else:
		expanded = true
		%Icon.texture = expanded_icon
	$Content.visible = expanded



func _on_text_editor_text_changed() -> void:
	Raw = %'Text Editor'.text
	# Ensure dropdown is expanded when typing.
	if not expanded:
		_on_dropdown_button_down()
	# Reset line color for first line.
	%'Text Editor'.set_line_background_color(0, Color(0,0,0,0))
	
	# Remove parsed expressions.
	Parsed.clear()
	Stored_parsed.clear()
	var error := 0
	var current_char := 0
	var parse_time:float
	
	# Count & parse each line.
	var line_index := -1
	for line in Raw.split('\n'):
		line_index += 1
		%'Text Editor'.set_line_background_color(line_index, Color(0,0,0,0)) # Reset line color.
		#if line.strip_edges() == '': continue # If empty, return.
		# Parse line & store parsed line in "Parsed".
		var start_time := Time.get_ticks_usec()
		var parsed = PKEE.parse_pkexp(line)
		parse_time += Time.get_ticks_usec()-start_time
		Parsed.append(parsed)
		if %'Button Store Parsed'.button_pressed: Stored_parsed.append(parsed)
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

	if error == 0: Invalid = false
	else: Invalid = true
	# Update validation label with error.
	_update_validation_label(error, current_char)
	
	# Send signal.
	on_update.emit(StringName(Raw), Stored_parsed, parse_time)



func _on_button_store_parsed_toggled(toggled_on:bool) -> void:
	if toggled_on:
		_on_text_editor_text_changed() # Re-parse the expressions.
	else:
		Stored_parsed.clear() # Empty the array of parsed expressions.
		on_update.emit(StringName(Raw), Stored_parsed, 0)


func _on_button_builder_pressed() -> void:
	var builder_scene:Window = load('res://addons/PowerKey/Editor/PKExp Builder/PKExp Builder.tscn').instantiate()
	builder_scene.init()
	EditorInterface.popup_dialog(builder_scene)
	builder_scene.finished.connect(func(raw:String) -> void:
		%'Text Editor'.text += '\n%s' % raw
		_on_text_editor_text_changed()
	)

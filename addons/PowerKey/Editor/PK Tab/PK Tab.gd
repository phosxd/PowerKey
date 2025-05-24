@tool
extends VBoxContainer
const base_icon_size := Vector2(32,0)
var Config:PK_Config
var resources_script_path_text_box:Node
var max_cached_pkexpressions_spin_box:Node
var warning_tag:Node
var guide_tabs:Node

func init() -> void:
	# Initialize values.
	Config = PK_Config.new()
	resources_script_path_text_box = get_node('Tabs/Configure/Resources Path/Text Box')
	max_cached_pkexpressions_spin_box = get_node('Tabs/Configure/Max Cached PKExpressions/SpinBox')
	warning_tag = get_node('Tabs/Configure/Warning Tag')
	guide_tabs = get_node('Tabs/Guide/Tabs')
	%'guide_gtr_layout_code1'.syntax_highlighter = GDScriptSyntaxHighlighter.new()
	# Scale button icons.
	var editor_scale := EditorInterface.get_editor_scale()
	%'Button Github'.custom_minimum_size = base_icon_size*editor_scale
	# Set UI values based on config.
	var config := Config.load_config()
	resources_script_path_text_box.text = config.resources_script_path
	max_cached_pkexpressions_spin_box.value = config.max_cached_pkexpressions
	check_resources_script_path()
	# Connect signals for RichTextLabels in the Guide.
	for child in guide_tabs.get_children():
		if child is RichTextLabel:
			child.meta_clicked.connect(func(meta):
				OS.shell_open(str(meta))
			)



# Checks.
# -------
func check_resources_script_path() -> void:
	var path:String = resources_script_path_text_box.text
	if not FileAccess.file_exists(path):
		warning_tag.visible = true
		warning_tag.get_node('Label 1').visible = false
		warning_tag.get_node('Label 1').visible = true
	else:
		warning_tag.visible = false





# UI Callbacks.
# -------------
func _on_tab_bar_tab_changed(tab:int) -> void:
	$Tabs.current_tab = tab

func _on_button_github_pressed() -> void:
	OS.shell_open('https://github.com/phosxd/PowerKey')


func _on_resources_script_path_text_changed() -> void:
	var text:String = $'Tabs/Configure/Resources Path/Text Box'.text
	# Remove new lines if added.
	text = text.replace('\n','')
	# Update config, then verify path.
	Config.update_config('resources_script_path', text)
	check_resources_script_path()
	# Update Text Box text if different.
	if text != $'Tabs/Configure/Resources Path/Text Box'.text: $'Tabs/Configure/Resources Path/Text Box'.text = text

func _on_max_cached_pkexpressions_value_changed(value:float) -> void:
	Config.update_config('max_cached_pkexpressions', int(value))

func _on_debug_option_1_toggled(toggled_on:bool) -> void:
	Config.update_config('debug_print_any_pkexpression_processed', toggled_on)

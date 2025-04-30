@tool
extends VBoxContainer
@onready var Config := PK_Config.new()

@onready var resources_script_path_text_box := get_node('Tabs/Configure/Resources Path/Text Box')
@onready var warning_tag := get_node('Tabs/Configure/Warning Tag')
@onready var guide_tabs := get_node('Tabs/Guide/Tabs')

func _ready() -> void:
	# Set UI values based on config.
	var config := Config.load_config()
	resources_script_path_text_box.text = config.resources_script_path
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

func _on_resources_script_path_text_submitted(new_text:String) -> void:
	Config.update_config('resources_script_path', new_text)
	check_resources_script_path()

func _on_button_github_pressed() -> void:
	OS.shell_open('https://github.com/phosxd/PowerKey')

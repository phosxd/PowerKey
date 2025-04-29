@tool
extends VBoxContainer
const config_file_path := 'res://addons/PowerKey/config.json'
const errors := {
	'failed_open_file': 'PowerKey: Unable to open file at "%s".',
	'default_config': 'PowerKey: Unable to read config file. Using default config.'
}
const default_config_data := """{
	\"resources_script_path\": \"\",
	\"activation_phrase\": \"@\",
}"""
const required_config_pairs := {
	'resources_script_path': '',
	'activation_phrase': '',
}

@onready var resources_script_path_text_box := get_node('Tabs/Configure/Resources Path/Text Box')
@onready var activation_phrase_text_box := get_node('Tabs/Configure/Activation Phrase/Text Box')
@onready var warning_tag := get_node('Tabs/Configure/Warning Tag')
@onready var guide_tabs := get_node('Tabs/Guide/Tabs')

func _ready() -> void:
	# Set UI values based on config.
	var config := load_config()
	resources_script_path_text_box.text = config.resources_script_path
	activation_phrase_text_box.text = config.activation_phrase
	check_resources_script_path()
	# Connect signals for RichTextLabels in the Guide.
	for child in guide_tabs.get_children():
		if child is RichTextLabel:
			child.meta_clicked.connect(func(meta):
				OS.shell_open(str(meta))
			)
	


# Config file functions.
# ----------------------
func load_config() -> Dictionary: ## Loads the config file. Returns default config data if config file not found.
	var config_data:String
	var file := FileAccess.open(config_file_path, FileAccess.READ) # Open config file.
	# If file doesn't exist or could not read from file, use default data.
	if not file:
		config_data = default_config_data
		printerr(errors.default_config)
	# If file found, read as text & close file.
	else:
		config_data = file.get_as_text()
		file.close()
	# Parse the text as json.
	var config_data_json := JSON.parse_string(config_data)
	# If parsing failed, use default config data.
	if not config_data_json:
		config_data_json = JSON.parse_string(default_config_data)
		printerr(errors.default_config)
	# Check parsed data for required key/value-type pairs.
	for key in required_config_pairs.keys():
		if key in config_data_json.keys():
			if typeof(required_config_pairs[key]) == typeof(config_data_json[key]): continue
		config_data_json = JSON.parse_string(default_config_data)
		printerr(errors.default_config)
		break
			
	return config_data_json


func update_config(key:String, value:String) -> void: ## Update the config file.
	var config_data := load_config()
	config_data[key] = value
	var file := FileAccess.open(config_file_path, FileAccess.WRITE)
	file.store_string(str(config_data))
	file.close()





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
	update_config('resources_script_path', new_text)
	check_resources_script_path()

func _on_activation_phrase_text_submitted(new_text:String) -> void:
	if new_text.length() == 0:
		new_text = '@'
		activation_phrase_text_box.text = '@'
	update_config('activation_phrase', new_text)

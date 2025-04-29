class_name PK_Config extends Node

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

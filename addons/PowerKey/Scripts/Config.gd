# This script loads & manages the configuration, from a config text file.
# New instance should be created if used (call `.new`).

class_name PK_Config extends Node

const config_file_path := 'res://addons/PowerKey/config.json'
const Errors := {
	'failed_open_file': 'PowerKey: Unable to open file at "%s".',
	'default_config': 'PowerKey: Unable to read config file. Using default config.'
}
const default_config := {
	'resources_script_path': '',
	'max_cached_pkexpressions': 3,
	'debug_print_any_pkexpression_processed': false
}



func load_config() -> Dictionary: ## Loads the config file. Returns default config data if config file not found.
	var config_json
	var file := FileAccess.open(config_file_path, FileAccess.READ) # Open config file.
	# If file doesn't exist or could not read from file, use default data.
	if not file:
		config_json =  default_config
		printerr(Errors.default_config)
	# If file found, read as text & close file.
	else:
		config_json = JSON.parse_string(file.get_as_text())
		file.close()

	# If parsing JSON failed, use default config.
	if not config_json:
		config_json = default_config
		printerr(Errors.default_config)

	# Check config_json for any missing values.
	for key in default_config.keys():
		if key in config_json.keys():
			if typeof(default_config[key]) == typeof(config_json[key]): continue
		config_json.set(key, default_config[key])

	# Update config file.
	set_config(config_json)

	# Return.
	return config_json



func set_config(config_data:Dictionary) -> void: ## Writes to the config file.
	var file := FileAccess.open(config_file_path, FileAccess.WRITE)
	file.store_string(str(config_data))
	file.close()

func update_config(key:String, value) -> void: ## Update the config file.
	var config_data := load_config()
	config_data[key] = value
	set_config(config_data)

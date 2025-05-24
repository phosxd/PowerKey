# This script loads & manages the configuration, from a config text file.
# New instance should be created if used (call `.new`).

class_name PK_Config extends Node

const Config_file_path := 'res://addons/PowerKey/config.json'
const Errors := {
	'failed_open_file': 'PowerKey: Unable to open file at "%s".',
	'default_config': 'PowerKey: Unable to read config file. Using default config.'
}



func load_config() -> Dictionary: ## Loads the config file. Returns default config data if config file not found.
	var config_json
	var changed := false
	var file := FileAccess.open(Config_file_path, FileAccess.READ) # Open config file.
	# If file doesn't exist or could not read from file, use default data.
	if not file:
		config_json = PK_Common.Schemas.config.latest
		changed = true
		printerr(Errors.default_config)
	# If file found, read as text & close file.
	else:
		config_json = JSON.parse_string(file.get_as_text())
		file.close()

	# If parsing JSON failed, use default config.
	if not config_json:
		config_json = PK_Common.Schemas.config.latest
		changed = true
		printerr(Errors.default_config)

	# Check config_json for any missing values.
	var config_json_matched := PK_Common.match_schema(config_json, PK_Common.Schemas.config.latest)
	if config_json_matched.object != config_json:
		config_json = config_json_matched.object
		changed = true

	# Update config file, if changed.
	if changed:
		set_config(config_json)

	# Return.
	return config_json



func set_config(data:Dictionary) -> void: ## Writes to the config file.
	var file := FileAccess.open(Config_file_path, FileAccess.WRITE)
	file.store_string(str(data))
	file.close()


func update_config(key:String, value) -> void: ## Update the config file.
	var data := load_config()
	data[key] = value
	set_config(data)

@tool
extends EditorPlugin
const Icon := preload('res://addons/PowerKey/icon.svg')
const PowerKey_editor_tscn := preload('res://addons/PowerKey/Editor/Editor.tscn')
var PowerKey_editor_instance: Control


func _enter_tree() -> void:
	# Add PowerKey to Godot editor.
	PowerKey_editor_instance = PowerKey_editor_tscn.instantiate()
	EditorInterface.get_editor_main_screen().add_child(PowerKey_editor_instance)
	_make_visible(false)
	# Enable singleton that will run when running the project.
	add_autoload_singleton('PowerKey', 'res://addons/PowerKey/Scripts/Singleton.gd')

func _exit_tree() -> void:
	if PowerKey_editor_instance:
		PowerKey_editor_instance.queue_free()
	# Remove singleton, when addon removed.
	remove_autoload_singleton('PowerKey')



func _make_visible(visible:bool) -> void:
	if PowerKey_editor_instance:
		PowerKey_editor_instance.visible = visible

func _has_main_screen() -> bool:
	return true

func _get_plugin_name():
	return 'PowerKey'

func _get_plugin_icon() -> Texture2D:
	return Texture2D.new()

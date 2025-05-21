@tool
extends EditorPlugin
const Icon := preload('res://addons/PowerKey/Icons/icon.svg')
const EditorInspectorPlugin_ := preload('res://addons/PowerKey/Scripts/EditorInspectorPlugin.gd')
var EditorInspectorPlugin_instance:EditorInspectorPlugin
const PowerKey_tab_tscn := preload('res://addons/PowerKey/Editor/PK Tab/PK Tab.tscn')
var PowerKey_tab_instance:Control


func _enter_tree() -> void:
	# Add InspectorPlugin.
	EditorInspectorPlugin_instance = EditorInspectorPlugin_.new()
	add_inspector_plugin(EditorInspectorPlugin_instance)
	# Enable singleton that will run when running the project.
	add_autoload_singleton('PowerKey', 'res://addons/PowerKey/Scripts/Singleton.gd')
	# Add PowerKey Editor menu to Godot editor.
	PowerKey_tab_instance = PowerKey_tab_tscn.instantiate()
	PowerKey_tab_instance.init()
	EditorInterface.get_editor_main_screen().add_child(PowerKey_tab_instance)
	_make_visible(false)


func _exit_tree() -> void:
	# Remove InspectorPlugin.
	remove_inspector_plugin(EditorInspectorPlugin_instance)
	# Remove singleton, when addon removed.
	remove_autoload_singleton('PowerKey')
	# Remove PowerKey Editor menu.
	if PowerKey_tab_instance:
		PowerKey_tab_instance.queue_free()





func _make_visible(visible:bool) -> void:
	if PowerKey_tab_instance:
		PowerKey_tab_instance.visible = visible

func _has_main_screen() -> bool:
	return true

func _get_plugin_name():
	return 'PowerKey'

func _get_plugin_icon() -> Texture2D: ## Return scaled plugin icon.
	var image := Icon.get_image() # Get base image from Icon.
	var new_size:Vector2i = image.get_size()*EditorInterface.get_editor_scale() # Calculate new base image size to match Editor display scale.
	image.resize(new_size.x, new_size.y) # Apply new scale.
	return ImageTexture.create_from_image(image) # Return new ImageTexture from resized base image.

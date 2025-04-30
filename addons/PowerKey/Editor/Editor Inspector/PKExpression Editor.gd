@tool
extends VBoxContainer
const collapsed_icon := preload('res://addons/PowerKey/Editor/Editor Inspector/collapsed.svg')
const expanded_icon := preload('res://addons/PowerKey/Editor/Editor Inspector/expanded.svg')
var expanded := false
var pk_expressions:String

signal on_update(raw_lines:String)



func init(pk_expressions_:String) -> void:
	$'Content/Items/TextEdit'.text = pk_expressions_
	pk_expressions = pk_expressions_



func _on_dropdown_button_pressed() -> void:
	if expanded:
		expanded = false
		$'Dropdown Button Panel/Visuals/Icon'.texture = collapsed_icon
	else:
		expanded = true
		$'Dropdown Button Panel/Visuals/Icon'.texture = expanded_icon
	$Content.visible = expanded


func _on_text_edit_text_changed() -> void:
	pk_expressions = $'Content/Items/TextEdit'.text
	on_update.emit(pk_expressions)

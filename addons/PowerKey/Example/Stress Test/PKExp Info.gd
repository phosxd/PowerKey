extends PanelContainer


func _on_pkexp_editor_update(raw: StringName, parsed: Array[Dictionary], parse_time:float) -> void:
	%'Parse Time'.text = 'Parse Time: %ss' % (parse_time/1000000)

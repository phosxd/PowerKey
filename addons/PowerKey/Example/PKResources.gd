extends Node
const titles := {'a':'Whoah! A title!', 'b':'ANOTHER TITLE?! No way..'}
var title_label_settings := LabelSettings.new()

func _ready() -> void:
	title_label_settings.font_size = 30
	title_label_settings.font_color = Color(1,0.5,0)

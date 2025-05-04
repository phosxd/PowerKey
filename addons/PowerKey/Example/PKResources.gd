extends Node
const explanation := 'In this example we are setting every single label\'s text & label settings using PowerKey PKExpressions. There is even a real-time FPS counter running! All while there are 0 script files attached to the scene or any of it\'s Nodes.'
const titles := {'a':'Whoah! A title!', 'b':'ANOTHER TITLE?! No way..'}
var title_label_settings := LabelSettings.new()
var current_fps:String

func _ready() -> void:
	title_label_settings.font_size = 30
	title_label_settings.font_color = Color(1,0.5,0)

func _process(delta:float) -> void:
	current_fps = 'Main-Thread Frames Per Second: %s' % Engine.get_frames_per_second()

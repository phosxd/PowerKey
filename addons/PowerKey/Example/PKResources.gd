extends Node
# Define some variables to use.
const explanation := 'In this example we are setting every single label\'s text & label settings using PowerKey PKExpressions. There is even a real-time FPS counter running! All while there are 0 script files attached to the scene or any of it\'s Nodes.'
const titles := {'a':'Whoah! A title!', 'b':'ANOTHER TITLE?! No way..'}
var title_label_settings := LabelSettings.new()

# Define constantly changing FPS variables.
var _current_fps := 0.0
var _min_fps := 999.0
var _max_fps := 0.0
var current_fps:String
var min_fps:String
var max_fps:String


func _ready() -> void:
	# Set title label settings values.
	title_label_settings.font_size = 30
	title_label_settings.font_color = Color(1,0.5,0)



var min_max_update_timer := 0.0 ## Keeps track of time since last min FPS & max FPS reset.
func _process(delta:float) -> void:
	min_max_update_timer += delta # Add to timer.
	# If 5 seconds past, then reset min FPS & max FPS.
	if min_max_update_timer >= 5.0:
		min_max_update_timer = 0.0
		_min_fps = 999.0
		_max_fps = 0.0
	
	# Update FPS values.
	_current_fps = Engine.get_frames_per_second()
	if _current_fps > _max_fps: _max_fps = _current_fps
	if _current_fps < _min_fps: _min_fps = _current_fps
	current_fps = 'Main-Thread Frames Per Second: %s' % _current_fps
	min_fps = 'Min-FPS: %s' % _min_fps
	max_fps = 'Max-FPS: %s' % _max_fps

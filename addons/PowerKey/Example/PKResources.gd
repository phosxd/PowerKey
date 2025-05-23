extends Node
# Define some variables to use.
const explanation := 'In this example we are setting every single label\'s text & label settings using PowerKey PKExpressions. There is even a real-time FPS counter running! All while there are 0 script files attached to the scene or any of it\'s Nodes.'
const titles := {'a':'Whoah! A title!', 'b':'ANOTHER TITLE?! No way..'}
const bottom_text:Array[String] = ['Text from an array :)']
const random_number_template := 'Random Number: %s'
var title_label_settings := LabelSettings.new()
var _frame_count_template := 'Slow updating counter: %s'
var _current_fps_template := 'Main-Thread Frames Per Second: %s'
var _min_fps_template := 'Min-FPS: %s'
var _max_fps_template := 'Max-FPS: %s'

# Define constantly changing variables.
var _frame_count := 0
var _current_fps := 0.0
var _min_fps := 999.0
var _max_fps := 0.0
var frame_count := _frame_count_template % 0
var current_fps := _current_fps_template % 0
var min_fps := _min_fps_template % 0
var max_fps := _max_fps_template % 0


func _ready() -> void:
	# Set title label settings values.
	title_label_settings.font_size = 30
	title_label_settings.font_color = Color(1,0.5,0)



var min_max_update_timer := 0.0 ## Keeps track of time since last min FPS & max FPS reset.
func _process(delta:float) -> void:
	_frame_count += 1
	frame_count = _frame_count_template % _frame_count
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
	current_fps = _current_fps_template % _current_fps
	min_fps = _min_fps_template % _min_fps
	max_fps = _max_fps_template % _max_fps

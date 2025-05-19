@tool
extends Node
const HighlightColors:Array[Color] = [
	Color.CORNFLOWER_BLUE,
	Color.STEEL_BLUE,
	Color.DARK_GRAY,
	Color.TAN,
]

func init(base) -> void:
	var parent:TextEdit = $'../'
	parent.syntax_highlighter = Highlighter.new(base)



class Highlighter extends SyntaxHighlighter:
	var Base
	func _init(base) -> void:
		Base = base

	func _get_line_syntax_highlighting(line:int) -> Dictionary:
		var hdata:Dictionary[int,Dictionary] = {}
		if Base.Parsed.size()-1 < line: return hdata # Return empty data if line index out of range.
		if Base.Parsed[line].error != 0: return hdata # If error in expression, dont highlight.
		var parser_hdata:PackedInt32Array = Base.Parsed[line].char_highlight_data # Get highlight data from Parsed.
		var index:int = 0
		for item in parser_hdata:
			if item == -1: hdata[index] = {}
			else: hdata[index] = {'color':HighlightColors[item]}
			index += 1
		return hdata

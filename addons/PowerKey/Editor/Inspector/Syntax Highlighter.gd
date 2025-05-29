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
	var virtual_textedit := TextEdit.new()
	var gdscript_highlighter := GDScriptSyntaxHighlighter.new()


	func _init(base) -> void:
		Base = base
		virtual_textedit.syntax_highlighter = gdscript_highlighter


	func _get_line_syntax_highlighting(line:int) -> Dictionary:
		var hdata:Dictionary[int,Dictionary] = {}
		if Base.Parsed.size()-1 < line: return hdata # Return empty data if line index out of range.
		if Base.Parsed[line].error != 0: return hdata # If error in expression, dont highlight.
		var parser_hdata:PackedInt32Array = Base.Parsed[line].char_highlight_data # Get highlight data from Parsed.
		
		# If an execute PKExpression & running in Godot Editor, use GDScript syntax highlighting.
		if Base.Parsed[line].type in [PK_EE.ExpTypes.EXECUTE,PK_EE.ExpTypes.EVAL] && Engine.is_editor_hint():
			virtual_textedit.text = Base.get_node('%Text Editor').get_line(line) # Set the virtual TextEdit's text to match actual PKExp Editor text.
			hdata = Dictionary(gdscript_highlighter.get_line_syntax_highlighting(0),TYPE_INT,'',null,TYPE_DICTIONARY,'',null) # Get highlighting data from virtual TextEdit.
			hdata[0] = {'color':HighlightColors[parser_hdata[0]]} # Set proper PKExpression Type highlight color.
		# Highlight based on parsed highlighting data.
		else:
			var index:int = 0
			for item in parser_hdata:
				if item == -1: hdata[index] = {}
				else: hdata[index] = {'color':HighlightColors[item]}
				index += 1
		return hdata

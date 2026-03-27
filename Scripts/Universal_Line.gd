extends PanelContainer

@onready var main = get_node("/root/UI")

var dictionary_index = -1


#* Cached references for this line’s data:
var conv: Dictionary
var block: Dictionary
var line: Dictionary
var line_data: Dictionary

var choice = ""					#/ For choices, the choice selected for that line

@onready var stylebox = self.get_theme_stylebox("panel")


#* Called when the node enters the scene tree for the first time:
func _ready() -> void:
	#% Update ID:
	$"HBox/Index".text = str(get_index())


#* Fill this line's UI from its line_data:
func _apply_line_data_to_ui() -> void:
	conv = {}
	block = {}
	line = {}
	line_data = {}

	conv = candy_dc.conversations[candy_dc.current_conversation]
	block = conv[candy_dc.current_block]
	line = block["Text"][dictionary_index]

	if line.keys().size() == 0:
		return

	$"HBox/Move".tooltip_text = "Left-Click to insert next line before this line.\nClick+Drag to reorder lines.\nRight-Click to delete this line.\n\n"

	#@ Set line elements to invisible:
	$"HBox/SpeechLine".visible = false

	$"HBox/Con".visible = false
	$"HBox/Con/Condition".visible = false
	$"HBox/Con/Type".visible = false
	$"HBox/Con/Transition".visible = false
	$"HBox/Con/Conversation".visible = false
	$"HBox/Con/Block".visible = false
	$"HBox/Con/Line".visible = false
	$"HBox/Con/Go".visible = false

	$"HBox/Con/Expression".visible = false
	$"HBox/Con/SetVariable".visible = false
	$"HBox/Con/Flag".visible = false
	$"HBox/Con/Name".visible = false
	$"HBox/Con/NameTable".visible = false
	$"HBox/Con/NameActorKey".visible = false
	$"HBox/Con/Operator".visible = false
	$"HBox/Con/Reference".visible = false
	$"HBox/Con/Disposition".visible = false
	$"HBox/Con/Role".visible = false

	$"HBox/Con/Await".visible = false
	$"HBox/Con/Function".visible = false
	$"HBox/Con/Signal".visible = false
	$"HBox/Con/Arguments".visible = false

	$"HBox/Con/Path".visible = false
	$"HBox/Con/File".visible = false
	$"HBox/Con/Format".visible = false
	$"HBox/Con/Method".visible = false
	$"HBox/Con/Dictionary".visible = false

	$"HBox/Con/Command".visible = false
	$"HBox/Con/Data".visible = false

	$"HBox/LM".visible = false
	$"HBox/LM/Reference".visible = false

	$"HBox/Input".visible = false
	$"HBox/Mouse".visible = false

	$"HBox/Choices".visible = false
	$"HBox/Choices/Config".visible = false
	$"HBox/Choices/Reference".visible = false
	$"HBox/Choices/MenuMode".visible = false
	$"HBox/Choices/CategoryMode".visible = false
	$"HBox/Choices/ChoiceMode".visible = false
	$"HBox/Choices/TimerMode".visible = false
	$"HBox/Choices/Enable".visible = false
	$"HBox/Choices/Activate".visible = false
	$"HBox/Choices/Show".visible = false
	$"HBox/Choices/Label".visible = false
	$"HBox/Choices/Tooltip".visible = false
	$"HBox/Choices/Time".visible = false
	$"HBox/Choices/Loop".visible = false
	$"HBox/Choices/TimerNode".visible = false
	$"HBox/Choices/TimerStatus".visible = false

	$"HBox/Clear".visible = false
	$"HBox/Clear/Box".visible = false
	$"HBox/Clear/Bubbles".visible = false
	$"HBox/Clear/Subtitles".visible = false
	$"HBox/Clear/Portraits".visible = false
	$"HBox/Clear/Busts".visible = false
	$"HBox/Clear/Backgrounds".visible = false

	$"HBox/Media".visible = false
	$"HBox/Media/Node".visible = false
	$"HBox/Media/Node/Button".visible = false
	$"HBox/Media/Animation".visible = false
	$"HBox/Media/Media".visible = false
	$"HBox/Media/Duration".visible = false
	$"HBox/Media/Lines".visible = false
	$"HBox/Media/Time".visible = false
	$"HBox/Media/Loop".visible = false
	$"HBox/Media/Wait".visible = false
	$"HBox/Media/Animated".visible = false
	$"HBox/Media/AllLines".visible = false
	$"HBox/Media/Box".visible = false
	$"HBox/Media/Portrait".visible = false
	$"HBox/Media/Volume".visible = false

	$"HBox/VN".visible = false
	$"HBox/VN/Scene".visible = false
	$"HBox/VN/Busts".visible = false
	$"HBox/VN/Layers".visible = false
	$"HBox/VN/Actors".visible = false
	$"HBox/VN/Reference".visible = false
	$"HBox/VN/Animation".visible = false
	$"HBox/VN/File".visible = false
	$"HBox/VN/Libraries".visible = false
	$"HBox/VN/Effects".visible = false
	$"HBox/VN/Loop".visible = false
	$"HBox/VN/Wait".visible = false
	$"HBox/VN/Time".visible = false
	$"HBox/VN/Default".visible = false
	$"HBox/VN/Axis".visible = false

	$"HBox/CS".visible = false
	$"HBox/CS/Scene".visible = false
	$"HBox/CS/Path1".visible = false
	$"HBox/CS/Path2".visible = false
	$"HBox/CS/Targets".visible = false
	$"HBox/CS/Markers".visible = false
	$"HBox/CS/File".visible = false
	$"HBox/CS/Animation".visible = false
	$"HBox/CS/Rotate".visible = false
	$"HBox/CS/Play".visible = false
	$"HBox/CS/Method".visible = false
	$"HBox/CS/Properties".visible = false
	$"HBox/CS/Value".visible = false
	$"HBox/CS/Energy".visible = false
	$"HBox/CS/Color".visible = false
	$"HBox/CS/Loop".visible = false
	$"HBox/CS/Wait".visible = false
	$"HBox/CS/Time".visible = false
	$"HBox/CS/Operators".visible = false
	$"HBox/CS/ColorPicker".visible = false
	$"HBox/CS/Visibility".visible = false
	$"HBox/CS/Default".visible = false

	$"HBox/Comment".visible = false

	$"HBox/Clear".visible = false

	$"HBox/EndTexture".visible = false

	var key_name = line.keys()[0]
	line_data = line[key_name]

	stylebox.border_color = Color(0, 0, 0)

	#@ Display Universal Line:
	match key_name:
		"Spoken Line":
			$"HBox/Move".text = "Spoken Line"
			$"HBox/Move".tooltip_text += "Display actor speech on screen."
			$"HBox/SpeechLine/Speaker/Ref".tooltip_text = "Actor or Role reference for the speaker.
				Prefix the reference with the role symbol (" + candy_dc.role_symbol + ") to indicate a role."

			#% Get data:
			$"HBox/SpeechLine/Speaker/Ref".text = str(line_data.get("Reference", ""))
			$"HBox/SpeechLine/Disposition/Disposition".text = str(line_data.get("Disposition", ""))
			$"HBox/SpeechLine/Portrait/File".text = str(line_data.get("Portrait", ""))
			$"HBox/SpeechLine/Voice/File".text = str(line_data.get("Voice", ""))

			#% Variant text (Default):
			if line_data.has("Variants") and line_data["Variants"].size() > 0:
				for variant in line_data["Variants"]:
					if variant.has("Default"):
						$"HBox/SpeechLine/Speech/Text".text = str(variant["Default"].get("Text", ""))
						break

			#% Character count:
			update_character_count()

			#% Tag colors and toggles:
			var ai = line_data.get("AI", 0)
			var btn_llm := $"HBox/SpeechLine/LLM"
			if ai == 0:
				btn_llm.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
			elif ai == 1:
				btn_llm.modulate = candy_dc.color_models[candy_dc.color_mode]["On"]
			elif ai == -1:
				btn_llm.modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]

			var tts = line_data.get("TTS", 0)
			var btn_tts := $"HBox/SpeechLine/LLM"
			if tts == 0:
				btn_tts.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
			elif tts == 1:
				btn_tts.modulate = candy_dc.color_models[candy_dc.color_mode]["On"]
			elif tts == -1:
				btn_tts.modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]

			var bubble = line_data.get("BubbleExempt", false)
			if bubble == true:
				$"HBox/SpeechLine/BubbleExempt".modulate = candy_dc.color_models[candy_dc.color_mode]["Neutral"]
			elif bubble == false:
				$"HBox/SpeechLine/BubbleExempt".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]

			var force = line_data.get("ForcePortrait", false)
			if force == "1":
				$"HBox/SpeechLine/ForcePortrait".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]
			elif force == "-1":
				$"HBox/SpeechLine/ForcePortrait".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]
			elif force == "0":
				$"HBox/SpeechLine/ForcePortrait".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]


			#% Toggle Visibility:
			$"HBox/SpeechLine".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		#& Control Commands:
		#region
		"§Call":
			$"HBox/Move".text = "Call"
			$"HBox/Move".tooltip_text += "Call a function."
			$"HBox/Con/SetVariable".tooltip_text = "Variable to store returned value to."

			#% Get data:
			$"HBox/Con/Function".text = str(line_data.get("Function", ""))
			$"HBox/Con/Arguments".text = str(line_data.get("Arguments", ""))
			$"HBox/Con/SetVariable".text = str(line_data.get("Variable", ""))

			if line_data["Await"] == true:
				$"HBox/Con/Await".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]   #/ green
			elif line_data["Await"] == false:
				$"HBox/Con/Await".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]   #/ red

			#% Toggle Visibility:
			$"HBox/Con".visible = true
			$"HBox/Con/Await".visible = true
			$"HBox/Con/Function".visible = true
			$"HBox/Con/Arguments".visible = true
			$"HBox/Con/SetVariable".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Emit":
			$"HBox/Move".text = "Emit"
			$"HBox/Move".tooltip_text += "Emit a signal."

			#% Get data:
			$"HBox/Con/Signal".text = str(line_data.get("Signal", ""))
			$"HBox/Con/Arguments".text = str(line_data.get("Arguments", ""))

			#% Toggle Visibility:
			$"HBox/Con".visible = true
			$"HBox/Con/Signal".visible = true
			$"HBox/Con/Arguments".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Await":
			$"HBox/Move".text = "Await"
			$"HBox/Move".tooltip_text += "Await on a signal."
			$"HBox/Con/SetVariable".tooltip_text = "Variable to store signal arguments to."

			#% Get data:
			$"HBox/Con/Signal".text = str(line_data.get("Signal", ""))
			$"HBox/Con/SetVariable".text = str(line_data.get("Variable", ""))

			#% Toggle Visibility:
			$"HBox/Con".visible = true
			$"HBox/Con/Signal".visible = true
			$"HBox/Con/SetVariable".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Set":
			$"HBox/Move".text = "Set"
			$"HBox/Move".tooltip_text += "Change the value of a variable."
			$"HBox/Con/SetVariable".tooltip_text = "Variable to modify."

			#% Get data:
			$"HBox/Con/SetVariable".text = str(line_data.get("Variable", ""))
			$"HBox/Con/Operator/Operator".text = str(line_data.get("Operator", ""))
			$"HBox/Con/Expression/Text".text = str(line_data.get("Expression", ""))

			#% Toggle Visibility:
			$"HBox/Con".visible = true
			$"HBox/Con/SetVariable".visible = true
			$"HBox/Con/Operator".visible = true
			$"HBox/Con/Expression".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Flag":
			$"HBox/Move".text = "Flag"
			$"HBox/Move".tooltip_text += "Change the value of a flage in the 'flags' dictionary."

			#% Get data:
			$"HBox/Con/Flag/Flag".text = str(line_data.get("Flag", ""))
			$"HBox/Con/Operator/Operator".text = str(line_data.get("Operator", ""))
			$"HBox/Con/Expression/Text".text = str(line_data.get("Expression", ""))

			#% Toggle Visibility:
			$"HBox/Con".visible = true
			$"HBox/Con/Flag".visible = true
			$"HBox/Con/Operator".visible = true
			$"HBox/Con/Expression".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Name":
			$"HBox/Move".text = "Name"
			$"HBox/Move".tooltip_text += "Change the display name of an actor in the 'actors' dictionary."

			#% Get data:
			$"HBox/Con/Reference/Ref".text = str(line_data.get("Reference", ""))
			$"HBox/Con/Name".text = str(line_data.get("Name", ""))
			$"HBox/Con/NameTable".text = str(line_data.get("Table", ""))
			$"HBox/Con/NameActorKey".text = str(line_data.get("Actor_Key", ""))

			#% Toggle Visibility:
			$"HBox/Con".visible = true
			$"HBox/Con/Reference".visible = true
			$"HBox/Con/Name".visible = true
			$"HBox/Con/NameTable".visible = true
			$"HBox/Con/NameActorKey".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Disposition":
			$"HBox/Move".text = "Disposition"
			$"HBox/Move".tooltip_text += "Change the disposition of an actor in the 'actors' dictionary."

			#% Get data:
			$"HBox/Con/Reference/Ref".text = str(line_data.get("Reference", ""))
			$"HBox/Con/Disposition/Disposition".text = str(line_data.get("Disposition", ""))

			#% Toggle Visibility:
			$"HBox/Con".visible = true
			$"HBox/Con/Reference".visible = true
			$"HBox/Con/Disposition".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Role":
			$"HBox/Move".text = "Role"
			$"HBox/Move".tooltip_text += "Assign an actor to a role in the 'actor_roles' dictionary."

			#% Get data:
			$"HBox/Con/Role/Ref".text = str(line_data.get("Role", ""))
			$"HBox/Con/Reference/Ref".text = str(line_data.get("Reference", ""))

			#% Toggle Visibility:
			$"HBox/Con".visible = true
			$"HBox/Con/Role".visible = true
			$"HBox/Con/Reference".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Export":
			$"HBox/Move".text = "Export"
			$"HBox/Move".tooltip_text += "Export variables to a file."
			$"HBox/Con/Format".tooltip_text = "File format to export to."

			#% Get data:
			$"HBox/Con/Path".text = str(line_data.get("Path", ""))
			$"HBox/Con/File".text = str(line_data.get("File", ""))
			$"HBox/Con/Data/Data".text = str(line_data.get("Data", ""))

			#% Format + Method:
			_apply_option_value($"HBox/Con/Format", line_data, "Format")
			_apply_option_value($"HBox/Con/Method", line_data, "Method")

			#% Toggle Visibility:
			$"HBox/Con".visible = true
			$"HBox/Con/Path".visible = true
			$"HBox/Con/File".visible = true
			$"HBox/Con/Format".visible = true
			$"HBox/Con/Method".visible = true
			$"HBox/Con/Data".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Import":
			$"HBox/Move".text = "Import"
			$"HBox/Move".tooltip_text += "Import variables from a file."
			$"HBox/Con/Format".tooltip_text = "Format of the file to import from."

			#% Get data:
			$"HBox/Con/Path".text = str(line_data.get("Path", ""))
			$"HBox/Con/File".text = str(line_data.get("File", ""))
			$"HBox/Con/Dictionary".text = str(line_data.get("Dictionary", ""))

			#% Format:
			_apply_option_value($"HBox/Con/Format", line_data, "Format")

			#% Toggle Visibility:
			$"HBox/Con".visible = true
			$"HBox/Con/Path".visible = true
			$"HBox/Con/File".visible = true
			$"HBox/Con/Format".visible = true
			$"HBox/Con/Dictionary".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Custom":
			$"HBox/Move".text = "Custom"
			$"HBox/Move".tooltip_text += "Run a custom command."

			#% Get data:
			$"HBox/Con/Command".text = str(line_data.get("Command", ""))
			$"HBox/Con/Data/Data".text = str(line_data.get("Data", ""))

			#% Toggle Visibility:
			$"HBox/Con".visible = true
			$"HBox/Con/Command".visible = true
			$"HBox/Con/Data".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]
		#endregion

		#& Condition Commands:
		#region
		"§If":
			$"HBox/Move".text = "If"
			$"HBox/Move".tooltip_text += "If condition check."

			#% Get data:
			$"HBox/Con/Condition/Text".text = str(line_data.get("Condition", ""))
			_apply_option_value($"HBox/Con/Type", line_data, "Type")

			#%Set
			$"HBox/Con/SetVariable".text = str(line_data.get("Variable", ""))
			$"HBox/Con/Flag/Flag".text = str(line_data.get("Flag", ""))
			$"HBox/Con/Operator/Operator".text = str(line_data.get("Operator", ""))
			$"HBox/Con/Expression/Text".text = str(line_data.get("Expression", ""))

			#% Call
			$"HBox/Con/Function".text = str(line_data.get("Function", ""))
			$"HBox/Con/Signal".text = str(line_data.get("Signal", ""))
			$"HBox/Con/Arguments".text = str(line_data.get("Arguments", ""))
			if line_data["Await"] == true:
				$"HBox/Con/Await".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]   #/ green
			elif line_data["Await"] == false:
				$"HBox/Con/Await".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]   #/ red

			#% Transition:
			_apply_option_value($"HBox/Con/Transition", line_data, "Transition")
			$"HBox/Con/Conversation/LineEdit".text = str(line_data.get("Conversation", ""))
			$"HBox/Con/Block/LineEdit".text = str(line_data.get("Block", ""))
			$"HBox/Con/Line/LineEdit".text = str(line_data.get("Line", ""))

			#% Toggle Visibility:
			$"HBox/Con".visible = true
			$"HBox/Con/Condition".visible = true
			$"HBox/Con/Type".visible = true
			match_condition_type(line_data["Type"])

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Elif":
			$"HBox/Move".text = "Elif"
			$"HBox/Move".tooltip_text += "Elif condition check."

			#% Get data:
			$"HBox/Con/Condition/Text".text = str(line_data.get("Condition", ""))
			_apply_option_value($"HBox/Con/Type", line_data, "Type")

			#%Set
			$"HBox/Con/SetVariable".text = str(line_data.get("Variable", ""))
			$"HBox/Con/Flag/Flag".text = str(line_data.get("Flag", ""))
			$"HBox/Con/Operator/Operator".text = str(line_data.get("Operator", ""))
			$"HBox/Con/Expression/Text".text = str(line_data.get("Expression", ""))

			#% Call
			$"HBox/Con/Function".text = str(line_data.get("Function", ""))
			$"HBox/Con/Signal".text = str(line_data.get("Signal", ""))
			$"HBox/Con/Arguments".text = str(line_data.get("Arguments", ""))
			if line_data["Await"] == true:
				$"HBox/Con/Await".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]   #/ green
			elif line_data["Await"] == false:
				$"HBox/Con/Await".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]   #/ red

			#% Transition:
			_apply_option_value($"HBox/Con/Transition", line_data, "Transition")
			$"HBox/Con/Conversation/LineEdit".text = str(line_data.get("Conversation", ""))
			$"HBox/Con/Block/LineEdit".text = str(line_data.get("Block", ""))
			$"HBox/Con/Line/LineEdit".text = str(line_data.get("Line", ""))

			#% Toggle Visibility:
			$"HBox/Con".visible = true
			$"HBox/Con/Condition".visible = true
			$"HBox/Con/Type".visible = true
			match_condition_type(line_data["Type"])

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Else":
			$"HBox/Move".text = "Else"
			$"HBox/Move".tooltip_text += "Else condition check."

			#% Get data:
			_apply_option_value($"HBox/Con/Type", line_data, "Type")

			#%Set
			$"HBox/Con/SetVariable".text = str(line_data.get("Variable", ""))
			$"HBox/Con/Flag/Flag".text = str(line_data.get("Flag", ""))
			$"HBox/Con/Operator/Operator".text = str(line_data.get("Operator", ""))
			$"HBox/Con/Expression/Text".text = str(line_data.get("Expression", ""))

			#% Call
			$"HBox/Con/Function".text = str(line_data.get("Function", ""))
			$"HBox/Con/Signal".text = str(line_data.get("Signal", ""))
			$"HBox/Con/Arguments".text = str(line_data.get("Arguments", ""))
			if line_data["Await"] == true:
				$"HBox/Con/Await".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]   #/ green
			elif line_data["Await"] == false:
				$"HBox/Con/Await".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]   #/ red

			#% Transition:
			_apply_option_value($"HBox/Con/Transition", line_data, "Transition")
			$"HBox/Con/Conversation/LineEdit".text = str(line_data.get("Conversation", ""))
			$"HBox/Con/Block/LineEdit".text = str(line_data.get("Block", ""))
			$"HBox/Con/Line/LineEdit".text = str(line_data.get("Line", ""))

			#% Toggle Visibility:
			$"HBox/Con".visible = true
			$"HBox/Con/Type".visible = true
			match_condition_type(line_data["Type"])

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§For":
			$"HBox/Move".text = "For"
			$"HBox/Move".tooltip_text += "For loop."

			#% Get data:
			$"HBox/Con/Condition/Text".text = str(line_data.get("Condition", ""))
			_apply_option_value($"HBox/Con/Type", line_data, "Type")

			#%Set
			$"HBox/Con/SetVariable".text = str(line_data.get("Variable", ""))
			$"HBox/Con/Flag/Flag".text = str(line_data.get("Flag", ""))
			$"HBox/Con/Operator/Operator".text = str(line_data.get("Operator", ""))
			$"HBox/Con/Expression/Text".text = str(line_data.get("Expression", ""))

			#% Call
			$"HBox/Con/Function".text = str(line_data.get("Function", ""))
			$"HBox/Con/Signal".text = str(line_data.get("Signal", ""))
			$"HBox/Con/Arguments".text = str(line_data.get("Arguments", ""))
			if line_data["Await"] == true:
				$"HBox/Con/Await".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]   #/ green
			elif line_data["Await"] == false:
				$"HBox/Con/Await".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]   #/ red

			#% Transition:
			_apply_option_value($"HBox/Con/Transition", line_data, "Transition")
			$"HBox/Con/Conversation/LineEdit".text = str(line_data.get("Conversation", ""))
			$"HBox/Con/Block/LineEdit".text = str(line_data.get("Block", ""))
			$"HBox/Con/Line/LineEdit".text = str(line_data.get("Line", ""))

			#% Toggle Visibility:
			$"HBox/Con".visible = true
			$"HBox/Con/Condition".visible = true
			$"HBox/Con/Type".visible = true
			match_condition_type(line_data["Type"])

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§While":
			$"HBox/Move".text = "While"
			$"HBox/Move".tooltip_text += "While loop."

			#% Get data:
			$"HBox/Con/Condition/Text".text = str(line_data.get("Condition", ""))
			_apply_option_value($"HBox/Con/Type", line_data, "Type")

			#%Set
			$"HBox/Con/SetVariable".text = str(line_data.get("Variable", ""))
			$"HBox/Con/Flag/Flag".text = str(line_data.get("Flag", ""))
			$"HBox/Con/Operator/Operator".text = str(line_data.get("Operator", ""))
			$"HBox/Con/Expression/Text".text = str(line_data.get("Expression", ""))

			#% Call
			$"HBox/Con/Function".text = str(line_data.get("Function", ""))
			$"HBox/Con/Signal".text = str(line_data.get("Signal", ""))
			$"HBox/Con/Arguments".text = str(line_data.get("Arguments", ""))
			if line_data["Await"] == true:
				$"HBox/Con/Await".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]   #/ green
			elif line_data["Await"] == false:
				$"HBox/Con/Await".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]   #/ red

			#% Transition:
			_apply_option_value($"HBox/Con/Transition", line_data, "Transition")
			$"HBox/Con/Conversation/LineEdit".text = str(line_data.get("Conversation", ""))
			$"HBox/Con/Block/LineEdit".text = str(line_data.get("Block", ""))
			$"HBox/Con/Line/LineEdit".text = str(line_data.get("Line", ""))

			#% Toggle Visibility:
			$"HBox/Con".visible = true
			$"HBox/Con/Condition".visible = true
			$"HBox/Con/Type".visible = true
			match_condition_type(line_data["Type"])

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]
		#endregion

		#& Transition Commands:
		#region
		"§Jump":
			$"HBox/Move".text = "Jump"
			$"HBox/Move".tooltip_text += "Transition to the specified conversation/block/line permanently."

			#% Get data:
			$"HBox/Con/Conversation/LineEdit".text = str(line_data.get("Conversation", ""))
			$"HBox/Con/Block/LineEdit".text = str(line_data.get("Block", ""))
			$"HBox/Con/Line/LineEdit".text = str(line_data.get("Line", ""))

			#% Toggle Visibility:
			$"HBox/Con".visible = true
			$"HBox/Con/Conversation".visible = true
			$"HBox/Con/Block".visible = true
			$"HBox/Con/Line".visible = true
			$"HBox/Con/Go".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Bridge":
			$"HBox/Move".text = "Bridge"
			$"HBox/Move".tooltip_text += "Transition to the specified conversation/block/line, and return later."

			#% Basic fields
			$"HBox/Con/Conversation/LineEdit".text = str(line_data.get("Conversation", ""))
			$"HBox/Con/Block/LineEdit".text = str(line_data.get("Block", ""))
			$"HBox/Con/Line/LineEdit".text = str(line_data.get("Line", ""))

			#% Toggle Visibility:
			$"HBox/Con".visible = true
			$"HBox/Con/Conversation".visible = true
			$"HBox/Con/Block".visible = true
			$"HBox/Con/Line".visible = true
			$"HBox/Con/Go".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§LM":
			$"HBox/Move".text = "Line Mark"
			$"HBox/Move".tooltip_text += "Place a line mark, which can be transitioned to."

			#% Get data:
			$"HBox/LM/Reference".text = str(line_data.get("Reference", ""))

			#% Toggle Visibility:
			$"HBox/LM".visible = true
			$"HBox/LM/Reference".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Return":
			$"HBox/Move".text = "Return"
			$"HBox/Move".tooltip_text += "Exit the block early and return to the previous block.\nRequires having entered the current block with §Bridge."

			#% Toggle Visibility:
			$"HBox/EndTexture".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§End":
			$"HBox/Move".text = "End"
			$"HBox/Move".tooltip_text += "End dialogue immediately."

			#% Toggle Visibility:
			$"HBox/EndTexture".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]
		#endregion

		#& Input Commands:
		#region
		"§Input":
			$"HBox/Move".text = "Input"
			$"HBox/Move".tooltip_text += "Display a player input UI."

			#% Get data:
			$"HBox/Input/File/FileField".text = str(line_data.get("File", ""))
			$"HBox/Input/Variable".text = str(line_data.get("Variable", ""))
			$"HBox/Input/Mode".text = str(line_data.get("Mode", ""))
			$"HBox/Input/Placeholder".text = str(line_data.get("Placeholder", ""))
			$"HBox/Input/Instructions".text = str(line_data.get("Instructions", ""))
			$"HBox/Input/Text".text = str(line_data.get("Text", ""))

			#% Toggle Visibility:
			$"HBox/Input".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Mouse":
			$"HBox/Move".text = "Mouse"
			$"HBox/Move".tooltip_text += "Change the mouse mode."

			#% Operator
			_apply_option_value($"HBox/Mouse/MouseMode", line_data, "Mouse Mode")

			#% Toggle Visibility:
			$"HBox/Mouse".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]
		#endregion

		#& Choice Commands:
		#region
		"§Choice_List":
			$"HBox/Move".text = "Choice List"
			$"HBox/Move".tooltip_text += "Display a choice list."

			#% Get data:
			$"HBox/Choices/Reference".text = str(line_data.get("Reference", ""))

			#% Toggle Visibility:
			$"HBox/Choices".visible = true
			$"HBox/Choices/Config".visible = true
			$"HBox/Choices/Reference".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Choice_Status":
			$"HBox/Move".text = "Choice Status"
			$"HBox/Move".tooltip_text += "Modify a choice."

			#% Get data:
			$"HBox/Choices/Label".text = str(line_data.get("Label", ""))
			$"HBox/Choices/Tooltip".text = str(line_data.get("Tooltip", ""))

			#% Drop-Downs:
			_apply_option_value($"HBox/Choices/MenuMode", line_data, "Menu Mode")
			_apply_option_value($"HBox/Choices/CategoryMode", line_data, "Category Mode")
			_apply_option_value($"HBox/Choices/ChoiceMode", line_data, "Choice Mode")
			_apply_option_value($"HBox/Choices/Enable", line_data, "Enable")
			_apply_option_value($"HBox/Choices/Activate", line_data, "Activate")
			_apply_option_value($"HBox/Choices/Show", line_data, "Show")

			#% Toggle Visibility:
			$"HBox/Choices".visible = true
			$"HBox/Choices/Config".visible = true
			$"HBox/Choices/MenuMode".visible = true
			$"HBox/Choices/CategoryMode".visible = true
			$"HBox/Choices/ChoiceMode".visible = true
			$"HBox/Choices/Enable".visible = true
			$"HBox/Choices/Activate".visible = true
			$"HBox/Choices/Show".visible = true
			$"HBox/Choices/Label".visible = true
			$"HBox/Choices/Tooltip".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Timer_Status":
			$"HBox/Move".text = "Timer Status"
			$"HBox/Move".tooltip_text += "Modify a choice list timer."

			#% Get data:
			$"HBox/Choices/Time".text = str(line_data.get("Time", ""))
			$"HBox/Choices/Loop".text = str(line_data.get("Loop", ""))

			#% Drop-Downs:
			_apply_option_value($"HBox/Choices/MenuMode", line_data, "Menu Mode")
			_apply_option_value($"HBox/Choices/TimerMode", line_data, "Timer Mode")
			_apply_option_value($"HBox/Choices/TimerNode", line_data, "Timer Node")
			_apply_option_value($"HBox/Choices/TimerStatus", line_data, "Status")

			#% Toggle Visibility:
			$"HBox/Choices".visible = true
			$"HBox/Choices/Config".visible = true
			$"HBox/Choices/MenuMode".visible = true
			$"HBox/Choices/TimerMode".visible = true
			$"HBox/Choices/Time".visible = true
			$"HBox/Choices/Loop".visible = true
			$"HBox/Choices/TimerNode".visible = true
			$"HBox/Choices/TimerStatus".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		#endregion

		#& BG Commands:
		#region
		"§BG_Scene":
			$"HBox/Move".text = "BG Scene"
			$"HBox/Move".tooltip_text += "Change the loaded BG scene."
			$"HBox/VN/Scene".tooltip_text = "Background scene to load."

			#% Get data:
			$"HBox/VN/Scene/Scene".text = str(line_data.get("Scene", ""))

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Scene".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§BG":
			$"HBox/Move".text = "Background"
			$"HBox/Move".tooltip_text += "Assign an image or animation to a background layer."
			$"HBox/VN/Layers/Layer".tooltip_text = "Layer to assign a file to."
			$"HBox/VN/File/FileName".tooltip_text = "File to assign to the background layer."

			#% Get data:
			$"HBox/VN/Layers/Layer".text = str(line_data.get("Layers", ""))
			$"HBox/VN/File/FileName".text = str(line_data.get("File", ""))
			$"HBox/VN/Animation".text = str(line_data.get("Animation", ""))
			$"HBox/VN/Loop/Loop".text = str(line_data.get("Loop", ""))
			$"HBox/VN/Wait/Wait".text = str(line_data.get("Wait", ""))
			$"HBox/VN/Time/Time".text = str(line_data.get("Time", ""))

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Layers".visible = true
			$"HBox/VN/File".visible = true
			$"HBox/VN/Animation".visible = true
			$"HBox/VN/Loop".visible = true
			$"HBox/VN/Wait".visible = true
			$"HBox/VN/Time".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§BG_Stop":
			$"HBox/Move".text = "BG Stop"
			$"HBox/Move".tooltip_text += "Stop animations on the specified background layers."
			$"HBox/VN/Layers/Layer".tooltip_text = "Layers to stop animations for."

			#% Get data:
			$"HBox/VN/Layers/Layer".text = str(line_data.get("Layers", ""))

			if line_data["Default"] == 1:
				$"HBox/VN/Default".text = "Reset"
			elif line_data["Default"] == 0:
				$"HBox/VN/Default".text = "Freeze"

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Layers".visible = true
			$"HBox/VN/Default".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§BG_Wait":
			$"HBox/Move".text = "BG Wait"
			$"HBox/Move".tooltip_text += "Pause dialogue until all background animations have finished."
			$"HBox/VN/Layers/Layer".tooltip_text = "Layers to wait on."

			#% Get data:
			$"HBox/VN/Layers/Layer".text = str(line_data.get("Layers", ""))
			$"HBox/VN/Wait/Wait".text = str(line_data.get("Wait", ""))
			$"HBox/VN/Time/Time".text = str(line_data.get("Time", ""))

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Layers".visible = true
			$"HBox/VN/Wait".visible = true
			$"HBox/VN/Time".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§BG_Remove":
			$"HBox/Move".text = "BG Remove"
			$"HBox/Move".tooltip_text += "Remove images and animations from the specified background layers."
			$"HBox/VN/Layers/Layer".tooltip_text = "Layers to remove files from."

			#% Get data:
			$"HBox/VN/Layers/Layer".text = str(line_data.get("Layers", ""))

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Layers".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§BG_Mirror":
			$"HBox/Move".text = "BG Mirror"
			$"HBox/Move".tooltip_text += "Flip a layer image."
			$"HBox/VN/Layers/Layer".tooltip_text = "Layers to mirror."

			#% Get data:
			$"HBox/VN/Layers/Layer".text = str(line_data.get("Layers", ""))

			#% Transition:
			_apply_option_value($"HBox/VN/Axis", line_data, "Axis")

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Layers".visible = true
			$"HBox/VN/Axis".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§BG_Effect":
			$"HBox/Move".text = "BG Effect"
			$"HBox/Move".tooltip_text += "Play effect animations on the specified background layers."
			$"HBox/VN/Layers/Layer".tooltip_text = "Layers to play effects on."

			#% Get data:
			$"HBox/VN/Layers/Layer".text = str(line_data.get("Layers", ""))
			$"HBox/VN/Libraries/Library".text = str(line_data.get("Library", ""))
			$"HBox/VN/Effects/Effects".text = str(line_data.get("Effects", ""))
			$"HBox/VN/Loop/Loop".text = str(line_data.get("Loop", ""))
			$"HBox/VN/Wait/Wait".text = str(line_data.get("Wait", ""))
			$"HBox/VN/Time/Time".text = str(line_data.get("Time", ""))

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Layers".visible = true
			$"HBox/VN/Libraries".visible = true
			$"HBox/VN/Effects".visible = true
			$"HBox/VN/Loop".visible = true
			$"HBox/VN/Wait".visible = true
			$"HBox/VN/Time".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§BG_Effect_Stop":
			$"HBox/Move".text = "BG Effect Stop"
			$"HBox/Move".tooltip_text += "Stop effect animations on the specified background layers."
			$"HBox/VN/Layers/Layer".tooltip_text = "Layers to stop effects for."

			#% Get data:
			$"HBox/VN/Layers/Layer".text = str(line_data.get("Layers", ""))
			$"HBox/VN/Effects/Effects".text = str(line_data.get("Effects", ""))

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Layers".visible = true
			$"HBox/VN/Effects".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§BG_Effect_Wait":
			$"HBox/Move".text = "BG Effect Wait"
			$"HBox/Move".tooltip_text += "Pause dialogue during BG effects."
			$"HBox/VN/Layers/Layer".tooltip_text = "Layers to wait on."

			#% Get data:
			$"HBox/VN/Layers/Layer".text = str(line_data.get("Layers", ""))
			$"HBox/VN/Effects/Effects".text = str(line_data.get("Effects", ""))
			$"HBox/VN/Wait/Wait".text = str(line_data.get("Wait", ""))
			$"HBox/VN/Time/Time".text = str(line_data.get("Time", ""))

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Layers".visible = true
			$"HBox/VN/Effects".visible = true
			$"HBox/VN/Wait".visible = true
			$"HBox/VN/Time".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]
		#endregion

		#& Effect Commands:
		#region
		"§Effect":
			$"HBox/Move".text = "Effect"
			$"HBox/Move".tooltip_text += "Play an effect animation anywhere in the UI."

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))
			$"HBox/Media/Animation/Animation".text = str(line_data.get("Animation", ""))
			$"HBox/Media/Loop/Loop".text = str(line_data.get("Loop", ""))
			$"HBox/Media/Wait/Wait".text = str(line_data.get("Wait", ""))
			$"HBox/Media/Time/Time".text = str(line_data.get("Time", ""))

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Animation".visible = true
			$"HBox/Media/Loop".visible = true
			$"HBox/Media/Wait".visible = true
			$"HBox/Media/Time".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Effect_Stop":
			$"HBox/Move".text = "Effect Stop"
			$"HBox/Move".tooltip_text += "Stop playing effects in the UI."

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Effect_Wait":
			$"HBox/Move".text = "Effect Wait"
			$"HBox/Move".tooltip_text += "Pause dialogue during effects."

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))
			$"HBox/Media/Wait/Wait".text = str(line_data.get("Wait", ""))
			$"HBox/Media/Time/Time".text = str(line_data.get("Time", ""))

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Wait".visible = true
			$"HBox/Media/Time".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Wait":
			$"HBox/Move".text = "Wait"
			$"HBox/Move".tooltip_text += "Pause dialogue processing for a set amount of time."

			#% Get data:
			$"HBox/Media/Time/Time".text = str(line_data.get("Time", ""))

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Time".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Hide":
			$"HBox/Move".text = "Hide"
			$"HBox/Move".tooltip_text += "Show or Hide UI elements over/under video or image players."

			if line_data["Box"] == "0":
				$"HBox/Clear/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]	#/ white
			elif line_data["Box"] == "1":
				$"HBox/Clear/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red

			if line_data["Portraits"] == "0":
				$"HBox/Clear/Portraits".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]	#/ white
			elif line_data["Portraits"] == "1":
				$"HBox/Clear/Portraits".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red

			#% Toggle Visibility:
			$"HBox/Clear".visible = true
			$"HBox/Clear/Box".visible = true
			$"HBox/Clear/Portraits".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§Clear":
			$"HBox/Move".text = "Clear"
			$"HBox/Move".tooltip_text += "Clear UI elements."

			#% Get data:
			if line_data["Box"] == "0":
				$"HBox/Clear/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]	#/ white
			elif line_data["Box"] == "1":
				$"HBox/Clear/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red

			if line_data["Bubbles"] == "0":
				$"HBox/Clear/Bubbles".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]	#/ white
			elif line_data["Bubbles"] == "1":
				$"HBox/Clear/Bubbles".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red

			if line_data["Subtitles"] == "0":
				$"HBox/Clear/Subtitles".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]	#/ white
			elif line_data["Subtitles"] == "1":
				$"HBox/Clear/Subtitles".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red

			if line_data["Portraits"] == "0":
				$"HBox/Clear/Portraits".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]	#/ white
			elif line_data["Portraits"] == "1":
				$"HBox/Clear/Portraits".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red

			if line_data["Busts"] == "0":
				$"HBox/Clear/Busts".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]	#/ white
			elif line_data["Busts"] == "1":
				$"HBox/Clear/Busts".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red

			if line_data["Backgrounds"] == "0":
				$"HBox/Clear/Backgrounds".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]	#/ white
			elif line_data["Backgrounds"] == "1":
				$"HBox/Clear/Backgrounds".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red

			#% Toggle Visibility:
			$"HBox/Clear".visible = true
			$"HBox/Clear/Box".visible = true
			$"HBox/Clear/Bubbles".visible = true
			$"HBox/Clear/Subtitles".visible = true
			$"HBox/Clear/Portraits".visible = true
			$"HBox/Clear/Busts".visible = true
			$"HBox/Clear/Backgrounds".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]
		#endregion

		#& Image Commands:
		#region
		"§Image":
			$"HBox/Move".text = "Image"

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))
			$"HBox/Media/Media/FileName".text = str(line_data.get("File", ""))
			$"HBox/Media/Duration/Duration".text = str(line_data.get("Duration", ""))
			$"HBox/Media/Time/Time".text = str(line_data.get("Time", ""))
			$"HBox/Media/Loop/Loop".text = str(line_data.get("Loop", ""))
			$"HBox/Media/Wait/Wait".text = str(line_data.get("Wait", ""))

			if line_data["Animated"] == 0:
				$"HBox/Media/Animated".text = "Static"
			elif line_data["Animated"] == 1:
				$"HBox/Media/Animated".text = "Animated"

			if line_data["Box"] == 0:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]		#/ white
			elif line_data["Box"] == 1:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]			#/ green
			elif line_data["Box"] == -1:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]		#/ red

			if line_data["Portrait"] == 0:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]	#/ white
			elif line_data["Portrait"] == 1:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]	#/ green
			elif line_data["Portrait"] == -1:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true
			$"HBox/Media/Media".visible = true
			$"HBox/Media/Animated".visible = true
			$"HBox/Media/Duration".visible = true
			$"HBox/Media/Time".visible = true
			$"HBox/Media/Wait".visible = true
			$"HBox/Media/Loop".visible = true
			$"HBox/Media/Box".visible = true
			$"HBox/Media/Portrait".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§I_Wait":
			$"HBox/Move".text = "Image Wait"

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))
			$"HBox/Media/Time/Time".text = str(line_data.get("Time", ""))
			$"HBox/Media/Wait/Wait".text = str(line_data.get("Wait", ""))

			if line_data["Box"] == 0:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]   #/ white
			elif line_data["Box"] == 1:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]   #/ green
			elif line_data["Box"] == -1:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]   #/ red

			if line_data["Portrait"] == 0:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]   #/ white
			elif line_data["Portrait"] == 1:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]   #/ green
			elif line_data["Portrait"] == -1:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]   #/ red

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true
			$"HBox/Media/Time".visible = true
			$"HBox/Media/Wait".visible = true
			$"HBox/Media/Box".visible = true
			$"HBox/Media/Portrait".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§I_Pause":
			$"HBox/Move".text = "Image Pause"

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))
			$"HBox/Media/Lines/Lines".text = str(line_data.get("Lines", ""))
			$"HBox/Media/Wait/Wait".text = str(line_data.get("Wait", ""))

			if line_data["All"] == 0:
				$"HBox/Media/AllLines".text = "Spoken"
			elif line_data["All"] == 1:
				$"HBox/Media/AllLines".text = "All"

			if line_data["Box"] == 0:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]		#/ white
			elif line_data["Box"] == 1:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]			#/ green
			elif line_data["Box"] == -1:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]		#/ red

			if line_data["Portrait"] == 0:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]	#/ white
			elif line_data["Portrait"] == 1:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]	#/ green
			elif line_data["Portrait"] == -1:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true
			$"HBox/Media/Lines".visible = true
			$"HBox/Media/AllLines".visible = true
			$"HBox/Media/Box".visible = true
			$"HBox/Media/Portrait".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§I_Resume":
			$"HBox/Move".text = "Image Resume"

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§I_Show":
			$"HBox/Move".text = "Image Show"

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))

			if line_data["Box"] == 0:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]   #/ white
			elif line_data["Box"] == 1:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]   #/ green
			elif line_data["Box"] == -1:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]   #/ red

			if line_data["Portrait"] == 0:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]   #/ white
			elif line_data["Portrait"] == 1:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]   #/ green
			elif line_data["Portrait"] == -1:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]   #/ red

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true
			$"HBox/Media/Box".visible = true
			$"HBox/Media/Portrait".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§I_Stop":
			$"HBox/Move".text = "Image Stop"

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]
		#endregion

		#& Video Commands:
		#region
		"§Video":
			$"HBox/Move".text = "Video"

			#% Modify tooltip:
			$"HBox/Media/Time/Time".tooltip_text = "How long to wait before resuming dialogue."

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))
			$"HBox/Media/Media/FileName".text = str(line_data.get("File", ""))
			$"HBox/Media/Loop/Loop".text = str(line_data.get("Loop", ""))
			$"HBox/Media/Time/Time".text = str(line_data.get("Time", ""))
			$"HBox/Media/Wait/Wait".text = str(line_data.get("Wait", ""))

			if line_data["Box"] == 0:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]		#/ white
			elif line_data["Box"] == 1:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]			#/ green
			elif line_data["Box"] == -1:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]		#/ red

			if line_data["Portrait"] == 0:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]	#/ white
			elif line_data["Portrait"] == 1:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]	#/ green
			elif line_data["Portrait"] == -1:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true
			$"HBox/Media/Media".visible = true
			$"HBox/Media/Time".visible = true
			$"HBox/Media/Wait".visible = true
			$"HBox/Media/Loop".visible = true
			$"HBox/Media/Box".visible = true
			$"HBox/Media/Portrait".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§V_Volume":
			$"HBox/Move".text = "Video Volume"

			#% Modify tooltip:
			$"HBox/Media/Time/Time".tooltip_text = "Change volume progressively over a set period of time, in seconds.\nPrefix with '!' (exclamation mark) if dialogue should pause while volume changes."

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))
			$"HBox/Media/Volume/Volume".text = str(line_data.get("Volume", ""))
			$"HBox/Media/Time/Time".text = str(line_data.get("Time", ""))

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true
			$"HBox/Media/Volume".visible = true
			$"HBox/Media/Time".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§V_Pause":
			$"HBox/Move".text = "Video Pause"

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))
			$"HBox/Media/Lines/Lines".text = str(line_data.get("Lines", ""))

			if line_data["All"] == 0:
				$"HBox/Media/AllLines".text = "Spoken"
			elif line_data["All"] == 1:
				$"HBox/Media/AllLines".text = "All"

			if line_data["Box"] == 0:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]	#/ white
			elif line_data["Box"] == 1:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]		#/ green
			elif line_data["Box"] == -1:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red

			if line_data["Portrait"] == 0:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]	#/ white
			elif line_data["Portrait"] == 1:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]	#/ green
			elif line_data["Portrait"] == -1:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true
			$"HBox/Media/Lines".visible = true
			$"HBox/Media/AllLines".visible = true
			$"HBox/Media/Box".visible = true
			$"HBox/Media/Portrait".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§V_Wait":
			$"HBox/Move".text = "Video Wait"

			#% Modify tooltip:
			$"HBox/Media/Time/Time".tooltip_text = "How long to wait before resuming dialogue."

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))
			$"HBox/Media/Time/Time".text = str(line_data.get("Time", ""))
			$"HBox/Media/Wait/Wait".text = str(line_data.get("Wait", ""))

			if line_data["Box"] == 0:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]   #/ white
			elif line_data["Box"] == 1:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]   #/ green
			elif line_data["Box"] == -1:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]   #/ red

			if line_data["Portrait"] == 0:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]   #/ white
			elif line_data["Portrait"] == 1:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]   #/ green
			elif line_data["Portrait"] == -1:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]   #/ red

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true
			$"HBox/Media/Time".visible = true
			$"HBox/Media/Wait".visible = true
			$"HBox/Media/Box".visible = true
			$"HBox/Media/Portrait".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§V_Resume":
			$"HBox/Move".text = "Video Resume"

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§V_Show":
			$"HBox/Move".text = "Video Show"

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))

			if line_data["Box"] == 0:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]   #/ white
			elif line_data["Box"] == 1:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]   #/ green
			elif line_data["Box"] == -1:
				$"HBox/Media/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]   #/ red

			if line_data["Portrait"] == 0:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]   #/ white
			elif line_data["Portrait"] == 1:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]   #/ green
			elif line_data["Portrait"] == -1:
				$"HBox/Media/Portrait".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]   #/ red

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true
			$"HBox/Media/Box".visible = true
			$"HBox/Media/Portrait".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§V_Skip":
			$"HBox/Move".text = "Video Skip"

			#% Modify tooltip:
			$"HBox/Media/Time/Time".tooltip_text = "The timestamp, in HH:MM:SS.00 format, to skip at/to.\nUse f=n to skip to a specific frame, where 'n' is the frame number."

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))
			$"HBox/Media/Time/Time".text = str(line_data.get("Time", ""))

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true
			$"HBox/Media/Time".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§V_Stop":
			$"HBox/Move".text = "Video Stop"

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]
		#endregion

		#& Audio Commands:
		#region
		"§Audio":
			$"HBox/Move".text = "Audio"

			#% Modify tooltip:
			$"HBox/Media/Time/Time".tooltip_text = "How long to wait before resuming dialogue."

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))
			$"HBox/Media/Media/FileName".text = str(line_data.get("File", ""))
			$"HBox/Media/Loop/Loop".text = str(line_data.get("Loop", ""))
			$"HBox/Media/Time/Time".text = str(line_data.get("Time", ""))
			$"HBox/Media/Wait/Wait".text = str(line_data.get("Wait", ""))

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true
			$"HBox/Media/Media".visible = true
			$"HBox/Media/Time".visible = true
			$"HBox/Media/Loop".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§A_Volume":
			$"HBox/Move".text = "Audio Volume"

			#% Modify tooltip:
			$"HBox/Media/Time/Time".tooltip_text = "Change volume progressively over a set period of time, in seconds.\nPrefix with '!' (exclamation mark) if dialogue should pause while volume changes."

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))
			$"HBox/Media/Volume/Volume".text = str(line_data.get("Volume", ""))
			$"HBox/Media/Time/Time".text = str(line_data.get("Time", ""))

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true
			$"HBox/Media/Volume".visible = true
			$"HBox/Media/Time".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§A_Pause":
			$"HBox/Move".text = "Audio Pause"

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))
			$"HBox/Media/Lines/Lines".text = str(line_data.get("Lines", ""))
			$"HBox/Media/Wait/Wait".text = str(line_data.get("Wait", ""))

			if line_data["All"] == 0:
				$"HBox/Media/AllLines".text = "Spoken"
			elif line_data["All"] == 1:
				$"HBox/Media/AllLines".text = "All"

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true
			$"HBox/Media/Lines".visible = true
			$"HBox/Media/AllLines".visible = true
			$"HBox/Media/Wait".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§A_Wait":
			$"HBox/Move".text = "Audio Wait"

			#% Modify tooltip:
			$"HBox/Media/Time/Time".tooltip_text = "How long to wait before resuming dialogue."

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))
			$"HBox/Media/Time/Time".text = str(line_data.get("Time", ""))
			$"HBox/Media/Wait/Wait".text = str(line_data.get("Wait", ""))

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true
			$"HBox/Media/Time".visible = true
			$"HBox/Media/Wait".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§A_Resume":
			$"HBox/Move".text = "Audio Resume"

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§A_Skip":
			$"HBox/Move".text = "Audio Skip"

			#% Modify tooltip:
			$"HBox/Media/Time/Time".tooltip_text = "The timestamp in HH:MM:SS.00 format to jump to."

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))
			$"HBox/Media/Time/Time".text = str(line_data.get("Time", ""))

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true
			$"HBox/Media/Time".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§A_Stop":
			$"HBox/Move".text = "Audio Stop"

			#% Get data:
			$"HBox/Media/Node/NodeName".text = str(line_data.get("Node", ""))

			#% Toggle Visibility:
			$"HBox/Media".visible = true
			$"HBox/Media/Node".visible = true
			$"HBox/Media/Node/Button".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]
		#endregion

		#& VN Commands:
		#region
		"§VN_Scene":
			$"HBox/Move".text = "VN Scene"
			$"HBox/Move".tooltip_text += "Change the VN bust scene."
			$"HBox/VN/Scene".tooltip_text = "Bust scene to load."

			#% Get data:
			$"HBox/VN/Scene/Scene".text = str(line_data.get("Scene", ""))

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Scene".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§VN_Bust":
			$"HBox/Move".text = "VN Bust"
			$"HBox/Move".tooltip_text += "Assign an actor to a bust node or change an actor's bust image."
			$"HBox/VN/Busts/Bust".tooltip_text = "Bust node to assign the actor to.
				Can be left empty if the actor is already assigned to the bust node."
			$"HBox/VN/File/FileName".tooltip_text = "File to assign to the bust."

			#% Get data:
			$"HBox/VN/Busts/Bust".text = str(line_data.get("Bust", ""))
			$"HBox/VN/Reference/Ref".text = str(line_data.get("Reference", ""))
			$"HBox/VN/Animation".text = str(line_data.get("Animation", ""))
			$"HBox/VN/File/FileName".text = str(line_data.get("File", ""))
			$"HBox/VN/Loop/Loop".text = str(line_data.get("Loop", ""))
			$"HBox/VN/Time/Time".text = str(line_data.get("Time", ""))
			$"HBox/VN/Wait/Wait".text = str(line_data.get("Wait", ""))

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Busts".visible = true
			$"HBox/VN/Reference".visible = true
			$"HBox/VN/Animation".visible = true
			$"HBox/VN/File".visible = true
			$"HBox/VN/Loop".visible = true
			$"HBox/VN/Time".visible = true
			$"HBox/VN/Wait".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§VN_Bust_Stop":
			$"HBox/Move".text = "VN Bust Stop"
			$"HBox/Move".tooltip_text += "Stop bust animations."
			$"HBox/VN/Actors/Actors".tooltip_text = "Actor busts to stop animations for.
				Provide a Role or Actor Reference."

			#% Get data:
			$"HBox/VN/Actors/Actors".text = str(line_data.get("Actors", ""))

			if line_data["Default"] == 1:
				$"HBox/VN/Default".text = "Reset"
			elif line_data["Default"] == 0:
				$"HBox/VN/Default".text = "Freeze"

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Actors".visible = true
			$"HBox/VN/Default".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§VN_Bust_Wait":
			$"HBox/Move".text = "VN Bust Wait"
			$"HBox/Move".tooltip_text += "Pause dialogue while bust animations are playing."
			$"HBox/VN/Actors/Actors".tooltip_text = "Actor busts to wait on.
				Provide a Role or Actor Reference."

			$"HBox/VN/Actors/Actors".text = str(line_data.get("Actors", ""))
			$"HBox/VN/Time/Time".text = str(line_data.get("Time", ""))
			$"HBox/VN/Wait/Wait".text = str(line_data.get("Wait", ""))

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Actors".visible = true
			$"HBox/VN/Time".visible = true
			$"HBox/VN/Wait".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§VN_Move":
			$"HBox/Move".text = "VN Move"
			$"HBox/Move".tooltip_text += "Move an actor to another bust node, preserving flip and animation state."
			$"HBox/VN/Busts/Bust".tooltip_text = "Bust node to move the actor to."
			$"HBox/VN/Actors/Actors".tooltip_text = "Actor to move to another bust.
				Provide a Role or Actor Reference."

			#% Get data:
			$"HBox/VN/Busts/Bust".text = str(line_data.get("Bust", ""))
			$"HBox/VN/Reference/Ref".text = str(line_data.get("Reference", ""))

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Busts".visible = true
			$"HBox/VN/Reference".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§VN_Mirror":
			$"HBox/Move".text = "VN Mirror"
			$"HBox/Move".tooltip_text += "Flip a bust vertically or horizontally."
			$"HBox/VN/Actors/Actors".tooltip_text = "Actor busts to mirror.
				Provide a Role or Actor Reference."

			#% Get data:
			$"HBox/VN/Reference/Ref".text = str(line_data.get("Actors", ""))

			#% Transition:
			_apply_option_value($"HBox/VN/Axis", line_data, "Axis")

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Actors".visible = true
			$"HBox/VN/Axis".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§VN_Remove":
			$"HBox/Move".text = "VN Remove"
			$"HBox/Move".tooltip_text += "Remove actors from the VN scene."
			$"HBox/VN/Actors/Actors".tooltip_text = "Actors to remove from busts.
				Provide a Role or Actor Reference."

			#% Get data:
			$"HBox/VN/Actors/Actors".text = str(line_data.get("Actors", ""))

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Actors".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§VN_Effect":
			$"HBox/Move".text = "VN Effect"
			$"HBox/Move".tooltip_text += "Play an effect on a bust node."
			$"HBox/VN/Actors/Actors".tooltip_text = "Actor busts to play effects on.
				Provide a Role or Actor Reference."

			#% Get data:
			$"HBox/VN/Actors/Actors".text = str(line_data.get("Actors", ""))
			$"HBox/VN/Libraries/Library".text = str(line_data.get("Library", ""))
			$"HBox/VN/Effects/Effects".text = str(line_data.get("Effects", ""))
			$"HBox/VN/Loop/Loop".text = str(line_data.get("Loop", ""))
			$"HBox/VN/Time/Time".text = str(line_data.get("Time", ""))
			$"HBox/VN/Wait/Wait".text = str(line_data.get("Wait", ""))

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Actors".visible = true
			$"HBox/VN/Libraries".visible = true
			$"HBox/VN/Effects".visible = true
			$"HBox/VN/Loop".visible = true
			$"HBox/VN/Time".visible = true
			$"HBox/VN/Wait".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§VN_Effect_Stop":
			$"HBox/Move".text = "VN Effect Stop"
			$"HBox/Move".tooltip_text += "Stop a playing VN effect."
			$"HBox/VN/Actors/Actors".tooltip_text = "Actor busts to stop effects for.
				Provide a Role or Actor Reference."

			#% Get data:
			$"HBox/VN/Actors/Actors".text = str(line_data.get("Actors", ""))
			$"HBox/VN/Effects/Effects".text = str(line_data.get("Effects", ""))

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Actors".visible = true
			$"HBox/VN/Effects".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§VN_Effect_Wait":
			$"HBox/Move".text = "VN Effect Wait"
			$"HBox/Move".tooltip_text += "Pause dialogue during VN effects."
			$"HBox/VN/Actors/Actors".tooltip_text = "Actor busts to wait on.
				Provide a Role or Actor Reference."

			#% Get data:
			$"HBox/VN/Actors/Actors".text = str(line_data.get("Actors", ""))
			$"HBox/VN/Effects/Effects".text = str(line_data.get("Effects", ""))
			$"HBox/VN/Wait/Wait".text = str(line_data.get("Wait", ""))
			$"HBox/VN/Time/Time".text = str(line_data.get("Time", ""))

			#% Toggle Visibility:
			$"HBox/VN".visible = true
			$"HBox/VN/Actors".visible = true
			$"HBox/VN/Effects".visible = true
			$"HBox/VN/Wait".visible = true
			$"HBox/VN/Time".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]
		#endregion

		#& Cutscene Commands:
		#region
		"§CS_Scene":
			$"HBox/Move".text = "CS Scene"
			$"HBox/Move".tooltip_text += "Instantiate a node as a child of another."

			#% Get data:
			$"HBox/CS/Path1".text = str(line_data.get("Path 1", ""))
			$"HBox/CS/Targets".text = str(line_data.get("Targets", ""))
			$"HBox/CS/Scene".text = str(line_data.get("Scene", ""))

			#% Toggle Visibility:
			$"HBox/CS".visible = true
			$"HBox/CS/Path1".visible = true
			$"HBox/CS/Targets".visible = true
			$"HBox/CS/Scene".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§CS_Visible":
			$"HBox/Move".text = "CS Visible"
			$"HBox/Move".tooltip_text += "Change the visibility of a node."

			#% Get data:
			$"HBox/CS/Path1".text = str(line_data.get("Path 1", ""))
			$"HBox/CS/Targets".text = str(line_data.get("Targets", ""))

			#% Operator
			_apply_option_value($"HBox/CS/Visibility", line_data, "Visibility")

			#% Toggle Visibility:
			$"HBox/CS".visible = true
			$"HBox/CS/Path1".visible = true
			$"HBox/CS/Targets".visible = true
			$"HBox/CS/Visibility".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§CS_Loc":
			$"HBox/Move".text = "CS Location"
			$"HBox/Move".tooltip_text += "Make nodes copy the position and rotation of other nodes.\nUsed for easy positioning of nodes during dialogues."

			#% Get data:
			$"HBox/CS/Path1".text = str(line_data.get("Path 1", ""))
			$"HBox/CS/Targets".text = str(line_data.get("Targets", ""))
			$"HBox/CS/Path2".text = str(line_data.get("Path 2", ""))
			$"HBox/CS/Markers".text = str(line_data.get("Markers", ""))

			if line_data["Rotate"] == "0":
				$"HBox/CS/Rotate".text = "Rotate"
				$"HBox/CS/Rotate".modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]   #/ grey
			elif line_data["Rotate"] == "1":
				$"HBox/CS/Rotate".text = "Rotate"

			#% Toggle Visibility:
			$"HBox/CS".visible = true
			$"HBox/CS/Path1".visible = true
			$"HBox/CS/Targets".visible = true
			$"HBox/CS/Path2".visible = true
			$"HBox/CS/Markers".visible = true
			$"HBox/CS/Rotate".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§CS_Move":
			$"HBox/Move".text = "CS Move"
			$"HBox/Move".tooltip_text += "Set nodes in motion, using the custom logic of your project."

			#% Get data:
			$"HBox/CS/Path1".text = str(line_data.get("Path 1", ""))
			$"HBox/CS/Targets".text = str(line_data.get("Targets", ""))
			$"HBox/CS/Path2".text = str(line_data.get("Path 2", ""))
			$"HBox/CS/Markers".text = str(line_data.get("Markers", ""))
			$"HBox/CS/Animation".text = str(line_data.get("Animation", ""))
			$"HBox/CS/Method".text = str(line_data.get("Method", ""))
			$"HBox/CS/Properties".text = str(line_data.get("Properties", ""))
			$"HBox/CS/Loop/Loop".text = str(line_data.get("Loop", ""))
			$"HBox/CS/Time/Time".text = str(line_data.get("Time", ""))
			$"HBox/CS/Wait/Wait".text = str(line_data.get("Wait", ""))

			#% Toggle Visibility:
			$"HBox/CS".visible = true
			$"HBox/CS/Path1".visible = true
			$"HBox/CS/Targets".visible = true
			$"HBox/CS/Path2".visible = true
			$"HBox/CS/Markers".visible = true
			$"HBox/CS/Animation".visible = true
			$"HBox/CS/Method".visible = true
			$"HBox/CS/Properties".visible = true
			$"HBox/CS/Loop".visible = true
			$"HBox/CS/Time".visible = true
			$"HBox/CS/Wait".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§CS_Anim":
			$"HBox/Move".text = "CS Anim."
			$"HBox/Move".tooltip_text += "Play an animation on a node, such as animating characters."

			#% Get data:
			$"HBox/CS/Path1".text = str(line_data.get("Path 1", ""))
			$"HBox/CS/Targets".text = str(line_data.get("Targets", ""))
			$"HBox/CS/Path2".text = str(line_data.get("Path 2", ""))
			$"HBox/CS/Animation".text = str(line_data.get("Animation", ""))
			$"HBox/CS/Loop/Loop".text = str(line_data.get("Loop", ""))
			$"HBox/CS/Wait/Wait".text = str(line_data.get("Wait", ""))
			$"HBox/CS/Time/Time".text = str(line_data.get("Time", ""))

			if line_data["Play"] == "0":
				$"HBox/CS/Play".text = "Hold"
			elif line_data["Play"] == "1":
				$"HBox/CS/Play".text = "Play"

			#% Toggle Visibility:
			$"HBox/CS".visible = true
			$"HBox/CS/Path1".visible = true
			$"HBox/CS/Targets".visible = true
			$"HBox/CS/Path2".visible = true
			$"HBox/CS/Animation".visible = true
			$"HBox/CS/Loop".visible = true
			$"HBox/CS/Wait".visible = true
			$"HBox/CS/Time".visible = true
			$"HBox/CS/Play".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§CS_Anim_Wait":
			$"HBox/Move".text = "CS Anim. Wait"
			$"HBox/Move".tooltip_text += "Pause dialogue processing while node animations play."

			#% Get data:
			$"HBox/CS/Path1".text = str(line_data.get("Path 1", ""))
			$"HBox/CS/Targets".text = str(line_data.get("Targets", ""))
			$"HBox/CS/Path2".text = str(line_data.get("Path 2", ""))
			$"HBox/CS/Wait/Wait".text = str(line_data.get("Wait", ""))
			$"HBox/CS/Time/Time".text = str(line_data.get("Time", ""))

			#% Toggle Visibility:
			$"HBox/CS".visible = true
			$"HBox/CS/Path1".visible = true
			$"HBox/CS/Targets".visible = true
			$"HBox/CS/Path2".visible = true
			$"HBox/CS/Wait".visible = true
			$"HBox/CS/Time".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§CS_Anim_Stop":
			$"HBox/Move".text = "CS Anim. Stop"
			$"HBox/Move".tooltip_text += "Stop an animation one or more nodes."

			#% Get data:
			$"HBox/CS/Path1".text = str(line_data.get("Path 1", ""))
			$"HBox/CS/Targets".text = str(line_data.get("Targets", ""))
			$"HBox/CS/Path2".text = str(line_data.get("Path 2", ""))

			if line_data["Default"] == "0":
				$"HBox/CS/Play".text = "Freeze"
			elif line_data["Default"] == "1":
				$"HBox/CS/Play".text = "Reset"

			#% Toggle Visibility:
			$"HBox/CS".visible = true
			$"HBox/CS/Path1".visible = true
			$"HBox/CS/Targets".visible = true
			$"HBox/CS/Path2".visible = true
			$"HBox/CS/Default".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§CS_Sprite":
			$"HBox/Move".text = "CS Sprite"
			$"HBox/Move".tooltip_text += "Play an animation on a node, such as animating characters."

			#% Get data:
			$"HBox/CS/Path1".text = str(line_data.get("Path 1", ""))
			$"HBox/CS/Targets".text = str(line_data.get("Targets", ""))
			$"HBox/CS/Path2".text = str(line_data.get("Path 2", ""))
			$"HBox/CS/File".text = str(line_data.get("File", ""))
			$"HBox/CS/Animation".text = str(line_data.get("Animation", ""))
			$"HBox/CS/Loop/Loop".text = str(line_data.get("Loop", ""))
			$"HBox/CS/Wait/Wait".text = str(line_data.get("Wait", ""))
			$"HBox/CS/Time/Time".text = str(line_data.get("Time", ""))

			if line_data["Play"] == "0":
				$"HBox/CS/Play".text = "Hold"
			elif line_data["Play"] == "1":
				$"HBox/CS/Play".text = "Play"

			#% Toggle Visibility:
			$"HBox/CS".visible = true
			$"HBox/CS/Path1".visible = true
			$"HBox/CS/Targets".visible = true
			$"HBox/CS/Path2".visible = true
			$"HBox/CS/File".visible = true
			$"HBox/CS/Animation".visible = true
			$"HBox/CS/Loop".visible = true
			$"HBox/CS/Wait".visible = true
			$"HBox/CS/Time".visible = true
			$"HBox/CS/Play".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§CS_Sprite_Wait":
			$"HBox/Move".text = "CS Sprite Wait"
			$"HBox/Move".tooltip_text += "Pause dialogue processing while sprite animations play."

			#% Get data:
			$"HBox/CS/Path1".text = str(line_data.get("Path 1", ""))
			$"HBox/CS/Targets".text = str(line_data.get("Targets", ""))
			$"HBox/CS/Path2".text = str(line_data.get("Path 2", ""))
			$"HBox/CS/Wait/Wait".text = str(line_data.get("Wait", ""))
			$"HBox/CS/Time/Time".text = str(line_data.get("Time", ""))

			#% Toggle Visibility:
			$"HBox/CS".visible = true
			$"HBox/CS/Path1".visible = true
			$"HBox/CS/Targets".visible = true
			$"HBox/CS/Path2".visible = true
			$"HBox/CS/Wait".visible = true
			$"HBox/CS/Time".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§CS_Sprite_Stop":
			$"HBox/Move".text = "CS Sprite Stop"
			$"HBox/Move".tooltip_text += "Stop an animation one or more sprites."

			#% Get data:
			$"HBox/CS/Path1".text = str(line_data.get("Path 1", ""))
			$"HBox/CS/Targets".text = str(line_data.get("Targets", ""))
			$"HBox/CS/Path2".text = str(line_data.get("Path 2", ""))

			if line_data["Default"] == "0":
				$"HBox/CS/Play".text = "Freeze"
			elif line_data["Default"] == "1":
				$"HBox/CS/Play".text = "Reset"

			#% Toggle Visibility:
			$"HBox/CS".visible = true
			$"HBox/CS/Path1".visible = true
			$"HBox/CS/Targets".visible = true
			$"HBox/CS/Path2".visible = true
			$"HBox/CS/Default".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§CS_Cam":
			$"HBox/Move".text = "CS Cam"
			$"HBox/Move".tooltip_text += "Change the active camera."

			#% Get data:
			$"HBox/CS/Path1".text = str(line_data.get("Path 1", ""))
			$"HBox/CS/Targets".text = str(line_data.get("Targets", ""))

			#% Toggle Visibility:
			$"HBox/CS".visible = true
			$"HBox/CS/Path1".visible = true
			$"HBox/CS/Targets".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§CS_Light":
			$"HBox/Move".text = "CS Light"
			$"HBox/Move".tooltip_text += "Change the color of a light."

			#% Get data:
			$"HBox/CS/Path1".text = str(line_data.get("Path 1", ""))
			$"HBox/CS/Targets".text = str(line_data.get("Targets", ""))
			$"HBox/CS/Color".text = str(line_data.get("Color", ""))
			$"HBox/CS/Energy".text = str(line_data.get("Energy", ""))

			#% Operator
			_apply_option_value($"HBox/CS/Operators", line_data, "Operator")

			#% Toggle Visibility:
			$"HBox/CS".visible = true
			$"HBox/CS/Path1".visible = true
			$"HBox/CS/Targets".visible = true
			$"HBox/CS/Operators".visible = true
			$"HBox/CS/Energy".visible = true
			$"HBox/CS/Color".visible = true
			$"HBox/CS/ColorPicker".visible = true

			if line_data["Color"] != null and line_data["Color"] != "":
				$"HBox/CS/ColorPicker".modulate = Color(line_data["Color"])
			else:
				$"HBox/CS/ColorPicker".modulate = Color(1, 1, 1)

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		"§CS_Toggle":
			$"HBox/Move".text = "CS Toggle"
			$"HBox/Move".tooltip_text += "Custom toggle properties on a node."

			#% Get data:
			$"HBox/CS/Path1".text = str(line_data.get("Path 1", ""))
			$"HBox/CS/Targets".text = str(line_data.get("Targets", ""))
			$"HBox/CS/Method".text = str(line_data.get("Method", ""))
			$"HBox/CS/Properties".text = str(line_data.get("Properties", ""))
			$"HBox/CS/Value".text = str(line_data.get("Value", ""))

			#% Operator
			_apply_option_value($"HBox/CS/Operators", line_data, "Operator")

			#% Toggle Visibility:
			$"HBox/CS".visible = true
			$"HBox/CS/Path1".visible = true
			$"HBox/CS/Targets".visible = true
			$"HBox/CS/Method".visible = true
			$"HBox/CS/Properties".visible = true
			$"HBox/CS/Value".visible = true

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]
		#endregion

		"§Comment":
			$"HBox/Move".text = "Comment"
			$"HBox/Move".tooltip_text += "Display a comment within the dialogue script. Dialogue editing use only, no effect during dialogues."

			#% Get data:
			$"HBox/Comment/Comment".text = str(line_data.get("Comment", ""))

			#% Toggle Visibility:
			$"HBox/Comment".visible = true

			if line_data["Color"] != null:
				$"HBox/Comment/Comment".add_theme_color_override("font_color", line_data["Color"])
				$"HBox/Comment/Color".modulate = line_data["Color"]

			else:
				$"HBox/Comment/Comment".add_theme_color_override("font_color", Color(1, 1, 1))
				$"HBox/Comment/Color".modulate = Color(1, 1, 1)

			stylebox.bg_color = candy_dc.line_colors[key_name]["BG"]
			stylebox.border_color = candy_dc.line_colors[key_name]["Border"]

		_:
			pass


#* Universal helper for restoring OptionButtons from dictionary data:
func _apply_option_value(btn: OptionButton, data: Dictionary, key: String) -> void:
	if btn == null:
		return

	#% 1) Reset any stale label/selection:
	btn.select(-1)
	btn.text = ""

	#% 2) Get stored value and reselect if present:
	if not data.has(key):
		return
	var value := str(data[key])
	if value == "":
		return

	for i in range(btn.item_count):
		if btn.get_item_text(i) == value:
			btn.select(i)
			break


#& UNIVERSAL ELEMENTS:
func _on_index_pressed() -> void:
	var copy = $"HBox/Index".text
	DisplayServer.clipboard_set(copy)


#& SPOKEN LINE:
#region - Spoken Line
#* LLM button:
func _on_llm_pressed() -> void:
	var btn = $"HBox/SpeechLine/LLM"
	if line_data["AI"] == 0:
		line_data["AI"] = 1
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["On"]	#/ green

	elif line_data["AI"] == 1:
		line_data["AI"] = -1
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red

	elif line_data["AI"] == -1:
		line_data["AI"] = 0
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]	#/ white


#* TTS Button:
func _on_tts_pressed() -> void:
	var btn = $"HBox/SpeechLine/TTS"
	if line_data["TTS"] == 0:
		line_data["TTS"] = 1
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["On"]	#/ green

	elif line_data["TTS"] == 1:
		line_data["TTS"] = -1
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red

	elif line_data["TTS"] == -1:
		line_data["TTS"] = 0
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]	#/ white


#* Bubble Exempt button:
func _on_bubble_exempt_pressed() -> void:
	var btn = $"HBox/SpeechLine/BubbleExempt"
	if line_data["BubbleExempt"] == false:
		line_data["BubbleExempt"] = true
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Neutral"]	#/ yellow

	elif line_data["BubbleExempt"] == true:
		line_data["BubbleExempt"] = false
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]		#/ white

#* Force Portrait button:
func _on_force_portrait_pressed() -> void:
	var btn = $"HBox/SpeechLine/ForcePortrait"
	if line_data["ForcePortrait"] == "0":
		line_data["ForcePortrait"] = "1"
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["On"]	#/ green

	elif line_data["ForcePortrait"] == "1":
		line_data["ForcePortrait"] = "-1"
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red

	elif line_data["ForcePortrait"] == "-1":
		line_data["ForcePortrait"] = "0"
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]	#/ white

#* Show the voice list popup (delegates to main):
func _on_voice_button_pressed() -> void:
	var field: LineEdit = $"HBox/SpeechLine/Voice/File"
	var char_name = $"HBox/SpeechLine/Speaker/Ref".text.strip_edges()
	main.open_voice_menu(self, field, char_name)

#* Hover preview for currently selected voice (delegates to main):
func _on_voice_file_mouse_entered() -> void:
	var filename = $"HBox/SpeechLine/Voice/File".text.strip_edges()
	var char_name = $"HBox/SpeechLine/Speaker/Ref".text.strip_edges()
	if filename == "" or char_name == "":
		return
	main._preview_voice(char_name, filename)

#* Unhover voice file - stop playing preview:
func _on_voice_file_mouse_exited() -> void:
	main.stop_voice_preview()

#* Write voice file name:
func _on_voice_file_text_changed(new_text: String) -> void:
	line_data["Voice"] = new_text

#* Select voice file from list:
func _apply_selected_voice(filename: String) -> void:
	$"HBox/SpeechLine/Voice/File".text = filename
	line_data["Voice"] = filename

func _on_disposition_pressed() -> void:
	var field: LineEdit = $"HBox/SpeechLine/Disposition/Disposition"
	main.open_disposition_menu(self, field)

func _on_reference_pressed() -> void:
	var field: LineEdit = $"HBox/SpeechLine/Speaker/Ref"
	var role = false
	if field.text.begins_with(candy_dc.role_symbol):
		role = true
	main.open_reference_menu(self, field, role)

func _apply_selected_disposition(disposition: String) -> void:
	#% If comma and no space, add space:
	if $"HBox/SpeechLine/Disposition/Disposition".text.ends_with(","):
		$"HBox/SpeechLine/Disposition/Disposition".text += " "

	#% If not comma and space → never had comma:
	if not $"HBox/SpeechLine/Disposition/Disposition".text.ends_with(", ") and $"HBox/SpeechLine/Disposition/Disposition".text != "":
		$"HBox/SpeechLine/Disposition/Disposition".text += ", "

	$"HBox/SpeechLine/Disposition/Disposition".text += disposition + ", "
	line_data["Disposition"] = $"HBox/SpeechLine/Disposition/Disposition".text

func _apply_selected_reference(reference: String) -> void:
	$"HBox/SpeechLine/Speaker/Ref".text = reference
	line_data["Reference"] = reference

#* Write disposition:
func _on_disposition_text_changed(new_text: String) -> void:
	line_data["Disposition"] = new_text

#* Write speaker reference:
func _on_ref_text_changed(new_text: String) -> void:
	line_data["Reference"] = new_text

#* Toggle animated portrait autoplay setting:
func _on_portrait_play_pressed() -> void:
	var p_play_btn = get_node("HBox/SpeechLine/Portrait/Play")
	if line_data["PortraitPlay"] == "0":
		line_data["PortraitPlay"] = "1"
		p_play_btn.modulate = Color(1, 1, 1)

	elif line_data["PortraitPlay"] == "1":
		line_data["PortraitPlay"] = "0"
		p_play_btn.modulate = Color(0.5, 0.5, 0.5)

#* Write portrait file name:
func _on_portrait_file_text_changed(new_text: String) -> void:
	line_data["Portrait"] = new_text

#* Hover preview for currently selected portrait (delegates to main):
func _on_portrait_file_mouse_entered() -> void:
	var filename = $"HBox/SpeechLine/Portrait/File".text.strip_edges()
	var char_name = $"HBox/SpeechLine/Speaker/Ref".text.strip_edges()
	if filename == "" or char_name == "":
		return
	main._preview_portrait(char_name, filename)

#* Unhover - stop showing preview:
func _on_portrait_file_mouse_exited() -> void:
	main.hide_portrait_panel()	#/ Hide ColorRect only, keep popup

#* Show the portrait list popup (delegates to main):
func _on_portrait_button_pressed() -> void:
	var field: LineEdit = $"HBox/SpeechLine/Portrait/File"
	var char_name = $"HBox/SpeechLine/Speaker/Ref".text.strip_edges()
	main.open_portrait_menu(self, field, char_name)
	#print(JSON.stringify(candy_dc.resources, "\t"))

#* Called by button presses inside the menu (main will call back):
func _apply_selected_portrait(filename: String) -> void:
	$"HBox/SpeechLine/Portrait/File".text = filename
	line_data["Portrait"] = filename

#* Save text changes to line_data in real time:
func _on_speech_text_changed(new_text) -> void:
	#% Update line data:
	for variant in line_data["Variants"]:
		if variant.has("Default"):
			variant["Default"]["Text"] = new_text
			break

	update_character_count()

#* Update character count:
func update_character_count():
	var speech_field = get_node("HBox/SpeechLine/Speech/Text")
	var total_chars := count_visible_chars(speech_field.text)
	var remaining = candy_dc.spoken_line_limit - total_chars
	$"HBox/SpeechLine/PanelC/LimitCount".text = str(remaining)
	if remaining < 0:
		$"HBox/SpeechLine/PanelC/LimitCount".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]
	elif remaining <= candy_dc.spoken_line_near_limit:
		$"HBox/SpeechLine/PanelC/LimitCount".modulate = candy_dc.color_models[candy_dc.color_mode]["Neutral"]
	else:
		$"HBox/SpeechLine/PanelC/LimitCount".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]

#* Count visible characters in a string (ignores BBCode tags):
func count_visible_chars(text: String) -> int:
	var count := 0
	var i := 0
	var length := text.length()

	while i < length:
		var c := text[i]

		#% If this looks like the start of a tag:
		if c == "[":
			#% Try to find the closing bracket:
			var closing := text.find("]", i + 1)
			if closing != -1:
				var maybe_tag := text.substr(i, closing - i + 1)

				#% Validate actual BBCode tag using your existing function:
				if _is_valid_bbcode_tag(maybe_tag):
					i = closing + 1		#/ Skip the whole tag
					continue
				#/ If invalid tag → treat "[" as normal text

		#% Otherwise this is a visible char:
		count += 1
		i += 1

	return count

#* Detects if a bracketed section is a valid BBCode tag:
func _is_valid_bbcode_tag(tag: String) -> bool:
	if not tag.begins_with("[") or not tag.ends_with("]"):
		return false

	#% Remove brackets:
	var inner = tag.substr(1, tag.length() - 2).strip_edges()
	if inner == "" or inner.begins_with(" "):
		return false

	#% Handle closing tags (e.g. [/b], [/color], [/pulse]):
	var is_closing = false
	if inner.begins_with("/"):
		is_closing = true
		inner = inner.substr(1)		#/ Strip the "/"

	#% Extract base name (before '=', ' '):
	var base_name := inner.split("=")[0].split(" ")[0]

	#% Is this even a known tag name?
	var is_known = (
		candy_dc.BBCODE_TAGS_SIMPLE.has(base_name)
		or candy_dc.BBCODE_TAGS_EQUALS.has(base_name)
		or candy_dc.BBCODE_TAGS_SPACE.has(base_name)
	)
	if not is_known:
		return false

	#% For closing tags, [/name] is always valid if name is known:
	if is_closing:
		return true

	#% Type 1 — simple tags with no parameters:
	if inner == base_name and candy_dc.BBCODE_TAGS_SIMPLE.has(base_name):
		return true

	#% Type 2 — tags with "=" parameters:
	if candy_dc.BBCODE_TAGS_EQUALS.has(base_name):
		if inner.begins_with(base_name + "="):
			return true

	#% Type 3 — tags with space-delimited params:
	if candy_dc.BBCODE_TAGS_SPACE.has(base_name):
		if inner.begins_with(base_name + " "):
			return true

	#% Fallback - known tag name but unusual formatting → still treat as BBCode:
	return true


#* Open the Writer:
func _on_write_pressed() -> void:
	candy_dc.write_line_index = dictionary_index

	main.get_node("Writer").visible = true
	main.get_node("Writer").line_data = line_data
	main.get_node("Writer").setup()
	candy_dc.editor_state = "writer"

#endregion - spoken line

#& CONDITIONS:
#region - Conditions
#* Open the Condition Editor:
func _on_condition_editor_pressed() -> void:
	main.get_node("ConditionEditor").visible = true
	main.get_node("ConditionEditor").line_data = line_data
	main.get_node("ConditionEditor/Condition").text = $"HBox/Con/Condition/Text".text
	candy_dc.condition_line = self
	candy_dc.condition_line_index = dictionary_index
	candy_dc.editor_state = "condition_editor"

func _on_if_command_condition_changed(new_text: String) -> void:
	line_data["Condition"] = new_text

func _on_condition_type_item_selected(index: int) -> void:
	var type_button = $"HBox/Con/Type"
	var type = type_button.get_item_text(index)
	line_data["Type"] = type
	match_condition_type(line_data["Type"])

#* Display data fields based on type:
func match_condition_type(type):
	$"HBox/Con/Transition".visible = false
	$"HBox/Con/Conversation".visible = false
	$"HBox/Con/Block".visible = false
	$"HBox/Con/Line".visible = false
	$"HBox/Con/Go".visible = false

	$"HBox/Con/Expression".visible = false

	$"HBox/Con/Await".visible = false
	$"HBox/Con/Function".visible = false
	$"HBox/Con/Signal".visible = false
	$"HBox/Con/Arguments".visible = false

	$"HBox/Con/SetVariable".visible = false
	$"HBox/Con/Flag".visible = false
	$"HBox/Con/Operator".visible = false
	$"HBox/Con/Expression".visible = false
	$"HBox/Con/Name".visible = false
	$"HBox/Con/NameTable".visible = false
	$"HBox/Con/NameActorKey".visible = false
	$"HBox/Con/Role".visible = false
	$"HBox/Con/Reference".visible = false
	$"HBox/Con/Disposition".visible = false

	match type:
		"Transition":
			$"HBox/Con/Transition".visible = true
			$"HBox/Con/Conversation".visible = true
			$"HBox/Con/Block".visible = true
			$"HBox/Con/Line".visible = true
			$"HBox/Con/Go".visible = true
		"Call":
			$"HBox/Con/SetVariable".tooltip_text += "Variable to store returned value to."
			$"HBox/Con/SetVariable".visible = true
			$"HBox/Con/Await".visible = true
			$"HBox/Con/Function".visible = true
			$"HBox/Con/Arguments".visible = true
		"Emit":
			$"HBox/Con/Signal".visible = true
			$"HBox/Con/Arguments".visible = true
		"Await":
			$"HBox/Con/SetVariable".tooltip_text += "Variable to store signal arguments to."
			$"HBox/Con/SetVariable".visible = true
			$"HBox/Con/Signal".visible = true
		"Set":
			$"HBox/Con/SetVariable".tooltip_text += "Variable to modify."
			$"HBox/Con/SetVariable".visible = true
			$"HBox/Con/Operator".visible = true
			$"HBox/Con/Expression".visible = true
		"Flag":
			$"HBox/Con/Flag".visible = true
			$"HBox/Con/Operator".visible = true
			$"HBox/Con/Expression".visible = true
		"Name":
			$"HBox/Con/Reference".visible = true
			$"HBox/Con/Name".visible = true
			$"HBox/Con/NameTable".visible = true
			$"HBox/Con/NameActorKey".visible = true
		"Role":
			$"HBox/Con/Role".visible = true
			$"HBox/Con/Reference".visible = true
		"Disposition":
			$"HBox/Con/Reference".visible = true
			$"HBox/Con/Disposition".visible = true


func _on_if_command_transition_item_selected(index: int) -> void:
	var transition_button = $"HBox/Con/Transition"
	var transition = transition_button.get_item_text(index)
	line_data["Transition"] = transition

func _on_if_conversation_changed(new_text: String) -> void:
	line_data["Conversation"] = new_text

func _on_if_block_changed(new_text: String) -> void:
	line_data["Block"] = new_text

func _on_if_line_changed(new_text: String) -> void:
	if line_data.has("Line"):
		line_data["Line"] = new_text

func _on_conversation_button_pressed() -> void:
	var field: LineEdit = $"HBox/Con/Conversation/LineEdit"
	main.open_conversation_menu(field)

func _apply_selected_conversation(conv_name: String) -> void:
	$"HBox/Con/Conversation/LineEdit".text = conv_name
	line_data["Conversation"] = conv_name

func _on_block_button_pressed() -> void:
	var field: LineEdit = $"HBox/Con/Block/LineEdit"
	var o_convo: LineEdit = $"HBox/Con/Conversation/LineEdit"
	main.open_block_menu(o_convo, field)

func _apply_selected_block(block_name: String) -> void:
	$"HBox/Con/Block/LineEdit".text = block_name
	line_data["Block"] = block_name

func _on_line_button_pressed() -> void:
	var field: LineEdit = $"HBox/Con/Line/LineEdit"
	var o_convo: LineEdit = $"HBox/Con/Conversation/LineEdit"
	var o_block: LineEdit = $"HBox/Con/Block/LineEdit"
	main.open_line_menu(o_convo, o_block, field)

func _apply_selected_line(ref_name: String) -> void:
	$"HBox/Con/Line/LineEdit".text = ref_name
	line_data["Line"] = ref_name


#* Jump to the selected conversation and block in the main editor:
func _on_if_command_go_pressed() -> void:
	var conv_field: LineEdit = $"HBox/Con/Conversation/LineEdit"
	var block_field: LineEdit = $"HBox/Con/Block/LineEdit"

	var conv_name: String = conv_field.text.strip_edges()
	var block_name: String = block_field.text.strip_edges()

	if conv_name == "":
		conv_name = candy_dc.current_conversation

	#@ Compute transition:
	#% Same conversation and block → do nothing:
	if conv_name == candy_dc.current_conversation and block_name == candy_dc.current_block:
		return

	#% No block → invalid, do nothing:
	elif block_name == "":
		return

	#% Yes conversation, yes block → switch both:
	elif conv_name != "" and block_name != "":
		if not Input.is_key_pressed(KEY_CTRL):
			candy_dc.current_conversation = conv_name
			candy_dc.current_block = block_name

	#@ Create Conversation/Block if they don't exist:
	if not candy_dc.conversations.has(conv_name):
		candy_dc.conversations[conv_name] = {}

	if not candy_dc.conversations[conv_name].has(block_name):
		candy_dc.conversations[conv_name][block_name] = {"Text": []}
		main._init_new_block(candy_dc.conversations[conv_name][block_name])

	#@ Don't transition if CTRL held down:
	if Input.is_key_pressed(KEY_CTRL):
		return

	#@ Immediately rebuild dropdowns:
	var conv_menu = main.get_node("VBox/TopBar/HBox/Conversations/Conversations")
	conv_menu.clear()
	for key in candy_dc.conversations.keys():
		conv_menu.add_item(key)
		if key == candy_dc.current_conversation:
			conv_menu.select(conv_menu.item_count - 1)

	#@ Refresh block dropdown:
	var block_menu = main.get_node("VBox/TopBar/HBox/Blocks/Blocks")
	block_menu.clear()
	for block_n in candy_dc.conversations[candy_dc.current_conversation].keys():
		block_menu.add_item(block_n)
		if block_n == candy_dc.current_block:
			block_menu.select(block_menu.item_count - 1)

	#@ Update the UI selectors so they match the new context:
	for i in range(conv_menu.item_count):
		if conv_menu.get_item_text(i) == candy_dc.current_conversation:
			conv_menu.select(i)
			break

	block_menu.clear()
	for block_key in candy_dc.conversations[candy_dc.current_conversation].keys():
		block_menu.add_item(block_key)
	for i in range(block_menu.item_count):
		if block_menu.get_item_text(i) == candy_dc.current_block:
			block_menu.select(i)
			break

	#@ Refresh the editor view:
	main._load_active_block()
	main.record_browsing_point()
	main.save_undo_step()

#endregion - conditions

#& SET:
#region - Set
func _on_set_editor_pressed() -> void:
	main.get_node("ConditionEditor").visible = true
	main.get_node("ConditionEditor").line_data = line_data
	main.get_node("ConditionEditor/Condition").text = $"HBox/Con/SetVariable".text
	candy_dc.condition_line = self
	candy_dc.condition_line_index = dictionary_index
	candy_dc.editor_state = "variable_editor"

func _on_set_variable_changed(new_text: String) -> void:
	line_data["Variable"] = new_text

func _on_set_flag_changed(new_text: String) -> void:
	line_data["Flag"] = new_text

func _on_set_operator_changed(new_text: String) -> void:
	line_data["Operator"] = new_text

func _on_for_operators_item_selected(index: int) -> void:
	var operator_button = $"HBox/Con/ForOperators"
	var operator = operator_button.get_item_text(index)
	line_data["Operator"] = operator

func _on_while_operators_item_selected(index: int) -> void:
	var operator_button = $"HBox/Con/WhileOperators"
	var operator = operator_button.get_item_text(index)
	line_data["Operator"] = operator

func _on_set_name_changed(new_text: String) -> void:
	line_data["Name"] = new_text

func _on_set_name_table_changed(new_text: String) -> void:
	line_data["Table"] = new_text

func _on_set_name_actor_key_changed(new_text: String) -> void:
	line_data["Actor_Key"] = new_text

func _on_set_reference_changed(new_text: String) -> void:
	line_data["Reference"] = new_text

func _on_set_disposition_changed(new_text: String) -> void:
	line_data["Disposition"] = new_text

func _on_set_role_changed(new_text: String) -> void:
	line_data["Role"] = new_text

func _on_set_actor_changed(new_text: String) -> void:
	line_data["Actor"] = new_text

func _on_set_operator_pressed() -> void:
	var field: LineEdit = $"HBox/Con/Operator/Operator"
	main.open_operator_menu(self, field)

func _on_set_flag_pressed() -> void:
	var field: LineEdit = $"HBox/Con/Flag/Flag"
	main.open_flag_menu(self, field)

func _on_set_disposition_pressed() -> void:
	var field: LineEdit = $"HBox/Con/Disposition/Disposition"
	main.open_disposition_menu(self, field)

func _on_set_expression_changed(new_text: String) -> void:
	line_data["Expression"] = new_text

func _on_set_role_pressed() -> void:
	var field: LineEdit = $"HBox/Con/Role/Ref"
	main.open_reference_menu(self, field, true)

func _on_set_reference_pressed() -> void:
	var field: LineEdit = $"HBox/Con/Reference/Ref"
	var role = false
	if field.text.begins_with(candy_dc.role_symbol):
		role = true
	main.open_reference_menu(self, field, role)

func _set_apply_selected_operator(operator: String) -> void:
	$"HBox/Con/Operator/Operator".text = operator
	line_data["Operator"] = operator

func _set_apply_selected_flag(flag: String) -> void:
	$"HBox/Con/Flag/Flag".text = flag
	line_data["Flag"] = flag

func _set_apply_selected_disposition(disposition: String) -> void:
	$"HBox/Con/Disposition/Disposition".text = disposition
	line_data["Disposition"] = disposition

func _set_apply_selected_role(reference: String) -> void:
	$"HBox/Con/Role/Ref".text = reference
	line_data["Role"] = reference

func _set_apply_selected_reference(reference: String) -> void:
	$"HBox/Con/Reference/Ref".text = reference
	line_data["Reference"] = reference
#endregion - set

#& CALL:
#region - Call
func _on_call_function_changed(new_text: String) -> void:
	line_data["Function"] = new_text

func _on_call_signal_changed(new_text: String) -> void:
	line_data["Signal"] = new_text

func _on_call_arguments_changed(new_text: String) -> void:
	line_data["Arguments"] = new_text

func _on_call_await_pressed() -> void:
	var btn = $"HBox/Con/Await"
	if line_data["Await"] == false:
		line_data["Await"] = true
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["On"]   #/ green

	elif line_data["Await"] == true:
		line_data["Await"] = false
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]   #/ red
#endregion - call

#& LM:
#region - Line Mark
#* Change the reference:
func _on_lm_ref_changed(new_text: String) -> void:
	line_data["Reference"] = new_text
#endregion - line mark

#& INPUT:
#region - Input
func _on_input_file_changed(new_text: String) -> void:
	line_data["File"] = new_text

func _on_input_menu_list_pressed() -> void:
	var field: LineEdit = $"HBox/Input/File/FileField"
	main.open_scene_menu(self, field, "Input_UI")

func _apply_selected_input_scene(filename: String) -> void:
	$"HBox/Input/File/FileField".text = filename
	line_data["File"] = filename

func _on_input_variable_changed(new_text: String) -> void:
	line_data["Variable"] = new_text

func _on_input_mode_changed(new_text: String) -> void:
	line_data["Mode"] = new_text

func _on_input_placeholder_changed(new_text: String) -> void:
	line_data["Placeholder"] = new_text

func _on_input_instructions_changed(new_text: String) -> void:
	line_data["Instructions"] = new_text

func _on_input_text_changed(new_text: String) -> void:
	line_data["Text"] = new_text
#endregion - input

#& MOUSE:
#region - Mouse
func _on_mouse_mode_item_selected(index: int) -> void:
	var mode_button = $"HBox/Mouse/MouseMode"
	var mode_name = mode_button.get_item_text(index)
	line_data["Mouse Mode"] = mode_name
#endregion - mouse

#& MEDIA:
#region - Media
func _on_media_node_text_changed(new_text: String) -> void:
	line_data["Node"] = new_text

func _on_media_node_pressed() -> void:
	var field: LineEdit = $"HBox/Media/Node/NodeName"
	main.open_media_player_menu(self, field)

func _apply_selected_media_player(media_player: String) -> void:
	$"HBox/Media/Node/NodeName".text = media_player
	line_data["Node"] = media_player

func _on_media_animation_text_changed(new_text: String) -> void:
	line_data["Animation"] = new_text

func _on_media_file_changed(new_text: String) -> void:
	line_data["File"] = new_text

func _on_media_file_button_pressed() -> void:
	var field: LineEdit = $"HBox/Media/Media/FileName"
	var node = $"HBox/Media/Node/NodeName".text
	main.open_media_menu(self, field, node)

func _apply_selected_media(filename: String) -> void:
	$"HBox/Media/Media/FileName".text = filename
	line_data["File"] = filename

#* Hover preview for currently selected portrait (delegates to main):
func _on_media_file_mouse_entered() -> void:
	var filename = $"HBox/Media/Media/FileName".text.strip_edges()
	var media_player = $"HBox/Media/Node/NodeName".text.strip_edges()
	if filename == "" or (media_player == "" and not line.has("§BG")):
		return

	if line.has("§Image"):
		if candy_dc.resources.has("Images") \
		and candy_dc.resources["Images"].has(media_player) \
		and candy_dc.resources["Images"][media_player].has(filename):
			var file = candy_dc.resources["Images"][media_player][filename]
			main._preview_media_image(file)

	elif line.has("§BG"):
		if candy_dc.resources.has("Backgrounds") \
		and candy_dc.resources["Backgrounds"].has(filename):
			var file = candy_dc.resources["Backgrounds"][filename]
			main._preview_media_bg(file)

	elif line.has("§Audio"):
		if candy_dc.resources.has("Audio") \
		and candy_dc.resources["Audio"].has(media_player) \
		and candy_dc.resources["Audio"][media_player].has(filename):
			var file = candy_dc.resources["Audio"][media_player][filename]
			main._preview_media_audio(file)

#* Unhover - stop showing preview:
func _on_media_file_mouse_exited() -> void:
	main.hide_media_preview_only()

func _on_media_duration_changed(new_text: String) -> void:
	line_data["Duration"] = new_text

func _on_media_lines_changed(new_text: String) -> void:
	line_data["Lines"] = new_text

func _on_media_time_changed(new_text: String) -> void:
	line_data["Time"] = new_text

func _on_media_loop_text_changed(new_text: String) -> void:
	line_data["Loop"] = new_text

func _on_media_wait_text_changed(new_text: String) -> void:
	line_data["Wait"] = new_text

func _on_media_all_lines_pressed() -> void:
	if line_data["All"] == 0:
		line_data["All"] = 1
		$"HBox/Media/AllLines".text = "All"

	elif line_data["All"] == 1:
		line_data["All"] = 0
		$"HBox/Media/AllLines".text = "Spoken"

func _on_media_animated_pressed() -> void:
	if line_data["Animated"] == 0:
		line_data["Animated"] = 1
		$"HBox/Media/Animated".text = "Animated"
	elif line_data["Animated"] == 1:
		line_data["Animated"] = 0
		$"HBox/Media/Animated".text = "Static"

func _on_media_box_pressed() -> void:
	var btn = $"HBox/Media/Box"
	if line_data["Box"] == 0:
		line_data["Box"] = 1
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["On"]   #/ green

	elif line_data["Box"] == 1:
		line_data["Box"] = -1
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]   #/ red

	elif line_data["Box"] == -1:
		line_data["Box"] = 0
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]   #/ white

func _on_media_portrait_pressed() -> void:
	var btn = $"HBox/Media/Portrait"
	if line_data["Portrait"] == 0:
		line_data["Portrait"] = 1
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["On"]   #/ green

	elif line_data["Portrait"] == 1:
		line_data["Portrait"] = -1
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]   #/ red

	elif line_data["Portrait"] == -1:
		line_data["Portrait"] = 0
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]   #/ white
#endregion - media

#& VOLUME:
#region - Volume
func _on_volume_node_text_changed(new_text: String) -> void:
	line_data["Node"] = new_text

func _on_volume_value_changed(new_text: String) -> void:
	line_data["Volume"] = new_text
#endregion -volume

#& VN:
#region - VN
func _apply_selected_bg(filename: String) -> void:
	$"HBox/VN/File/FileName".text = filename
	line_data["File"] = filename

func _on_vn_scene_changed(new_text: String) -> void:
	line_data["Scene"] = new_text

func _on_vn_scene_button_pressed() -> void:
	var field: LineEdit = $"HBox/VN/Scene/Scene"
	var type = "VN"
	if line.has("§BG"):
		type = "BG"
	main.open_scene_menu(self, field, type)

func _apply_selected_vn_scene(filename: String) -> void:
	$"HBox/VN/Scene/Scene".text = filename
	line_data["Scene"] = filename

func _on_vn_bust_changed(new_text: String) -> void:
	line_data["Bust"] = new_text

func _on_vn_bust_button_pressed() -> void:
	var field: LineEdit = $"HBox/VN/Busts/Bust"
	main.open_vn_bust_node_menu(self, field)

func _apply_selected_vn_bust_node(node_name: String) -> void:
	$"HBox/VN/Busts/Bust".text = node_name
	line_data["Bust"] = node_name

func _on_vn_layer_changed(new_text: String) -> void:
	line_data["Layers"] = new_text

func _on_vn_layer_button_pressed() -> void:
	var field: LineEdit = $"HBox/VN/Layers/Layer"
	main.open_vn_layer_node_menu(self, field)

func _apply_selected_vn_layer(filename: String) -> void:
	if line.has("§BG"):
		$"HBox/VN/Layers/Layer".text = filename
		line_data["Layers"] = filename
	else:
		#% If comma and no space, add space:
		if $"HBox/VN/Layers/Layer".text.ends_with(","):
			$"HBox/VN/Layers/Layer".text += " "
		#% If not comma and space → never had comma:
		if not $"HBox/VN/Layers/Layer".text.ends_with(", ") and $"HBox/VN/Layers/Layer".text != "":
			$"HBox/VN/Layers/Layer".text += ", "
		$"HBox/VN/Layers/Layer".text += filename + ", "
		line_data["Layers"] = $"HBox/VN/Layers/Layer".text

func _on_vn_library_changed(new_text: String) -> void:
	line_data["Library"] = new_text

func _on_vn_library_button_pressed() -> void:
	var field: LineEdit = $"HBox/VN/Libraries/Library"
	var type = "VN"
	if line.has("§BG"):
		type = "BG"
	main.open_vn_library_menu(self, field, type)

func _on_vn_animation_changed(new_text: String) -> void:
	line_data["Animation"] = new_text

func _on_vn_actors_changed(new_text: String) -> void:
	line_data["Actors"] = new_text

func _on_vn_actors_button_pressed() -> void:
	var field: LineEdit = $"HBox/VN/Actors/Actors"
	main.open_vn_actors_menu(self, field)

func _add_selected_actor(actor: String) -> void:
	#% If comma and no space, add space:
	if $"HBox/VN/Actors/Actors".text.ends_with(","):
		$"HBox/VN/Actors/Actors".text += " "
	#% If not comma and space → never had comma:
	if not $"HBox/VN/Actors/Actors".text.ends_with(", ") and $"HBox/VN/Actors/Actors".text != "":
		$"HBox/VN/Actors/Actors".text += ", "

	$"HBox/VN/Actors/Actors".text += actor + ", "
	line_data["Actors"] = $"HBox/VN/Actors/Actors".text

func _on_vn_effects_changed(new_text: String) -> void:
	line_data["Effects"] = new_text

func _on_vn_effects_button_pressed() -> void:
	var field: LineEdit = $"HBox/VN/Effects/Effects"
	main.open_vn_effects_menu(self, field)

func _apply_selected_vn_effects(effect: String) -> void:
	#% If comma and no space, add space:
	if $"HBox/VN/Effects/Effects".text.ends_with(","):
		$"HBox/VN/Effects/Effects".text += " "
	#% If not comma and space → never had comma:
	if not $"HBox/VN/Effects/Effects".text.ends_with(", ") and $"HBox/VN/Effects/Effects".text != "":
		$"HBox/VN/Effects/Effects".text += ", "
	$"HBox/VN/Effects/Effects".text += effect + ", "
	line_data["Effects"] = $"HBox/VN/Effects/Effects".text

#* Hover preview for currently selected portrait (delegates to main)
func _on_vn_bust_mouse_entered() -> void:
	var filename = $"HBox/VN/File/FileName".text.strip_edges()
	var char_name = $"HBox/VN/Reference/Ref".text.strip_edges()
	var layer_name = $"HBox/VN/Layers/Layer".text
	var key_name = line.keys()[0]

	if key_name == "§VN_Bust":
		if filename == "" or char_name == "":
			return
		main._preview_media_bust(char_name, filename)

	elif key_name == "§BG":
		if filename == "" or layer_name == "":
			return
		main._preview_media_bg(layer_name, filename)


#* Unhover - stop showing preview:
func _on_vn_bust_mouse_exited() -> void:
	main.hide_media_preview_only()

func _on_vn_ref_changed(new_text: String) -> void:
	line_data["Reference"] = new_text

func _on_vn_reference_pressed() -> void:
	var field: LineEdit = $"HBox/VN/Reference/Ref"
	var role = false
	if field.text.begins_with(candy_dc.role_symbol):
		role = true
	main.open_reference_menu(self, field, role)

func _apply_selected_vn_reference(reference: String) -> void:
	$"HBox/VN/Reference/Ref".text = reference
	line_data["Reference"] = reference

func _on_bust_file_changed(new_text: String) -> void:
	line_data["File"] = new_text

func _on_vn_bust_file_pressed() -> void:
	var field: LineEdit = $"HBox/VN/File/FileName"
	var char_name = $"HBox/VN/Reference/Ref".text.strip_edges()
	var layer = $"HBox/VN/Layers/Layer".text
	var key_name = line.keys()[0]

	if key_name == "§VN_Bust":
		main.open_vn_bust_file_menu(self, field, char_name)
	elif key_name == "§BG":
		main.open_bg_file_menu(self, field, layer)

func _apply_selected_vn_bust_file(filename: String) -> void:
	$"HBox/VN/File/FileName".text = filename
	line_data["File"] = filename

func _on_vn_loop_changed(new_text: String) -> void:
	line_data["Loop"] = int(new_text)

func _on_vn_time_text_changed(new_text: String) -> void:
	line_data["Time"] = new_text

func _on_vn_wait_text_changed(new_text: String) -> void:
	line_data["Wait"] = new_text

func _on_vn_default_pressed() -> void:
	var btn = $"HBox/VN/Default"
	if line_data["Default"] == 0:
		line_data["Default"] = 1
		btn.text = "Reset"

	elif line_data["Default"] == 1:
		line_data["Default"] = 0
		btn.text = "Freeze"

func _on_vn_axis_selected(index: int) -> void:
	var axis_button = $"HBox/VN/Axis"
	var axis = axis_button.get_item_text(index)
	line_data["Axis"] = axis
#endregion - vn

#& CS:
#region - CS
func _on_cs_scene_text_changed(new_text: String) -> void:
	line_data["Scene"] = new_text

func _on_cs_path_1_changed(new_text: String) -> void:
	line_data["Path 1"] = new_text

func _on_cs_path_2_changed(new_text: String) -> void:
	line_data["Path 2"] = new_text

func _on_cs_target_changed(new_text: String) -> void:
	line_data["Targets"] = new_text

func _on_cs_animation_changed(new_text: String) -> void:
	line_data["Animation"] = new_text

func _on_cs_method_changed(new_text: String) -> void:
	line_data["Method"] = new_text

func _on_cs_properties_changed(new_text: String) -> void:
	line_data["Properties"] = new_text

func _on_cs_value_changed(new_text: String) -> void:
	line_data["Value"] = new_text

func _on_cs_energy_changed(new_text: String) -> void:
	line_data["Energy"] = new_text

func _on_cs_color_changed(new_text: String) -> void:
	line_data["Color"] = new_text

	if line_data["Color"] != null and line_data["Color"] != "":
		$"HBox/CS/ColorPicker".modulate = Color(line_data["Color"])
	else:
		$"HBox/CS/ColorPicker".modulate = Color(1, 1, 1)

func _on_cs_marker_changed(new_text: String) -> void:
	line_data["Markers"] = new_text

func _on_cs_rotate_pressed() -> void:
	var btn = $"HBox/CS/Rotate"
	if line_data["Rotate"] == "0":
		line_data["Rotate"] = "1"
		btn.text = "Rotate"
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]   #/ white

	elif line_data["Rotate"] == "1":
		line_data["Rotate"] = "0"
		btn.text = "Rotate"
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]   #/ grey

func _on_cs_play_pressed() -> void:
	var btn = $"HBox/CS/Play"
	if line_data["Play"] == "0":
		line_data["Play"] = "1"
		btn.text = "Play"

	elif line_data["Play"] == "1":
		line_data["Play"] = "0"
		btn.text = "Hold"

func _on_cs_loop_changed(new_text: String) -> void:
	line_data["Loop"] = int(new_text)

func _on_cs_time_text_changed(new_text: String) -> void:
	line_data["Time"] = new_text

func _on_cs_wait_text_changed(new_text: String) -> void:
	line_data["Wait"] = new_text

func _on_cs_default_pressed() -> void:
	var btn = $"HBox/CS/Default"
	if line_data["Default"] == "0":
		line_data["Default"] = "1"
		btn.text = "Reset"

	elif line_data["Default"] == "1":
		line_data["Default"] = "0"
		btn.text = "Freeze"

func _on_cs_operators_item_selected(index: int) -> void:
	var operator_button = $"HBox/CS/Operators"
	var operator = operator_button.get_item_text(index)
	line_data["Operator"] = operator

func _on_cs_color_picker_pressed() -> void:
	candy_dc.color_pick_mode = "cs_light_color"
	main.get_node("Color").visible = true
	if line_data["Color"] != null:
		main.get_node("Color/PanelContainer/VBox/ColorPicker").color = line_data["Color"]
	candy_dc.cs_line_index = dictionary_index
	candy_dc.cs_line = self

func _on_cs_visi_status_item_selected(index: int) -> void:
	var operator_button = $"HBox/CS/Visibility"
	var operator = operator_button.get_item_text(index)
	line_data["Visibility"] = operator

#endregion - cs

#& CHOICES:
#region - Choices
func _on_choices_reference_changed(new_text: String) -> void:
	line_data["Reference"] = new_text

func _on_choice_list_config_pressed() -> void:
	if line.has("§Choice_List"):
		var editor = main.get_node("ChoiceListEditor")

		#% Setup Editor:
		editor.line_data = line_data
		editor.visible = true
		editor.setup()
		candy_dc.editor_state = "choice_list_editor"

	elif line.has("§Choice_Status"):
		var editor = main.get_node("ChoiceStatusEditor")

		#% Setup Editor:
		editor.line_data = line_data
		editor.line_type = "Choice Status"
		editor.visible = true
		editor.setup()
		candy_dc.editor_state = "choice_status_editor"


	elif line.has("§Timer_Status"):
		var editor = main.get_node("ChoiceStatusEditor")

		#% Setup Editor:
		editor.line_data = line_data
		editor.line_type = "Timer Status"
		editor.visible = true
		editor.setup()
		candy_dc.editor_state = "choice_status_editor"

func _on_menu_mode_item_selected(index: int) -> void:
	var mode_button = $"HBox/Choices/MenuMode"
	var mode = mode_button.get_item_text(index)
	line_data["Menu Mode"] = mode

func _on_category_mode_item_selected(index: int) -> void:
	var mode_button = $"HBox/Choices/CategoryMode"
	var mode = mode_button.get_item_text(index)
	line_data["Category Mode"] = mode

func _on_choice_mode_item_selected(index: int) -> void:
	var mode_button = $"HBox/Choices/ChoiceMode"
	var mode = mode_button.get_item_text(index)
	line_data["Choice Mode"] = mode

func _on_timer_mode_item_selected(index: int) -> void:
	var mode_button = $"HBox/Choices/TimerMode"
	var mode = mode_button.get_item_text(index)
	line_data["Timer Mode"] = mode

func _on_enable_item_selected(index: int) -> void:
	var status_button = $"HBox/Choices/Enable"
	var status = status_button.get_item_text(index)
	line_data["Enable"] = status

func _on_activate_item_selected(index: int) -> void:
	var status_button = $"HBox/Choices/Activate"
	var status = status_button.get_item_text(index)
	line_data["Activate"] = status

func _on_show_item_selected(index: int) -> void:
	var status_button = $"HBox/Choices/Show"
	var status = status_button.get_item_text(index)
	line_data["Show"] = status

func _on_label_text_changed(new_text: String) -> void:
	line_data["Label"] = new_text

func _on_tooltip_text_changed(new_text: String) -> void:
	line_data["Tooltip"] = new_text

func _on_timer_node_item_selected(index: int) -> void:
	var status_button = $"HBox/Choices/TimerNode"
	var status = status_button.get_item_text(index)
	line_data["Timer Node"] = status

func _on_time_text_changed(new_text: String) -> void:
	line_data["Time"] = new_text

func _on_loop_text_changed(new_text: String) -> void:
	line_data["Loop"] = new_text

func _on_timer_status_item_selected(index: int) -> void:
	var status_button = $"HBox/Choices/TimerStatus"
	var status = status_button.get_item_text(index)
	line_data["Status"] = status
#endregion - choices

#& COMMENTS:
#region - Comments
func _on_comment_color_pressed() -> void:
	candy_dc.color_pick_mode = "comment"
	main.get_node("Color").visible = true
	if line_data["Color"] != null:
		main.get_node("Color/PanelContainer/VBox/ColorPicker").color = line_data["Color"]
	candy_dc.comment_line_index = dictionary_index
	candy_dc.comment_line = self

func _on_comment_text_changed(new_text: String) -> void:
	line_data["Comment"] = new_text
#endregion - comments

#& CLEAR:
#region - Clear
func _on_clear_box_pressed() -> void:
	if line_data["Box"] == "1":
		line_data["Box"] = "0"
		$"HBox/Clear/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red
	elif line_data["Box"] == "0":
		line_data["Box"] = "1"
		$"HBox/Clear/Box".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]	#/ green

func _on_clear_bubbles_pressed() -> void:
	if line_data["Bubbles"] == "1":
		line_data["Bubbles"] = "0"
		$"HBox/Clear/Bubbles".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red
	elif line_data["Bubbles"] == "0":
		line_data["Bubbles"] = "1"
		$"HBox/Clear/Bubbles".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]	#/ green

func _on_clear_subtitles_pressed() -> void:
	if line_data["Subtitles"] == "1":
		line_data["Subtitles"] = "0"
		$"HBox/Clear/Subtitles".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red
	elif line_data["Subtitles"] == "0":
		$"HBox/Clear/Subtitles".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]	#/ green

func _on_clear_portraits_pressed() -> void:
	if line_data["Portraits"] == "1":
		line_data["Portraits"] = "0"
		$"HBox/Clear/Portraits".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red
	elif line_data["Portraits"] == "0":
		line_data["Portraits"] = "1"
		$"HBox/Clear/Portraits".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]	#/ green

func _on_clear_busts_pressed() -> void:
	if line_data["Busts"] == "1":
		line_data["Busts"] = "0"
		$"HBox/Clear/Busts".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red
	elif line_data["Busts"] == "0":
		line_data["Busts"] = "1"
		$"HBox/Clear/Busts".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]	#/ green

func _on_clear_backgrounds_pressed() -> void:
	if line_data["Backgrounds"] == "1":
		line_data["Backgrounds"] = "0"
		$"HBox/Clear/Backgrounds".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ red
	elif line_data["Backgrounds"] == "0":
		line_data["Backgrounds"] = "1"
		$"HBox/Clear/Backgrounds".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]	#/ green
#endregion - clear

#& EXPORT/IMPORT:
#region - Clear
func _on_path_text_changed(new_text: String) -> void:
	line_data["Path"] = new_text

func _on_con_file_text_changed(new_text: String) -> void:
	line_data["File"] = new_text

func _on_con_dictionary_text_changed(new_text: String) -> void:
	line_data["Dictionary"] = new_text

func _on_con_format_item_selected(index: int) -> void:
	var format_button = $"HBox/Con/Format"
	var format = format_button.get_item_text(index)
	line_data["Format"] = format

func _on_con_method_item_selected(index: int) -> void:
	var method_button = $"HBox/Con/Method"
	var method = method_button.get_item_text(index)
	line_data["Method"] = method

func _on_data_editor_pressed() -> void:
	main.get_node("DataEditor").visible = true
	main.get_node("DataEditor").line_data = line_data
	main.get_node("DataEditor/Data").text = $"HBox/Con/Data/Data".text
	candy_dc.condition_line = self
	candy_dc.condition_line_index = dictionary_index
	candy_dc.editor_state = "data_editor"
#endregion

#& CUSTOM:
#region - Clear
func _on_command_text_changed(new_text: String) -> void:
	line_data["Command"] = new_text

func _on_data_text_changed(new_text: String) -> void:
	line_data["Data"] = new_text
#endregion

#& SELECTION AND MOVING:
#region - Line Selection/Move
#* Called when user clicks the Move button:
func _on_move_gui_input(event: InputEvent) -> void:
	#% Ignore motion events — only handle button presses:
	if not (event is InputEventMouseButton):
		return

	if event.pressed:
		#% LEFT CLICK → selection and move logic:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if Input.is_key_pressed(KEY_ALT):
				candy_dc.alt_click_line_index = dictionary_index
				candy_dc.alt_click_move_below = Input.is_key_pressed(KEY_CTRL)
				candy_dc.alt_click_target_set.emit(dictionary_index, candy_dc.alt_click_move_below)
				return

			elif Input.is_key_pressed(KEY_ESCAPE):
				main._clear_selection()
				return

			elif Input.is_key_pressed(KEY_SHIFT):
				_select_range()
				return

			elif Input.is_key_pressed(KEY_CTRL):
				_toggle_selection()
				return

			#% Regular click (no modifiers) → select this line:
			candy_dc.selected_lines = [dictionary_index]
			candy_dc.last_clicked_line = dictionary_index
			_highlight_all_selected()


		#% RIGHT CLICK → open context menu for deleting a line:
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			candy_dc.line_right_clicked.emit(dictionary_index)
			return

#* Refresh highlight state of all lines:
func _highlight_all_selected() -> void:
	var line_list = main.get_node("VBox/HBox/WorkArea/Lines")
	for i in range(line_list.get_child_count()):
		var node = line_list.get_child(i)
		var idx = node.dictionary_index   #/ logical dictionary index of that panel
		if idx in candy_dc.selected_lines:
			node.get_node("HBox/Move").modulate = candy_dc.color_models[candy_dc.color_mode]["Selected"]
		else:
			node.get_node("HBox/Move").modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]

#* Select or deselect this line (CTRL):
func _toggle_selection() -> void:
	var idx = dictionary_index
	if idx in candy_dc.selected_lines:
		candy_dc.selected_lines.erase(idx)
		$"HBox/Move".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]  #/ restore normal color
	else:
		candy_dc.selected_lines.append(idx)
		$"HBox/Move".modulate = candy_dc.color_models[candy_dc.color_mode]["Selected"]  #/ cyan
	candy_dc.last_clicked_line = idx

#* SHIFT + Click selects a range from last clicked:
func _select_range() -> void:
	if candy_dc.last_clicked_line == -1:
		_toggle_selection()
		return

	var start = min(candy_dc.last_clicked_line, dictionary_index)
	var end = max(candy_dc.last_clicked_line, dictionary_index)
	for i in range(start, end + 1):
		if not i in candy_dc.selected_lines:
			candy_dc.selected_lines.append(i)

	#% Highlight all selected:
	_highlight_selection()

	candy_dc.last_clicked_line = dictionary_index

#* Refresh highlights for all selected lines:
func _highlight_selection() -> void:
	var line_list = main.get_node("VBox/HBox/WorkArea/Lines")
	for i in range(line_list.get_child_count()):
		var node = line_list.get_child(i)
		var idx = node.dictionary_index   #/ same fix here
		if idx in candy_dc.selected_lines:
			node.get_node("HBox/Move").modulate = candy_dc.color_models[candy_dc.color_mode]["Selected"]
		else:
			node.get_node("HBox/Move").modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
#endregion - line selection/move

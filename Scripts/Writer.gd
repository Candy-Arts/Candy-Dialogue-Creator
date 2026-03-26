extends CanvasLayer

@onready var main = get_node("/root/UI")

var line_data

var variant_name_mode = ""

var updating_progress = false
var user_dragging_progress = false
var variant_updating_progress = false
var user_variant_dragging_progress = false

var last_focused_edit: Control = null

var custom_insert_menu_mode = ""
var editing_custom_insert
var current_insert_context_index := -1

var rc_target_index: int = -1


var show_hide_lines = {
	"Comments": {
		"Hide": false,
		"Commands": ["§Comment"],
		"Color": Color(0.75, 0.75, 0.75)
	},
	"Choices": {
		"Hide": false,
		"Commands": ["§Choice_List", "§Choice_Status", "§Timer_Status"],
		"Color": Color(0.505, 0.382, 0.75)
	},
	"Input": {
		"Hide": false,
		"Commands": ["§Input", "§Mouse"],
		"Color": Color("Saddle_Brown")
	},
	"Conditions": {
		"Hide": false,
		"Commands": ["§If", "§Elif", "§Else", "§For", "§While"],
		"Color": Color(0.75, 0.375, 0.75)
	},
	"Transitions": {
		"Hide": false,
		"Commands": ["§Jump", "§Bridge", "§LM", "§Return", "§End"],
		"Color": Color(1, 0.25, 0.25)
	},
	"Controls": {
		"Hide": false,
		"Commands": ["§Call", "§Emit", "§Await", "§Set", "§Flag", "§Name", "§Role", "§Disposition", "§Export", "§Import", "§Custom"],
		"Color": Color(0.562, 0.75, 0.562)
	},
	"BG": {
		"Hide": false,
		"Commands": ["BG_Scene", "§BG", "§BG_Stop", "§BG_Remove", "§BG_Wait", "§BG_Mirror", "§BG_Effect", "§BG_Effect_Stop", "§BG_Effect_Wait"],
		"Color": Color("Teal")
	},
	"Effects": {
		"Hide": false,
		"Commands": ["§Effect", "§Effect_Stop", "§Effect_Wait", "§Wait", "§Hide", "§Clear"],
		"Color": Color("Teal")
	},
	"Audio": {
		"Hide": false,
		"Commands": ["§Audio", "§A_Volume", "§A_Wait", "§A_Pause", "§A_Resume", "§A_Skip", "§A_Stop"],
		"Color": Color(0.75, 0.0, 0.75),
	},
	"Images": {
		"Hide": false,
		"Commands": ["§Image", "§I_Pause", "§I_Wait", "§I_Resume", "§I_Show", "§I_Stop"],
		"Color": Color("Forest_Green"),
	},
	"Videos": {
		"Hide": false,
		"Commands": ["§Video", "§V_Volume", "§V_Wait", "§V_Pause", "§V_Resume", "§V_Skip", "§V_Stop", "§V_Show"],
		"Color": Color(1, 0.5, 0.25),
	},
	"VN": {
		"Hide": false,
		"Commands": ["§VN_Scene", "§VN_Bust", "§VN_Bust_Stop", "§VN_Remove", "§VN_Move", "§VN_Bust_Wait", "§VN_Mirror", "§VN_Effect", "§VN_Effect_Stop", "§VN_Effect_Wait"],
		"Color": Color(0.72, 0.75, 0.3)
	},
	"CS": {
		"Hide": false,
		"Commands": ["§CS_Scene", "§CS_Visible", "§CS_Loc", "§CS_Move", "§CS_Anim", "§CS_Anim_Wait", "§CS_Anim_Stop", "§CS_Sprite", "§CS_Sprite_Wait", "§CS_Sprite_Stop", "§CS_Cam", "§CS_Light", "§CS_Toggle"],
		"Color": Color("Dark_Slate_Gray")
	},
}


func _ready() -> void:
	#@ Hide variant UI:
	$"Main/HBox/Options/VariantOptions".visible = false
	$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant".visible = false

	#@ Configure BBCode buttons:
	for line in $"Main/HBox/RightPanel/BBCode".get_children():
		for child in line.get_children():
			#% Prevent buttons from stealing focus from the text field where BBCode tags are to be inserted:
			if child is BaseButton:
				child.focus_mode = Control.FOCUS_NONE
			#% Connect button signals:
			if child is Button:
				child.pressed.connect(_on_insert_bbcode_pressed.bind(child))

	#@ Create custom inserts:
	populate_custom_inserts()

	var popup := $"CustomInsertRC"
	popup.clear()
	popup.add_item("Edit")
	popup.add_item("Move Up")
	popup.add_item("Move Down")
	popup.add_item("Sort")
	popup.add_item("Delete")
	popup.id_pressed.connect(_on_custom_insert_context_selected)

	#@ Configure line list scrollbar:
	var scroll := $"Main/HBox/VBoxContainer/LinesList/HBox/VScrollBar"
	scroll.value_changed.connect(update_spoken_lines_list)
	scroll.value = 0

	#@ Create the right-click context menu for spoken lines:
	var line_rc := PopupMenu.new()
	line_rc.name = "LineRC"
	line_rc.add_item("Delete Line", 0)
	line_rc.id_pressed.connect(_on_line_context_selected)
	add_child(line_rc)

	#@ Connect Spoken Line Buttons once:
	var vbox := $"Main/HBox/VBoxContainer/LinesList/HBox/VBox"
	for btn in vbox.get_children():
		var btn_line = btn.get_node("HBox/ScrollContainer/Panel").get_node("Line")
		var btn_up = btn.get_node("HBox/Up")
		var btn_down = btn.get_node("HBox/Down")
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.focus_mode = Control.FOCUS_NONE

		#% Right-click → open context menu:
		btn_line.gui_input.connect(func(event):
			if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_RIGHT \
			and event.pressed:
				rc_target_index = vbox.get_children().find(btn)
				var popup_2 := get_node("LineRC")

				#% Grey out delete option if this line is currently selected:
				if candy_dc.write_line_index == rc_target_index:
					popup_2.set_item_disabled(0, true)
				else:
					popup_2.set_item_disabled(0, false)

				popup_2.set_position(get_viewport().get_mouse_position())
				popup_2.popup()
		)

		#% Normal left-click → select the line:
		btn_line.pressed.connect(func():
			if btn_line.has_meta("real_index"):
				_on_spoken_line_button_pressed(btn_line.get_meta("real_index")))

		#% Move Up and Move Down connections:
		btn_up.pressed.connect(func():
			if btn_line.has_meta("real_index"):
				_move_spoken_line(btn_line.get_meta("real_index"), "up"))

		btn_down.pressed.connect(func():
			if btn_line.has_meta("real_index"):
				_move_spoken_line(btn_line.get_meta("real_index"), "down"))

	#@ Connect the hide lines button signals:
	var hide_lines_container := $"Main/HBox/VBoxContainer/HideLines"
	for btn in hide_lines_container.get_children():
		if btn is Button:
			btn.pressed.connect(hide_show_lines.bind(btn))

	#@ Fetch the VBox containing the variant panels:
	var variant_list: VBoxContainer = $"Main/HBox/Options/VariantOptions/PanelContainer/VBox/HBox/VariantList"

	#@ Iterate through all variant panels:
	for panel in variant_list.get_children():
		var btn_variant: Button = panel.get_node("HBox/Button")
		var btn_status: Button = panel.get_node("HBox/Status")

		#@ Connect pressed() signals:
		if not btn_variant.pressed.is_connected(variant_selected):
			btn_variant.pressed.connect(variant_selected.bind(btn_variant))

		if not btn_status.pressed.is_connected(variant_toggle):
			btn_status.pressed.connect(variant_toggle.bind(btn_variant))


func _process(_delta: float) -> void:
	if updating_progress != true and user_dragging_progress != true:
		var player = main.get_node("VoicePreview")
		if player == null or not player.playing:
			return

		var progress_slider := $"Main/HBox/Options/DefaultOptions/DefaultVoiceButtons/VBoxContainer/Progress/DefaultVoiceProgress"
		var stream = player.stream
		if stream == null:
			return

		var length = stream.get_length()
		if length <= 0:
			return

		updating_progress = true
		progress_slider.value = (player.get_playback_position() / length) * 100.0
		updating_progress = false

	if variant_updating_progress != true and user_variant_dragging_progress != true:
		var player = main.get_node("VoicePreview")
		if player == null or not player.playing:
			return

		var progress_slider := $"Main/HBox/Options/DefaultOptions/DefaultVoiceButtons/VBoxContainer/Progress/DefaultVoiceProgress"
		var stream = player.stream
		if stream == null:
			return

		var length = stream.get_length()
		if length <= 0:
			return

		variant_updating_progress = true
		progress_slider.value = (player.get_playback_position() / length) * 100.0
		variant_updating_progress = false


#* Setup the Writer UI:
func setup():
	print(line_data)

	candy_dc.editor_state = "writer"

	var variants = line_data["Variants"]
	var idx = -1

	reset_variant_data()

	#% Recreate custom inserts:
	populate_custom_inserts()

	#% Setup show/hide lines:
	for l in $"Main/HBox/VBoxContainer/HideLines".get_children():
		if show_hide_lines[l.name]["Hide"] == true:
			l.modulate = Color(0.5, 0.5, 0.5)
		elif show_hide_lines[l.name]["Hide"] == false:
			l.modulate = Color(1, 1, 1)

	#% Load text for the Default variant:
	for i in range(variants.size()):
		if variants[i].has("Default"):
			idx = i
			get_node("Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Text").text = variants[i]["Default"]["Text"]
			break

	if idx == -1:
		$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Text".text = ""

	var line_speaker = line_data["Reference"]
	$"Main/HBox/WritingArea/TopBar/Index".text = "[" + str(candy_dc.write_line_index) + "]"
	$"Main/HBox/WritingArea/TopBar/Speaker/SpeakerField".text = line_speaker
	$"Main/HBox/WritingArea/TopBar/Disposition/DispositionField".text = line_data["Disposition"]

	#% LLM button:
	var llm_btn := $"Main/HBox/WritingArea/TopBar/LLM"
	match line_data.get("AI", 0):
		1:
			llm_btn.modulate = candy_dc.color_models[candy_dc.color_mode]["On"]		#/ green
		-1:
			llm_btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]		#/ red
		_:
			llm_btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]		#/ white

	#% Bubble Exempt button:
	var bubble_btn := $"Main/HBox/WritingArea/TopBar/BubbleExempt"
	if line_data.get("BubbleExempt", false):
		bubble_btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Neutral"]	#/ yellow
	else:
		bubble_btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]		#/ white

	#% Force Portrait button:
	var force_btn := $"Main/HBox/WritingArea/TopBar/ForcePortrait"
	if line_data.get("ForcePortrait", false):
		force_btn.modulate = candy_dc.color_models[candy_dc.color_mode]["On"]			#/ green
	else:
		force_btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]		#/ white


	#% Load text direction for the Default variant:
	var default_dir_button := get_node("Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Stats/TextDirection")
	var default_text_edit := get_node("Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Text")
	var default_text_preview := get_node("Main/HBox/WritingArea/Preview/DefaultPreview/Text")

	var default_direction := "ltr"
	if variants[idx]["Default"].has("Direction"):
		default_direction = variants[idx]["Default"]["Direction"]

	if default_direction == "rtl":
		default_text_preview.text_direction = TextServer.DIRECTION_RTL
		default_text_preview.layout_direction = Control.LAYOUT_DIRECTION_RTL

		default_text_edit.text_direction = TextServer.DIRECTION_RTL
		default_text_edit.layout_direction = Control.LAYOUT_DIRECTION_RTL
		#default_text_edit.text_direction = Control.TEXT_DIRECTION_RTL
		default_dir_button.text = "⇠"
	elif default_direction == "ltr":
		default_text_preview.text_direction = TextServer.DIRECTION_LTR
		default_text_preview.layout_direction = Control.LAYOUT_DIRECTION_LTR

		default_text_edit.text_direction = TextServer.DIRECTION_LTR
		default_text_edit.layout_direction = Control.LAYOUT_DIRECTION_LTR
		#default_text_edit.text_direction = Control.TEXT_DIRECTION_LTR
		default_dir_button.text = "⇢"

	#% Handle portrait:
	var portrait_name = line_data["Portrait"]
	var portrait_rect = get_node("Main/HBox/Options/DefaultOptions/PortraitPreview")
	var portraits = candy_dc.resources.get("*Portraits", {})

	$"Main/HBox/Options/DefaultOptions/Portrait/PortraitName".text = portrait_name

	if line_speaker != "" and portraits.has(line_speaker):
		var dict = portraits[line_speaker]
		var portrait_to_load = portrait_name

		#% Use "Default" portrait if none specified or missing:
		if portrait_to_load == "" or not dict.has(portrait_to_load):
			if dict.has("Default.png"):
				portrait_to_load = "Default.png"

		if dict.has(portrait_to_load):
			var path = dict[portrait_to_load]
			var img := Image.new()
			if img.load(path) == OK:
				var tex := ImageTexture.create_from_image(img)
				portrait_rect.texture_normal = tex
				portrait_rect.visible = true
			else:
				portrait_rect.texture_normal = load("res://Resources/Writer_Empty_Portrait.png")
		else:
			portrait_rect.texture_normal = load("res://Resources/Writer_Empty_Portrait.png")
	else:
		portrait_rect.texture_normal = load("res://Resources/Writer_Empty_Portrait.png")

	#await get_tree().process_frame

	$"Main/HBox/Options/DefaultOptions/VoiceFile/VoiceName".text = line_data["Voice"]

	$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Text".text = line_data["Variants"][idx]["Default"]["Text"]
	$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Text".grab_focus()

	#% Update character counters for the default text:
	var text_node: TextEdit = $"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Text"
	var writer_text: String = text_node.text
	var total_chars := writer_text.length()
	var remaining = candy_dc.spoken_line_limit - total_chars

	$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Stats/Total/Number".text = str(total_chars)
	$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Stats/Limit/Number".text = str(remaining)

	if remaining < 0:
		$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Stats/Limit/Number".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]	#/ Red = too long
	elif remaining <= candy_dc.spoken_line_near_limit:
		$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Stats/Limit/Number".modulate = candy_dc.color_models[candy_dc.color_mode]["Neutral"]	#/ Yellow = close
	else:
		$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Stats/Limit/Number".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]	#/ Green = safe

	#% Load DevCom variant into Writer/DevCom:
	for variant_dict in variants:
		if variant_dict.has("DevCom"):
			$"Main/HBox/WritingArea/SplitSpeechComments/DevCom".text = variant_dict["DevCom"]["Text"]
			break

	#% Update preview:
	$"Main/HBox/WritingArea/Preview/DefaultPreview/Text".text = writer_text

	#await get_tree().process_frame

	#% Load text direction for this variant:
	if candy_dc.write_variant != "":
		var dir_button := get_node("Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Stats/TextDirection")
		var text_edit := get_node("Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Text")
		var text_preview := get_node("Main/HBox/WritingArea/Preview/VariantPreview/Text")

		var direction := "ltr"
		for variant_dict in variants:
			if variant_dict.has(candy_dc.write_variant):
				var data = variant_dict[candy_dc.write_variant]
				direction = data["Direction"]
				text_edit.text = data["Text"]
				text_preview.text = text_edit.text
				break

		if direction == "rtl":
			text_preview.text_direction = TextServer.DIRECTION_RTL
			text_preview.layout_direction = Control.LAYOUT_DIRECTION_RTL

			text_edit.text_direction = TextServer.DIRECTION_RTL
			text_edit.layout_direction = Control.LAYOUT_DIRECTION_RTL
			#text_edit.text_direction = Control.TEXT_DIRECTION_RTL
			dir_button.text = "⇠"
		elif direction == "ltr":
			text_preview.text_direction = TextServer.DIRECTION_LTR
			text_preview.layout_direction = Control.LAYOUT_DIRECTION_LTR

			text_edit.text_direction = TextServer.DIRECTION_LTR
			text_edit.layout_direction = Control.LAYOUT_DIRECTION_LTR
			#text_edit.text_direction = Control.TEXT_DIRECTION_LTR
			dir_button.text = "⇢"

	#% Grey out Next and Previous buttons:
	$"Main/HBox/WritingArea/NavButtons/PreviousLine".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
	$"Main/HBox/WritingArea/NavButtons/NextLine".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
	if candy_dc.write_line_index == 0:
		$"Main/HBox/WritingArea/NavButtons/PreviousLine".modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]
	if candy_dc.write_line_index + 1 == candy_dc.conversations[candy_dc.current_conversation][candy_dc.current_block]["Text"].size():
		$"Main/HBox/WritingArea/NavButtons/NextLine".modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]

	#% Refresh line list:
	update_spoken_lines_list()

	#% Refresh variant list:
	update_variant_list()


#* When text input areas are focused:
func _on_edit_focus_entered() -> void:
	last_focused_edit = get_viewport().gui_get_focus_owner()


#* Close writer window:
func _on_enter_pressed() -> void:
	candy_dc.editor_state = "ui"

	$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Text".text = ""
	$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Text".text = ""
	$"Main/HBox/WritingArea/TopBar/Index".text = ""
	$"Main/HBox/WritingArea/TopBar/Speaker/SpeakerField".text = ""
	$"Main/HBox/WritingArea/TopBar/Disposition/DispositionField".text = ""
	$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Stats/Total/Number".text = ""
	$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Stats/Limit/Number".text = ""
	$"Main/HBox/Options/DefaultOptions/PortraitPreview".texture_normal = null
	$"Main/HBox/Options/DefaultOptions/Portrait/PortraitName".text = ""
	self.visible = false

	#% Stop voice play:
	if main.get_node("VoicePreview").playing or main.get_node("VoicePreview").stream_paused:
		main.get_node("VoicePreview").stop()
	if main.get_node("VariantVoicePreview").playing or main.get_node("VariantVoicePreview").stream_paused:
		main.get_node("VariantVoicePreview").stop()

	main._update_visible_lines()


#* Update text data and character counters in the Writer window:
func _on_default_text_changed() -> void:
	var text_node: TextEdit = $"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Text"
	var writer_text: String = text_node.text

	$"Main/HBox/WritingArea/Preview/DefaultPreview/Text".text = writer_text

	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return
	if candy_dc.write_line_index < 0:
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]
	if candy_dc.write_line_index >= lines.size():
		return

	#% Update the main data:
	var variants = line_data["Variants"]
	for i in range(variants.size()):
		if variants[i].has("Default"):
			variants[i]["Default"]["Text"] = writer_text
			break
	line_data["Variants"] = variants
	lines[candy_dc.write_line_index]["Spoken Line"] = line_data
	block["Text"] = lines
	conv[candy_dc.current_block] = block
	candy_dc.conversations[candy_dc.current_conversation] = conv

	#% Update UI counts:
	var total_chars := count_visible_chars(writer_text)
	var remaining = candy_dc.spoken_line_limit - total_chars
	$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Stats/Total/Number".text = str(total_chars)
	$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Stats/Limit/Number".text = str(remaining)
	if remaining < 0:
		$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Stats/Limit/Number".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]
	elif remaining <= candy_dc.spoken_line_near_limit:
		$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Stats/Limit/Number".modulate = candy_dc.color_models[candy_dc.color_mode]["Neutral"]
	else:
		$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Stats/Limit/Number".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]

	#% Refresh variant list:
	update_spoken_lines_list()


#* Play Default voice preview:
func _on_play_voice_pressed() -> void:
	var voice_error_label := $"Main/HBox/Options/DefaultOptions/VoiceError"
	voice_error_label.text = ""   #/ Clear previous error

	var player = main.get_node("VoicePreview")

	#% Resume or pause:
	if player.stream_paused:
		player.stream_paused = false
		return
	if player.playing:
		main.get_node("VoicePreview").stream_paused = true
		return

	var voice_name: String = line_data["Voice"]
	var speaker: String = line_data["Reference"]
	var role: bool = line_data["Reference"].begins_with(candy_dc.role_symbol)

	#% Validation:
	if role:
		return		#/ Role lines never play voices

	if speaker == "":
		voice_error_label.text = "No speaker assigned."
		await get_tree().create_timer(3.0).timeout
		voice_error_label.text = ""
		return

	if voice_name == "":
		voice_error_label.text = "No file selected."
		await get_tree().create_timer(3.0).timeout
		voice_error_label.text = ""
		return

	#% Navigate nested dictionary (Talks/Speaker/Conversation/Block):
	if not (candy_dc.resources.has("*Voices")
	and candy_dc.resources["*Voices"].has(speaker)
	and candy_dc.resources["*Voices"][speaker].has(candy_dc.current_conversation)
	and candy_dc.resources["*Voices"][speaker][candy_dc.current_conversation].has(candy_dc.current_block)):
		voice_error_label.text = "File not found."
		await get_tree().create_timer(3.0).timeout
		voice_error_label.text = ""
		return

	var block_dict = candy_dc.resources["*Voices"][speaker][candy_dc.current_conversation][candy_dc.current_block]
	if not block_dict.has(voice_name):
		voice_error_label.text = "File not found."
		await get_tree().create_timer(3.0).timeout
		voice_error_label.text = ""
		return

	var path: String = block_dict[voice_name]
	if not FileAccess.file_exists(path):
		voice_error_label.text = "File not found."
		await get_tree().create_timer(3.0).timeout
		voice_error_label.text = ""
		return

	#% Load and play:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		voice_error_label.text = "File could not be opened."
		await get_tree().create_timer(3.0).timeout
		voice_error_label.text = ""
		return

	var stream := AudioStreamMP3.new()
	stream.data = file.get_buffer(file.get_length())
	player.stream = stream
	player.play()

#* Pause Default voice preview:
func _on_pause_voice_pressed() -> void:
	if main.get_node("VoicePreview").playing:
		main.get_node("VoicePreview").stream_paused = true


#* Play Variant voice preview:
func _on_variant_play_voice_pressed() -> void:
	var voice_error_label := $"Main/HBox/Options/VariantOptions/VariantVoiceError"
	voice_error_label.text = ""		#/ Clear previous error

	var player = main.get_node("VariantVoicePreview")

	#% No variant selected:
	if candy_dc.write_variant == "":
		voice_error_label.text = "No variant selected."
		await get_tree().create_timer(3.0).timeout
		voice_error_label.text = ""
		return

	#% Resume or pause:
	if player.stream_paused:
		player.stream_paused = false
		return
	if player.playing:
		main.get_node("VariantVoicePreview").stream_paused = true
		return

	var voice_name: String = line_data["Voice"]
	var speaker: String = line_data["Reference"]
	var role: bool = line_data["Reference"].begins_with(candy_dc.role_symbol)

	#% Validation:
	if role:
		return   #/ Role lines never play voices

	if speaker == "":
		voice_error_label.text = "No speaker assigned."
		await get_tree().create_timer(3.0).timeout
		voice_error_label.text = ""
		return

	if voice_name == "":
		voice_error_label.text = "No file selected."
		await get_tree().create_timer(3.0).timeout
		voice_error_label.text = ""
		return

	#% Navigate nested dictionary (Talks/Speaker/Conversation/Block):
	if not (candy_dc.resources.has("*Voices")
	and candy_dc.resources["*Voices"].has(speaker)
	and candy_dc.resources["*Voices"][speaker].has(candy_dc.current_conversation)
	and candy_dc.resources["*Voices"][speaker][candy_dc.current_conversation].has(candy_dc.current_block)
	and candy_dc.resources["*Voices"][speaker][candy_dc.current_conversation][candy_dc.current_block].has(candy_dc.write_variant)):
		voice_error_label.text = "File not found."
		await get_tree().create_timer(3.0).timeout
		voice_error_label.text = ""
		return

	var variant_dict = candy_dc.resources["*Voices"][speaker][candy_dc.current_conversation][candy_dc.current_block][candy_dc.write_variant]
	if not variant_dict.has(voice_name):
		voice_error_label.text = "File not found."
		await get_tree().create_timer(3.0).timeout
		voice_error_label.text = ""
		return

	var path: String = variant_dict[voice_name]
	if not FileAccess.file_exists(path):
		voice_error_label.text = "File not found."
		await get_tree().create_timer(3.0).timeout
		voice_error_label.text = ""
		return

	#% Load and play:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		voice_error_label.text = "File could not be opened."
		await get_tree().create_timer(3.0).timeout
		voice_error_label.text = ""
		return

	var stream := AudioStreamMP3.new()
	stream.data = file.get_buffer(file.get_length())
	player.stream = stream
	player.play()

#* Pause Variant voice preview:
func _on_variant_pause_voice_pressed() -> void:
	if main.get_node("VariantVoicePreview").playing:
		main.get_node("VariantVoicePreview").stream_paused = true


#* Update variant speech text:
func _on_variant_text_changed() -> void:
	if candy_dc.write_variant == "":
		return

	#% Access the current line in candy_dc.conversations:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]

	if candy_dc.write_line_index < 0 or candy_dc.write_line_index >= lines.size():
		return

	var variants = line_data["Variants"]

	#% Get variant text:
	var variant_text_node = $"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Text"
	var variant_text = variant_text_node.text

	$"Main/HBox/WritingArea/Preview/VariantPreview/Text".text = variant_text

	#% Save the text to the global data:
	for variant_dict in variants:
		if variant_dict.has(candy_dc.write_variant):
			variant_dict[candy_dc.write_variant]["Text"] = variant_text
			break

	update_variant_counts()

	#% Write back to candy_dc.conversations:
	line_data["Variants"] = variants
	lines[candy_dc.write_line_index]["Spoken Line"] = line_data
	block["Text"] = lines
	conv[candy_dc.current_block] = block
	candy_dc.conversations[candy_dc.current_conversation] = conv

	#% Refresh line list:
	update_spoken_lines_list()


#* Update character, limit, and word counters for variants:
func update_variant_counts():
	var variants = line_data["Variants"]
	var variant_text_node = $"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Text"
	var variant_text = variant_text_node.text

	#% Variant character counts:
	var total_chars := count_visible_chars(variant_text)
	var remaining = candy_dc.spoken_line_limit - total_chars

	$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Stats/2/Total/Number".text = str(total_chars)

	var diff_label := $"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Stats/2/Limit/Number"
	diff_label.text = str(remaining)

	if remaining < 0:
		diff_label.modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]			#/ Red
	elif remaining <= candy_dc.spoken_line_near_limit:
		diff_label.modulate = candy_dc.color_models[candy_dc.color_mode]["Neutral"]		#/ Yellow
	else:
		diff_label.modulate = candy_dc.color_models[candy_dc.color_mode]["On"]			#/ Green

	#% Difference from the Default variant:
	var default_text = ""
	for variant_dict in variants:
		if variant_dict.has("Default"):
			default_text = variant_dict["Default"]["Text"]
			break

	var default_length = default_text.length()
	var diff_from_default = total_chars - default_length
	var diff_from_default_label = $"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Stats/1/Characters/Number"

	if diff_from_default == 0:
		diff_from_default_label.text = "±0"
		diff_from_default_label.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]		#/ White
	elif diff_from_default > 0:
		diff_from_default_label.text = "+" + str(diff_from_default)
		diff_from_default_label.modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]		#/ Red
	else:
		diff_from_default_label.text = str(diff_from_default)
		diff_from_default_label.modulate = candy_dc.color_models[candy_dc.color_mode]["On"]		#/ Green

	#% Word difference compared to Default:
	var default_words = default_text.split(" ", false).size()
	var variant_words = variant_text.split(" ", false).size()
	var diff_words = variant_words - default_words
	var diff_label_words = $"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Stats/1/Words/Number"

	if diff_words == 0:
		diff_label_words.text = "±0"
		diff_label_words.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]	#/ White
	elif diff_words > 0:
		diff_label_words.text = "+" + str(diff_words)
		diff_label_words.modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]		#/ Red
	else:
		diff_label_words.text = str(diff_words)
		diff_label_words.modulate = candy_dc.color_models[candy_dc.color_mode]["On"]		#/ Green


#* Filter Mode toggle:
func _on_filter_mode_pressed() -> void:
	if candy_dc.variant_filter_mode == "Restrict":
		candy_dc.variant_filter_mode = "Exclude"
		$"Main/HBox/Options/VariantOptions/FiltersL1/FilterMode".text = "Exclude"
	elif candy_dc.variant_filter_mode == "Exclude":
		candy_dc.variant_filter_mode = "Restrict"
		$"Main/HBox/Options/VariantOptions/FiltersL1/FilterMode".text = "Restrict"

	#% Refresh variant list:
	update_variant_list()

	#% Refresh line list:
	update_spoken_lines_list()

#* Filter Match toggle:
func _on_filter_match_pressed() -> void:
	if candy_dc.variant_filter_match == "Exact":
		candy_dc.variant_filter_match = "Loose"
		$"Main/HBox/Options/VariantOptions/FiltersL1/FilterMatch".text = "Loose"
	elif candy_dc.variant_filter_match == "Loose":
		candy_dc.variant_filter_match = "Exact"
		$"Main/HBox/Options/VariantOptions/FiltersL1/FilterMatch".text = "Exact"

	#% Refresh variant list:
	update_variant_list()

	#% Refresh line list:
	update_spoken_lines_list()

#* Show variant options:
func _on_show_variants_toggle_pressed() -> void:
	if candy_dc.variant_show == true:
		candy_dc.variant_show = false
		$"Main/HBox/Options/DefaultOptions/VariantToggle/ShowVariantsToggle".text = ""
		$"Main/HBox/Options/VariantOptions".visible = false
		$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant".visible = false
		$"Main/HBox/WritingArea/Preview/VariantPreview".visible = false
	elif candy_dc.variant_show == false:
		candy_dc.variant_show = true
		$"Main/HBox/Options/DefaultOptions/VariantToggle/ShowVariantsToggle".text = "✕"
		$"Main/HBox/Options/VariantOptions".visible = true
		$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant".visible = true
		$"Main/HBox/WritingArea/Preview/VariantPreview".visible = true

	#% Refresh variant list:
	update_variant_list()

	#% Refresh line list:
	update_spoken_lines_list()


#* Filter keywords:
func _on_filters_text_changed(new_text: String) -> void:
	#% Split on commas and strip spaces:
	var filter_array: Array = []
	for item in new_text.split(",", false):
		var trimmed = item.strip_edges()
		if trimmed != "":
			filter_array.append(trimmed)

	candy_dc.variant_filter = filter_array

	#% Refresh variant list:
	update_variant_list()

	#% Refresh line list:
	update_spoken_lines_list()


#* Change variant weight:
func _on_variant_weight_changed(new_text):
	if candy_dc.write_variant == "":
		return

	#% Access the current line in candy_dc.conversations:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]

	if candy_dc.write_line_index < 0 or candy_dc.write_line_index >= lines.size():
		return

	var variants = line_data["Variants"]

	#% Save the text to the global data:
	for variant_dict in variants:
		if variant_dict.has(candy_dc.write_variant):
			variant_dict[candy_dc.write_variant]["Weight"] = new_text
			break

	#% Write back to candy_dc.conversations:
	line_data["Variants"] = variants
	lines[candy_dc.write_line_index]["Spoken Line"] = line_data
	block["Text"] = lines
	conv[candy_dc.current_block] = block
	candy_dc.conversations[candy_dc.current_conversation] = conv

	#% Refresh line list:
	update_spoken_lines_list()


#* Toggle writing direction for the active variant:
func _on_variant_text_direction_pressed() -> void:
	var btn := $"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Stats/TextDirection"
	var text_edit := $"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Text"
	var text_preview := $"Main/HBox/WritingArea/Preview/VariantPreview/Text"

	#@ Safety checks:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return
	if candy_dc.write_line_index < 0:
		return
	if candy_dc.write_variant == "":
		return

	#@ Fetch current line:
	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]
	if candy_dc.write_line_index >= lines.size():
		return

	#@ Ensure Variants array exists:
	if not line_data.has("Variants"):
		return
	var variants = line_data["Variants"]

	#@ Find the variant currently being written:
	var variant_name = candy_dc.write_variant
	var variant_data = null
	var variant_entry = null

	for entry in variants:
		if entry.has(variant_name):
			variant_data = entry[variant_name]
			variant_entry = entry
			break
	if variant_data == null:
		return

	#@ Toggle between "ltr" and "rtl" (treat "default" as ltr):
	var current_dir = variant_data.get("Direction", "default")
	var new_dir := ""
	var new_symbol := ""

	if current_dir == "rtl":
		new_dir = "ltr"
		new_symbol = "⇢"
	else:
		new_dir = "rtl"
		new_symbol = "⇠"

	#@ Update button label:
	btn.text = new_symbol

	#@ Apply direction immediately to TextEdit:
	if new_dir == "rtl":
		text_preview.text_direction = TextServer.DIRECTION_RTL
		text_preview.layout_direction = Control.LAYOUT_DIRECTION_RTL

		text_edit.text_direction = TextServer.DIRECTION_RTL
		text_edit.layout_direction = Control.LAYOUT_DIRECTION_RTL
		#text_edit.text_direction = Control.TEXT_DIRECTION_RTL
	elif new_dir == "ltr":
		text_preview.text_direction = TextServer.DIRECTION_LTR
		text_preview.layout_direction = Control.LAYOUT_DIRECTION_LTR

		text_edit.text_direction = TextServer.DIRECTION_LTR
		text_edit.layout_direction = Control.LAYOUT_DIRECTION_LTR
		#text_edit.text_direction = Control.TEXT_DIRECTION_LTR

	#@ Save direction to variant data:
	variant_data["Direction"] = new_dir
	variant_entry[variant_name] = variant_data

	#@ Reinsert modified variant:
	for i in range(variants.size()):
		if variants[i].has(variant_name):
			variants[i] = variant_entry
			break

	line_data["Variants"] = variants
	lines[candy_dc.write_line_index]["Spoken Line"] = line_data
	block["Text"] = lines
	conv[candy_dc.current_block] = block
	candy_dc.conversations[candy_dc.current_conversation] = conv

	#% Refresh variant list:
	update_variant_list()


#* Update Comment text:
func _on_dev_com_text_changed() -> void:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return
	if candy_dc.write_line_index < 0:
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]

	if candy_dc.write_line_index >= lines.size():
		return

	var variants = line_data["Variants"]

	var comment_text_node = get_node("Main/HBox/WritingArea/SplitSpeechComments/DevCom")

	#@ Update the DevCom variant text:
	for variant_dict in variants:
		if variant_dict.has("DevCom"):
			variant_dict["DevCom"]["Text"] = comment_text_node.text
			break

	#@ Write back to candy_dc.conversations:
	line_data["Variants"] = variants
	lines[candy_dc.write_line_index]["Spoken Line"] = line_data
	block["Text"] = lines
	conv[candy_dc.current_block] = block
	candy_dc.conversations[candy_dc.current_conversation] = conv

#* Switch to previous spoken line:
func _on_previous_line_pressed() -> void:
	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]

	var idx = candy_dc.write_line_index
	if idx <= 0:
		return		#/ No previous line.

	#% Stop voice play:
	if main.get_node("VoicePreview").playing or main.get_node("VoicePreview").stream_paused:
		main.get_node("VoicePreview").stop()
	if main.get_node("VariantVoicePreview").playing or main.get_node("VariantVoicePreview").stream_paused:
		main.get_node("VariantVoicePreview").stop()

	for i in range(idx - 1, -1, -1):
		if lines[i].has("Spoken Line"):
			line_data = lines[i]["Spoken Line"]
			candy_dc.write_line_index = i
			reset_variant_data()
			setup()
			return


#* Switch to next spoken line:
func _on_next_line_pressed() -> void:
	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]

	var idx = candy_dc.write_line_index
	if idx >= lines.size() - 1:
		return		#/ Already at end

	#% Stop voice play:
	if main.get_node("VoicePreview").playing or main.get_node("VoicePreview").stream_paused:
		main.get_node("VoicePreview").stop()
	if main.get_node("VariantVoicePreview").playing or main.get_node("VariantVoicePreview").stream_paused:
		main.get_node("VariantVoicePreview").stop()

	for i in range(idx + 1, lines.size()):
		if lines[i].has("Spoken Line"):
			line_data = lines[i]["Spoken Line"]
			candy_dc.write_line_index = i
			reset_variant_data()
			setup()
			return


#* Reset character stats for variants:
func reset_variant_data():
	$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Text".text = ""
	$"Main/HBox/WritingArea/Preview/VariantPreview/Text".text = ""
	$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Stats/2/Total/Number".text = "0"
	$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Stats/2/Limit/Number".text = str(candy_dc.spoken_line_limit)
	$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Stats/2/Limit/Number".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]	#/ Green
	$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Stats/1/Characters/Number".text = ""
	$"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Stats/1/Words/Number".text = ""

#* Play voice file for the currently selected variant:
func _on_play_voice_variant_pressed() -> void:
	var error_label := $"Main/HBox/Options/VariantOptions/VariantVoiceError"
	error_label.text = ""

	var player = main.get_node("VoicePreview")

	#% Resume or restart if paused:
	if player.stream_paused:
		player.stream_paused = false
		return
	if player.playing:
		player.stop()

	var voice_name: String = line_data["Voice"]
	var speaker: String = line_data["Reference"]
	var role: bool = line_data["Reference"].begins_with(candy_dc.role_symbol)
	var variant: String = candy_dc.write_variant

	#% Validation:
	if role:
		return
	if speaker == "":
		error_label.text = "No speaker assigned."
		await get_tree().create_timer(3.0).timeout
		error_label.text = ""
		return
	if variant == "" or variant == "Default":
		error_label.text = "No variant selected."
		await get_tree().create_timer(3.0).timeout
		error_label.text = ""
		return
	if voice_name == "":
		error_label.text = "No file selected."
		await get_tree().create_timer(3.0).timeout
		error_label.text = ""
		return

	#% Navigate nested dictionary (Talks/Speaker/Conversation/Block):
	if not (candy_dc.resources.has("*Voices")
	and candy_dc.resources["*Voices"].has(speaker)
	and candy_dc.resources["*Voices"][speaker].has(candy_dc.current_conversation)
	and candy_dc.resources["*Voices"][speaker][candy_dc.current_conversation].has(candy_dc.current_block)):
		error_label.text = "File not found."
		await get_tree().create_timer(3.0).timeout
		error_label.text = ""
		return

	var block_dict = candy_dc.resources["*Voices"][speaker][candy_dc.current_conversation][candy_dc.current_block]
	if not block_dict.has(voice_name):
		error_label.text = "File not found."
		await get_tree().create_timer(3.0).timeout
		error_label.text = ""
		return

	var path: String = block_dict[voice_name]
	if not FileAccess.file_exists(path):
		error_label.text = "File not found."
		await get_tree().create_timer(3.0).timeout
		error_label.text = ""
		return

	#% Load and play:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		error_label.text = "File could not be opened."
		await get_tree().create_timer(3.0).timeout
		error_label.text = ""
		return

	var stream := AudioStreamMP3.new()
	stream.data = file.get_buffer(file.get_length())
	player.stream = stream
	player.play()


#* Pause playback of variant voice:
func _on_pause_voice_variant_pressed() -> void:
	if main.get_node("VoicePreview").playing:
		main.get_node("VoicePreview").stream_paused = true


#* Stop playback of variant voice:
func _on_stop_voice_variant_pressed() -> void:
	if main.get_node("VoicePreview").playing or main.get_node("VoicePreview").stream_paused:
		main.get_node("VoicePreview").stop()


#* Add a new spoken line immediately after the line being edited:
func _on_add_line_pressed() -> void:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return
	if candy_dc.write_line_index < 0:
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]

	#@ Create wrapped spoken line dictionary using the template:
	var payload = candy_dc.command_templates["Spoken Line"].duplicate(true)
	var new_line := {"Spoken Line": payload}

	#@ Detect modifiers:
	var ctrl := Input.is_key_pressed(KEY_CTRL)
	var shift := Input.is_key_pressed(KEY_SHIFT)

	var insert_index = candy_dc.write_line_index + 1		#/ Default → after current
	var insert_before := false

	#% CTRL+Click → insert BEFORE:
	if ctrl and not shift:
		insert_before = true
		insert_index = candy_dc.write_line_index

	#% SHIFT+Click → add at END:
	elif shift and not ctrl:
		insert_index = lines.size()

	#% CTRL+SHIFT+Click → add at START:
	elif ctrl and shift:
		insert_before = true
		insert_index = 0

	insert_index = clamp(insert_index, 0, lines.size())

	lines.insert(insert_index, new_line)

	#@ Write back to globals:
	block["Text"] = lines
	conv[candy_dc.current_block] = block
	candy_dc.conversations[candy_dc.current_conversation] = conv

	main.save_undo_step()

	#@ Refresh displays:
	main._update_visible_lines()
	apply_writer_scroll_limits()

	#@ Adjust scrollbar position (follow inserted line):
	var scroll := $"Main/HBox/VBoxContainer/LinesList/HBox/VScrollBar"

	if insert_before:
		scroll.value = clamp(scroll.value - 1, scroll.min_value, scroll.max_value)
	elif insert_index == lines.size() - 1:
		scroll.value = scroll.max_value
	else:
		scroll.value = clamp(scroll.value + 1, scroll.min_value, scroll.max_value)

	#@ Move to the new line:
	if ctrl and shift:
		candy_dc.write_line_index = 0
	elif shift and not ctrl:
		candy_dc.write_line_index = lines.size() - 2	#+ -2 instead of -1 because _on_next_line_pressed() doesn't work when at the last line.

	_on_next_line_pressed()
	if insert_before:
		#+ Note for devs, since this may seem paradoxical at first glance:
		#+ If the new line is inserted before, we normally wouldn't change line/index;
		#+ However, we must call do _on_next_line_pressed() or _on_previous_line_pressed() to ensure the UI and internal data are updated correctly;
		#+ _on_next_line_pressed() then _on_previous_line_pressed() updates the data/UI and returns us to the new inserted line.
		_on_previous_line_pressed()

	#% Refresh variant list:
	update_variant_list()

	#% Refresh line list:
	update_spoken_lines_list()


#* Called when the user edits the speaker reference in the Writer:
func _on_speaker_text_changed(new_text: String) -> void:
	#@ Update local line data:
	line_data["Reference"] = new_text

	#@ Update global structure:
	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]
	if candy_dc.write_line_index >= lines.size():
		return
	lines[candy_dc.write_line_index]["Spoken Line"] = line_data
	block["Text"] = lines
	conv[candy_dc.current_block] = block
	candy_dc.conversations[candy_dc.current_conversation] = conv

	#@ Refresh portrait display:
	var portrait_rect = get_node("Main/HBox/Options/DefaultOptions/PortraitPreview")
	var portraits = candy_dc.resources.get("*Portraits", {})
	var portrait_name = line_data["Portrait"]

	if new_text.strip_edges() == "" or new_text.begins_with(candy_dc.role_symbol):
		portrait_rect.texture_normal = load("res://Resources/Writer_Empty_Portrait.png")
		update_spoken_lines_list()
		return

	if portraits.has(new_text):
		var dict = portraits[new_text]
		var portrait_to_load = portrait_name

		if portrait_to_load == "" or not dict.has(portrait_to_load):
			if dict.has("Default.png"):
				portrait_to_load = "Default.png"

		if dict.has(portrait_to_load):
			var path = dict[portrait_to_load]
			var img := Image.new()
			if img.load(path) == OK:
				var tex := ImageTexture.create_from_image(img)
				portrait_rect.texture_normal = tex
				portrait_rect.visible = true
				update_spoken_lines_list()
				return

	#% Fallback - no portrait found:
	portrait_rect.texture_normal = load("res://Resources/Writer_Empty_Portrait.png")

	update_spoken_lines_list()


#* Toggle animated portrait autoplay setting:
func _on_portrait_play_pressed() -> void:
	var p_play_btn = get_node("Main/HBox/Options/DefaultOptions/Portrait/Play")
	if line_data["PortraitPlay"] == "0":
		line_data["PortraitPlay"] = "1"
		p_play_btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]

	elif line_data["PortraitPlay"] == "1":
		line_data["PortraitPlay"] = "0"
		p_play_btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]

#* Called when the user edits the portrait name in the Writer:
func _on_portrait_name_text_changed(new_text: String) -> void:
	var portrait_rect

	#@ Validate editing context:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return
	if candy_dc.write_line_index < 0:
		return

	#@ Update local line data:
	line_data["Portrait"] = new_text.strip_edges()

	#@ Write back to globals:
	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]
	if candy_dc.write_line_index >= lines.size():
		return
	lines[candy_dc.write_line_index]["Spoken Line"] = line_data
	block["Text"] = lines
	conv[candy_dc.current_block] = block
	candy_dc.conversations[candy_dc.current_conversation] = conv

	#@ Portrait update:
	#% Skip portrait display if this is a Role line:
	if line_data.get("Reference", "").begins_with(candy_dc.role_symbol):
		portrait_rect = get_node("Main/HBox/Options/DefaultOptions/PortraitPreview")
		portrait_rect.texture_normal_normal = "res://Resources/Writer_Empty_Portrait.png"
		return

	#% Refresh portrait display:
	portrait_rect = get_node("Main/HBox/Options/DefaultOptions/PortraitPreview")
	var speaker: String = line_data.get("Reference", "").strip_edges()
	var portrait_name: String = new_text.strip_edges()
	var portraits = candy_dc.resources.get("*Portraits", {})

	#% No speaker means we can’t look up portraits:
	if speaker == "" or speaker.begins_with(candy_dc.role_symbol):
		portrait_rect.texture_normal = load("res://Resources/Writer_Empty_Portrait.png")
		return

	if portraits.has(speaker):
		var dict = portraits[speaker]
		var portrait_to_load = portrait_name

		#% Load portrait image if found:
		if dict.has(portrait_to_load):
			var path = dict[portrait_to_load]
			var img := Image.new()
			if img.load(path) == OK:
				var tex := ImageTexture.create_from_image(img)
				portrait_rect.texture_normal = tex
				portrait_rect.visible = true
				return

	#% If no valid portrait found → hide it:
	portrait_rect.texture_normal = load("res://Resources/Writer_Empty_Portrait.png")


#* Open portrait selection menu:
func _on_portrait_pressed() -> void:
	var grid := $"PortraitsGrid/Grid"
	var speaker = line_data.get("Reference", "").strip_edges()

	if speaker == "" or speaker.begins_with(candy_dc.role_symbol):
		return

	$"PortraitsBG".visible = true
	$"PortraitsGrid".visible = true
	$"SelectPortrait".visible = true

	#@ Clear previous thumbnails:
	for c in grid.get_children():
		c.queue_free()

	#@ Access portrait dictionary for this speaker:
	var portraits_dict = candy_dc.resources.get("*Portraits", {}).get(speaker, {})
	if portraits_dict.is_empty():
		return

	#@ Create one entry (TextureRect + Label) per portrait file:
	for portrait_name in portraits_dict.keys():
		var container := Button.new()
		container.custom_minimum_size = Vector2(192, 216)
		container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		container.flat = true
		container.focus_mode = Control.FOCUS_NONE

		#% Load portrait texture:
		var tex_rect := TextureRect.new()
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(192, 192)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var img := Image.new()
		var path = portraits_dict[portrait_name]
		if typeof(path) != TYPE_STRING:
			continue
		if FileAccess.file_exists(path) and img.load(path) == OK:
			var tex := ImageTexture.create_from_image(img)
			tex_rect.texture = tex

		#% Label below the image:
		var label := Label.new()
		label.text = portrait_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(192, 24)
		label.position = Vector2(0, 192)
		label.add_theme_color_override("font_color", candy_dc.color_models[candy_dc.color_mode]["Null"])

		#% Add children:
		container.add_child(tex_rect)
		container.add_child(label)
		grid.add_child(container)

		#% Connect click:
		container.pressed.connect(func():
			_apply_selected_portrait(portrait_name))


#* Called when a portrait thumbnail is clicked:
func _apply_selected_portrait(portrait_name: String) -> void:
	#@ Update line data:
	line_data["Portrait"] = portrait_name

	#@ Write back to globals:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return
	if candy_dc.write_line_index < 0:
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]
	if candy_dc.write_line_index >= lines.size():
		return
	lines[candy_dc.write_line_index]["Spoken Line"] = line_data
	block["Text"] = lines
	conv[candy_dc.current_block] = block
	candy_dc.conversations[candy_dc.current_conversation] = conv

	#@ Update Writer UI:
	$"Main/HBox/Options/DefaultOptions/Portrait/PortraitName".text = portrait_name

	#@ Display the selected portrait in the Writer preview:
	var portraits = candy_dc.resources.get("*Portraits", {})
	var speaker = line_data.get("Reference", "").strip_edges()
	var portrait_rect = get_node("Main/HBox/Options/DefaultOptions/PortraitPreview")

	if speaker != "" and not speaker.begins_with(candy_dc.role_symbol) and portraits.has(speaker) and portraits[speaker].has(portrait_name):
		var path = portraits[speaker][portrait_name]
		var img := Image.new()
		if FileAccess.file_exists(path) and img.load(path) == OK:
			var tex := ImageTexture.create_from_image(img)
			portrait_rect.texture_normal = tex
			portrait_rect.visible = true
		else:
			portrait_rect.texture_normal = load("res://Resources/Writer_Empty_Portrait.png")

	else:
		portrait_rect.texture_normal = load("res://Resources/Writer_Empty_Portrait.png")

	#@ Close the portrait menu:
	_on_select_portrait_pressed()


#* Apply selected portrait and close portrait menu:
func _on_select_portrait_pressed() -> void:
	$"PortraitsBG".visible = false
	$"PortraitsGrid".visible = false
	$"SelectPortrait".visible = false

	#@ Clear portraits from grid:
	var grid := $"PortraitsGrid/Grid"
	for c in grid.get_children():
		c.queue_free()


#* Called when the user edits the disposition field in the Writer:
func _on_disposition_text_changed(new_text: String) -> void:
	#@ Validate editing context:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return
	if candy_dc.write_line_index < 0:
		return

	#@ Update local line data:
	line_data["Disposition"] = new_text.strip_edges()

	#@ Write back to globals:
	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]
	if candy_dc.write_line_index >= lines.size():
		return
	lines[candy_dc.write_line_index]["Spoken Line"] = line_data
	block["Text"] = lines
	conv[candy_dc.current_block] = block
	candy_dc.conversations[candy_dc.current_conversation] = conv

	update_spoken_lines_list()


#* Show the disposition list popup (delegates to main):
func _on_disposition_select_pressed() -> void:
	var field: LineEdit = $"Main/HBox/WritingArea/TopBar/Disposition/DispositionField"
	main.open_disposition_menu(self, field)


#* Show the reference list popup (delegates to main):
func _on_reference_select_pressed() -> void:
	var field: LineEdit = $"Main/HBox/WritingArea/TopBar/Speaker/SpeakerField"
	var role = false
	if field.text.begins_with(candy_dc.role_symbol):
		role = true
	main.open_reference_menu(self, field, role)


func _apply_selected_disposition(disposition: String) -> void:
	$"Main/HBox/WritingArea/TopBar/Disposition/DispositionField".text += disposition + ", "
	line_data["Disposition"] = $"Main/HBox/WritingArea/TopBar/Disposition/DispositionField".text


func _apply_selected_reference(reference: String) -> void:
	$"Main/HBox/WritingArea/TopBar/Speaker/SpeakerField".text = reference
	line_data["Reference"] = reference
	_on_speaker_text_changed(reference)


#* Update weight for Default variant:
func _on_default_weight_changed(new_text) -> void:
	var text_node: TextEdit = $"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Text"
	var writer_text: String = text_node.text

	$"Main/HBox/WritingArea/Preview/DefaultPreview/Text".text = writer_text

	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return
	if candy_dc.write_line_index < 0:
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]
	if candy_dc.write_line_index >= lines.size():
		return

	#% Update the main data:
	var variants = line_data["Variants"]
	for i in range(variants.size()):
		if variants[i].has("Default"):
			variants[i]["Default"]["Weight"] = new_text
			break
	line_data["Variants"] = variants
	lines[candy_dc.write_line_index]["Spoken Line"] = line_data
	block["Text"] = lines
	conv[candy_dc.current_block] = block
	candy_dc.conversations[candy_dc.current_conversation] = conv

	#% Refresh variant list:
	update_spoken_lines_list()



#* Toggle writing direction for the Default text:
func _on_default_text_direction_pressed() -> void:
	var btn := $"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Stats/TextDirection"   #/ or your actual node path for the button
	var text_edit := $"Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Default/Text"
	var text_preview := $"Main/HBox/WritingArea/Preview/DefaultPreview/Text"

	#@ Safety checks:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return
	if candy_dc.write_line_index < 0:
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]
	if candy_dc.write_line_index >= lines.size():
		return

	#@ Access Default variant:
	var variants = line_data["Variants"]
	var default_dict = {}
	for v in variants:
		if v.has("Default"):
			default_dict = v
			break
	if default_dict.is_empty():
		return

	var default_data = default_dict["Default"]

	#@ Toggle between "default", "ltr", and "rtl":
	var current_dir = "default"
	if default_data.has("Direction"):
		current_dir = default_data["Direction"]

	var new_dir := ""
	var new_symbol := ""

	if current_dir == "rtl":
		new_dir = "ltr"
		new_symbol = "⇢"
	elif current_dir == "ltr" or current_dir == "default":
		new_dir = "rtl"
		new_symbol = "⇠"

	#@ Update button label:
	btn.text = new_symbol

	#@ Apply direction immediately to the Default text field:
	if new_dir == "rtl":
		text_preview.text_direction = TextServer.DIRECTION_RTL
		text_preview.layout_direction = Control.LAYOUT_DIRECTION_RTL

		text_edit.text_direction = TextServer.DIRECTION_RTL
		text_edit.layout_direction = Control.LAYOUT_DIRECTION_RTL
		#text_edit.text_direction = Control.TEXT_DIRECTION_RTL
	elif new_dir == "ltr":
		text_preview.text_direction = TextServer.DIRECTION_LTR
		text_edit.layout_direction = Control.LAYOUT_DIRECTION_LTR

		text_edit.text_direction = TextServer.DIRECTION_LTR
		text_edit.layout_direction = Control.LAYOUT_DIRECTION_LTR
		#text_edit.text_direction = Control.TEXT_DIRECTION_LTR

	#@ Save direction to Default variant data:
	default_data["Direction"] = new_dir
	default_dict["Default"] = default_data

	#@ Replace back into line_data and globals:
	for i in range(variants.size()):
		if variants[i].has("Default"):
			variants[i] = default_dict
			break

	line_data["Variants"] = variants
	lines[candy_dc.write_line_index]["Spoken Line"] = line_data
	block["Text"] = lines
	conv[candy_dc.current_block] = block
	candy_dc.conversations[candy_dc.current_conversation] = conv


#* Called when the user edits the voice file name in the Writer:
func _on_voice_name_text_changed(new_text: String) -> void:
	#@ Validate editing context:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return
	if candy_dc.write_line_index < 0:
		return

	#@ Update local line data:
	line_data["Voice"] = new_text.strip_edges()

	#@ Write back to globals:
	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]
	if candy_dc.write_line_index >= lines.size():
		return
	lines[candy_dc.write_line_index]["Spoken Line"] = line_data
	block["Text"] = lines
	conv[candy_dc.current_block] = block
	candy_dc.conversations[candy_dc.current_conversation] = conv


#* Show the voice list popup (delegates to main):
func _on_voice_button_pressed() -> void:
	var field: LineEdit = $"Main/HBox/Options/DefaultOptions/VoiceFile/VoiceName"
	var char_name = line_data["Reference"]
	main.open_voice_menu(self, field, char_name)


#* Select voice file from list:
func _apply_selected_voice(filename: String) -> void:
	$"Main/HBox/Options/DefaultOptions/VoiceFile/VoiceName".text = filename
	line_data["Voice"] = filename


#* Change default voice volume:
func _on_volume_value_changed(value: float) -> void:
	var player = main.get_node("VoicePreview")
	if player == null:
		return

	#% 25 = default (1×), 100 = 4×, 0 = silent:
	if value <= 0:
		player.volume_db = -80.0	#/ Effectively mute
		return

	#% Map 25 → 1×, 100 → 4× using a logarithmic scale:
	var linear_ratio := value / 25.0
	if linear_ratio < 0.01:
		linear_ratio = 0.01

	var db := linear_to_db(linear_ratio)
	player.volume_db = db


#* Seek manually only when user is dragging, not when process() updates it:
func _on_progress_value_changed(value: float) -> void:
	if updating_progress:
		return
	if not user_dragging_progress:
		return		#/ Ignore automatic updates

	var player = main.get_node("VoicePreview")
	if player == null:
		return

	var stream = player.stream
	if stream == null:
		return

	var length = stream.get_length()
	if length <= 0:
		return

	player.seek((value / 100.0) * length)

func _on_progress_drag_started() -> void:
	user_dragging_progress = true

func _on_progress_drag_ended(_value_changed: bool) -> void:
	user_dragging_progress = false

	#% Seek once when the user lets go:
	_on_progress_value_changed($"Main/HBox/Options/DefaultOptions/DefaultVoiceButtons/VBoxContainer/Progress/DefaultVoiceProgress".value)


#* Change default voice volume:
func _on_variant_volume_value_changed(value: float) -> void:
	var player = main.get_node("VariantVoicePreview")
	if player == null:
		return

	#% 25 = default (1×), 100 = 4×, 0 = silent:
	if value <= 0:
		player.volume_db = -80.0	#/ Effectively mute
		return

	#% Map 25 → 1×, 100 → 4× using a logarithmic scale:
	var linear_ratio := value / 25.0
	if linear_ratio < 0.01:
		linear_ratio = 0.01

	var db := linear_to_db(linear_ratio)
	player.volume_db = db


#* Seek manually only when user is dragging, not when process() updates it:
func _on_variant_progress_value_changed(value: float) -> void:
	if variant_updating_progress:
		return
	if not user_dragging_progress:
		return		#/ Ignore automatic updates

	var player = main.get_node("VariantVoicePreview")
	if player == null:
		return

	var stream = player.stream
	if stream == null:
		return

	var length = stream.get_length()
	if length <= 0:
		return

	player.seek((value / 100.0) * length)

func _on_variant_progress_drag_started() -> void:
	user_variant_dragging_progress = true

func _on_variant_progress_drag_ended(_value_changed: bool) -> void:
	user_variant_dragging_progress = false

	#% Seek once when the user lets go:
	_on_progress_value_changed($"Main/HBox/Options/VariantOptions/VariantVoiceButtons/VBoxContainer/Progress/VariantVoiceProgress".value)


#* LLM button:
func _on_llm_pressed() -> void:
	var btn = $"Main/HBox/WritingArea/TopBar/LLM"
	if line_data["AI"] == 0:
		line_data["AI"] = 1
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["On"]		#/ green

	elif line_data["AI"] == 1:
		line_data["AI"] = -1
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]		#/ red

	elif line_data["AI"] == -1:
		line_data["AI"] = 0
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]		#/ white

func _on_tts_pressed() -> void:
	var btn = $"Main/HBox/WritingArea/TopBar/TTS"
	if line_data["TTS"] == 0:
		line_data["TTS"] = 1
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["On"]		#/ green

	elif line_data["TTS"] == 1:
		line_data["TTS"] = -1
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]		#/ red

	elif line_data["TTS"] == -1:
		line_data["TTS"] = 0
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]		#/ white

#* Bubble Exempt button:
func _on_bubble_exempt_pressed() -> void:
	var btn = $"Main/HBox/WritingArea/TopBar/BubbleExempt"
	if line_data["BubbleExempt"] == false:
		line_data["BubbleExempt"] = true
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Neutral"]	#/ yellow

	elif line_data["BubbleExempt"] == true:
		line_data["BubbleExempt"] = false
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]		#/ white

#* Force Portrait button:
func _on_force_portrait_pressed() -> void:
	var btn = $"Main/HBox/WritingArea/TopBar/ForcePortrait"
	if line_data["ForcePortrait"] == false:
		line_data["ForcePortrait"] = true
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["On"]		#/ green

	elif line_data["ForcePortrait"] == true:
		line_data["ForcePortrait"] = false
		btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]		#/ white


#* Insert BBCode tags into the active text edit or line edit:
func _on_insert_bbcode_pressed(source: BaseButton) -> void:
	if source == null:
		return

	#@ Determine tag type based on button name:
	var open_tag := ""
	var close_tag := ""
	match source.name:
		"Var":
			var variable_name = $"Main/HBox/RightPanel/BBCode/Media2/TextValue"
			var variable_text = variable_name.text.strip_edges()
			open_tag = candy_dc.var_in_speech_start + variable_text
			close_tag = candy_dc.var_in_speech_end

		"Sub":
			var variable_name = $"Main/HBox/RightPanel/BBCode/Media2/TextValue"
			var variable_text = variable_name.text.strip_edges()
			#? •|variable_text•
			open_tag = candy_dc.substitution_symbol + candy_dc.separator_symbol
			close_tag = variable_text + candy_dc.substitution_symbol

		"Bold":
			open_tag = "[b]"
			close_tag = "[/b]"
		"Italic":
			open_tag = "[i]"
			close_tag = "[/i]"
		"Underline":
			open_tag = "[u]"
			close_tag = "[/u]"
		"Strike":
			open_tag = "[s]"
			close_tag = "[/s]"
		"Shake":
			open_tag = "[shake]"
			close_tag = "[/shake]"
		"Wave":
			open_tag = "[wave]"
			close_tag = "[/wave]"
		"Tornado":
			open_tag = "[tornado]"
			close_tag = "[/tornado]"
		"Rainbow":
			open_tag = "[rainbow]"
			close_tag = "[/rainbow]"
		"Fade":
			open_tag = "[fade]"
			close_tag = "[/fade]"
		"Pulse":
			open_tag = "[pulse]"
			close_tag = "[/pulse]"
		"URL":
			var url = $"Main/HBox/RightPanel/BBCode/Media2/TextValue"
			var url_stripped = url.text.strip_edges()
			open_tag = "[url=%s]" % url_stripped
			close_tag = "[/url]"
		"Image":
			var image = $"Main/HBox/RightPanel/BBCode/Media2/TextValue"
			var image_stripped = image.text.strip_edges()
			open_tag = "[img]" + image_stripped
			close_tag = "[/img]"
		"Size":
			var size_line = $"Main/HBox/RightPanel/BBCode/Font1/SizeValue"
			var size_text = size_line.text.strip_edges()
			var size := 16		#/ Default fallback
			if size_text.is_valid_int():
				var val := int(size_text)
				if val > 0:
					size = val
			open_tag = "[font_size=%d]" % size
			close_tag = "[/font_size]"

		"BGColor":
			var color_line := $"Main/HBox/RightPanel/BBCode/Color2/ColorValue"
			var color_text = color_line.text.strip_edges()
			if color_text == "":
				color_text = "black"	#/ Default black background
			open_tag = "[bgcolor=%s]" % color_text
			close_tag = "[/bgcolor]"

		"FGColor":
			var color_line := $"Main/HBox/RightPanel/BBCode/Color2/ColorValue"
			var color_text = color_line.text.strip_edges()
			if color_text == "":
				color_text = "white"	#/ Default white background
			open_tag = "[fgcolor=%s]" % color_text
			close_tag = "[/fgcolor]"

		"Left":
			open_tag = "[left]"
			close_tag = "[/left]"

		"Center":
			open_tag = "[center]"
			close_tag = "[/center]"

		"Right":
			open_tag = "[right]"
			close_tag = "[/right]"

		"Fill":
			open_tag = "[fill]"
			close_tag = "[/fill]"

		"Indent":
			open_tag = "[indent]"
			close_tag = "[/indent]"

		"Font":
			var font = $"Main/HBox/RightPanel/BBCode/Media2/TextValue"
			var font_stripped = font.text.strip_edges()
			open_tag = "[font=%s]" % font_stripped
			close_tag = "[/font]"

		"OutlineColor":
			var color_line = $"Main/HBox/RightPanel/BBCode/Color2/ColorValue"
			var color_text = color_line.text.strip_edges()
			if color_text == "":
				color_text = "black"	#/ default fallback color
			open_tag = "[outline_color=%s]" % color_text
			close_tag = "[/outline_color]"

		"OutlineSize":
			var size_line = $"Main/HBox/RightPanel/BBCode/Font1/SizeValue"
			var size_text = size_line.text.strip_edges()
			var size := 2
			if size_text.is_valid_int():
				var val := int(size_text)
				if val > 0:
					size = val
			open_tag = "[outline_size=%d]" % size
			close_tag = "[/outline_size]"

		"Dropcap":
			open_tag = "[dropcap]"
			close_tag = "[/dropcap]"

		"Hint":
			var hint = $"Main/HBox/RightPanel/BBCode/Media2/TextValue"
			var hint_stripped = hint.text.strip_edges()
			open_tag = "[hint=%s]" % hint_stripped
			close_tag = "[/hint]"

		"BR":
			open_tag = "[br]"
			close_tag = ""		#/ no closing tag needed

		"HR":
			open_tag = "[hr {}]"
			close_tag = ""		#/ no closing tag needed

		"Paragraph":
			open_tag = "[p {}]"
			close_tag = "[/p]"	#/ no closing tag needed

		"Color":
			var color_line = $"Main/HBox/RightPanel/BBCode/Color2/ColorValue"
			var color_text = color_line.text.strip_edges()
			if color_text == "":
				color_text = "white"	#/ default fallback color
			open_tag = "[color=%s]" % color_text
			close_tag = "[/color]"

		"L_Bracket":
			open_tag = "[lb]"
			close_tag = ""		#/ no closing tag needed

		"R_Bracket":
			open_tag = "[rb]"
			close_tag = ""		#/ no closing tag needed

		_:
			return		#/ Unknown tag button

	_insert_bbcode_into_active(open_tag, close_tag)


#* Insert BBCode tags into the active edit (LineEdit or TextEdit), wrapping selection if any:
func _insert_bbcode_into_active(open_tag: String, close_tag: String) -> void:
	var target := last_focused_edit
	if target == null:
		return

	if target is LineEdit:
		var e: LineEdit = target
		var txt := e.text
		if e.has_selection():
			var from := e.get_selection_from_column()
			var to   := e.get_selection_to_column()
			var mid  := txt.substr(from, to - from)
			e.text = txt.substr(0, from) + open_tag + mid + close_tag + txt.substr(to)
			#% Place caret just after opening tag (keep selection wrapped if you want):
			e.set_caret_column(from + open_tag.length())
		else:
			var caret := e.get_caret_column()
			e.text = txt.substr(0, caret) + open_tag + close_tag + txt.substr(caret)
			e.set_caret_column(caret + open_tag.length())
		e.grab_focus()
		return

	if target is TextEdit:
		var e: TextEdit = target
		e.begin_complex_operation()
		if e.has_selection():
			var sel_text := e.get_selected_text()
			#% Remove selected region, caret moves to its start:
			e.delete_selection()
			#% Insert wrapped selection at caret:
			e.insert_text_at_caret(open_tag + sel_text + close_tag)
			#% Move caret back inside the tags (between open and close, after selected text):
			e.set_caret_column(e.get_caret_column() - close_tag.length())
		else:
			#% No selection → insert empty tags and put caret between them:
			e.insert_text_at_caret(open_tag + close_tag)
			e.set_caret_column(e.get_caret_column() - close_tag.length())
		e.end_complex_operation()
		e.grab_focus()


#* Rebuild the custom insert button list from candy_dc.custom_writer_inserts:
func populate_custom_inserts() -> void:
	var list_container := $"Main/HBox/RightPanel/Inserts/CustomInserts/List"

	#% Clear previous UI:
	for child in list_container.get_children():
		child.queue_free()

	#% Group inserts by category:
	var categories := {}
	for insert_entry in candy_dc.custom_writer_inserts:
		if insert_entry.size() < 4:
			continue   #/ ensure [category, name, part1, part2]
		var category = insert_entry[0]
		if not categories.has(category):
			categories[category] = []
		categories[category].append(insert_entry)

	#% Build foldable sections per category:
	for category in categories.keys():
		var fold := FoldableContainer.new()
		fold.title = category
		fold.folded = false
		fold.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list_container.add_child(fold)

		var grid := GridContainer.new()
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fold.add_child(grid)

		for insert_entry in categories[category]:
			var name_text = insert_entry[1]
			var open_tag = insert_entry[2]
			var close_tag = insert_entry[3]

			var button := Button.new()
			button.text = name_text
			button.focus_mode = Control.FOCUS_NONE
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			#% Right-click context menu:
			button.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
					var index = candy_dc.custom_writer_inserts.find(insert_entry)
					_on_insert_button_right_clicked(index, event.global_position))

			#% Left-click to apply insert:
			button.pressed.connect(func():
				_apply_custom_insert(open_tag, close_tag))

			grid.add_child(button)



#* Insert a custom writer tag at caret or around selected text:
func _apply_custom_insert(open_tag: String, close_tag: String) -> void:
	_insert_bbcode_into_active(open_tag, close_tag)


#* Open menu to create new Insert:
func _on_add_insert_pressed() -> void:
	custom_insert_menu_mode = "new"
	$"CustomInsertMenu".visible = true
	$"CustomInsertMenu/VBox/Category".grab_focus()


#* Cancel Insert creation:
func _on_insert_cancel_pressed() -> void:
	custom_insert_menu_mode = ""
	$"CustomInsertMenu".visible = false


#* Confirm Insert creation:
func _on_insert_confirm_pressed() -> void:
	var category_field := $"CustomInsertMenu/VBox/Category"
	var name_field := $"CustomInsertMenu/VBox/Name"
	var part1_field := $"CustomInsertMenu/VBox/Part1"
	var part2_field := $"CustomInsertMenu/VBox/Part2"
	var warning_field := $"CustomInsertMenu/VBox/Warning"

	var category_text = category_field.text.strip_edges()
	var name_text = name_field.text.strip_edges()
	var part1_text = part1_field.text.strip_edges()
	var part2_text = part2_field.text.strip_edges()

	#% Ignore if category or name is empty:
	if name_text == "" or category_text == "":
		warning_field.text = "Category and Name required."
		return

	#% Create new insert:
	if custom_insert_menu_mode == "new":
		candy_dc.custom_writer_inserts.append([category_text, name_text, part1_text, part2_text])

	#% Edit existing insert:
	elif custom_insert_menu_mode == "edit":
		for i in range(candy_dc.custom_writer_inserts.size()):
			var insert_entry = candy_dc.custom_writer_inserts[i]
			if insert_entry[1] == editing_custom_insert:   #/ name moved to index 1 now
				candy_dc.custom_writer_inserts[i] = [category_text, name_text, part1_text, part2_text]
				break

	#% Refresh UI and cleanup:
	populate_custom_inserts()
	custom_insert_menu_mode = ""
	editing_custom_insert = ""
	$"CustomInsertMenu".visible = false

	#% Optionally clear the fields:
	category_field.text = ""
	name_field.text = ""
	part1_field.text = ""
	part2_field.text = ""

	#% Save profile to save inserts:
	main.get_node("ProfileMenu").save_profile()


func _on_insert_button_right_clicked(index: int, global_pos: Vector2) -> void:
	current_insert_context_index = index
	var popup := $"CustomInsertRC"
	popup.set_position(global_pos)
	popup.visible = true


func _on_custom_insert_context_selected(id: int) -> void:
	var popup := $"CustomInsertRC"
	popup.visible = false

	if current_insert_context_index < 0 or current_insert_context_index >= candy_dc.custom_writer_inserts.size():
		return

	match id:
		0:  #% Edit:
			custom_insert_menu_mode = "edit"
			var entry = candy_dc.custom_writer_inserts[current_insert_context_index]
			editing_custom_insert = entry[0]
			$"CustomInsertMenu/VBox/Name".text = entry[0]
			$"CustomInsertMenu/VBox/Part1".text = entry[1]
			$"CustomInsertMenu/VBox/Part2".text = entry[2]
			$"CustomInsertMenu".visible = true

		1:  #% Move Up:
			if current_insert_context_index > 0:
				var i = current_insert_context_index
				var temp = candy_dc.custom_writer_inserts[i]
				candy_dc.custom_writer_inserts[i] = candy_dc.custom_writer_inserts[i - 1]
				candy_dc.custom_writer_inserts[i - 1] = temp
				populate_custom_inserts()

		2:  #% Move Down:
			if current_insert_context_index < candy_dc.custom_writer_inserts.size() - 1:
				var i = current_insert_context_index
				var temp = candy_dc.custom_writer_inserts[i]
				candy_dc.custom_writer_inserts[i] = candy_dc.custom_writer_inserts[i + 1]
				candy_dc.custom_writer_inserts[i + 1] = temp
				populate_custom_inserts()

		3:  #% Sort:
			candy_dc.custom_writer_inserts.sort_custom(func(a, b):
				return a[0].to_lower() < b[0].to_lower())
			populate_custom_inserts()

		4:  #% Delete:
			candy_dc.custom_writer_inserts.remove_at(current_insert_context_index)
			populate_custom_inserts()


func _on_pick_color_pressed() -> void:
	candy_dc.color_pick_mode = "writer"
	main.get_node("Color").visible = true


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
					i = closing + 1		#/ skip the whole tag
					continue

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
		inner = inner.substr(1)   #/ strip the "/"

	#% Extract base name (before '=', ' '):
	var base_name := inner.split("=")[0].split(" ")[0]

	#% Check if known BBCode tag:
	var is_known = (
		candy_dc.BBCODE_TAGS_SIMPLE.has(base_name)
		or candy_dc.BBCODE_TAGS_EQUALS.has(base_name)
		or candy_dc.BBCODE_TAGS_SPACE.has(base_name)
	)

	#%Check if custom Writer insert:
	for insert in candy_dc.custom_writer_inserts:
		if insert.size() >= 2:
			var open_tag = insert[1]
			var close_tag = insert[2]

			#% Compare full tags, not just base name, since inserts can include spaces:
			if tag == open_tag or tag == close_tag:
				is_known = true
				break

	if not is_known:
		return false

	#% For closing tags, [/name] is always valid if name is known:
	if is_closing:
		return true

	#% Type 1 - simple tags with no parameters:
	if inner == base_name and candy_dc.BBCODE_TAGS_SIMPLE.has(base_name):
		return true

	#% Type 2 - tags with "=" parameters:
	if candy_dc.BBCODE_TAGS_EQUALS.has(base_name):
		if inner.begins_with(base_name + "="):
			return true

	#% Type 3 - tags with space-delimited params:
	if candy_dc.BBCODE_TAGS_SPACE.has(base_name):
		if inner.begins_with(base_name + " "):
			return true

	#% Fallback: known tag name but unusual formatting → still treat as BBCode:
	return true


#* Refresh the Spoken Lines list:
func update_spoken_lines_list(_value := 0.0) -> void:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]
	if lines.is_empty():
		return

	var vbox := $"Main/HBox/VBoxContainer/LinesList/HBox/VBox"
	var scroll := $"Main/HBox/VBoxContainer/LinesList/HBox/VScrollBar"
	var total_lines = lines.size()
	var button_count := vbox.get_child_count()
	if button_count == 0:
		return

	apply_writer_scroll_limits()
	var start_index = clamp(int(scroll.value), 0, max(total_lines - button_count, 0))

	#@ Color presets for spoken lines:
	var color_1 := Color(0, 0.6, 1)
	var color_2 := Color(0, 0.6, 1)
	var color_selected := Color(0, 1, 1)

	var visible_i := 0

	#@ Iterate through buttons:
	for i in range(start_index, start_index + button_count):
		var btn := vbox.get_child(visible_i)
		var btn_line := btn.get_node("HBox/ScrollContainer/Panel").get_node("Line")
		var btn_up := btn.get_node("HBox/Up")
		var btn_down := btn.get_node("HBox/Down")
		visible_i += 1

		if i >= total_lines:
			btn.visible = false
			continue

		var line_dict = lines[i]
		var is_spoken = line_dict.has("Spoken Line")

		#@ Determine if this line should be hidden due to category:
		var should_hide := false

		if not is_spoken:
			#% Identify command type (first key in dict, e.g. §Comment):
			for key in line_dict.keys():
				if typeof(key) == TYPE_STRING and key.begins_with("§"):
					for category in show_hide_lines.keys():
						var cat = show_hide_lines[category]
						if key in cat["Commands"]:
							should_hide = cat["Hide"]
							break
				if should_hide:
					break

		#@ Hide lines if their category is off:
		if should_hide:
			btn.visible = false
			continue

		#@ Spoken Lines:
		if is_spoken:
			var spoken_line = line_dict["Spoken Line"]
			var speaker = spoken_line.get("Reference", "")
			var disposition = spoken_line.get("Disposition", "")
			var variants = spoken_line.get("Variants", [])
			var text := ""

			var target_variant := "Default"

			if candy_dc.variant_show == true and candy_dc.write_variant != "":
				target_variant = candy_dc.write_variant

			for variant_dict in variants:
				if variant_dict.has(target_variant):
					if bool(variant_dict[target_variant].get("Enabled", false)):
						text = variant_dict[target_variant].get("Text", "")
					break

			text = text.strip_edges()
			text = bbcode_strip_tags(text)
			#text = remove_writer_inserts(text)
			if disposition != "":
				btn_line.text = "%d | [%s] %s: \"%s\"" % [i, disposition, speaker, text]
			else:
				btn_line.text = "%d | %s: \"%s\"" % [i, speaker, text]
			btn_line.set_meta("real_index", i)
			btn_up.set_meta("real_index", i)
			btn_down.set_meta("real_index", i)

			#% Get ColorRect:
			var color_rect := btn.get_node("HBox/ScrollContainer/Panel/ColorRect")

			#% Always black background for spoken lines:
			color_rect.color = Color(0, 0, 0)
			color_rect.visible = false

			if i == candy_dc.write_line_index:
				var col := color_selected
				btn_line.add_theme_color_override("font_color", col)
				btn_up.add_theme_color_override("font_color", col)
				btn_down.add_theme_color_override("font_color", col)
			else:
				var alt := i % 2
				var col := Color()
				if alt == 0:
					col = color_1
				else:
					col = color_2

				btn_line.add_theme_color_override("font_color", col)
				btn_up.add_theme_color_override("font_color", col)
				btn_down.add_theme_color_override("font_color", col)

			btn.visible = true
			btn.focus_mode = Control.FOCUS_NONE

			if btn_line.is_connected("pressed", Callable(self, "_on_spoken_line_button_pressed")):
				btn_line.disconnect("pressed", Callable(self, "_on_spoken_line_button_pressed"))
			btn_line.pressed.connect(_on_spoken_line_button_pressed.bind(i))

		#@ Command Lines:
		else:
			#% Extract command name (e.g., §Comment):
			var command_name = line_dict.keys()[0]
			var command_data = line_dict[command_name]
			var display_text = "%d | %s" % [i, command_name]

			#% Add extra info for certain commands:
			match command_name:
				#?---------------------------------------------------------
				"§Comment":
					var comment_text := str(command_data["Comment"]).strip_edges()
					display_text = "%d | %s: %s" % [i, command_name, comment_text]

				#?---------------------------------------------------------
				"§Bridge", "§Jump":
					var convo_ref := str(command_data.get("Conversation", "")).strip_edges()
					var block_ref := str(command_data.get("Block", "")).strip_edges()
					var line_ref := str(command_data.get("Line", "")).strip_edges()
					display_text = "%d | %s: %s → %s → %s" % [i, command_name, convo_ref, block_ref, line_ref]

				#?---------------------------------------------------------
				"§LM":
					var ref_text := str(command_data["Reference"]).strip_edges()
					display_text = "%d | %s: %s" % [i, command_name, ref_text]

				#?---------------------------------------------------------
				"§End":
					display_text = "%d | %s  X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X X" % [i, command_name]

				#?---------------------------------------------------------
				"§Return":
					display_text = "%d | %s ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑ ↑" % [i, command_name]

				#?---------------------------------------------------------
				"§Set":
					var variable := str(command_data.get("Variable", "")).strip_edges()
					var operator := str(command_data.get("Operator", "")).strip_edges()
					var expression := str(command_data.get("Expression", "")).strip_edges()
					display_text = "%d | %s: %s %s %s" % [i, command_name, variable, operator, expression]

				#?---------------------------------------------------------
				"§Call":
					var function := str(command_data.get("Function", "")).strip_edges()
					var arguments := str(command_data.get("Arguments", "")).strip_edges()
					var cmd_await = command_data.get("Await", "")
					if cmd_await == true:
						display_text = "%d | %s: [AWAIT] %s(%s)" % [i, command_name, function, arguments]
					else:
						display_text = "%d | %s: %s(%s)" % [i, command_name, function, arguments]

				#?---------------------------------------------------------
				"§Emit":
					var signal_name := str(command_data.get("Signal", "")).strip_edges()
					var args := str(command_data.get("Arguments", "")).strip_edges()
					display_text = "%d | %s: %s(%s)" % [i, command_name, signal_name, args]

				#?---------------------------------------------------------
				"§Await":
					var signal_name := str(command_data.get("Signal", "")).strip_edges()
					display_text = "%d | %s: %s()" % [i, command_name, signal_name]

				#?---------------------------------------------------------
				"§Flag":
					var flag := str(command_data.get("Flag", "")).strip_edges()
					var operator := str(command_data.get("Operator", "")).strip_edges()
					var expression := str(command_data.get("Expression", "")).strip_edges()
					display_text = "%d | %s: %s %s %s" % [i, command_name, flag, operator, expression]

				#?---------------------------------------------------------
				"§Name":
					var value := str(command_data.get("Name", "")).strip_edges()
					var reference := str(command_data.get("Reference", "")).strip_edges()
					var key := str(command_data.get("Actor_Key", "")).strip_edges()
					if key == "":
						key = "Display Name"
					display_text = "%d | %s: [%s] %s → %s" % [i, command_name, reference, key, value]

				#?---------------------------------------------------------
				"§Role":
					var role := str(command_data.get("Role", "")).strip_edges()
					var reference := str(command_data.get("Reference", "")).strip_edges()
					display_text = "%d | %s: %s ← %s" % [i, command_name, role, reference]

				#?---------------------------------------------------------
				"§Disposition":
					var disposition := str(command_data.get("Disposition", "")).strip_edges()
					var reference := str(command_data.get("Reference", "")).strip_edges()
					display_text = "%d | %s: %s = %s" % [i, command_name, reference, disposition]

				#?---------------------------------------------------------
				"§Export":
					var file := str(command_data.get("File", "")).strip_edges()
					var format := str(command_data.get("Format", "")).strip_edges()
					display_text = "%d | %s: %s.%s" % [i, command_name, file, format]

				#?---------------------------------------------------------
				"Import":
					var file := str(command_data.get("File", "")).strip_edges()
					var format := str(command_data.get("Format", "")).strip_edges()
					display_text = "%d | %s: %s.%s" % [i, command_name, file, format]

				#?---------------------------------------------------------
				"§Custom":
					var command := str(command_data.get("Command", "")).strip_edges()
					#var data := str(command_data.get("Data", "")).strip_edges()
					display_text = "%d | %s: %s" % [i, command_name, command]

				#?---------------------------------------------------------
				"§If", "§Elif", "§For", "§While":
					var cond := str(command_data.get("Condition", "")).strip_edges()
					var type := str(command_data.get("Type", "")).strip_edges()

					match type:
						"Set":
							var variable := str(command_data.get("Variable", "")).strip_edges()
							var operator := str(command_data.get("Operator", "")).strip_edges()
							var expression := str(command_data.get("Expression", "")).strip_edges()
							display_text = "%d | %s: %s %s %s" % [i, command_name, variable, operator, expression]

						"Call":
							var function := str(command_data.get("Function", "")).strip_edges()
							var arguments := str(command_data.get("Arguments", "")).strip_edges()
							var cmd_await = command_data.get("Await", "")
							if cmd_await == true:
								display_text = "%d | %s: [%s] Call: [AWAIT] %s(%s)" % [i, command_name, cond, function, arguments]
							else:
								display_text = "%d | %s: [%s] Call: %s(%s)" % [i, command_name, cond, function, arguments]

						"Emit":
							var cmd_signal := str(command_data.get("Signal", "")).strip_edges()
							var arguments := str(command_data.get("Arguments", "")).strip_edges()
							display_text = "%d | %s: [%s] Emit: %s(%s)" % [i, command_name, cond, cmd_signal, arguments]

						"Await":
							var cmd_signal := str(command_data.get("Signal", "")).strip_edges()
							var arguments := str(command_data.get("Arguments", "")).strip_edges()
							display_text = "%d | %s: [%s] Await: %s(%s)" % [i, command_name, cond, cmd_signal, arguments]

						"Flag":
							var flag := str(command_data.get("Flag", "")).strip_edges()
							var operator := str(command_data.get("Operator", "")).strip_edges()
							var expression := str(command_data.get("Expression", "")).strip_edges()
							display_text = "%d | %s: %s %s %s" % [i, command_name, flag, operator, expression]

						"Disposition":
							var disposition := str(command_data.get("Disposition", "")).strip_edges()
							var reference := str(command_data.get("Reference", "")).strip_edges()
							display_text = "%d | %s: [%s] Disposition: %s = %s" % [i, command_name, cond, reference, disposition]

						"Role":
							var role := str(command_data.get("Role", "")).strip_edges()
							var reference := str(command_data.get("Reference", "")).strip_edges()
							display_text = "%d | %s: [%s] Role: %s ← %s" % [i, command_name, cond, role, reference]

						"Name":
							var value := str(command_data.get("Name", "")).strip_edges()
							var reference := str(command_data.get("Reference", "")).strip_edges()
							display_text = "%d | %s: [%s] Name: %s → %s" % [i, command_name, cond, reference, value]

						"Transition":
							var trans := str(command_data.get("Transition", "")).strip_edges()
							var convo := str(command_data.get("Conversation", "")).strip_edges()
							var block_ref := str(command_data.get("Block", "")).strip_edges()
							var line_ref := str(command_data.get("Line", "")).strip_edges()
							display_text = "%d | %s: [%s] (%s) %s → %s → %s" % [i, command_name, cond, trans, convo, block_ref, line_ref]

				#?---------------------------------------------------------
				"§Else":
					var type := str(command_data.get("Type", "")).strip_edges()

					match type:
						"Set":
							var variable := str(command_data.get("Variable", "")).strip_edges()
							display_text = "%d | %s: -- Set: %s" % [i, command_name, variable]

						"Call":
							var function := str(command_data.get("Function", "")).strip_edges()
							var arguments := str(command_data.get("Arguments", "")).strip_edges()
							var cmd_await = command_data.get("Await", "")
							if cmd_await == true:
								display_text = "%d | %s: Call: [AWAIT] %s(%s)" % [i, command_name, function, arguments]
							else:
								display_text = "%d | %s: Call: %s(%s)" % [i, command_name, function, arguments]

						"Emit":
							var cmd_signal := str(command_data.get("Signal", "")).strip_edges()
							var arguments := str(command_data.get("Arguments", "")).strip_edges()
							display_text = "%d | %s: Emit: %s(%s)" % [i, command_name, cmd_signal, arguments]

						"Await":
							var cmd_signal := str(command_data.get("Signal", "")).strip_edges()
							var arguments := str(command_data.get("Arguments", "")).strip_edges()
							display_text = "%d | %s: Await: %s(%s)" % [i, command_name, cmd_signal, arguments]

						"Flag":
							var variable := str(command_data.get("Variable", "")).strip_edges()
							var operator := str(command_data.get("Operator", "")).strip_edges()
							var value := str(command_data.get("Value", "")).strip_edges()
							display_text = "%d | %s: Flag: %s %s %s" % [i, command_name, variable, operator, value]

						"Disposition":
							var disposition := str(command_data.get("Disposition", "")).strip_edges()
							var reference := str(command_data.get("Reference", "")).strip_edges()
							display_text = "%d | %s: Disposition: %s = %s" % [i, command_name, reference, disposition]

						"Role":
							var role := str(command_data.get("Role", "")).strip_edges()
							var reference := str(command_data.get("Reference", "")).strip_edges()
							display_text = "%d | %s: Role: %s ← %s" % [i, command_name, role, reference]

						"Name":
							var value := str(command_data.get("Value", "")).strip_edges()
							var reference := str(command_data.get("Reference", "")).strip_edges()
							display_text = "%d | %s: Name: %s → %s" % [i, command_name, reference, value]

						"Transition":
							var trans := str(command_data.get("Transition", "")).strip_edges()
							var convo := str(command_data.get("Conversation", "")).strip_edges()
							var block_ref := str(command_data.get("Block", "")).strip_edges()
							var line_ref := str(command_data.get("Line", "")).strip_edges()
							display_text = "%d | %s: (%s) %s → %s → %s" % [i, command_name, trans, convo, block_ref, line_ref]

				#?---------------------------------------------------------
				"§Input":
					var file := str(command_data.get("File", "")).strip_edges()
					var mode := str(command_data.get("Mode", "")).strip_edges()
					var variable := str(command_data.get("Variable", "")).strip_edges()
					display_text = "%d | %s: [%s] %s, %s" % [i, command_name, file, mode, variable]

				#?---------------------------------------------------------
				"§Mouse":
					var mode := str(command_data.get("Mouse Mode", "")).strip_edges()
					display_text = "%d | %s: %s" % [i, command_name, mode]

				#?---------------------------------------------------------
				"§Choice_List":
					var reference := str(command_data.get("Reference", "")).strip_edges()
					display_text = "%d | %s: %s" % [i, command_name, reference]

				#?---------------------------------------------------------
				"§Choice_Status":
					display_text = "%d | %s:" % [i, command_name]

				#?---------------------------------------------------------
				"§BG":
					var bg_layer := str(command_data.get("Layer", "")).strip_edges()
					var file := str(command_data.get("File", "")).strip_edges()
					display_text = "%d | %s: %s (%s) " % [i, command_name, bg_layer, file]

				#?---------------------------------------------------------
				"§BG_Stop":
					var bg_layers := str(command_data.get("Layers", "")).strip_edges()
					var default :bool = command_data.get("Default", false).strip_edges()

					display_text = "%d | %s: %s (%s)" % [i, command_name, bg_layers, default]

				#?---------------------------------------------------------
				"§BG_Mirror":
					var bg_layers := str(command_data.get("Layers", "")).strip_edges()
					var axis :bool = command_data.get("Axis", false).strip_edges()

					display_text = "%d | %s: %s (%s)" % [i, command_name, bg_layers, axis]

				#?---------------------------------------------------------
				"§BG_Remove":
					var bg_layers := str(command_data.get("Layers", "")).strip_edges()

					display_text = "%d | %s: %s" % [i, command_name, bg_layers]

				#?---------------------------------------------------------
				"§BG_Effect", "§BG_Effect_Stop":
					var bg_layers := str(command_data.get("Layers", "")).strip_edges()
					var effects := str(command_data.get("Effects", "")).strip_edges()

					display_text = "%d | %s: %s (%s)" % [i, command_name, bg_layers, effects]

				#?---------------------------------------------------------
				"§BG_Wait":
					var bg_layers := str(command_data.get("Layers", "")).strip_edges()
					display_text = "%d | %s: %s" % [i, command_name, bg_layers]

				#?---------------------------------------------------------
				"§Effect":
					var node := str(command_data.get("Node", "")).strip_edges()
					var anim := str(command_data.get("Animation", "")).strip_edges()
					display_text = "%d | %s: [%s] %s" % [i, command_name, node, anim]

				#?---------------------------------------------------------
				"§Effect_Stop", "§Effect_Wait":
					var node := str(command_data.get("Node", "")).strip_edges()
					display_text = "%d | %s: [%s]" % [i, command_name, node]

				#?---------------------------------------------------------
				"§Wait":
					var time := str(command_data.get("Time", "")).strip_edges()
					display_text = "%d | %s: %s" % [i, command_name, time]

				#?---------------------------------------------------------
				"§Hide":
					var box := str(command_data.get("Box", "")).strip_edges()
					var portrait := str(command_data.get("Portrait", "")).strip_edges()
					display_text = "%d | %s: Box %s | Portrait %s" % [i, command_name, box, portrait]

				#?---------------------------------------------------------
				"§Clear":
					var box := str(command_data.get("Box", "")).strip_edges()
					var bubbles := str(command_data.get("Bubbles", "")).strip_edges()
					var subtitles := str(command_data.get("Subtitles", "")).strip_edges()
					var portrait := str(command_data.get("Portraits", "")).strip_edges()
					var busts := str(command_data.get("Busts", "")).strip_edges()
					var bg := str(command_data.get("Backgrounds", "")).strip_edges()
					display_text = "%d | %s: Box %s | Bubbles %s | Subs %s | Portrait %s | Busts %s | BG %s" % [i, command_name, box, bubbles, subtitles, portrait, busts, bg]

				#?---------------------------------------------------------
				"§Video", "§Audio", "§Image":
					var node := str(command_data.get("Node", "")).strip_edges()
					var file := str(command_data.get("File", "")).strip_edges()
					display_text = "%d | %s: [%s] %s" % [i, command_name, node, file]

				#?---------------------------------------------------------
				"§V_Skip", "§A_Skip":
					var node := str(command_data.get("Node", "")).strip_edges()
					var time := str(command_data.get("Time", "")).strip_edges()
					display_text = "%d | %s: [%s] %s" % [i, command_name, node, time]

				#?---------------------------------------------------------
				"§V_Volume", "§A_Volume":
					var node := str(command_data.get("Node", "")).strip_edges()
					var volume := int(command_data.get("Volume", 0))
					var absolute :bool = command_data.get("Absolute", false)
					var op := ""
					if absolute:
						op = "=="
					else:
						op = "+=" if volume >= 0 else "-="

					display_text = "%d | %s: [%s] %s %d" % [i, command_name, node, op, abs(volume)]

				#?---------------------------------------------------------
				"§V_Stop", "§A_Stop", "§I_Stop":
					var node := str(command_data.get("Node", "")).strip_edges()
					display_text = "%d | %s: [%s]" % [i, command_name, node]

				#?---------------------------------------------------------
				"§VN_Scene", "§BG_Scene":
					var scene := str(command_data.get("Scene", "")).strip_edges()
					display_text = "%d | %s: [%s]" % [i, command_name, scene]

				#?---------------------------------------------------------
				"§VN_Bust":
					var bust := str(command_data.get("Bust", "")).strip_edges()
					var reference := str(command_data.get("Reference", "")).strip_edges()
					var file := str(command_data.get("File", "")).strip_edges()
					display_text = "%d | %s: %s → %s (%s)" % [i, command_name, reference, bust, file]

				#?---------------------------------------------------------
				"§VN_Move":
					var bust := str(command_data.get("Bust", "")).strip_edges()
					var reference := str(command_data.get("Reference", "")).strip_edges()
					display_text = "%d | %s: %s → %s" % [i, command_name, reference, bust]

				#?---------------------------------------------------------
				"§VN_Mirror":
					var reference := str(command_data.get("Reference", "")).strip_edges()
					var axis := str(command_data.get("Axis", "")).strip_edges()
					display_text = "%d | %s: %s (%s)" % [i, command_name, reference, axis]

				#?---------------------------------------------------------
				"§VN_Bust_Stop":
					var actors := str(command_data.get("Actors", "")).strip_edges()
					var default :bool = command_data.get("Default", false).strip_edges()
					display_text = "%d | %s: %s (%s)" % [i, command_name, actors, default]

				#?---------------------------------------------------------
				"§VN_Remove":
					var actors := str(command_data.get("Actors", "")).strip_edges()
					display_text = "%d | %s: %s" % [i, command_name, actors]

				#?---------------------------------------------------------
				"§VN_Effect", "§VN_Effect_Stop":
					var actors := str(command_data.get("Actors", "")).strip_edges()
					var effect := str(command_data.get("Effect", "")).strip_edges()
					display_text = "%d | %s: %s (%s)" % [i, command_name, actors, effect]

				#?---------------------------------------------------------
				"§VN_Effect_Wait":
					var actors := str(command_data.get("Actors", "")).strip_edges()
					var effect := str(command_data.get("Effect", "")).strip_edges()
					var time := str(command_data.get("Time", "")).strip_edges()
					display_text = "%d | %s: %s (%s / %s)" % [i, command_name, actors, effect, time]

				#?---------------------------------------------------------
				"§VN_Bust_Wait":
					var actors := str(command_data.get("Actors", "")).strip_edges()
					var time :bool = command_data.get("Time", false).strip_edges()
					display_text = "%d | %s: %s (%s)" % [i, command_name, actors, time]

				#?---------------------------------------------------------
				"§CS_Scene":
					var targets := str(command_data.get("Targets", "")).strip_edges()
					var scene := str(command_data.get("Scene", "")).strip_edges()
					display_text = "%d | %s: %s → %s" % [i, command_name, targets, scene]

				#?---------------------------------------------------------
				"§CS_Visible":
					var targets := str(command_data.get("Targets", "")).strip_edges()
					var visib := str(command_data.get("Visibility", "")).strip_edges()
					display_text = "%d | %s: %s → %s" % [i, command_name, targets, visib]

				#?---------------------------------------------------------
				"§CS_Loc":
					var targets := str(command_data.get("Targets", "")).strip_edges()
					var marker := str(command_data.get("Marker", "")).strip_edges()
					display_text = "%d | %s: %s → %s" % [i, command_name, targets, marker]

				#?---------------------------------------------------------
				"§CS_Move":
					var targets := str(command_data.get("Targets", "")).strip_edges()
					var marker := str(command_data.get("Marker", "")).strip_edges()
					var animation := str(command_data.get("Animation", "")).strip_edges()
					display_text = "%d | %s: %s → %s (%s)" % [i, command_name, targets, marker, animation]

				#?---------------------------------------------------------
				"§CS_Anim":
					var targets := str(command_data.get("Targets", "")).strip_edges()
					var animation := str(command_data.get("Animation", "")).strip_edges()
					display_text = "%d | %s: %s → %s" % [i, command_name, targets, animation]

				#?---------------------------------------------------------
				"§CS_Anim_Stop":
					var targets := str(command_data.get("Targets", "")).strip_edges()
					display_text = "%d | %s: %s" % [i, command_name, targets]

				#?---------------------------------------------------------
				"§CS_Anim_Wait":
					var targets := str(command_data.get("Targets", "")).strip_edges()
					var time := str(command_data.get("Time", "")).strip_edges()
					display_text = "%d | %s: %s (%s)" % [i, command_name, targets, time]

				#?---------------------------------------------------------
				"§CS_Sprite":
					var targets := str(command_data.get("Targets", "")).strip_edges()
					var animation := str(command_data.get("Animation", "")).strip_edges()
					display_text = "%d | %s: %s → %s" % [i, command_name, targets, animation]

				#?---------------------------------------------------------
				"§CS_Sprite_Stop":
					var targets := str(command_data.get("Targets", "")).strip_edges()
					display_text = "%d | %s: %s" % [i, command_name, targets]

				#?---------------------------------------------------------
				"§CS_Sprite_Wait":
					var targets := str(command_data.get("Targets", "")).strip_edges()
					var time := str(command_data.get("Time", "")).strip_edges()
					display_text = "%d | %s: %s (%s)" % [i, command_name, targets, time]

				#?---------------------------------------------------------
				"§CS_Cam":
					var targets := str(command_data.get("Targets", "")).strip_edges()
					display_text = "%d | %s: %s" % [i, command_name, targets]

				#?---------------------------------------------------------
				"§CS_Light":
					var targets := str(command_data.get("Targets", "")).strip_edges()
					var operator := str(command_data.get("Operator", "")).strip_edges()
					var energy := str(command_data.get("Energy", "")).strip_edges()
					var color := str(command_data.get("Color", "")).strip_edges()
					display_text = "%d | %s: %s %s %s %s" % [i, command_name, targets, operator, energy, color]

				#?---------------------------------------------------------
				"§CS_Toggle":
					var targets := str(command_data.get("Targets", "")).strip_edges()
					var method := str(command_data.get("Method", "")).strip_edges()
					var props := str(command_data.get("Properties", "")).strip_edges()
					var value := str(command_data.get("Value", "")).strip_edges()
					display_text = "%d | %s: %s | %s | %s" % [i, command_name, targets, method, props, value]

				#?---------------------------------------------------------
				_:
					pass  #/ default display stays as §Command

			#@ Apply colors
			#% Retrieve color info from candy_dc.line_colors:
			var color_data = candy_dc.line_colors.get(command_name, {})
			var font_col = color_data.get("BG", Color(1, 1, 1))              #/ Font color
			var border_col = color_data.get("Border", Color(0.0, 0.0, 0.0))  #/ Highlight base

			#% Adjust colors:
			if font_col == Color(0.2, 0.2, 0.2) or font_col == Color(0.25, 0.25, 0.25):
				font_col = Color(0, 0, 0)

			#% Get references:
			var color_rect := btn.get_node("HBox/ScrollContainer/Panel/ColorRect")

			#% Apply colors:
			btn_line.text = display_text
			btn_line.add_theme_color_override("font_color", font_col)

			#% Color Up/Down buttons:
			if font_col == Color(0, 0, 0):
				btn_up.add_theme_color_override("font_color", border_col)
				btn_down.add_theme_color_override("font_color", border_col)
			else:
				btn_up.add_theme_color_override("font_color", font_col)
				btn_down.add_theme_color_override("font_color", font_col)

			#% Set highlight background via ColorRect:
			color_rect.color = border_col
			color_rect.visible = true

			#% Metadata and visibility:
			btn_line.set_meta("real_index", i)
			btn.visible = true


#* Called when a spoken line button is clicked:
func _on_spoken_line_button_pressed(line_index: int) -> void:
	#% Change current Writer context to the chosen spoken line:
	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]

	if line_index < 0 or line_index >= lines.size():
		return
	if lines[line_index].has("Spoken Line"):
		line_data = lines[line_index]["Spoken Line"]
		candy_dc.write_line_index = line_index

	reset_variant_data()

	#% Refresh variant list:
	update_variant_list()

	setup()


#* Remove BBCode tags from a string (without touching visible text):
func bbcode_strip_tags(text: String) -> String:
	var result := ""
	var i := 0
	var length := text.length()

	while i < length:
		var c := text[i]
		#% If this looks like a tag, attempt to skip it:
		if c == "[":
			var closing := text.find("]", i + 1)
			if closing != -1:
				var tag := text.substr(i, closing - i + 1)
				if _is_valid_bbcode_tag(tag):
					i = closing + 1		#/ skip tag entirely
					continue
		#% Otherwise keep the character:
		result += c
		i += 1

	return result


#! Unused - May be used once feature to exclude inserts from lines list is implemented
#* Remove Writer inserts (custom tag pairs defined in candy_dc.custom_writer_inserts):
func remove_writer_inserts(text: String) -> String:
	var result := text
	for insert in candy_dc.custom_writer_inserts:
		if insert.size() >= 2:
			var open_tag = insert[1]
			var close_tag = insert[2]
			if open_tag != "":
				result = result.replace(open_tag, "")
			if close_tag != "":
				result = result.replace(close_tag, "")
	return result


#* Apply scroll limits based on number of spoken lines in current block:
func apply_writer_scroll_limits() -> void:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return

	var scroll := $"Main/HBox/VBoxContainer/LinesList/HBox/VScrollBar"
	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]

	#% Count spoken lines only:
	var spoken_count := 0
	for entry in lines:
		if entry.has("Spoken Line"):
			spoken_count += 1

	var visible_buttons := $"Main/HBox/VBoxContainer/LinesList/HBox/VBox".get_child_count()

	scroll.min_value = 0
	scroll.page = visible_buttons
	scroll.max_value = max(spoken_count, 1)

	#% Clamp the scrollbar value so it stays valid:
	scroll.value = clamp(scroll.value, 0, max(spoken_count - visible_buttons, 0))

	#% Enforce one frame later (same trick as main UI):
	await get_tree().process_frame
	scroll.page = visible_buttons
	scroll.queue_redraw()


#* Delete the line chosen from the right-click menu:
func _on_line_context_selected(id: int) -> void:
	if id != 0 or rc_target_index < 0:
		return

	if candy_dc.write_line_index == id:
		return

	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]

	#% Prevent deletion if only one spoken line remains:
	var remaining_spoken := 0
	for l in lines:
		if l.has("Spoken Line"):
			remaining_spoken += 1
	if remaining_spoken <= 1:
		push_warning("Cannot delete the last spoken line in this block.")
		rc_target_index = -1
		return

	if rc_target_index >= lines.size():
		return

	lines.remove_at(rc_target_index)
	block["Text"] = lines
	conv[candy_dc.current_block] = block
	candy_dc.conversations[candy_dc.current_conversation] = conv

	main.save_undo_step()
	main._update_visible_lines()
	apply_writer_scroll_limits()
	update_spoken_lines_list()
	rc_target_index = -1


#* Move a spoken line up or down in the conversation block:
func _move_spoken_line(real_index: int, direction: String) -> void:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return

	#@ Determine step size based on modifier keys:
	var step := 1
	var ctrl := Input.is_key_pressed(KEY_CTRL)
	var shift := Input.is_key_pressed(KEY_SHIFT)
	var alt := Input.is_key_pressed(KEY_ALT)

	if ctrl and shift and alt:
		step = 250
	elif shift and alt:
		step = 100
	elif ctrl and alt:
		step = 25
	elif ctrl and shift:
		step = 10
	elif alt:
		step = 5
	elif shift:
		step = 3
	elif ctrl:
		step = 2

	#@ Direction multiplier:
	var dir_mult := -1 if direction == "up" else 1
	var line_offset := dir_mult * step

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]

	if real_index < 0 or real_index >= lines.size():
		return

	var new_index = clamp(real_index + line_offset, 0, lines.size() - 1)
	if new_index == real_index:
		return

	#@ Track which line is currently selected:
	var selected_index = candy_dc.write_line_index

	#@ Move the line directly:
	var moved_line = lines[real_index]
	lines.remove_at(real_index)
	lines.insert(new_index, moved_line)

	#@ Write back:
	block["Text"] = lines
	conv[candy_dc.current_block] = block
	candy_dc.conversations[candy_dc.current_conversation] = conv

	main.save_undo_step()

	#@ Adjust selection if it’s affected by the move::
	#% The moved line itself was selected → follow it:
	if selected_index == real_index:
		candy_dc.write_line_index = new_index
	#% Moved line up and replaced selected one → selected moves down:
	elif dir_mult == -1 and selected_index == new_index:
		candy_dc.write_line_index = selected_index + 1
	#% Already handled above:
	elif dir_mult == 1 and selected_index == real_index:
		pass
	#% Moved line down and replaced selected one → selected moves up:
	elif dir_mult == 1 and selected_index == new_index:
		candy_dc.write_line_index = selected_index - 1

	#@ Apply new selection (if still valid):
	if candy_dc.write_line_index >= 0 and candy_dc.write_line_index < lines.size():
		_on_spoken_line_button_pressed(candy_dc.write_line_index)

	#@ Always refresh UI afterward:
	main._update_visible_lines()

	#% Refresh variant list:
	update_variant_list()


#* Hide or show lines by category:
func hide_show_lines(source):
	if show_hide_lines[source.name]["Hide"] == true:
		show_hide_lines[source.name]["Hide"] = false
		source.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
	elif show_hide_lines[source.name]["Hide"] == false:
		show_hide_lines[source.name]["Hide"] = true
		source.modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]

	#% Refresh line list:
	update_spoken_lines_list()


#* Export for testing:
func _on_test_pressed() -> void:
	main._on_test_export_pressed()


#* Update the variant list:
func update_variant_list():
	#@ Fetch UI nodes:
	var vbox: VBoxContainer = $"Main/HBox/Options/VariantOptions/PanelContainer/VBox/HBox/VariantList"
	var scrollbar: VScrollBar = $"Main/HBox/Options/VariantOptions/PanelContainer/VBox/HBox/VScrollBar"
	var variant_text_edit = get_node("Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Text")

	#@ Build enabled lookup for the selected line:
	var enabled_map: Dictionary = {}

	if line_data.has("Variants"):
		for entry in line_data["Variants"]:
			for k in entry.keys():
				var vname := str(k)
				var payload: Dictionary = entry[k]
				enabled_map[vname] = bool(payload.get("Enabled", false))

	#@ Gather all variant names:
	var all_variants: Array = candy_dc.variants_dict.keys()

	#@ Prepare filtering:
	var filtered_variants: Array = []

	var filter_match: String = candy_dc.variant_filter_match
	var filter_mode: String = candy_dc.variant_filter_mode

	var keywords: Array = candy_dc.variant_filter

	#@ Apply filters:
	for variant in all_variants:
		var variant_str := str(variant)
		var matched := false

		#% Keywords provided, filter:
		if keywords.size() > 0:
			for kw in keywords:
				if filter_match == "Exact":
					if variant_str == kw:
						matched = true
						break
				elif filter_match == "Loose":
					if variant_str.find(kw) != -1:
						matched = true
						break

		#% No keywords, show all:
		if keywords.size() == 0:
			filtered_variants.append(variant_str)
		elif filter_mode == "Restrict":
			if matched:
				filtered_variants.append(variant_str)
		elif filter_mode == "Exclude":
			if not matched:
				filtered_variants.append(variant_str)

	#@ Sort alphabetically (case-insensitive):
	filtered_variants.sort_custom(func(a, b): return a.to_lower() < b.to_lower())

	#@ Clamp scrollbar:
	var panel_count: int = vbox.get_child_count()
	scrollbar.max_value = max(filtered_variants.size() - panel_count, 0)
	scrollbar.value = clamp(scrollbar.value, 0, scrollbar.max_value)

	#@ Populate panels:
	var start_index: int = int(scrollbar.value)

	for i in range(panel_count):
		var panel = vbox.get_child(i)
		var btn_variant: Button = panel.get_node("HBox/Button")
		var btn_status: Button = panel.get_node("HBox/Status")

		var variant_index := start_index + i

		if variant_index < filtered_variants.size():
			var vname: String = filtered_variants[variant_index]

			panel.visible = true
			btn_variant.text = vname
			btn_variant.disabled = false

			#@ Color variants:
			if vname == candy_dc.write_variant:
				#% Selected variant:
				if enabled_map.has(vname):
					#% Variant exists:
					var is_enabled: bool = bool(enabled_map[vname])
					#% Enabled == true:
					if is_enabled:
						btn_variant.modulate = candy_dc.color_models[candy_dc.color_mode]["Selected"]	#/ Cyan
						variant_text_edit.editable = true
					#% Enabled == false:
					else:
						btn_variant.modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]		#/ Red
						variant_text_edit.editable = false
				#% Variant does not exist for this line:
				else:
					btn_variant.modulate = candy_dc.color_models[candy_dc.color_mode]["Neutral"]		#/ Yellow
					variant_text_edit.editable = false
			else:
				#% Non-selected variants:
				if enabled_map.has(vname):
					#% Exists but not selected:
					btn_variant.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]			#/ White
				else:
					#% Doesn't exist for this line:
					btn_variant.modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]			#/ Grey

			#@ Update status:
			if enabled_map.has(vname):
				#% Variant exists for this line:
				var is_enabled: bool = bool(enabled_map[vname])
				if is_enabled:
					btn_status.text = "●"	#/ Enabled
				else:
					btn_status.text = "○"	#/ Disabled
			else:
				btn_status.text = "○"		#/ Variant not present → treat as disabled
		else:
			panel.visible = false


#* Select variant:
func variant_selected(v):
	var variant_text_area = get_node("Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Text")
	var variant_direction_button = get_node("Main/HBox/WritingArea/SplitSpeechComments/SplitDefaultVariants/Variant/Stats/TextDirection")
	var variant_text_direction = ""
	var variant_name = v.text
	var variant_text_preview = get_node("Main/HBox/WritingArea/Preview/VariantPreview/Text")

	#@ Check if line has variant:
	for entry in line_data["Variants"]:
		#% If variant found:
		if entry.has(variant_name):
			#% Set variant as write variant:
			candy_dc.write_variant = variant_name

			#% Display variant text in variant writing area:
			variant_text_area.text = entry[variant_name]["Text"]

			#% Display variant preview:
			variant_text_preview.text = variant_text_area.text

			#% Set text direction:
			variant_text_direction = entry[variant_name]["Direction"]
			if variant_text_direction == "rtl":
				variant_direction_button.text = "⇠"
			elif variant_text_direction == "ltr" or variant_text_direction == "default":
				variant_direction_button.text = "⇢"
			break

	#% Stop voice play:
	if (main.get_node("VariantVoicePreview").playing or main.get_node("VariantVoicePreview").stream_paused):
		main.get_node("VariantVoicePreview").stop()

	#% Refresh variant list:
	update_variant_list()

	#% Refresh line list:
	update_spoken_lines_list()


#* Toggle variant enabled status:
func variant_toggle(v):
	main.save_undo_step()

	var variant_name = v.text
	var variants: Array = line_data["Variants"]
	var found := false

	#@ Look up default direction from candy_dc.variants_dict:
	var default_dir := "default"
	if candy_dc.variants_dict.has(variant_name):
		default_dir = str(candy_dc.variants_dict[variant_name].get("Direction", "default"))

	#@ Search for existing variant entry:
	for entry in variants:
		if entry.has(variant_name):
			#% Toggle Enabled flag:
			var current := bool(entry[variant_name].get("Enabled", false))
			entry[variant_name]["Enabled"] = not current
			found = true

			break

	#@ If variant does not exist, add it (Enabled = true):
	if not found:
		var new_entry := {
			variant_name: {
				"Text": "",
				"Enabled": true,
				"Hide": false,
				"Direction": default_dir,
			}
		}
		variants.append(new_entry)

	main.save_undo_step()

	#% Refresh variant list:
	update_variant_list()

	#% Refresh line list:
	update_spoken_lines_list()


#* Clear any selected variants and display Default lines:
func _on_variant_default_pressed() -> void:
	candy_dc.write_variant = ""

	#% Refresh variant list:
	update_variant_list()

	#% Refresh line list:
	update_spoken_lines_list()


func _on_v_scroll_bar_value_changed(_value: float) -> void:
	update_variant_list()

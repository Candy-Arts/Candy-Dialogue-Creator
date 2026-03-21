extends CanvasLayer

@onready var main = get_node("/root/UI")

var conversation = ""
var block = ""
var line_index = -1
var line_data: Dictionary



func load_alter_data():
	if line_data["TargetButton"] == true:
		$"ScrollContainer/VBox/Meta/TargetButtonsBool".text = "True"
		$"ScrollContainer/VBox/Meta/TargetButtonsBool".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]

	else:
		$"ScrollContainer/VBox/Meta/TargetButtonsBool".text = "False"
		$"ScrollContainer/VBox/Meta/TargetButtonsBool".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]

	if line_data["Reload"] == true:
		$"ScrollContainer/VBox/Meta/ReloadBool".text = "True"
		$"ScrollContainer/VBox/Meta/ReloadBool".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]
	else:
		$"ScrollContainer/VBox/Meta/ReloadBool".text = "False"
		$"ScrollContainer/VBox/Meta/ReloadBool".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]

	#% Choice Selection:
	if line_data["ChoiceSelected"] == true:
		$"ScrollContainer/VBox/ChoiceSelect/Selected".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]
	else:
		$"ScrollContainer/VBox/ChoiceSelect/Selected".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]

	if line_data["ChoiceAll"] == true:
		$"ScrollContainer/VBox/ChoiceSelect/All".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]
	else:
		$"ScrollContainer/VBox/ChoiceSelect/All".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]

	$"ScrollContainer/VBox/ChoiceSelect/Tags".text = line_data["ChoiceTags"]
	$"ScrollContainer/VBox/ChoiceSelect/Names".text = line_data["ChoiceNames"]

	#% Timer Selection:
	if line_data["TimerTriggered"] == true:
		$"ScrollContainer/VBox/TimerSelect/Selected".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]
	else:
		$"ScrollContainer/VBox/TimerSelect/Selected".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]

	if line_data["TimerAll"] == true:
		$"ScrollContainer/VBox/TimerSelect/All".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]
	else:
		$"ScrollContainer/VBox/TimerSelect/All".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]

	$"ScrollContainer/VBox/TimerSelect/Tags".text = line_data["TimerTags"]
	$"ScrollContainer/VBox/TimerSelect/Names".text = line_data["TimerNames"]


	#% Scenes:
	$"ScrollContainer/VBox/Scenes/MenuScene".text = line_data["Changes"]["General"]["MenuScene"]
	$"ScrollContainer/VBox/Scenes/ButtonScene".text = line_data["Changes"]["General"]["ButtonScene"]


	#% MouseMode:
	var mouse_mode_button: OptionButton = $"ScrollContainer/VBox/MouseMode/MouseMode"
	var mouse_mode_value := str(line_data["Changes"]["General"].get("MouseMode", ""))
	for i in range(mouse_mode_button.item_count):
		if mouse_mode_button.get_item_text(i) == mouse_mode_value:
			mouse_mode_button.select(i)
			break

	#% Limiter:
	if line_data["Changes"]["General"]["Limit"] == null:
		$"ScrollContainer/VBox/Limiter/Limit".text = ""
	else:
		$"ScrollContainer/VBox/Limiter/Limit".text = str(line_data["Changes"]["General"]["Limit"])


	var limit_mode_button: OptionButton = $"ScrollContainer/VBox/Limiter/Mode"
	var limit_mode_value := str(line_data["Changes"]["General"].get("LimitMode", ""))
	for i in range(limit_mode_button.item_count):
		if limit_mode_button.get_item_text(i) == limit_mode_value:
			limit_mode_button.select(i)
			break

	#% General Timer:
	if line_data["Changes"]["General"]["Timer"] == null:
		$"ScrollContainer/VBox/GeneralTimer/Time".text = ""
	else:
		$"ScrollContainer/VBox/GeneralTimer/Time".text = str(line_data["Changes"]["General"]["Timer"])

	var timer_mode_button: OptionButton = $"ScrollContainer/VBox/GeneralTimer/Mode"
	var timer_mode_value := str(line_data["Changes"]["General"].get("TimerMode", ""))
	for i in range(timer_mode_button.item_count):
		if timer_mode_button.get_item_text(i) == timer_mode_value:
			timer_mode_button.select(i)
			break

	var timer_draw_button: OptionButton = $"ScrollContainer/VBox/GeneralTimer/Draw"
	var timer_draw_value := str(line_data["Changes"]["General"].get("TimerDraw", ""))
	for i in range(timer_draw_button.item_count):
		if timer_draw_button.get_item_text(i) == timer_draw_value:
			timer_draw_button.select(i)
			break

	var timer_loop_button: OptionButton = $"ScrollContainer/VBox/GeneralTimer/Loop"
	var timer_loop_value := str(line_data["Changes"]["General"].get("TimerLoop", ""))
	for i in range(timer_loop_button.item_count):
		if timer_loop_button.get_item_text(i) == timer_loop_value:
			timer_loop_button.select(i)
			break

	var timer_show_button: OptionButton = $"ScrollContainer/VBox/GeneralTimer/Show"
	var timer_show_value := str(line_data["Changes"]["General"].get("ShowTimer", ""))
	for i in range(timer_show_button.item_count):
		if timer_show_button.get_item_text(i) == timer_show_value:
			timer_show_button.select(i)
			break


	#% Choices:
	$"ScrollContainer/VBox/Choices1/ChoiceLabel".text = line_data["Changes"]["Choices"]["Label"]
	$"ScrollContainer/VBox/Choices1/Tags".text = line_data["Changes"]["Choices"]["Tags"]
	$"ScrollContainer/VBox/Choices2/Tooltip".text = line_data["Changes"]["Choices"]["Tooltip"]
	$"ScrollContainer/VBox/Choices2/ButtonScene".text = line_data["Changes"]["Choices"]["ButtonScene"]

	if line_data["Changes"]["Choices"]["Weight"] == null:
		$"ScrollContainer/VBox/Choices3/Weight".text = ""
	else:
		$"ScrollContainer/VBox/Choices3/Weight".text = str(line_data["Changes"]["Choices"]["Weight"])

	if line_data["Changes"]["Choices"]["Limit"] == null:
		$"ScrollContainer/VBox/Choices3/Limit".text = ""
	else:
		$"ScrollContainer/VBox/Choices3/Limit".text = str(line_data["Changes"]["Choices"]["Limit"])

	if line_data["Changes"]["Choices"]["Auto"] == null:
		$"ScrollContainer/VBox/Choices3/Auto".text = ""
	else:
		$"ScrollContainer/VBox/Choices3/Auto".text = str(line_data["Changes"]["Choices"]["Auto"])

	var choice_enable_button: OptionButton = $"ScrollContainer/VBox/Choices4/Enable"
	var choice_enable_value := str(line_data["Changes"]["Choices"].get("Enable", ""))
	for i in range(choice_enable_button.item_count):
		if choice_enable_button.get_item_text(i) == choice_enable_value:
			choice_enable_button.select(i)
			break

	var choice_activate_button: OptionButton = $"ScrollContainer/VBox/Choices4/Activate"
	var choice_activate_value := str(line_data["Changes"]["Choices"].get("Active", ""))
	for i in range(choice_activate_button.item_count):
		if choice_activate_button.get_item_text(i) == choice_activate_value:
			choice_activate_button.select(i)
			break

	var choice_show_button: OptionButton = $"ScrollContainer/VBox/Choices4/Show"
	var choice_show_value := str(line_data["Changes"]["Choices"].get("Show", ""))
	for i in range(choice_show_button.item_count):
		if choice_show_button.get_item_text(i) == choice_show_value:
			choice_show_button.select(i)
			break

	var choice_close_button: OptionButton = $"ScrollContainer/VBox/Choices4/Close"
	var choice_close_value := str(line_data["Changes"]["Choices"].get("Close", ""))
	for i in range(choice_close_button.item_count):
		if choice_close_button.get_item_text(i) == choice_close_value:
			choice_close_button.select(i)
			break


	#% Choice Timers:
	$"ScrollContainer/VBox/Timers1/Tags".text = line_data["Changes"]["Timers"]["Tags"]

	if line_data["Changes"]["Timers"]["Time"] == null:
		$"ScrollContainer/VBox/Timers2/Time".text = ""
	else:
		$"ScrollContainer/VBox/Timers2/Time".text = str(line_data["Changes"]["Timers"]["Time"])

	var ctimer_start_button: OptionButton = $"ScrollContainer/VBox/Timers2/Start"
	var ctimer_start_value := str(line_data["Changes"]["Timers"].get("Start", ""))
	for i in range(ctimer_start_button.item_count):
		if ctimer_start_button.get_item_text(i) == ctimer_start_value:
			ctimer_start_button.select(i)
			break

	var ctimer_loop_button: OptionButton = $"ScrollContainer/VBox/Timers2/Start"
	var ctimer_loop_value := str(line_data["Changes"]["Timers"].get("Loop", ""))
	for i in range(ctimer_loop_button.item_count):
		if ctimer_loop_button.get_item_text(i) == ctimer_loop_value:
			ctimer_loop_button.select(i)
			break

	var ctimer_show_button: OptionButton = $"ScrollContainer/VBox/Timers2/Start"
	var ctimer_show_value := str(line_data["Changes"]["Timers"].get("ShowTimer", ""))
	for i in range(ctimer_show_button.item_count):
		if ctimer_show_button.get_item_text(i) == ctimer_show_value:
			ctimer_show_button.select(i)
			break

	var ctimer_select_button: OptionButton = $"ScrollContainer/VBox/Timers2/Start"
	var ctimer_select_value := str(line_data["Changes"]["Timers"].get("Select", ""))
	for i in range(ctimer_select_button.item_count):
		if ctimer_select_button.get_item_text(i) == ctimer_select_value:
			ctimer_select_button.select(i)
			break


	#% Transitions:
	var setup_trans_button: OptionButton = $"ScrollContainer/VBox/SetupTrans/Transition"
	var setup_trans_value := str(line_data["Changes"]["Transitions"]["Setup"].get("Transition", ""))
	for i in range(setup_trans_button.item_count):
		if setup_trans_button.get_item_text(i) == setup_trans_value:
			setup_trans_button.select(i)
			break

	$"ScrollContainer/VBox/SetupTrans/Conversation".text = line_data["Changes"]["Transitions"]["Setup"]["Conversation"]
	$"ScrollContainer/VBox/SetupTrans/Block".text = line_data["Changes"]["Transitions"]["Setup"]["Block"]
	$"ScrollContainer/VBox/SetupTrans/Line".text = line_data["Changes"]["Transitions"]["Setup"]["Line"]


	var init_trans_button: OptionButton = $"ScrollContainer/VBox/InitTrans/Transition"
	var init_trans_value := str(line_data["Changes"]["Transitions"]["Initialization"].get("Transition", ""))
	for i in range(init_trans_button.item_count):
		if init_trans_button.get_item_text(i) == init_trans_value:
			init_trans_button.select(i)
			break

	$"ScrollContainer/VBox/InitTrans/Conversation".text = line_data["Changes"]["Transitions"]["Initialization"]["Conversation"]
	$"ScrollContainer/VBox/InitTrans/Block".text = line_data["Changes"]["Transitions"]["Initialization"]["Block"]
	$"ScrollContainer/VBox/InitTrans/Line".text = line_data["Changes"]["Transitions"]["Initialization"]["Line"]


	var chosen_trans_button: OptionButton = $"ScrollContainer/VBox/ChosenTrans/Transition"
	var chosen_trans_value := str(line_data["Changes"]["Transitions"]["Chosen"].get("Transition", ""))
	for i in range(chosen_trans_button.item_count):
		if chosen_trans_button.get_item_text(i) == chosen_trans_value:
			chosen_trans_button.select(i)
			break

	$"ScrollContainer/VBox/ChosenTrans/Conversation".text = line_data["Changes"]["Transitions"]["Chosen"]["Conversation"]
	$"ScrollContainer/VBox/ChosenTrans/Block".text = line_data["Changes"]["Transitions"]["Chosen"]["Block"]
	$"ScrollContainer/VBox/ChosenTrans/Line".text = line_data["Changes"]["Transitions"]["Chosen"]["Line"]


	var ctimer_trans_button: OptionButton = $"ScrollContainer/VBox/CTimerTrans/Transition"
	var ctimer_trans_value := str(line_data["Changes"]["Transitions"]["End"].get("Transition", ""))
	for i in range(ctimer_trans_button.item_count):
		if ctimer_trans_button.get_item_text(i) == ctimer_trans_value:
			ctimer_trans_button.select(i)
			break

	$"ScrollContainer/VBox/CTimerTrans/Conversation".text = line_data["Changes"]["Transitions"]["End"]["Conversation"]
	$"ScrollContainer/VBox/CTimerTrans/Block".text = line_data["Changes"]["Transitions"]["End"]["Block"]
	$"ScrollContainer/VBox/CTimerTrans/Line".text = line_data["Changes"]["Transitions"]["End"]["Line"]


func _on_choice_timer_select_item_selected(index: int) -> void:
	line_data["Changes"]["Timers"]["Select"] = $"ScrollContainer/VBox/Timers2/Select".get_item_text(index)

func _on_choice_timer_show_item_selected(index: int) -> void:
	line_data["Changes"]["Timers"]["ShowTimer"] = $"ScrollContainer/VBox/Timers2/Show".get_item_text(index)

func _on_choice_timer_loop_item_selected(index: int) -> void:
	line_data["Changes"]["Timers"]["Loop"] = $"ScrollContainer/VBox/Timers2/Loop".get_item_text(index)

func _on_choice_timer_start_item_selected(index: int) -> void:
	line_data["Changes"]["Timers"]["Start"] = $"ScrollContainer/VBox/Timers2/Start".get_item_text(index)

func _on_choice_timer_tags_text_changed(new_text: String) -> void:
	if new_text == "":
		line_data["Changes"]["Timers"]["Tags"] = null
	else:
		line_data["Changes"]["Timers"]["Tags"] = int(new_text)


func _on_close_item_selected(index: int) -> void:
	line_data["Changes"]["Choices"]["Close"] = $"ScrollContainer/VBox/Choices4/Close".get_item_text(index)

func _on_choice_show_item_selected(index: int) -> void:
	line_data["Changes"]["Choices"]["Show"] = $"ScrollContainer/VBox/Choices4/Show".get_item_text(index)

func _on_activate_item_selected(index: int) -> void:
	line_data["Changes"]["Choices"]["Active"] = $"ScrollContainer/VBox/Choices4/Activate".get_item_text(index)

func _on_enable_item_selected(index: int) -> void:
	line_data["Changes"]["Choices"]["Enabled"] = $"ScrollContainer/VBox/Choices4/Enable".get_item_text(index)


func _on_choice_limit_text_changed(new_text: String) -> void:
	if new_text == "":
		line_data["Changes"]["Choices"]["Auto"] = null
	else:
		line_data["Changes"]["Choices"]["Limit"] = int(new_text)

func _on_weight_text_changed(new_text: String) -> void:
	if new_text == "":
		line_data["Changes"]["Choices"]["Auto"] = null
	else:
		line_data["Changes"]["Choices"]["Weight"] = int(new_text)

func _on_auto_text_changed(new_text: String) -> void:
	if new_text == "":
		line_data["Changes"]["Choices"]["Auto"] = null
	else:
		line_data["Changes"]["Choices"]["Auto"] = int(new_text)

func _on_choice_button_scene_text_changed(new_text: String) -> void:
	line_data["Changes"]["Choices"]["ButtonScene"] = new_text

func _on_tooltip_text_changed(new_text: String) -> void:
	line_data["Changes"]["Choices"]["Tooltip"] = new_text

func _on_choice_tags_text_changed(new_text: String) -> void:
	line_data["Changes"]["Choices"]["Tags"] = new_text

func _on_choice_label_text_changed(new_text: String) -> void:
	line_data["Changes"]["Choices"]["Label"] = new_text


func _on_general_timer_show_item_selected(index: int) -> void:
	line_data["Changes"]["General"]["ShowTimer"] = $"ScrollContainer/VBox/GeneralTimer/Show".get_item_text(index)

func _on_general_timer_loop_item_selected(index: int) -> void:
	line_data["Changes"]["General"]["TimerLoop"] = $"ScrollContainer/VBox/GeneralTimer/Loop".get_item_text(index)

func _on_general_timer_draw_item_selected(index: int) -> void:
	line_data["Changes"]["General"]["TimerDraw"] = $"ScrollContainer/VBox/GeneralTimer/Draw".get_item_text(index)

func _on_general_timer_mode_item_selected(index: int) -> void:
	line_data["Changes"]["General"]["TimerMode"] = $"ScrollContainer/VBox/GeneralTimer/Mode".get_item_text(index)

func _on_general_timer_time_text_changed(new_text: String) -> void:
	if new_text == "":
		line_data["Changes"]["General"]["Timer"] = null
	else:
		line_data["Changes"]["General"]["Timer"] = int(new_text)


func _on_limiter_mode_item_selected(index: int) -> void:
	line_data["Changes"]["General"]["LimitMode"] = $"ScrollContainer/VBox/Limiter/Mode".get_item_text(index)

func _on_limiter_limit_text_changed(new_text: String) -> void:
	if new_text == "":
		line_data["Changes"]["General"]["Limit"] = null
	else:
		line_data["Changes"]["General"]["Limit"] = int(new_text)


func _on_mouse_mode_item_selected(index: int) -> void:
	line_data["Changes"]["General"]["Mouse"] = $"ScrollContainer/VBox/MouseMode/MouseMode".get_item_text(index)


func _on_button_scene_text_changed(new_text: String) -> void:
	line_data["Changes"]["General"]["ButtonScene"] = new_text

func _on_menu_scene_text_changed(new_text: String) -> void:
	line_data["Changes"]["General"]["MenuScene"] = new_text


func _on_timer_select_names_text_changed(new_text: String) -> void:
	line_data["TimerNames"] = new_text

func _on_timer_select_tags_text_changed(new_text: String) -> void:
	line_data["TimerTags"] = new_text

func _on_timer_select_selected_pressed() -> void:
	if line_data["TimerTriggered"] == true:
		line_data["TimerTriggered"] = false
		$"ScrollContainer/VBox/TimerSelect/Selected".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]

	elif line_data["TimerTriggered"] == false:
		line_data["TimerTriggered"] = true
		$"ScrollContainer/VBox/TimerSelect/Selected".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]

func _on_timer_select_all_pressed() -> void:
	if line_data["TimerAll"] == true:
		line_data["TimerAll"] = false
		$"ScrollContainer/VBox/TimerSelect/All".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]

	elif line_data["TimerAll"] == false:
		line_data["TimerAll"] = true
		$"ScrollContainer/VBox/TimerSelect/All".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]


func _on_choice_select_names_text_changed(new_text: String) -> void:
	line_data["ChoiceNames"] = new_text

func _on_choice_select_tags_text_changed(new_text: String) -> void:
	line_data["ChoiceTags"] = new_text

func _on_choice_select_selected_pressed() -> void:
	if line_data["ChoiceSelected"] == true:
		line_data["ChoiceSelected"] = false
		$"ScrollContainer/VBox/ChoiceSelect/Selected".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]

	elif line_data["ChoiceSelected"] == false:
		line_data["ChoiceSelected"] = true
		$"ScrollContainer/VBox/ChoiceSelect/Selected".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]

func _on_choice_select_all_pressed() -> void:
	if line_data["ChoiceAll"] == true:
		line_data["ChoiceAll"] = false
		$"ScrollContainer/VBox/ChoiceSelect/All".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]

	elif line_data["ChoiceAll"] == false:
		line_data["ChoiceAll"] = true
		$"ScrollContainer/VBox/ChoiceSelect/All".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]


func _on_reload_bool_pressed() -> void:
	if line_data["Reload"] == true:
		line_data["Reload"] = false
		$"ScrollContainer/VBox/Meta/ReloadBool".text = "False"
		$"ScrollContainer/VBox/Meta/ReloadBool".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]

	elif line_data["Reload"] == false:
		line_data["Reload"] = true
		$"ScrollContainer/VBox/Meta/ReloadBool".text = "True"
		$"ScrollContainer/VBox/Meta/ReloadBool".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]


func _on_target_buttons_bool_pressed() -> void:
	if line_data["TargetButton"] == true:
		line_data["TargetButton"] = false
		$"ScrollContainer/VBox/Meta/TargetButtonsBool".text = "False"
		$"ScrollContainer/VBox/Meta/TargetButtonsBool".modulate = candy_dc.color_models[candy_dc.color_mode]["Off"]

	elif line_data["TargetButton"] == false:
		line_data["TargetButton"] = true
		$"ScrollContainer/VBox/Meta/TargetButtonsBool".text = "True"
		$"ScrollContainer/VBox/Meta/TargetButtonsBool".modulate = candy_dc.color_models[candy_dc.color_mode]["On"]




func _on_setup_transition_item_selected(index: int) -> void:
	line_data["Changes"]["Transitions"]["Setup"]["Transition"] = $"ScrollContainer/VBox/SetupTrans/Transition".get_item_text(index)

func _on_init_transition_item_selected(index: int) -> void:
	line_data["Changes"]["Transitions"]["Initialization"]["Transition"] = $"ScrollContainer/VBox/InitTrans/Transition".get_item_text(index)

func _on_chosen_transition_item_selected(index: int) -> void:
	line_data["Changes"]["Transitions"]["Chosen"]["Transition"] = $"ScrollContainer/VBox/ChosenTrans/Transition".get_item_text(index)

func _on_ctimer_transition_item_selected(index: int) -> void:
	line_data["Changes"]["Transitions"]["End"]["Transition"] = $"ScrollContainer/VBox/CTimerTrans/Transition".get_item_text(index)


func _on_setup_trans_conversation_text_changed(new_text: String) -> void:
	line_data["Changes"]["Transitions"]["Setup"]["Conversation"] = new_text

func _on_setup_trans_block_text_changed(new_text: String) -> void:
	line_data["Changes"]["Transitions"]["Setup"]["Block"] = new_text

func _on_setup_trans_line_text_changed(new_text: String) -> void:
	line_data["Changes"]["Transitions"]["Setup"]["Line"] = new_text


func _on_init_trans_conversation_text_changed(new_text: String) -> void:
	line_data["Changes"]["Transitions"]["Initialization"]["Conversation"] = new_text

func _on_init_trans_block_text_changed(new_text: String) -> void:
	line_data["Changes"]["Transitions"]["Initialization"]["Block"] = new_text

func _on_init_trans_line_text_changed(new_text: String) -> void:
	line_data["Changes"]["Transitions"]["Initialization"]["Line"] = new_text



func _on_chosen_trans_conversation_text_changed(new_text: String) -> void:
	line_data["Changes"]["Transitions"]["Chosen"]["Conversation"] = new_text

func _on_chosen_trans_block_text_changed(new_text: String) -> void:
	line_data["Changes"]["Transitions"]["Chosen"]["Block"] = new_text

func _on_chosen_trans_line_text_changed(new_text: String) -> void:
	line_data["Changes"]["Transitions"]["Chosen"]["Line"] = new_text


func _on_ctimer_trans_conversation_text_changed(new_text: String) -> void:
	line_data["Changes"]["Transitions"]["End"]["Conversation"] = new_text

func _on_ctimer_trans_block_text_changed(new_text: String) -> void:
	line_data["Changes"]["Transitions"]["End"]["Block"] = new_text

func _on_ctimer_trans_line_text_changed(new_text: String) -> void:
	line_data["Changes"]["Transitions"]["End"]["Line"] = new_text


func _on_enter_pressed() -> void:
	self.visible = false
	candy_dc.editor_state = "ui"




func _on_conversation_button_pressed(source) -> void:
	#@ Get references to menu and list container
	var popup: PopupPanel = main.get_node("FileMenu")
	var vbox: VBoxContainer = main.get_node("FileMenu/ScrollContainer/VBoxContainer")

	#@ Clear previous entries
	for child in vbox.get_children():
		child.queue_free()

	#@ Add all conversations as selectable buttons
	for convo_name in candy_dc.conversations.keys():
		var btn := Button.new()
		btn.text = convo_name
		btn.connect("pressed", func():
			#% Update dictionary and LineEdit when conversation selected

			if source.get_parent().get_parent().get_parent().name == "SetupTrans":
				line_data["Changes"]["Transitions"]["Setup"]["Conversation"] = convo_name
			elif source.get_parent().get_parent().get_parent().name == "InitTrans":
				line_data["Changes"]["Transitions"]["Initialization"]["Conversation"] = convo_name
			elif source.get_parent().get_parent().get_parent().name == "ChosenTrans":
				line_data["Changes"]["Transitions"]["Chosen"]["Conversation"] = convo_name
			elif source.get_parent().get_parent().get_parent().name == "CTimerTrans":
				line_data["Changes"]["Transitions"]["End"]["Conversation"] = convo_name

			source.get_parent().text = convo_name
			popup.hide()
		)
		vbox.add_child(btn)

	#@ Show the menu near the button
	popup.popup_centered()



func _on_block_button_pressed(source) -> void:
	var popup: PopupPanel = main.get_node("FileMenu")
	var vbox: VBoxContainer = main.get_node("FileMenu/ScrollContainer/VBoxContainer")

	#@ Clear previous entries
	for child in vbox.get_children():
		child.queue_free()

	#@ Determine which conversation to use
	var convo_name
	if source.get_parent().get_parent().get_parent().name == "SetupTrans":
		convo_name = $"ScrollContainer/VBox/SetupTrans/Conversation".text
	elif source.get_parent().get_parent().get_parent().name == "InitTrans":
		convo_name = $"ScrollContainer/VBox/InitTrans/Conversation".text
	elif source.get_parent().get_parent().get_parent().name == "ChosenTrans":
		convo_name = $"ScrollContainer/VBox/ChosenTrans/Conversation".text
	elif source.get_parent().get_parent().get_parent().name == "CTimerTrans":
		convo_name = $"ScrollContainer/VBox/CTimerTrans/Conversation".text

	if convo_name == "" or not candy_dc.conversations.has(convo_name):
		convo_name = candy_dc.current_conversation

	#@ Get that conversation’s blocks
	var convo_data: Dictionary = candy_dc.conversations[convo_name]

	#@ Add block buttons
	for block_name in convo_data.keys():
		var btn := Button.new()
		btn.text = block_name
		btn.connect("pressed", func():
			if source.get_parent().get_parent().get_parent().name == "SetupTrans":
				line_data["Changes"]["Transitions"]["Setup"]["Block"] = block_name
			elif source.get_parent().get_parent().get_parent().name == "InitTrans":
				line_data["Changes"]["Transitions"]["Initialization"]["Block"] = block_name
			elif source.get_parent().get_parent().get_parent().name == "ChosenTrans":
				line_data["Changes"]["Transitions"]["Chosen"]["Block"] = block_name
			elif source.get_parent().get_parent().get_parent().name == "CTimerTrans":
				line_data["Changes"]["Transitions"]["End"]["Block"] = block_name
			source.get_parent().text = block_name
			popup.hide()
		)
		vbox.add_child(btn)

	#@ Show the popup
	popup.popup_centered()


func _on_line_button_pressed(source) -> void:
	var popup: PopupPanel = main.get_node("FileMenu")
	var vbox: VBoxContainer = main.get_node("FileMenu/ScrollContainer/VBoxContainer")

	#@ Clear previous entries
	for child in vbox.get_children():
		child.queue_free()

	#@ Determine conversation and block
	var convo_name
	if source.get_parent().get_parent().get_parent().name == "SetupTrans":
		convo_name = $"ScrollContainer/VBox/SetupTrans/Conversation".text
	elif source.get_parent().get_parent().get_parent().name == "InitTrans":
		convo_name = $"ScrollContainer/VBox/InitTrans/Conversation".text
	elif source.get_parent().get_parent().get_parent().name == "ChosenTrans":
		convo_name = $"ScrollContainer/VBox/ChosenTrans/Conversation".text
	elif source.get_parent().get_parent().get_parent().name == "CTimerTrans":
		convo_name = $"ScrollContainer/VBox/CTimerTrans/Conversation".text

	var block_name
	if source.get_parent().get_parent().get_parent().name == "SetupTrans":
		block_name = $"ScrollContainer/VBox/SetupTrans/Block".text
	elif source.get_parent().get_parent().get_parent().name == "InitTrans":
		block_name = $"ScrollContainer/VBox/InitTrans/Block".text
	elif source.get_parent().get_parent().get_parent().name == "ChosenTrans":
		block_name = $"ScrollContainer/VBox/ChosenTrans/Block".text
	elif source.get_parent().get_parent().get_parent().name == "CTimerTrans":
		block_name = $"ScrollContainer/VBox/CTimerTrans/Block".text

	var convo_valid = convo_name != "" and candy_dc.conversations.has(convo_name)
	var block_valid = block_name != ""

	#@ Case 1: no convo + no block → use current convo/block
	if convo_name == "" and block_name == "":
		convo_name = candy_dc.current_conversation
		block_name = candy_dc.current_block

	#@ Case 2: no convo + block selected → use current convo if block exists
	elif convo_name == "" and block_name != "":
		if candy_dc.conversations[candy_dc.current_conversation].has(block_name):
			convo_name = candy_dc.current_conversation
		else:
			block_name = ""
			convo_name = candy_dc.current_conversation

	#@ Case 3: convo selected but no block → invalid setup
	elif convo_valid and not block_valid:
		var label := Label.new()
		label.text = "[Not Found]"
		vbox.add_child(label)
		popup.popup_centered()
		return

	#@ Verify final convo/block exist
	if not candy_dc.conversations.has(convo_name) or not candy_dc.conversations[convo_name].has(block_name):
		var label := Label.new()
		label.text = "[Not Found]"
		vbox.add_child(label)
		popup.popup_centered()
		return

	#@ Collect all "Line Marker Command" lines in the target block
	var lines = candy_dc.conversations[convo_name][block_name]["Text"]
	var found := false
	for line_dict in lines:
		if line_dict.has("LM Command"):
			var ref_name := str(line_dict["LM Command"].get("Reference", ""))
			if ref_name.strip_edges() == "":
				continue
			found = true
			var btn := Button.new()
			btn.text = ref_name
			btn.connect("pressed", func():
				if source.get_parent().get_parent().get_parent().name == "SetupTrans":
					line_data["Changes"]["Transitions"]["Setup"]["Line"] = ref_name
				elif source.get_parent().get_parent().get_parent().name == "InitTrans":
					line_data["Changes"]["Transitions"]["Initialization"]["Line"] = ref_name
				elif source.get_parent().get_parent().get_parent().name == "ChosenTrans":
					line_data["Changes"]["Transitions"]["Chosen"]["Line"] = ref_name
				elif source.get_parent().get_parent().get_parent().name == "CTimerTrans":
					line_data["Changes"]["Transitions"]["End"]["Line"] = ref_name
				source.get_parent().text = ref_name
				popup.hide()
			)
			vbox.add_child(btn)

	#@ If nothing found, display a [Not Found] entry
	if not found:
		var label := Label.new()
		label.text = "[Not Found]"
		vbox.add_child(label)

	popup.popup_centered()



func apply_menu_or_button_scene(field, scene):
	field.text = scene

	if field == get_node("ScrollContainer/VBox/Scenes/MenuScene"):
		line_data["Changes"]["General"]["MenuScene"] = scene

	elif field == get_node("ScrollContainer/VBox/Scenes/ButtonScene"):
		line_data["Changes"]["General"]["ButtonScene"] = scene

	elif field == get_node("ScrollContainer/VBox/Choices2/ButtonScene"):
		line_data["Changes"]["Choices"]["ButtonScene"] = scene


func _on_menu_select_pressed() -> void:
	var field = get_node("ScrollContainer/VBox/Scenes/MenuScene")
	main.open_choice_menus_menu("Alter", field)

func _on_button_select_pressed() -> void:
	var field = get_node("ScrollContainer/VBox/Scenes/ButtonScene")
	main.open_choice_buttons_menu("Alter", field)

func _on_choice_button_select_pressed() -> void:
	var field = get_node("ScrollContainer/VBox/Choices2/ButtonScene")
	main.open_choice_buttons_menu("Alter", field)

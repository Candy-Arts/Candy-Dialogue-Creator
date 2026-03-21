extends CanvasLayer

@onready var main = get_node("/root/UI")

#^ Add right-click delete menus for Choices and ChoiceTimers
@onready var choice_rc: PopupMenu = PopupMenu.new()
@onready var timer_rc: PopupMenu = PopupMenu.new()

var conversation = ""
var block = ""
var line_index = -1
var choices_reference = ""
var line_data: Dictionary

var selected_choice = ""
var selected_timer = ""


func _ready() -> void:
	#@ Create Choice context menu:
	choice_rc.name = "ChoiceRC"
	choice_rc.add_item("Delete Choice", 0)
	choice_rc.id_pressed.connect(_on_choice_context_selected)
	add_child(choice_rc)

	#@ Create Timer context menu:
	timer_rc.name = "TimerRC"
	timer_rc.add_item("Delete Timer", 0)
	timer_rc.id_pressed.connect(_on_timer_context_selected)
	add_child(timer_rc)

	#@ Right-click on Choices → show delete option:
	$"Choices".gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if $"Choices".selected >= 0:
				var disable_delete = $"Choices".item_count <= 1
				choice_rc.set_item_disabled(0, disable_delete)
				choice_rc.set_position(get_viewport().get_mouse_position())
				choice_rc.popup()
	)

	#@ Right-click on ChoiceTimers → show delete option:
	$"Choice Settings/ChoiceTimers".gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if $"Choice Settings/ChoiceTimers".selected >= 0:
				timer_rc.set_item_disabled(0, false)
				timer_rc.set_position(get_viewport().get_mouse_position())
				timer_rc.popup()
	)

#* Called when user selects an option in the Choices context menu:
func _on_choice_context_selected(id: int) -> void:
	if id != 0:
		return

	var choice_box: OptionButton = $"Choices"
	if choice_box.item_count <= 1:
		return   #/ Prevent deleting the last one

	var choice_name := choice_box.get_item_text(choice_box.selected)
	line_data["Choices"].erase(choice_name)
	choice_box.remove_item(choice_box.selected)

	#@ Auto-select first remaining choice:
	if choice_box.item_count > 0:
		selected_choice = choice_box.get_item_text(0)
		line_data["SelectedChoice"] = selected_choice
	else:
		selected_choice = ""
		line_data["SelectedChoice"] = ""

	load_choice_data()


#* Called when user selects an option in the Timer context menu
func _on_timer_context_selected(id: int) -> void:
	if id != 0:
		return

	var timer_box: OptionButton = $"Choice Settings/ChoiceTimers"
	if timer_box.selected < 0:
		return

	var timer_name := timer_box.get_item_text(timer_box.selected)
	var timers_dict: Dictionary = line_data["Choices"][selected_choice]["Timers"]

	#% Remove the deleted timer from data and UI
	if timers_dict.has(timer_name):
		timers_dict.erase(timer_name)
	timer_box.remove_item(timer_box.selected)

	#% Choose a new selected timer if any remain
	if timer_box.item_count > 0:
		selected_timer = timer_box.get_item_text(0)
		line_data["Choices"][selected_choice]["SelectedTimer"] = selected_timer
	else:
		selected_timer = ""
		line_data["Choices"][selected_choice]["SelectedTimer"] = ""
		$"Choice Settings/Choice Timer Settings".visible = false

	load_choice_data()


#* Close editor:
func _on_finish_pressed() -> void:
	self.visible = false
	candy_dc.editor_state = "ui"


func _on_mouse_mode_item_selected(index: int) -> void:
	line_data["Mouse"] = $"MouseMode".get_item_text(index)


func _on_choices_limit_changed(new_text: String) -> void:
	line_data["Limit"] = int(new_text)


func _on_limit_mode_item_selected(index: int) -> void:
	line_data["LimitMode"] = $"LimitMode".get_item_text(index)


func _on_gen_timer_changed(new_text: String) -> void:
	line_data["Timer"] = int(new_text)


func _on_timer_mode_pressed() -> void:
	if line_data["TimerMode"] == "Single":
		line_data["TimerMode"] = "Multi"
		$"TimerMode".text = "Multi"
	elif line_data["TimerMode"] == "Multi":
		line_data["TimerMode"] = "Single"
		$"TimerMode".text = "Single"


func _on_timer_draw_item_selected(index: int) -> void:
	line_data["TimerDraw"] = $"TimerDraw".get_item_text(index)

func _on_gen_timer_loop_pressed() -> void:
	if line_data["TimerLoop"] == true:
		line_data["TimerLoop"] = false
		$"GenTimerLoop".modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]
	elif line_data["TimerLoop"] == false:
		line_data["TimerLoop"] = true
		$"GenTimerLoop".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]


func _on_show_general_timer_pressed() -> void:
	if line_data["ShowTimer"] == false:
		line_data["ShowTimer"] = true
		$"Show".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
	elif line_data["ShowTimer"] == true:
		line_data["ShowTimer"] = false
		$"Show".modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]


func _on_choice_select_pressed() -> void:
	var choice_box: OptionButton = $"Choices"

	#@ Clear existing list
	choice_box.clear()

	#@ Get all choices from the dictionary
	var choices_dict: Dictionary = line_data["Choices"]

	#@ Add all available choices
	for choice_name in choices_dict.keys():
		choice_box.add_item(choice_name)

	#@ Reselect the one currently active in the editor
	if selected_choice != "":
		for i in range(choice_box.item_count):
			if choice_box.get_item_text(i) == selected_choice:
				choice_box.select(i)
				break


func _on_choices_item_selected(index: int) -> void:
	#@ Update selected choice
	selected_choice = $"Choices".get_item_text(index)
	line_data["SelectedChoice"] = selected_choice

	#@ Check for timers in this choice
	var timers_dict: Dictionary = line_data["Choices"][selected_choice]["Timers"]
	if timers_dict.size() > 0:
		#% Select the first available timer
		var first_timer_name: String = timers_dict.keys()[0]
		selected_timer = first_timer_name
		line_data["Choices"][selected_choice]["SelectedTimer"] = first_timer_name
	else:
		#% No timers
		selected_timer = ""
		line_data["Choices"][selected_choice]["SelectedTimer"] = ""

	#@ Reload choice data in the editor
	load_choice_data()


func _on_add_choice_pressed() -> void:
	#@ Get the existing Choices dictionary
	var choices_dict: Dictionary = line_data["Choices"]

	#@ Find a new unique name: Choice_1, Choice_2, etc.
	var index := 1
	var new_choice_name := "Choice_%d" % index
	while choices_dict.has(new_choice_name):
		index += 1
		new_choice_name = "Choice_%d" % index

	#@ Create a new choice dictionary based on the template in Globals
	var template_choice: Dictionary = candy_dc.command_templates["§Choices"]["Choices"]["Choice_1"].duplicate(true)

	#@ Insert the new choice into the current line's Choices dictionary
	choices_dict[new_choice_name] = template_choice

	#@ Update the UI dropdown
	var choice_box: OptionButton = $"Choices"
	choice_box.add_item(new_choice_name)
	choice_box.select(choice_box.item_count - 1)

	#@ Update selection tracking
	line_data["SelectedChoice"] = new_choice_name
	selected_choice = new_choice_name

	#@ Clear any selected timer (new choice has none)
	line_data["Choices"][selected_choice]["SelectedTimer"] = ""
	selected_timer = ""

	#@ Refresh editor display for the new choice
	load_choice_data()


func _on_weight_text_changed(new_text: String) -> void:
	line_data["Choices"][selected_choice]["Weight"] = int(new_text)


func _on_limit_text_changed(new_text: String) -> void:
	line_data["Choices"][selected_choice]["Limit"] = int(new_text)


func _on_auto_text_changed(new_text: String) -> void:
	line_data["Choices"][selected_choice]["Auto"] = int(new_text)


func _on_choice_enabled_pressed() -> void:
	if line_data["Choices"][selected_choice]["Enabled"] == true:
		line_data["Choices"][selected_choice]["Enabled"] = false
		$"Choice Settings/Enabled".text = "Disabled"
		$"Choice Settings/Enabled".modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]

	elif line_data["Choices"][selected_choice]["Enabled"] == false:
		line_data["Choices"][selected_choice]["Enabled"] = true
		$"Choice Settings/Enabled".text = "Enabled"
		$"Choice Settings/Enabled".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]


func _on_choice_active_pressed() -> void:
	if line_data["Choices"][selected_choice]["Active"] == true:
		line_data["Choices"][selected_choice]["Active"] = false
		$"Choice Settings/Active".text = "Inactive"
		$"Choice Settings/Active".modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]

	elif line_data["Choices"][selected_choice]["Active"] == false:
		line_data["Choices"][selected_choice]["Active"] = true
		$"Choice Settings/Active".text = "Active"
		$"Choice Settings/Active".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]


func _on_choice_show_pressed() -> void:
	if line_data["Choices"][selected_choice]["Show"] == true:
		line_data["Choices"][selected_choice]["Show"] = false
		$"Choice Settings/Show".text = "Hide"
		$"Choice Settings/Show".modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]

	elif line_data["Choices"][selected_choice]["Show"] == false:
		line_data["Choices"][selected_choice]["Show"] = true
		$"Choice Settings/Show".text = "Show"
		$"Choice Settings/Show".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]

func _on_choice_close_pressed() -> void:
	if line_data["Choices"][selected_choice]["Close"] == true:
		line_data["Choices"][selected_choice]["Close"] = false
		$"Choice Settings/Close".text = "Continue Choices"

	elif line_data["Choices"][selected_choice]["Close"] == false:
		line_data["Choices"][selected_choice]["Close"] = true
		$"Choice Settings/Close".text = "Close Choices"

func _on_setup_transition_item_selected(index: int) -> void:
	line_data["Setup"]["Transition"] = $"Choice Settings/Init Transition".get_item_text(index)


func _on_setup_conversation_changed(new_text: String) -> void:
	line_data["Setup"]["Conversation"] = new_text


func _on_setup_conversations_button_pressed() -> void:
	#@ Get references to menu and list container
	var popup: PopupPanel = main.get_node("FileMenu")
	var vbox: VBoxContainer = main.get_node("FileMenu/ScrollContainer/VBoxContainer")


	#@ Clear previous entries
	for child in vbox.get_children():
		child.queue_free()

	#@ Add all conversations as selectable buttons
	var button_count = 0
	for convo_name in candy_dc.conversations.keys():
		var btn := Button.new()
		btn.text = convo_name
		btn.connect("pressed", func():
			#% Update dictionary and LineEdit when conversation selected
			line_data["Setup"]["Conversation"] = convo_name
			$"Setup Conversation".text = convo_name
			popup.hide()
		)
		vbox.add_child(btn)
		button_count += 1

	#% Position & show list:
	var call_button = get_node("Setup Conversation/Button")
	popup.position = call_button.get_global_position() + Vector2(-popup.size.x, call_button.size.y)
	popup.size.y = 8 + button_count * 31
	if popup.size.y > 318:
		popup.size.y = 318
	popup.popup()


func _on_setup_block_changed(new_text: String) -> void:
	line_data["Setup"]["Block"] = new_text


func _on_setup_block_button_pressed() -> void:
	var popup: PopupPanel = main.get_node("FileMenu")
	var vbox: VBoxContainer = main.get_node("FileMenu/ScrollContainer/VBoxContainer")

	#@ Clear previous entries
	for child in vbox.get_children():
		child.queue_free()

	#@ Determine which conversation to use
	var convo_name = line_data["Setup"]["Conversation"]
	if convo_name == "" or not candy_dc.conversations.has(convo_name):
		convo_name = candy_dc.current_conversation

	#@ Get that conversation’s blocks
	var convo_data: Dictionary = candy_dc.conversations[convo_name]

	#@ Add block buttons
	var button_count = 0
	for block_name in convo_data.keys():
		var btn := Button.new()
		btn.text = block_name
		btn.connect("pressed", func():
			line_data["Setup"]["Block"] = block_name
			$"Setup Block".text = block_name
			popup.hide()
		)
		vbox.add_child(btn)
		button_count += 1

	#% Position & show list:
	var call_button = get_node("Setup Block/Button")
	popup.position = call_button.get_global_position() + Vector2(-popup.size.x, call_button.size.y)
	popup.size.y = 8 + button_count * 31
	if popup.size.y > 318:
		popup.size.y = 318
	popup.popup()


func _on_setup_line_changed(new_text: String) -> void:
	line_data["Setup"]["Line"] = new_text


func _on_setup_line_button_pressed() -> void:
	var popup: PopupPanel = main.get_node("FileMenu")
	var vbox: VBoxContainer = main.get_node("FileMenu/ScrollContainer/VBoxContainer")

	#@ Clear previous entries
	for child in vbox.get_children():
		child.queue_free()

	#@ Determine conversation and block
	var convo_name = line_data["Setup"]["Conversation"]
	var block_name = line_data["Setup"]["Block"]
	if convo_name == "":
		convo_name = candy_dc.current_conversation
	if block_name == "":
		block_name = candy_dc.current_block

	#@ Verify final convo/block exist
	if not candy_dc.conversations.has(convo_name) or not candy_dc.conversations[convo_name].has(block_name):
		var label := Label.new()
		label.text = "[Not Found]"
		vbox.add_child(label)
		popup.size.y = 39
		popup.popup_centered()
		return

	#@ Collect all "Line Marker Command" lines in the target block
	var lines = candy_dc.conversations[convo_name][block_name]["Text"]
	var found := false
	var button_count = 0
	for line_dict in lines:
		if line_dict.has("§LM"):
			var ref_name := str(line_dict["§LM"].get("Reference", ""))
			if ref_name.strip_edges() == "":
				continue
			found = true
			var btn := Button.new()
			btn.text = ref_name
			btn.connect("pressed", func():
				line_data["Setup"]["Line"] = ref_name
				$"Setup Line".text = ref_name
				popup.hide()
			)
			vbox.add_child(btn)
			button_count += 1

	#@ If nothing found, display a [Not Found] entry
	if not found:
		var label := Label.new()
		label.text = "[Not Found]"
		vbox.add_child(label)
		popup.size.y = 39

	#% Position & show list:
	var call_button = get_node("Setup Line/Button")
	popup.position = call_button.get_global_position() + Vector2(-popup.size.x, call_button.size.y)
	popup.size.y = 8 + button_count * 31
	if popup.size.y > 318:
		popup.size.y = 318
	popup.popup()


#* Jump to Initialization target
func _on_setup_go_pressed() -> void:
	var conv_name = $"Setup Conversation".text.strip_edges()
	var block_name = $"Setup Block".text.strip_edges()

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
	_on_finish_pressed()


func _on_init_transition_item_selected(index: int) -> void:
	line_data["Choices"][selected_choice]["Initialization"]["Transition"] = $"Choice Settings/Init Transition".get_item_text(index)


func _on_init_conversation_changed(new_text: String) -> void:
	line_data["Choices"][selected_choice]["Initialization"]["Conversation"] = new_text


func _on_init_conversations_button_pressed() -> void:
	#@ Get references to menu and list container
	var popup: PopupPanel = main.get_node("FileMenu")
	var vbox: VBoxContainer = main.get_node("FileMenu/ScrollContainer/VBoxContainer")

	#@ Clear previous entries
	for child in vbox.get_children():
		child.queue_free()

	#@ Add all conversations as selectable buttons
	var button_count = 0
	for convo_name in candy_dc.conversations.keys():
		var btn := Button.new()
		btn.text = convo_name
		btn.connect("pressed", func():
			#% Update dictionary and LineEdit when conversation selected
			line_data["Choices"][selected_choice]["Initialization"]["Conversation"] = convo_name
			$"Choice Settings/Init Conversation".text = convo_name
			popup.hide()
		)
		vbox.add_child(btn)
		button_count += 1

	#% Position & show list:
	var call_button = get_node("Choice Settings/Init Conversation/Button")
	popup.position = call_button.get_global_position() + Vector2(-popup.size.x, call_button.size.y)
	popup.size.y = 8 + button_count * 31
	if popup.size.y > 318:
		popup.size.y = 318
	popup.popup()


func _on_init_block_changed(new_text: String) -> void:
	line_data["Choices"][selected_choice]["Initialization"]["Block"] = new_text


func _on_init_block_button_pressed() -> void:
	var popup: PopupPanel = main.get_node("FileMenu")
	var vbox: VBoxContainer = main.get_node("FileMenu/ScrollContainer/VBoxContainer")

	#@ Clear previous entries
	for child in vbox.get_children():
		child.queue_free()

	#@ Determine which conversation to use
	var convo_name = line_data["Choices"][selected_choice]["Initialization"]["Conversation"]
	if convo_name == "" or not candy_dc.conversations.has(convo_name):
		convo_name = candy_dc.current_conversation

	#@ Get that conversation’s blocks
	var convo_data: Dictionary = candy_dc.conversations[convo_name]

	#@ Add block buttons
	var button_count = 0
	for block_name in convo_data.keys():
		var btn := Button.new()
		btn.text = block_name
		btn.connect("pressed", func():
			line_data["Choices"][selected_choice]["Initialization"]["Block"] = block_name
			$"Choice Settings/Init Block".text = block_name
			popup.hide()
		)
		vbox.add_child(btn)
		button_count += 1

	#% Position & show list:
	var call_button = get_node("Choice Settings/Init Block/Button")
	popup.position = call_button.get_global_position() + Vector2(-popup.size.x, call_button.size.y)
	popup.size.y = 8 + button_count * 31
	if popup.size.y > 318:
		popup.size.y = 318
	popup.popup()


func _on_init_line_text_changed(new_text: String) -> void:
	line_data["Choices"][selected_choice]["Initialization"]["Line"] = new_text


func _on_init_line_button_pressed() -> void:
	var popup: PopupPanel = main.get_node("FileMenu")
	var vbox: VBoxContainer = main.get_node("FileMenu/ScrollContainer/VBoxContainer")

	#@ Clear previous entries
	for child in vbox.get_children():
		child.queue_free()

	#@ Determine conversation and block
	var convo_name = line_data["Choices"][selected_choice]["Initialization"]["Conversation"]
	var block_name = line_data["Choices"][selected_choice]["Initialization"]["Block"]
	if convo_name == "":
		convo_name = candy_dc.current_conversation
	if block_name == "":
		block_name = candy_dc.current_block

	#@ Verify final convo/block exist
	if not candy_dc.conversations.has(convo_name) or not candy_dc.conversations[convo_name].has(block_name):
		var label := Label.new()
		label.text = "[Not Found]"
		vbox.add_child(label)
		popup.size.y = 39
		popup.popup_centered()
		return

	#@ Collect all "Line Marker Command" lines in the target block
	var lines = candy_dc.conversations[convo_name][block_name]["Text"]
	var found := false
	var button_count = 0
	for line_dict in lines:
		if line_dict.has("§LM"):
			var ref_name := str(line_dict["§LM"].get("Reference", ""))
			if ref_name.strip_edges() == "":
				continue
			found = true
			var btn := Button.new()
			btn.text = ref_name
			btn.connect("pressed", func():
				line_data["Choices"][selected_choice]["Initialization"]["Line"] = ref_name
				$"Choice Settings/Init Line".text = ref_name
				popup.hide()
			)
			vbox.add_child(btn)
			button_count += 1

	#@ If nothing found, display a [Not Found] entry
	if not found:
		var label := Label.new()
		label.text = "[Not Found]"
		vbox.add_child(label)
		popup.size.y = 39

	#% Position & show list:
	var call_button = get_node("Choice Settings/Init Line/Button")
	popup.position = call_button.get_global_position() + Vector2(-popup.size.x, call_button.size.y)
	popup.size.y = 8 + button_count * 31
	if popup.size.y > 318:
		popup.size.y = 318
	popup.popup()


#* Jump to Initialization target
func _on_init_go_pressed() -> void:
	var conv_name = $"Choice Settings/Init Conversation".text.strip_edges()
	var block_name = $"Choice Settings/Init Block".text.strip_edges()

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
	_on_finish_pressed()


#* Jump to Chosen target
func _on_chosen_go_pressed() -> void:
	var conv_name = $"Choice Settings/Chosen Conversation".text.strip_edges()
	var block_name = $"Choice Settings/Chosen Block".text.strip_edges()

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
	_on_finish_pressed()


#* Jump to Timer target
func _on_timer_go_pressed() -> void:
	var conv_name = $"Choice Settings/Choice Timer Settings/Timer Conversation".text.strip_edges()
	var block_name = $"Choice Settings/Choice Timer Settings/Timer Block".text.strip_edges()

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
	_on_finish_pressed()


func _on_chosen_transition_item_selected(index: int) -> void:
	line_data["Choices"][selected_choice]["Chosen"]["Transition"] = $"Choice Settings/Chosen Transition".get_item_text(index)


func _on_chosen_conversation_changed(new_text: String) -> void:
	line_data["Choices"][selected_choice]["Chosen"]["Conversation"] = new_text


func _on_chosen_conversation_button_pressed() -> void:
	#@ Get references to menu and list container
	var popup: PopupPanel = main.get_node("FileMenu")
	var vbox: VBoxContainer = main.get_node("FileMenu/ScrollContainer/VBoxContainer")

	#@ Clear previous entries
	for child in vbox.get_children():
		child.queue_free()

	#@ Add all conversations as selectable buttons
	var button_count = 0
	for convo_name in candy_dc.conversations.keys():
		var btn := Button.new()
		btn.text = convo_name
		btn.connect("pressed", func():
			#% Update dictionary and LineEdit when conversation selected
			line_data["Choices"][selected_choice]["Chosen"]["Conversation"] = convo_name
			$"Choice Settings/Chosen Conversation".text = convo_name
			popup.hide()
		)
		vbox.add_child(btn)
		button_count += 1

	#% Position & show list:
	var call_button = get_node("Choice Settings/Chosen Conversation/Button")
	popup.size.y = 8 + button_count * 31
	if popup.size.y > 318:
		popup.size.y = 318
	popup.position = call_button.get_global_position() + Vector2(-popup.size.x, -popup.size.y)
	popup.popup()


func _on_chosen_block_changed(new_text: String) -> void:
	line_data["Choices"][selected_choice]["Chosen"]["Block"] = new_text


func _on_chosen_block_button_pressed() -> void:
	var popup: PopupPanel = main.get_node("FileMenu")
	var vbox: VBoxContainer = main.get_node("FileMenu/ScrollContainer/VBoxContainer")

	#@ Clear previous entries
	for child in vbox.get_children():
		child.queue_free()

	#@ Determine which conversation to use
	var convo_name = line_data["Choices"][selected_choice]["Chosen"]["Conversation"]
	if convo_name == "" or not candy_dc.conversations.has(convo_name):
		convo_name = candy_dc.current_conversation

	#@ Get that conversation’s blocks
	var convo_data: Dictionary = candy_dc.conversations[convo_name]

	#@ Add block buttons
	var button_count = 0
	for block_name in convo_data.keys():
		var btn := Button.new()
		btn.text = block_name
		btn.connect("pressed", func():
			line_data["Choices"][selected_choice]["Chosen"]["Block"] = block_name
			$"Choice Settings/Chosen Block".text = block_name
			popup.hide()
		)
		vbox.add_child(btn)
		button_count += 1

	#% Position & show list:
	var call_button = get_node("Choice Settings/Chosen Block/Button")
	popup.size.y = 8 + button_count * 31
	if popup.size.y > 318:
		popup.size.y = 318
	popup.position = call_button.get_global_position() + Vector2(-popup.size.x, -popup.size.y)
	popup.popup()


func _on_chosen_line_changed(new_text: String) -> void:
	line_data["Choices"][selected_choice]["Chosen"]["Line"] = new_text


func _on_chosen_line_button_pressed() -> void:
	var popup: PopupPanel = main.get_node("FileMenu")
	var vbox: VBoxContainer = main.get_node("FileMenu/ScrollContainer/VBoxContainer")

	#@ Clear previous entries
	for child in vbox.get_children():
		child.queue_free()

	#@ Determine conversation and block
	var convo_name = line_data["Choices"][selected_choice]["Chosen"]["Conversation"]
	var block_name = line_data["Choices"][selected_choice]["Chosen"]["Block"]
	if convo_name == "":
		convo_name = candy_dc.current_conversation
	if block_name == "":
		block_name = candy_dc.current_block

	#@ Verify final convo/block exist
	if not candy_dc.conversations.has(convo_name) or not candy_dc.conversations[convo_name].has(block_name):
		var label := Label.new()
		label.text = "[Not Found]"
		vbox.add_child(label)
		popup.size.y = 39
		popup.popup_centered()
		return

	#@ Collect all "Line Marker Command" lines in the target block
	var lines = candy_dc.conversations[convo_name][block_name]["Text"]
	var found := false
	var button_count = 0
	for line_dict in lines:
		if line_dict.has("§LM"):
			var ref_name := str(line_dict["§LM"].get("Reference", ""))
			if ref_name.strip_edges() == "":
				continue
			found = true
			var btn := Button.new()
			btn.text = ref_name
			btn.connect("pressed", func():
				line_data["Choices"][selected_choice]["Chosen"]["Line"] = ref_name
				$"Choice Settings/Chosen Line".text = ref_name
				popup.hide()
			)
			vbox.add_child(btn)
			button_count += 1

	#@ If nothing found, display a [Not Found] entry
	if not found:
		var label := Label.new()
		label.text = "[Not Found]"
		vbox.add_child(label)
		popup.size.y = 39

	#% Position & show list:
	var call_button = get_node("Choice Settings/Chosen Line/Button")
	popup.size.y = 8 + button_count * 31
	if popup.size.y > 318:
		popup.size.y = 318
	popup.position = call_button.get_global_position() + Vector2(-popup.size.x, -popup.size.y)
	popup.popup()


func _on_choice_timers_pressed() -> void:
	var timer_box: OptionButton = $"Choice Settings/ChoiceTimers"

	#@ Clear any existing entries
	timer_box.clear()

	#@ Get the timers dictionary for the current choice
	var timers_dict: Dictionary = line_data["Choices"][selected_choice]["Timers"]

	#@ Add each timer to the dropdown
	for timer_name in timers_dict.keys():
		timer_box.add_item(timer_name)

	#@ Reselect the active timer if one is set
	if selected_timer != "":
		for i in range(timer_box.item_count):
			if timer_box.get_item_text(i) == selected_timer:
				timer_box.select(i)
				break


func _on_choice_timers_item_selected(index: int) -> void:
	line_data["Choices"][selected_choice]["SelectedTimer"] = $"Choice Settings/ChoiceTimers".get_item_text(index)
	selected_timer = $"Choice Settings/ChoiceTimers".get_item_text(index)
	$"Choice Settings/Choice Timer Settings".visible = true
	load_timer_data()


func _on_add_choice_timer_pressed() -> void:
	#@ Get the current choice’s timer dictionary
	var timers_dict: Dictionary = line_data["Choices"][selected_choice]["Timers"]

	#@ Find a new unique timer name
	var index := 1
	var new_timer_name := "Timer %d" % index
	while timers_dict.has(new_timer_name):
		index += 1
		new_timer_name = "Timer %d" % index

	#@ Create a new timer dictionary (based on the template in Globals)
	var template_timer := {
		"Tags": "",
		"Time": -1,
		"Start": true,
		"Loop": false,
		"ShowTimer": true,
		"End": {
			"Transition": "Bridge",
			"Conversation": "",
			"Block": "",
			"Line": "",
		},
		"Select": true,
	}

	#@ Insert it into the choice’s Timers dictionary
	timers_dict[new_timer_name] = template_timer

	#@ Update the UI dropdown
	var timer_box: OptionButton = $"Choice Settings/ChoiceTimers"
	timer_box.add_item(new_timer_name)
	timer_box.select(timer_box.item_count - 1)

	#@ Update selection tracking
	line_data["Choices"][selected_choice]["SelectedTimer"] = new_timer_name
	selected_timer = new_timer_name
	$"Choice Settings/Choice Timer Settings".visible = true

	load_timer_data()


func _on_show_choice_timer_pressed() -> void:
	if line_data["Choices"][selected_choice]["Timers"][selected_timer]["ShowTimer"] == false:
		line_data["Choices"][selected_choice]["Timers"][selected_timer]["ShowTimer"] = true
		$"Choice Settings/Choice Timer Settings/Show".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
	elif line_data["Choices"][selected_choice]["Timers"][selected_timer]["ShowTimer"] == true:
		line_data["Choices"][selected_choice]["Timers"][selected_timer]["ShowTimer"] = false
		$"Choice Settings/Choice Timer Settings/Show".modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]


func _on_choice_timer_time_changed(new_text: String) -> void:
	line_data["Choices"][selected_choice]["Timers"][selected_timer]["Time"] = int(new_text)


func _on_timer_tags_text_changed(new_text: String) -> void:
	line_data["Choices"][selected_choice]["Timers"][selected_timer]["Tags"] = new_text


func _on_choice_timer_start_pressed() -> void:
	if line_data["Choices"][selected_choice]["Timers"][selected_timer]["Start"] == false:
		line_data["Choices"][selected_choice]["Timers"][selected_timer]["Start"] = true
		$"Choice Settings/Choice Timer Settings/Start".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
	elif line_data["Choices"][selected_choice]["Timers"][selected_timer]["Start"] == true:
		line_data["Choices"][selected_choice]["Timers"][selected_timer]["Start"] = false
		$"Choice Settings/Choice Timer Settings/Start".modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]


func _on_choice_timer_loop_pressed() -> void:
	if line_data["Choices"][selected_choice]["Timers"][selected_timer]["Loop"] == false:
		line_data["Choices"][selected_choice]["Timers"][selected_timer]["Loop"] = true
		$"Choice Settings/Choice Timer Settings/Loop".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
	elif line_data["Choices"][selected_choice]["Timers"][selected_timer]["Loop"] == true:
		line_data["Choices"][selected_choice]["Timers"][selected_timer]["Loop"] = false
		$"Choice Settings/Choice Timer Settings/Loop".modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]


func _on_choice_timer_select_pressed() -> void:
	if line_data["Choices"][selected_choice]["Timers"][selected_timer]["Select"] == false:
		line_data["Choices"][selected_choice]["Timers"][selected_timer]["Select"] = true
		$"Choice Settings/Choice Timer Settings/Select".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
	elif line_data["Choices"][selected_choice]["Timers"][selected_timer]["Select"] == true:
		line_data["Choices"][selected_choice]["Timers"][selected_timer]["Select"] = false
		$"Choice Settings/Choice Timer Settings/Select".modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]


func _on_timer_transition_item_selected(index: int) -> void:
	line_data["Choices"][selected_choice]["Timers"][selected_timer]["End"]["Transition"] = $"Choice Settings/Choice Timer Settings/Timer Transition".get_item_text(index)


func _on_timer_conversation_changed(new_text: String) -> void:
	line_data["Choices"][selected_choice]["Chosen"]["Conversation"] = new_text


func _on_timer_conversation_button_pressed() -> void:
	#@ Get references to menu and list container
	var popup: PopupPanel = main.get_node("FileMenu")
	var vbox: VBoxContainer = main.get_node("FileMenu/ScrollContainer/VBoxContainer")

	#@ Clear previous entries
	for child in vbox.get_children():
		child.queue_free()

	#@ Add all conversations as selectable buttons
	var button_count = 0
	for convo_name in candy_dc.conversations.keys():
		var btn := Button.new()
		btn.text = convo_name
		btn.connect("pressed", func():
			#% Update dictionary and LineEdit when conversation selected
			line_data["Choices"][selected_choice]["Timers"][selected_timer]["End"]["Conversation"] = convo_name
			$"Choice Settings/Choice Timer Settings/Timer Conversation".text = convo_name
			popup.hide()
		)
		vbox.add_child(btn)
		button_count += 1

	#% Position & show list:
	var call_button = get_node("Choice Settings/Choice Timer Settings/Timer Conversation/Button")
	popup.size.y = 8 + button_count * 31
	if popup.size.y > 318:
		popup.size.y = 318
	popup.position = call_button.get_global_position() + Vector2(-popup.size.x, -popup.size.y)
	popup.popup()


func _on_timer_block_changed(new_text: String) -> void:
	line_data["Choices"][selected_choice]["Chosen"]["Block"] = new_text


func _on_timer_block_button_pressed() -> void:
	var popup: PopupPanel = main.get_node("FileMenu")
	var vbox: VBoxContainer = main.get_node("FileMenu/ScrollContainer/VBoxContainer")

	#@ Clear previous entries
	for child in vbox.get_children():
		child.queue_free()

	#@ Determine which conversation to use
	var convo_name = line_data["Choices"][selected_choice]["Timers"][selected_timer]["End"]["Conversation"]
	if convo_name == "" or not candy_dc.conversations.has(convo_name):
		convo_name = candy_dc.current_conversation

	#@ Get that conversation’s blocks
	var convo_data: Dictionary = candy_dc.conversations[convo_name]

	#@ Add block buttons
	var button_count = 0
	for block_name in convo_data.keys():
		var btn := Button.new()
		btn.text = block_name
		btn.connect("pressed", func():
			line_data["Choices"][selected_choice]["Timers"][selected_timer]["End"]["Block"] = block_name
			$"Choice Settings/Choice Timer Settings/Timer Block".text = block_name
			popup.hide()
		)
		vbox.add_child(btn)
		button_count += 1

	#% Position & show list:
	var call_button = get_node("Choice Settings/Choice Timer Settings/Timer Block/Button")
	popup.size.y = 8 + button_count * 31
	if popup.size.y > 318:
		popup.size.y = 318
	popup.position = call_button.get_global_position() + Vector2(-popup.size.x, -popup.size.y)
	popup.popup()


func _on_timer_line_changed(new_text: String) -> void:
	line_data["Choices"][selected_choice]["Chosen"]["Line"] = new_text


func _on_timer_line_button_pressed() -> void:
	var popup: PopupPanel = main.get_node("FileMenu")
	var vbox: VBoxContainer = main.get_node("FileMenu/ScrollContainer/VBoxContainer")

	#% Clear previous entries
	for child in vbox.get_children():
		child.queue_free()

	#% Determine conversation and block
	var convo_name = line_data["Choices"][selected_choice]["Timers"][selected_timer]["End"]["Conversation"]
	var block_name = line_data["Choices"][selected_choice]["Timers"][selected_timer]["End"]["Block"]
	if convo_name == "":
		convo_name = candy_dc.current_conversation
	if block_name == "":
		block_name = candy_dc.current_block

	#% Verify final convo/block exist
	if not candy_dc.conversations.has(convo_name) or not candy_dc.conversations[convo_name].has(block_name):
		var label := Label.new()
		label.text = "[Not Found]"
		vbox.add_child(label)
		popup.size.y = 39
		popup.popup_centered()
		return

	#% Collect all "Line Marker Command" lines in the target block
	var lines = candy_dc.conversations[convo_name][block_name]["Text"]
	var found := false
	var button_count = 0
	for line_dict in lines:
		if line_dict.has("§LM"):
			var ref_name := str(line_dict["§LM"].get("Reference", ""))
			if ref_name.strip_edges() == "":
				continue
			found = true
			var btn := Button.new()
			btn.text = ref_name
			btn.connect("pressed", func():
				line_data["Choices"][selected_choice]["Timers"][selected_timer]["End"]["Line"] = ref_name
				$"Choice Settings/Choice Timer Settings/Timer Line".text = ref_name
				popup.hide()
			)
			vbox.add_child(btn)
			button_count += 1

	#% If nothing found, display a [Not Found] entry
	if not found:
		var label := Label.new()
		label.text = "[Not Found]"
		vbox.add_child(label)
		popup.size.y = 39

	#% Position & show list:
	var call_button = get_node("Choice Settings/Choice Timer Settings/Timer Line/Button")
	popup.size.y = 8 + button_count * 31
	if popup.size.y > 318:
		popup.size.y = 318
	popup.position = call_button.get_global_position() + Vector2(-popup.size.x, -popup.size.y)
	popup.popup()


func _on_choice_label_changed() -> void:
	line_data["Choices"][selected_choice]["Label"] = $"Choice Settings/ChoiceLabel".text
	update_choice_list()


func _on_tooltip_changed() -> void:
	line_data["Choices"][selected_choice]["Tooltip"] = $"Choice Settings/Tooltip".text


func _on_tags_field_text_changed() -> void:
	line_data["Choices"][selected_choice]["Tags"] = $"Choice Settings/TagsField".text


func _on_choice_button_field_text_changed(new_text) -> void:
	line_data["Choices"][selected_choice]["ButtonScene"] = new_text


func _on_menu_field_text_changed(new_text) -> void:
	line_data["MenuScene"] = new_text


func _on_button_field_text_changed(new_text) -> void:
	line_data["ButtonScene"] = new_text


#* Called when opening the editor, or when switching to another choice
func load_choice_data() -> void:
	#% Clear timer UI
	$"Choice Settings/Choice Timer Settings".visible = false
	$"Choice Settings/ChoiceTimers".clear()
	$"Choice Settings/ChoiceTimers".select(-1)
	$"Choice Settings/Choice Timer Settings/Timer".text = ""
	$"Choice Settings/Choice Timer Settings/Start".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
	$"Choice Settings/Choice Timer Settings/Loop".modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]
	$"Choice Settings/Choice Timer Settings/Select".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
	$"Choice Settings/Choice Timer Settings/Timer Transition".select(0)
	$"Choice Settings/Choice Timer Settings/Timer Conversation".text = ""
	$"Choice Settings/Choice Timer Settings/Timer Block".text = ""
	$"Choice Settings/Choice Timer Settings/Timer Line".text = ""
	$"Choice Settings/Choice Timer Settings/Timer Tags".text = ""

	#% General choice fields
	$"Texts/Group Reference".text = line_data["Reference"]
	$"Limit".text = str(line_data["Limit"])

	#% Scenes
	$"Menu Field".text = line_data["MenuScene"]
	$"Button Field".text = line_data["ButtonScene"]

	#% Mouse Mode:
	var mouse_mode_btn: OptionButton = $"MouseMode"
	var mouse_mode_value := str(line_data.get("Mouse", "Default"))
	for i in range(mouse_mode_btn.item_count):
		if mouse_mode_btn.get_item_text(i) == mouse_mode_value:
			mouse_mode_btn.select(i)
			break

	#% Limit Mode
	var limit_mode_btn: OptionButton = $"LimitMode"
	var limit_mode_value := str(line_data.get("LimitMode", "Random"))
	for i in range(limit_mode_btn.item_count):
		if limit_mode_btn.get_item_text(i) == limit_mode_value:
			limit_mode_btn.select(i)
			break

	$"GenTimer".text = str(line_data["Timer"])

	#% Timer Mode
	if line_data["TimerMode"] == "Single":
		$"TimerMode".text = "Single"
	elif line_data["TimerMode"] == "Multi":
		$"TimerMode".text = "Multi"

	#% Timer Draw
	var timer_draw_btn: OptionButton = $"TimerDraw"
	var timer_draw_value := str(line_data.get("TimerDraw", "Random"))
	for i in range(timer_draw_btn.item_count):
		if timer_draw_btn.get_item_text(i) == timer_draw_value:
			timer_draw_btn.select(i)
			break

	#% Timer Loop
	if line_data["TimerLoop"]:
		$"GenTimerLoop".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
	else:
		$"GenTimerLoop".modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"]

	#% Populate choice list
	var choice_box: OptionButton = $"Choices"
	choice_box.clear()
	for choice_name in line_data["Choices"].keys():
		choice_box.add_item(choice_name)
	for i in range(choice_box.item_count):
		if choice_box.get_item_text(i) == selected_choice:
			choice_box.select(i)
			break

	#% Basic fields for selected choice
	$"Choice Settings/Weight".text = str(line_data["Choices"][selected_choice]["Weight"])
	$"Choice Settings/Limit".text = str(line_data["Choices"][selected_choice]["Limit"])
	$"Choice Settings/Auto".text = str(line_data["Choices"][selected_choice]["Auto"])

	#% Toggles
	$"Choice Settings/Enabled".text = "Enabled" if line_data["Choices"][selected_choice]["Enabled"] else "Disabled"
	$"Choice Settings/Enabled".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"] if line_data["Choices"][selected_choice]["Enabled"] else candy_dc.color_models[candy_dc.color_mode]["Fade"]

	$"Choice Settings/Active".text = "Active" if line_data["Choices"][selected_choice]["Active"] else "Inactive"
	$"Choice Settings/Active".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"] if line_data["Choices"][selected_choice]["Enabled"] else candy_dc.color_models[candy_dc.color_mode]["Fade"]

	$"Choice Settings/Show".text = "Show" if line_data["Choices"][selected_choice]["Show"] else "Hide"
	$"Choice Settings/Show".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"] if line_data["Choices"][selected_choice]["Enabled"] else candy_dc.color_models[candy_dc.color_mode]["Fade"]

	$"Choice Settings/Close".text = "Close Choices" if line_data["Choices"][selected_choice]["Close"] else "Continue Choices"

	#% Init transition
	var init_btn: OptionButton = $"Choice Settings/Init Transition"
	var init_val := str(line_data["Choices"][selected_choice]["Initialization"].get("Transition", ""))
	for i in range(init_btn.item_count):
		if init_btn.get_item_text(i) == init_val:
			init_btn.select(i)
			break
	$"Choice Settings/Init Conversation".text = line_data["Choices"][selected_choice]["Initialization"]["Conversation"]
	$"Choice Settings/Init Block".text = line_data["Choices"][selected_choice]["Initialization"]["Block"]
	$"Choice Settings/Init Line".text = line_data["Choices"][selected_choice]["Initialization"]["Line"]

	#% Chosen transition
	var chosen_btn: OptionButton = $"Choice Settings/Chosen Transition"
	var chosen_val := str(line_data["Choices"][selected_choice]["Chosen"].get("Transition", ""))
	for i in range(chosen_btn.item_count):
		if chosen_btn.get_item_text(i) == chosen_val:
			chosen_btn.select(i)
			break
	$"Choice Settings/Chosen Conversation".text = line_data["Choices"][selected_choice]["Chosen"]["Conversation"]
	$"Choice Settings/Chosen Block".text = line_data["Choices"][selected_choice]["Chosen"]["Block"]
	$"Choice Settings/Chosen Line".text = line_data["Choices"][selected_choice]["Chosen"]["Line"]

	#% Timer section
	if selected_timer != "":
		load_timer_data()

	#% Label + Tags + Tooltip
	$"Choice Settings/ChoiceLabel".text = line_data["Choices"][selected_choice]["Label"]
	$"Choice Settings/TagsField".text = line_data["Choices"][selected_choice]["Tags"]
	$"Choice Settings/Tooltip".text = line_data["Choices"][selected_choice]["Tooltip"]

	#% Button Scene:
	$"Choice Settings/Button Field".text = line_data["Choices"][selected_choice]["ButtonScene"]

	update_choice_list()


#* Called when switching timers in the editor
func load_timer_data() -> void:
	$"Choice Settings/Choice Timer Settings".visible = true

	#% Choice timers list
	var timer_box: OptionButton = $"Choice Settings/ChoiceTimers"
	timer_box.clear()
	for timer_name in line_data["Choices"][selected_choice]["Timers"].keys():
		timer_box.add_item(timer_name)
	for i in range(timer_box.item_count):
		if timer_box.get_item_text(i) == selected_timer:
			timer_box.select(i)
			break

	#% Timer fields
	var timer_dict = line_data["Choices"][selected_choice]["Timers"][selected_timer]
	$"Choice Settings/Choice Timer Settings/Timer".text = str(timer_dict["Time"])
	$"Choice Settings/Choice Timer Settings/Start".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"] if timer_dict["Start"] else candy_dc.color_models[candy_dc.color_mode]["Fade"]
	$"Choice Settings/Choice Timer Settings/Loop".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"] if timer_dict["Loop"] else candy_dc.color_models[candy_dc.color_mode]["Fade"]
	$"Choice Settings/Choice Timer Settings/Select".modulate = candy_dc.color_models[candy_dc.color_mode]["Null"] if timer_dict["Select"] else candy_dc.color_models[candy_dc.color_mode]["Fade"]
	$"Choice Settings/Choice Timer Settings/Timer Tags".text = str(timer_dict["Tags"])

	#% Transition
	var transition_btn: OptionButton = $"Choice Settings/Choice Timer Settings/Timer Transition"
	var transition_value := str(timer_dict["End"].get("Transition", ""))
	for i in range(transition_btn.item_count):
		if transition_btn.get_item_text(i) == transition_value:
			transition_btn.select(i)
			break

	$"Choice Settings/Choice Timer Settings/Timer Conversation".text = timer_dict["End"]["Conversation"]
	$"Choice Settings/Choice Timer Settings/Timer Block".text = timer_dict["End"]["Block"]
	$"Choice Settings/Choice Timer Settings/Timer Line".text = timer_dict["End"]["Line"]


func apply_menu_or_button_scene(field, scene):
	field.text = scene

	if field == get_node("Menu Field"):
		line_data["MenuScene"] = scene

	elif field == get_node("Button Field"):
		line_data["ButtonScene"] = scene

	elif field == get_node("Choice Settings/Button Field"):
		line_data["Choices"][selected_choice]["ButtonScene"] = scene


func _on_choice_button_select_pressed() -> void:
	var field = get_node("Choice Settings/Button Field")
	main.open_choice_buttons_menu("Choice", field)


func _on_button_select_pressed() -> void:
	var field = get_node("Button Field")
	main.open_choice_buttons_menu("Choice", field)


func _on_menu_select_pressed() -> void:
	var field = get_node("Menu Field")
	main.open_choice_menus_menu("Choice", field)


#* Refresh the displayed list of choices in the UI:
func update_choice_list() -> void:
	#@ Setup:
	#% Access the label node:
	var rtt := $"ChoiceList/Choices"

	#% Clear previous content:
	rtt.clear()

	#% Get all choices:
	var choices: Dictionary = line_data.get("Choices", {})

	#@ Build the output text:
	for choice_key in choices.keys():
		var label = choices[choice_key].get("Label", "")
		var weight = str(choices[choice_key].get("Weight", ""))
		var limit = str(choices[choice_key].get("Limit", ""))
		var auto = str(choices[choice_key].get("Auto", ""))

		#% Detect the selected choice:
		if choice_key == selected_choice:
			#% Cyan highlight:
			var line = "[color=cyan]" + str(choice_key + ": " + label + " | " + "W: " + weight + ", L: " + limit + ", A: " + auto) + "[/color]\n"
			rtt.append_text(line)
		else:
			var line = str(choice_key + ": " + label + " | " + "W: " + weight + ", L: " + limit + ", A: " + auto + "\n")
			rtt.append_text(line)

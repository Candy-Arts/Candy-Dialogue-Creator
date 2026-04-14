extends CanvasLayer

@onready var main = get_node("/root/UI")

var line_data
var category_data
var choice_data
var timer_data

var selected_timer = ""
var selected_category = ""
var selected_choice = ""

var naming_mode = ""
var renamed_choice = ""
var renamed_category = ""
var renamed_timer = ""

func _ready() -> void:
	#@ Iterate through all variant panels:
	var choice_list = get_node("PanelC/PanelC/HBox/VBox/PanelC/List/Items")

	for panel in choice_list.get_children():
		var p = panel
		var btn_delete: Button = p.get_node("HBox/Buttons/Delete")
		var btn_rename: Button = p.get_node("HBox/Buttons/Rename")
		var btn_duplicate: Button = p.get_node("HBox/Buttons/Duplicate")
		var btn_up: Button = p.get_node("HBox/Move/Up")
		var btn_down: Button = p.get_node("HBox/Move/Down")
		var btn: Button = p.get_node("HBox/Text")

		#@ Connect pressed() signals:
		btn_up.pressed.connect(func(): move_item_up(p.item_type, p.item_name, p.category_name))
		btn_down.pressed.connect(func(): move_item_down(p.item_type,  p.item_name, p.category_name))
		btn_delete.pressed.connect(func(): delete_item(p.item_type,  p.item_name, p.category_name))
		btn_rename.pressed.connect(func(): rename_item(p.item_type,  p.item_name, p.category_name))
		btn_duplicate.pressed.connect(func(): duplicate_item(p.item_type,  p.item_name, p.category_name))
		btn.pressed.connect(func(): select_item(p.item_type, p.item_name, p.category_name))

		p.visible = false

#* Setup editor:
func setup():
	selected_timer = ""
	selected_category = ""
	selected_choice = ""

	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings".visible = false
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings".visible = false
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings".visible = false

	general_setup()
	update_choice_list()

#* Setup general display:
func general_setup():
	#@ General Data:
	$"PanelC/PanelC/HBox/Options/Top/Reference".text = line_data["Reference"]

	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Title/Title".text = line_data["Title"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Tags/Tags".text = line_data["Tags"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Scenes/Menu/MenuField".text = line_data["Menu Scene"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Scenes/Category/CatScField".text = line_data["Category Scene"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Scenes/Button/ButtonScField".text = line_data["Button Scene"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Prompt/Prompt".text = line_data["Prompt"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Custom/Custom".text = line_data["Custom"]

	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Gen_Setup/Conversation/Conversation".text = line_data["Setup"]["Conversation"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Gen_Setup/Block/Block".text = line_data["Setup"]["Block"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Gen_Setup/Line/Line".text = line_data["Setup"]["Line"]

	#@ Populate the "Main Category" OptionButton with existing categories:
	var cat_button: OptionButton = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/HBox/MainCat/Category"
	cat_button.clear()

	if line_data.has("Categories"):
		for category_entry in line_data["Categories"]:
			for category_name in category_entry.keys():
				cat_button.add_item(category_name)

	_apply_option_value($"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/HBox/GenMouse/MouseMode", line_data, "Mouse")
	_apply_option_value($"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/HBox/MainCat/Category", line_data, "Main")

#* Setup choice data display:
func category_setup():
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/Title/Title/Title".text = category_data["Title"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/Tags/Tags".text = category_data["Tags"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/Scenes/Category/MenuField".text = category_data["Category Scene"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/Scenes/Button/ButtonField".text = category_data["Button Scene"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/Prompt/Prompt".text = category_data["Prompt"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/Custom/Custom".text = category_data["Custom"]

	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/CatSetup/Conversation/Conversation".text = category_data["Setup"]["Conversation"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/CatSetup/Block/Block".text = category_data["Setup"]["Block"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/CatSetup/Line/Line".text = category_data["Setup"]["Line"]

	_apply_option_value($"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/Scenes/CatMouse/MouseMode", category_data, "Mouse")

#* Setup choice data display:
func choice_setup():
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Label/Text".text = choice_data["Label"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Tags/Tags".text = choice_data["Tags"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Tooltip/Tooltip".text = choice_data["Tooltip"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Scene/ButtonScene/ButtonField".text = choice_data["Button Scene"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Custom/Custom".text = choice_data["Custom"]

	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Choice_Setup/Conversation/Conversation".text = choice_data["Setup"]["Conversation"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Choice_Setup/Block/Block".text = choice_data["Setup"]["Block"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Choice_Setup/Line/Line".text = choice_data["Setup"]["Line"]

	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Select/Transition/Conversation/Conversation".text = choice_data["Finish"]["Conversation"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Select/Transition/Block/Block".text = choice_data["Finish"]["Block"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Select/Transition/Line/Line".text = choice_data["Finish"]["Line"]

	#@ Populate the "Navigation" OptionButton with existing categories:
	var nav_button: OptionButton = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Effect/CatNav"
	nav_button.clear()

	update_option_buttons()

	await get_tree().process_frame

	_apply_option_index($"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Config/Enable", choice_data, "Enabled")
	_apply_option_index($"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Config/Active", choice_data, "Active")
	_apply_option_index($"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Config/Visible", choice_data, "Invisible")
	_apply_option_value($"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Effect/CatNav", choice_data, "Navigate")
	_apply_option_value($"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Select/Type", choice_data["Finish"], "Type")

#* Setup timer data display:
func timer_setup():
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Tags/Tags".text = timer_data["Tags"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Config/Time/Time".text = timer_data["Time"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Config/Loop/Loop".text = timer_data["Loop"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Config/Display/Display".text = timer_data["Display"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Select/Choices".text = timer_data["Timer Choices"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Custom/Custom".text = timer_data["Custom"]

	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timer_Setup/Conversation/Conversation".text = timer_data["Setup"]["Conversation"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timer_Setup/Block/Block".text = timer_data["Setup"]["Block"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timer_Setup/Line/Line".text = timer_data["Setup"]["Line"]

	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timeout/Transition/Conversation/Conversation".text = timer_data["Timeout"]["Conversation"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timeout/Transition/Block/Block".text = timer_data["Timeout"]["Block"]
	$"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timeout/Transition/Line/Line".text = timer_data["Timeout"]["Line"]

	_apply_option_value($"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Config/Start/Auto", timer_data, "Auto")


func update_option_buttons():
	#@ Populate the "Main Category" OptionButton with existing categories:
	var cat_button: OptionButton = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/HBox/MainCat/Category"
	cat_button.clear()

	if line_data.has("Categories"):
		for category_entry in line_data["Categories"]:
			for category_name in category_entry.keys():
				cat_button.add_item(category_name)

	if line_data.has("Main") and line_data["Main"] != "":
		for i in cat_button.item_count:
			if cat_button.get_item_text(i) == line_data["Main"]:
				cat_button.select(i)
				break
	elif cat_button.item_count > 0:
		cat_button.select(0)
		line_data["Main"] = cat_button.get_item_text(0)

	#@ Populate the "Navigation" OptionButton with existing categories:
	var nav_button: OptionButton = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Effect/CatNav"
	nav_button.clear()

	#% Add empty option at the top
	nav_button.add_item("")

	if line_data.has("Categories"):
		for category_entry in line_data["Categories"]:
			for category_name in category_entry.keys():
				nav_button.add_item(category_name)


#* Close editor:
func _on_finish_pressed() -> void:
	self.visible = false
	candy_dc.editor_state = "ui"

	#% Refresh main UI lines:
	main._load_active_block()


#* Universal helper for restoring OptionButtons from dictionary data
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

#* Restore OptionButton by stored index:
func _apply_option_index(btn: OptionButton, data: Dictionary, key: String) -> void:
	if btn == null:
		return

	#% Reset selection:
	btn.select(-1)

	if not data.has(key):
		return

	var index = int(data[key])

	#% Make sure index is valid:
	if index >= 0 and index < btn.item_count:
		btn.select(index)


func _on_add_timer_pressed() -> void:
	naming_mode = "New Timer"
	$"PanelC/NameMenu".visible = true
	$"PanelC/NameMenu/VBox/Error".text = ""
	$"PanelC/NameMenu/VBox/LineEdit".text = ""
	$"PanelC/NameMenu/VBox/Label".text = "Create new timer:"
	$"PanelC/NameMenu/VBox/LineEdit".grab_focus()

func _on_add_category_pressed() -> void:
	naming_mode = "New Category"
	$"PanelC/NameMenu".visible = true
	$"PanelC/NameMenu/VBox/Error".text = ""
	$"PanelC/NameMenu/VBox/LineEdit".text = ""
	$"PanelC/NameMenu/VBox/Label".text = "Create new category:"
	$"PanelC/NameMenu/VBox/LineEdit".grab_focus()

func _on_add_choice_pressed() -> void:
	if selected_category == "":
		return
	naming_mode = "New Choice"
	$"PanelC/NameMenu".visible = true
	$"PanelC/NameMenu/VBox/Error".text = ""
	$"PanelC/NameMenu/VBox/LineEdit".text = ""
	$"PanelC/NameMenu/VBox/Label".text = "Create new choice:"
	$"PanelC/NameMenu/VBox/LineEdit".grab_focus()

func _on_name_cancel_pressed() -> void:
	naming_mode = ""
	$"PanelC/NameMenu".visible = false
	$"PanelC/NameMenu/VBox/Error".text = ""
	$"PanelC/NameMenu/VBox/LineEdit".text = ""
	$"PanelC/NameMenu/VBox/Label".text = ""


#* Confirm creation or rename of a timer, category, or choice:
func _on_name_enter_pressed() -> void:
	var name_field: LineEdit = $"PanelC/NameMenu/VBox/LineEdit"
	var error_label: Label = $"PanelC/NameMenu/VBox/Error"
	var new_name: String = name_field.text.strip_edges()
	error_label.text = ""

	if new_name == "":
		error_label.text = "Name cannot be empty."
		return

	elif new_name.contains(","):
		error_label.text = "Name cannot feature commas (,)."
		return

	match naming_mode:
		#@ Create new timer:
		"New Timer":
			if not line_data.has("Timers"):
				line_data["Timers"] = []
			for entry in line_data["Timers"]:
				if entry.has(new_name):
					error_label.text = "A timer with this name already exists."
					return
			line_data["Timers"].append({
				new_name: {
					"Display": "",
					"Tags": "",
					"Time": "0",
					"Auto": "Start",
					"Loop": "1",
					"Setup": {"Type": "Bridge", "Conversation": "", "Block": "", "Line": ""},
					"Timeout": {"Type": "Bridge", "Conversation": "", "Block": "", "Line": ""},
					"Timer Choices": "",
					"Custom": "",
				}
			})

		#@ Create new category:
		"New Category":
			if not line_data.has("Categories"):
				line_data["Categories"] = []
			for entry in line_data["Categories"]:
				if entry.has(new_name):
					error_label.text = "A category with this name already exists."
					return
			line_data["Categories"].append({
				new_name: {
					"Title": "",
					"Mouse": "Default",
					"Tags": "",
					"Prompt": "",
					"Category Scene": "",
					"Button Scene": "",
					"Setup": {"Type": "Bridge", "Conversation": "", "Block": "", "Line": ""},
					"Custom": "",
					"Choices": [],
				}
			})

		#@ Create new choice:
		"New Choice":
			if selected_category == "":
				error_label.text = "No category selected."
				return
			for category_entry in line_data["Categories"]:
				if category_entry.has(selected_category):
					var cat_data = category_entry[selected_category]
					for choice_entry in cat_data["Choices"]:
						if choice_entry.has(new_name):
							error_label.text = "A choice with this name already exists in the selected category."
							return
					cat_data["Choices"].append({
						new_name: {
							"Button Scene": "",
							"Setup": {"Type": "Bridge", "Conversation": "", "Block": "", "Line": ""},
							"Label": "",
							"Tags": "",
							"Tooltip": "",
							"Enabled": "1",
							"Active": "1",
							"Invisible": "0",
							"Navigate": "",
							"Finish": {"Type": "Continue", "Conversation": "", "Block": "", "Line": ""},
							"Custom": "",
						}
					})
					break

		#@ Rename timer:
		"Rename Timer":
			for entry in line_data["Timers"]:
				for k in entry.keys():
					if k == renamed_timer:
						if new_name == k:
							error_label.text = "Name is unchanged."
							return
						for e2 in line_data["Timers"]:
							if e2.has(new_name):
								error_label.text = "A timer with this name already exists."
								return
						var data = entry[k]
						entry.erase(k)
						entry[new_name] = data

						#% Update selected timer if necessary:
						if selected_timer == renamed_timer:
							selected_timer = new_name
						break
				break

		#@ Rename category:
		"Rename Category":
			var category_entry = null

			#@ Find the correct category entry:
			for entry in line_data["Categories"]:
				if entry.has(renamed_category):
					category_entry = entry
					break

			if category_entry == null:
				return

			#@ Check unchanged:
			if new_name == renamed_category:
				error_label.text = "Name is unchanged."
				return

			#@ Check duplicate:
			for e2 in line_data["Categories"]:
				if e2.has(new_name):
					error_label.text = "A category with this name already exists."
					return

			#@ Perform rename:
			var data = category_entry[renamed_category]
			category_entry.erase(renamed_category)
			category_entry[new_name] = data

			#@ Update selection if necessary:
			if selected_category == renamed_category:
				selected_category = new_name

		#@ Rename choice:
		"Rename Choice":
			var cat_data = null

			#@ Find category data:
			for category_entry in line_data["Categories"]:
				if category_entry.has(renamed_category):
					cat_data = category_entry[renamed_category]
					break

			if cat_data == null:
				return

			var choice_entry = null

			#@ Find the correct choice entry:
			for entry in cat_data["Choices"]:
				if entry.has(renamed_choice):
					choice_entry = entry
					break

			if choice_entry == null:
				return

			#@ Check unchanged:
			if new_name == renamed_choice:
				error_label.text = "Name is unchanged."
				return

			#@ Check duplicate inside this category:
			for c2 in cat_data["Choices"]:
				if c2.has(new_name):
					error_label.text = "A choice with this name already exists in the selected category."
					return

			#@ Perform rename:
			var data = choice_entry[renamed_choice]
			choice_entry.erase(renamed_choice)
			choice_entry[new_name] = data

			#@ Update selected choice if necessary:
			if selected_choice == renamed_choice and selected_category == renamed_category:
				selected_choice = new_name

		_:
			return

	#@ Hide menu and refresh:
	naming_mode = ""
	renamed_timer = ""
	renamed_category = ""
	renamed_choice = ""
	$"PanelC/NameMenu".visible = false
	$"PanelC/NameMenu/VBox/Error".text = ""
	$"PanelC/NameMenu/VBox/LineEdit".text = ""
	$"PanelC/NameMenu/VBox/Label".text = ""
	update_choice_list()

#& GENERAL:
#region
func _on_reference_text_changed(new_text: String) -> void:
	line_data["Reference"] = new_text

func _on_general_title_text_changed(new_text: String) -> void:
	line_data["Title"] = new_text

func _on_general_main_category_item_selected(index: int) -> void:
	var main_cat_button = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/HBox/MainCat/Category"
	var cat = main_cat_button.get_item_text(index)
	line_data["Main"] = cat

func _on_general_custom_text_changed(new_text: String) -> void:
	line_data["Custom"] = new_text

func _on_general_prompt_text_changed(new_text: String) -> void:
	line_data["Prompt"] = new_text

func _on_general_tags_text_changed() -> void:
	var gen_tags = get_node("PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Tags/Tags")
	line_data["Tags"] = gen_tags.text

func _on_general_mouse_mode_item_selected(index: int) -> void:
	var mouse_button = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/HBox/GenMouse/MouseMode"
	var mode = mouse_button.get_item_text(index)
	line_data["Mouse"] = mode


#° Setup:
func _on_general_setup_go_pressed() -> void:
	var conv_name = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Gen_Setup/Conversation/Conversation".text.strip_edges()
	var block_name = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Gen_Setup/Block/Block".text.strip_edges()

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


func _on_general_setup_conversation_text_changed(new_text: String) -> void:
	line_data["Setup"]["Conversation"] = new_text

func _on_general_setup_conversation_list_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Gen_Setup/Conversation/Conversation"
	main.open_conversation_menu(null, field)

func _on_general_setup_block_text_changed(new_text: String) -> void:
	line_data["Setup"]["Block"] = new_text

func _on_general_setup_block_list_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Gen_Setup/Block/Block"
	var o_convo: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Gen_Setup/Conversation/Conversation"
	main.open_block_menu(null, o_convo, field)

func _on_general_setup_line_text_changed(new_text: String) -> void:
	line_data["Setup"]["Line"] = new_text

func _on_general_setup_line_list_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Gen_Setup/Line/Line"
	var o_convo: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Gen_Setup/Conversation/Conversation"
	var o_block: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Gen_Setup/Block/Block"
	main.open_line_menu(null, o_convo, o_block, field)



#° Scenes:
func _on_general_menu_select_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Scenes/Menu/MenuField"
	var type = "General_ChoiceMenuSc"
	main.open_scene_menu(null, field, type)

func _apply_selected_general_scene(field, filename: String) -> void:
	field.text = filename
	line_data["Menu Scene"] = filename

func _on_general_menu_field_text_changed(new_text: String) -> void:
	line_data["Menu Scene"] = new_text

func _on_general_cat_sc_select_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Scenes/Category/CatScField"
	var type = "General_ChoiceCategoriesSc"
	main.open_scene_menu(null, field, type)

func _apply_selected_general_cat_sc_scene(field, filename: String) -> void:
	field.text = filename
	line_data["Category Scene"] = filename

func _on_general_cat_sc_field_text_changed(new_text: String) -> void:
	line_data["Category Scene"] = new_text

func _on_general_button_sc_select_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/GeneralSettings/Scenes/Button/ButtonScField"
	var type = "General_ChoiceButtonsSc"
	main.open_scene_menu(null, field, type)

func _apply_selected_general_button_sc_scene(field, filename: String) -> void:
	field.text = filename
	line_data["Button Scene"] = filename

func _on_general_button_sc_field_text_changed(new_text: String) -> void:
	line_data["Button Scene"] = new_text
#endregion


#& CATEGORIES:
#region
func _on_category_mouse_mode_item_selected(index: int) -> void:
	var mouse_button = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/Scenes/CatMouse/MouseMode"
	var mode = mouse_button.get_item_text(index)
	category_data["Mouse"] = mode

func _on_category_title_text_changed(new_text: String) -> void:
	category_data["Title"] = new_text

func _on_category_tags_text_changed() -> void:
	var cat_tags = get_node("PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/Tags/Tags")
	category_data["Tags"] = cat_tags.text

func _on_category_prompt_text_changed(new_text: String) -> void:
	category_data["Prompt"] = new_text

func _on_category_custom_text_changed(new_text: String) -> void:
	category_data["Custom"] = new_text


#° Setup:
func _on_category_setup_go_pressed() -> void:
	var conv_name = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/CatSetup/Conversation/Conversation".text.strip_edges()
	var block_name = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/CatSetup/Block/Block".text.strip_edges()

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


func _on_category_setup_conversation_text_changed(new_text: String) -> void:
	category_data["Setup"]["Conversation"] = new_text

func _on_category_setup_conversation_list_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/CatSetup/Conversation/Conversation"
	main.open_conversation_menu(null, field)

func _on_category_setup_block_text_changed(new_text: String) -> void:
	category_data["Setup"]["Block"] = new_text

func _on_category_setup_block_list_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/CatSetup/Block/Block"
	var o_convo: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/CatSetup/Conversation/Conversation"
	main.open_block_menu(null, o_convo, field)

func _on_category_setup_line_text_changed(new_text: String) -> void:
	category_data["Setup"]["Line"] = new_text

func _on_category_setup_line_list_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/CatSetup/Line/Line"
	var o_convo: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/CatSetup/Conversation/Conversation"
	var o_block: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/CatSetup/Block/Block"
	main.open_line_menu(null, o_convo, o_block, field)



#° Scenes:
func _on_category_sc_select_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/Scenes/Category/MenuField"
	var type = "Category_ChoiceCategorySc"
	main.open_scene_menu(null, field, type)

func _apply_category_sc_select_scene(field, filename: String) -> void:
	field.text = filename
	category_data["Category Scene"] = filename

func _on_category_sc_field_text_changed(new_text: String) -> void:
	category_data["Category Scene"] = new_text

func _on_category_button_sc_select_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings/Scenes/Button/ButtonField"
	var type = "Category_ChoiceButtonsSc"
	main.open_scene_menu(null, field, type)

func _apply_category_button_sc_select_scene(field, filename: String) -> void:
	field.text = filename
	category_data["Button Scene"] = filename

func _on_category_button_sc_field_text_changed(new_text: String) -> void:
	category_data["Button Scene"] = new_text

#endregion


#& CHOICES:
#region
func _on_choice_label_text_changed() -> void:
	var field = get_node("PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Label/Text")
	choice_data["Label"] = field.text

func _on_choice_tags_text_changed() -> void:
	var choice_tags = get_node("PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Tags/Tags")
	choice_data["Tags"] = choice_tags.text

func _on_choice_tooltip_text_changed() -> void:
	var field = get_node("PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Tooltip/Tooltip")
	choice_data["Tooltip"] = field.text

func _on_choice_custom_text_changed(new_text: String) -> void:
	choice_data["Custom"] = new_text

func _on_choice_enabled_item_selected(index: int) -> void:
	var enabled_button = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Config/Enable"
	var status = enabled_button.get_item_text(index)
	choice_data["Enabled"] = str(status)

func _on_choice_active_item_selected(index: int) -> void:
	var active_button = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Config/Active"
	var status = active_button.get_item_text(index)
	choice_data["Active"] = str(status)

func _on_choice_visible_item_selected(index: int) -> void:
	var visible_button = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Config/Visible"
	var status = visible_button.get_item_text(index)
	choice_data["Invisible"] = str(status)

func _on_choice_navigation_item_selected(index: int) -> void:
	var navigate_button = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Effect/CatNav"
	var category = navigate_button.get_item_text(index)
	choice_data["Navigate"] = category



#° Setup:
func _on_choice_setup_go_pressed() -> void:
	var conv_name = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Choice_Setup/Conversation/Conversation".text.strip_edges()
	var block_name = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Choice_Setup/Block/Block".text.strip_edges()

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


func _on_choice_setup_conversation_text_changed(new_text: String) -> void:
	choice_data["Setup"]["Conversation"] = new_text

func _on_choice_setup_conversation_list_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Choice_Setup/Conversation/Conversation"
	main.open_conversation_menu(null, field)

func _on_choice_setup_block_text_changed(new_text: String) -> void:
	choice_data["Setup"]["Block"] = new_text

func _on_choice_setup_block_list_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Choice_Setup/Block/Block"
	var o_convo: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Choice_Setup/Conversation/Conversation"
	main.open_block_menu(null, o_convo, field)

func _on_choice_setup_line_text_changed(new_text: String) -> void:
	choice_data["Setup"]["Line"] = new_text

func _on_choice_setup_line_list_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Choice_Setup/Line/Line"
	var o_convo: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Choice_Setup/Conversation/Conversation"
	var o_block: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Choice_Setup/Block/Block"
	main.open_line_menu(null, o_convo, o_block, field)


#° Select:
func _on_choice_select_go_pressed() -> void:
	var conv_name = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Select/Transition/Conversation/Conversation".text.strip_edges()
	var block_name = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Select/Transition/Block/Block".text.strip_edges()

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


func _on_choice_select_transition_item_selected(index: int) -> void:
	var transition_button = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Select/Type"
	var transition = transition_button.get_item_text(index)
	choice_data["Finish"]["Type"] = transition

func _on_choice_select_conversation_text_changed(new_text: String) -> void:
	choice_data["Finish"]["Conversation"] = new_text

func _on_choice_select_conversation_list_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Select/Transition/Conversation/Conversation"
	main.open_conversation_menu(null, field)

func _on_choice_select_block_text_changed(new_text: String) -> void:
	choice_data["Finish"]["Block"] = new_text

func _on_choice_select_block_list_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Select/Transition/Block/Block"
	var o_convo: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Select/Transition/Conversation/Conversation"
	main.open_block_menu(null, o_convo, field)

func _on_choice_select_line_text_changed(new_text: String) -> void:
	choice_data["Finish"]["Line"] = new_text

func _on_choice_select_line_list_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Select/Transition/Line/Line"
	var o_convo: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Select/Transition/Conversation/Conversation"
	var o_block: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Select/Transition/Block/Block"
	main.open_line_menu(null, o_convo, o_block, field)


#° Scenes:
func _on_choice_button_sc_select_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings/Scene/ButtonScene/ButtonField"
	var type = "Button_ChoiceButtonsSc"
	main.open_scene_menu(null, field, type)

func _apply_button_sc_select_scene(field, filename: String) -> void:
	field.text = filename
	choice_data["Button Scene"] = filename

func _on_choice_button_sc_field_text_changed(new_text: String) -> void:
	choice_data["Button Scene"] = new_text
#endregion


#& TIMERS:
#region
func _on_timer_tags_text_changed() -> void:
	var timer_tags = get_node("PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Tags/Tags")
	timer_data["Tags"] = timer_tags.text

func _on_timer_custom_text_changed(new_text: String) -> void:
	timer_data["Custom"] = new_text

func _on_timer_select_text_changed() -> void:
	var timer_select = get_node("PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Select/Choices")
	timer_data["Timer Choices"] = timer_select.text

func _on_timer_time_text_changed(new_text: String) -> void:
	timer_data["Time"] = new_text

func _on_timer_loop_text_changed(new_text: String) -> void:
	timer_data["Loop"] = new_text

func _on_timer_auto_item_selected(index: int) -> void:
	var auto_button = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Config/Start/Auto"
	var status = auto_button.get_item_text(index)
	timer_data["Auto"] = status

func _on_timer_display_text_changed(new_text: String) -> void:
	timer_data["Display"] = new_text

#° Setup:
func _on_timer_setup_go_pressed() -> void:
	var conv_name = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timer_Setup/Conversation/Conversation".text.strip_edges()
	var block_name = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timer_Setup/Block/Block".text.strip_edges()

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


func _on_timer_setup_conversation_text_changed(new_text: String) -> void:
	timer_data["Setup"]["Conversation"] = new_text

func _on_timer_setup_conversation_list_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timer_Setup/Conversation/Conversation"
	main.open_conversation_menu(null, field)

func _on_timer_setup_block_text_changed(new_text: String) -> void:
	timer_data["Setup"]["Block"] = new_text

func _on_timer_setup_block_list_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timer_Setup/Block/Block"
	var o_convo: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timer_Setup/Conversation/Conversation"
	main.open_block_menu(null, o_convo, field)

func _on_timer_setup_line_text_changed(new_text: String) -> void:
	timer_data["Setup"]["Line"] = new_text

func _on_timer_setup_line_list_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timer_Setup/Line/Line"
	var o_convo: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timer_Setup/Conversation/Conversation"
	var o_block: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timer_Setup/Block/Block"
	main.open_line_menu(null, o_convo, o_block, field)


#° Select:
func _on_timer_select_go_pressed() -> void:
	var conv_name = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timeout/Transition/Conversation/Conversation".text.strip_edges()
	var block_name = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timeout/Transition/Block/Block".text.strip_edges()

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

func _on_timer_timeout_conversation_text_changed(new_text: String) -> void:
	timer_data["Timeout"]["Conversation"] = new_text

func _on_timer_timeout_conversation_list_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timeout/Transition/Conversation/Conversation"
	main.open_conversation_menu(null, field)

func _on_timer_timeout_block_text_changed(new_text: String) -> void:
	timer_data["Timeout"]["Block"] = new_text

func _on_timer_timeout_block_list_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timeout/Transition/Block/Block"
	var o_convo: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timeout/Transition/Conversation/Conversation"
	main.open_block_menu(null, o_convo, field)

func _on_timer_timeout_line_text_changed(new_text: String) -> void:
	timer_data["Timeout"]["Line"] = new_text

func _on_timer_timeout_line_list_pressed() -> void:
	var field: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timeout/Transition/Line/Line"
	var o_convo: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timeout/Transition/Conversation/Conversation"
	var o_block: LineEdit = $"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings/Timeout/Transition/Block/Block"
	main.open_line_menu(null, o_convo, o_block, field)

#endregion


#* Update the choice list:
func update_choice_list():
	#@ Fetch UI nodes:
	var list_vbox: VBoxContainer = $"PanelC/PanelC/HBox/VBox/PanelC/List/Items"
	var scrollbar: VScrollBar = $"PanelC/PanelC/HBox/VBox/PanelC/List/VScrollBar"

	#@ Build flat list of display entries:
	var display_items: Array = []     #/ {"type": "Timer"|"Category"|"Choice", "name": String}

	#% Add timers:
	if line_data.has("Timers"):
		for timer_entry in line_data["Timers"]:
			for timer_name in timer_entry.keys():
				display_items.append({
					"type": "Timer",
					"name": timer_name,
				})

	#% Add categories and choices:
	if line_data.has("Categories"):
		for category_entry in line_data["Categories"]:
			for category_name in category_entry.keys():
				display_items.append({
					"type": "Category",
					"name": category_name,
				})

				#% Nested choices:
				var cat_data: Dictionary = category_entry[category_name]
				if cat_data.has("Choices"):
					for choice_entry in cat_data["Choices"]:
						for choice_name in choice_entry.keys():
							display_items.append({
								"type": "Choice",
								"name": choice_name,
								"category": category_name,
							})

	#@ Clamp scrollbar:
	var panel_count: int = list_vbox.get_child_count()
	scrollbar.max_value = max(display_items.size() - panel_count, 0)
	scrollbar.value = clamp(scrollbar.value, 0, scrollbar.max_value)

	#@ Populate visible panels:
	var start_index: int = int(scrollbar.value)

	for i in range(panel_count):
		var panel: Control = list_vbox.get_child(i)
		var label: Button = panel.get_node("HBox/Text")

		var item_index := start_index + i

		if item_index < display_items.size():
			var data = display_items[item_index]
			panel.visible = true

			#@ Update item info:
			panel.item_type = data["type"]
			panel.item_name = data["name"]

			#% Assign parent category name for choices:
			if data.has("category"):
				panel.category_name = data["category"]
			else:
				panel.category_name = ""

			#@ Update display text:
			match data["type"]:
				"Timer":
					label.text = "[Timer] " + data["name"]
					if selected_timer == data["name"]:
						label.modulate = candy_dc.color_models[candy_dc.color_mode]["Selected"]
					else:
						label.modulate = candy_dc.color_models[candy_dc.color_mode]["Neutral"]
				"Category":
					label.text = data["name"]
					if selected_category == data["name"] and selected_choice == "":		#/ If selected_choice != "", a choice is selected.
						label.modulate = candy_dc.color_models[candy_dc.color_mode]["Selected"]
					else:
						label.modulate = candy_dc.color_models[candy_dc.color_mode]["On"]
				"Choice":
					label.text = "    " + data["name"]

					if selected_choice == data["name"] and selected_category == data["category"]:
						label.modulate = candy_dc.color_models[candy_dc.color_mode]["Selected"]
					else:
						label.modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]

		else:
			panel.visible = false

	update_option_buttons()

#* Select a timer, category, or choice:
func select_item(item_type: String, item_name: String, category_name: String) -> void:
	match item_type:
		"Timer":
			selected_timer = item_name
			selected_category = ""
			selected_choice = ""

			#@ Fetch timer data:
			timer_data = {}
			if line_data.has("Timers"):
				for entry in line_data["Timers"]:
					if entry.has(item_name):
						timer_data = entry[item_name]
						break

			timer_setup()
			$"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings".visible = true
			$"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings".visible = false
			$"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings".visible = false
			update_choice_list()

		"Category":
			selected_category = item_name
			selected_timer = ""
			selected_choice = ""

			#@ Fetch category data:
			category_data = {}
			if line_data.has("Categories"):
				for entry in line_data["Categories"]:
					if entry.has(item_name):
						category_data = entry[item_name]
						break

			category_setup()
			$"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings".visible = false
			$"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings".visible = true
			$"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings".visible = false
			update_choice_list()

		"Choice":
			selected_choice = item_name
			selected_category = category_name
			selected_timer = ""

			#@ Fetch choice data:
			choice_data = {}
			if line_data.has("Categories"):
				for cat_entry in line_data["Categories"]:
					if cat_entry.has(category_name):
						var cat_data = cat_entry[category_name]
						if cat_data.has("Choices"):
							for choice_entry in cat_data["Choices"]:
								if choice_entry.has(item_name):
									choice_data = choice_entry[item_name]
									break
						break

			choice_setup()
			$"PanelC/PanelC/HBox/Options/ScrollC/VBox/TimerSettings".visible = false
			$"PanelC/PanelC/HBox/Options/ScrollC/VBox/CategorySettings".visible = false
			$"PanelC/PanelC/HBox/Options/ScrollC/VBox/ChoiceSettings".visible = true
			update_choice_list()

		_:
			selected_timer = ""
			selected_category = ""
			selected_choice = ""
			update_choice_list()


#* Begin renamed a timer, category, or choice:
func rename_item(item_type: String, item_name: String, category_name: String) -> void:
	match item_type:
		"Timer":
			renamed_timer = item_name
			renamed_category = ""
			renamed_choice = ""
			naming_mode = "Rename Timer"

		"Category":
			renamed_timer = ""
			renamed_category = item_name
			renamed_choice = ""
			naming_mode = "Rename Category"

		"Choice":
			renamed_timer = ""
			renamed_category = category_name
			renamed_choice = item_name
			naming_mode = "Rename Choice"

		_:
			return

	#@ Prepare rename UI:
	var name_menu = $"PanelC/NameMenu"
	name_menu.visible = true
	name_menu.get_node("VBox/Error").text = ""
	name_menu.get_node("VBox/LineEdit").text = item_name
	name_menu.get_node("VBox/Label").text = naming_mode


#* Delete a timer, category, or choice:
func delete_item(item_type: String, item_name: String, category_name: String) -> void:
	match item_type:
		"Timer":
			if line_data.has("Timers"):
				for i in range(line_data["Timers"].size()):
					var entry = line_data["Timers"][i]
					if entry.has(item_name):
						line_data["Timers"].remove_at(i)

						#% Reset selection if the deleted timer was selected:
						if selected_timer == item_name:
							selected_timer = ""
						break

		"Category":
			if line_data.has("Categories"):
				for i in range(line_data["Categories"].size()):
					var entry = line_data["Categories"][i]
					if entry.has(item_name):
						line_data["Categories"].remove_at(i)

						#% Reset selection if the deleted category was selected:
						if selected_category == item_name:
							selected_category = ""
							selected_choice = ""   #/ Clear choice too since it belonged to this category
						break

		"Choice":
			if line_data.has("Categories") and category_name != "":
				for category_entry in line_data["Categories"]:
					if category_entry.has(category_name):
						var cat_data = category_entry[category_name]
						var choices = cat_data["Choices"]

						for i in range(choices.size()):
							var choice_entry = choices[i]
							if choice_entry.has(item_name):
								choices.remove_at(i)

								#% Reset selection if the deleted choice was selected:
								if selected_choice == item_name and selected_category == category_name:
									selected_choice = ""
								break
						break

	#@ Refresh list after modification:
	update_choice_list()



#* Helper: ensure unique choice name in a category:
func _get_unique_choice_name(base_name: String, category_name: String) -> String:
	var categories = line_data.get("Categories", [])
	for cat_entry in categories:
		if cat_entry.has(category_name):
			var cat_data = cat_entry[category_name]
			var existing_names: Array = []
			for entry in cat_data["Choices"]:
				for k in entry.keys():
					existing_names.append(k)

			if not existing_names.has(base_name):
				return base_name

			var n := 1
			while true:
				var candidate := "%s(%d)" % [base_name, n]
				if not existing_names.has(candidate):
					return candidate
				n += 1
	return base_name


#* Helper: ensure unique timer or category name:
func _get_unique_timer_or_category_name(base_name: String, key: String) -> String:
	var items = line_data.get(key, [])
	var existing_names: Array = []
	for entry in items:
		for k in entry.keys():
			existing_names.append(k)
	var new_name := base_name
	var n := 1
	while existing_names.has(new_name):
		new_name = "%s(%d)" % [base_name, n]
		n += 1
	return new_name


#* Duplicate a timer, category, or choice:
func duplicate_item(item_type: String, item_name: String, category_name: String) -> void:
	var shift := Input.is_key_pressed(KEY_SHIFT)

	match item_type:
		"Timer":
			var timers = line_data["Timers"]
			for entry in timers:
				for k in entry.keys():
					if k == item_name:
						var new_name := _get_unique_timer_or_category_name(item_name, "Timers")
						var new_data = entry[k].duplicate(true)
						timers.append({new_name: new_data})
						break

		"Category":
			var categories = line_data["Categories"]
			for entry in categories:
				for k in entry.keys():
					if k == item_name:
						var new_name := _get_unique_timer_or_category_name(item_name, "Categories")
						var old_data: Dictionary = entry[k]
						var new_data: Dictionary = old_data.duplicate(true)

						if not shift:
							#% Regular click → clear choices:
							new_data["Choices"] = []

						categories.append({new_name: new_data})
						break

		"Choice":
			if category_name == "":
				return
			for cat_entry in line_data["Categories"]:
				if cat_entry.has(category_name):
					var cat_data = cat_entry[category_name]
					var choices = cat_data["Choices"]

					for choice_entry in choices:
						for ch_key in choice_entry.keys():
							if ch_key == item_name:
								var new_name := _get_unique_choice_name(item_name, category_name)
								var new_data = choice_entry[ch_key].duplicate(true)
								choices.append({new_name: new_data})
								break

	update_choice_list()


#* Move an item upward in its list (or across boundaries when needed):
func move_item_up(item_type: String, item_name: String, category_name: String) -> void:
	var ctrl := Input.is_key_pressed(KEY_CTRL)
	var shift := Input.is_key_pressed(KEY_SHIFT)
	var step := 5 if ctrl else 1

	match item_type:
		"Timer":
			var timers = line_data["Timers"]
			for i in range(timers.size()):
				var key = timers[i].keys()[0]
				if key == item_name:
					var new_index = max(i - step, 0)
					if new_index != i:
						timers.insert(new_index, timers.pop_at(i))
					break

		"Category":
			var categories = line_data["Categories"]
			for i in range(categories.size()):
				var key = categories[i].keys()[0]
				if key == item_name:
					var new_index = max(i - step, 0)
					new_index = max(new_index, 0)	#/ Never go above timers
					if new_index != i:
						categories.insert(new_index, categories.pop_at(i))
					break

		"Choice":
			if category_name == "":
				return
			var categories = line_data["Categories"]
			for cat_i in range(categories.size()):
				var cat_key = categories[cat_i].keys()[0]
				if cat_key == category_name:
					var cat_data = categories[cat_i][cat_key]
					var choices = cat_data["Choices"]

					for i in range(choices.size()):
						var ch_key = choices[i].keys()[0]
						if ch_key == item_name:
							if shift and cat_i > 0:
								#@ Jump to previous category’s bottom:
								var prev_cat_data = categories[cat_i - 1][categories[cat_i - 1].keys()[0]]
								var moved = choices.pop_at(i)
								var moved_data = moved[ch_key]
								var new_name := _get_unique_choice_name(ch_key, categories[cat_i - 1].keys()[0])
								prev_cat_data["Choices"].append({new_name: moved_data})
							else:
								var new_index = i - step
								if new_index < 0 and cat_i > 0:
									var prev_cat_data = categories[cat_i - 1][categories[cat_i - 1].keys()[0]]
									var moved = choices.pop_at(i)
									var moved_data = moved[ch_key]
									var new_name := _get_unique_choice_name(ch_key, categories[cat_i - 1].keys()[0])
									prev_cat_data["Choices"].append({new_name: moved_data})
								else:
									new_index = max(new_index, 0)
									choices.insert(new_index, choices.pop_at(i))
							break
					break


	update_choice_list()


#* Move an item downward in its list (or across boundaries when needed):
func move_item_down(item_type: String, item_name: String, category_name: String) -> void:
	var ctrl := Input.is_key_pressed(KEY_CTRL)
	var shift := Input.is_key_pressed(KEY_SHIFT)
	var step := 5 if ctrl else 1

	match item_type:
		"Timer":
			var timers = line_data["Timers"]
			for i in range(timers.size()):
				var key = timers[i].keys()[0]
				if key == item_name:
					var new_index = min(i + step, timers.size() - 1)
					if new_index != i:
						timers.insert(new_index, timers.pop_at(i))
					break

		"Category":
			var categories = line_data["Categories"]
			for i in range(categories.size()):
				var key = categories[i].keys()[0]
				if key == item_name:
					var new_index = min(i + step, categories.size() - 1)
					if new_index != i:
						categories.insert(new_index, categories.pop_at(i))
					break

		"Choice":
			if category_name == "":
				return
			var categories = line_data["Categories"]
			for cat_i in range(categories.size()):
				var cat_key = categories[cat_i].keys()[0]
				if cat_key == category_name:
					var cat_data = categories[cat_i][cat_key]
					var choices = cat_data["Choices"]

					for i in range(choices.size()):
						var ch_key = choices[i].keys()[0]
						if ch_key == item_name:
							if shift and cat_i < categories.size() - 1:
								#@ Jump to next category top:
								var next_cat_data = categories[cat_i + 1][categories[cat_i + 1].keys()[0]]
								var moved = choices.pop_at(i)
								var moved_data = moved[ch_key]
								var new_name := _get_unique_choice_name(ch_key, categories[cat_i + 1].keys()[0])
								next_cat_data["Choices"].insert(0, {new_name: moved_data})
							else:
								var new_index = i + step
								if new_index >= choices.size() and cat_i < categories.size() - 1:
									#% Move to next category top:
									var next_cat_data = categories[cat_i + 1][categories[cat_i + 1].keys()[0]]
									var moved = choices.pop_at(i)
									var moved_data = moved[ch_key]
									var new_name := _get_unique_choice_name(ch_key, categories[cat_i + 1].keys()[0])
									next_cat_data["Choices"].insert(0, {new_name: moved_data})
								else:
									new_index = min(new_index, choices.size() - 1)
									choices.insert(new_index, choices.pop_at(i))
							break
					break
	update_choice_list()


#* Scroll list:
func _on_v_scroll_bar_value_changed(_value: float) -> void:
	update_choice_list()

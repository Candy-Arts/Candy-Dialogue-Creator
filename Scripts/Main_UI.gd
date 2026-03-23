extends Control

@onready var file_popup: PopupPanel = $"FileMenu"
@onready var file_box: VBoxContainer = $"FileMenu/ScrollContainer/VBoxContainer"
@onready var portrait_popup: PopupPanel = $"Portrait"
@onready var portrait_preview: TextureRect = $"Portrait/Preview"   #/ ColorRect/TextureRect holder
@onready var voice_preview: AudioStreamPlayer = $"VoicePreview"
@onready var media_image_preview: TextureRect = $"Portrait/Preview"   #/ ColorRect/TextureRect holder
@onready var media_audio_preview: AudioStreamPlayer = $"VoicePreview"   #/ ColorRect/TextureRect holder
@onready var video_popup: PopupPanel = $"Video"
@onready var media_video_preview: VideoStreamPlayer = $"Video/Preview"   #/ ColorRect/TextureRect holder
@onready var bust_preview: TextureRect = $"Portrait/Preview"   #/ ColorRect/TextureRect holder
@onready var background_preview: TextureRect = $"Portrait/Preview"   #/ ColorRect/TextureRect holder


@onready var lines_vbox
var lines_data: Array = []  #/ The active block’s "Text" array
var line_pool: Array = []   #/ Universal line nodes

@onready var scroll_bar = $"VBox/HBox/ScrollLines"

@onready var rc_menu := PopupMenu.new()

var in_command_button := false

var scroll_area = ""


const VISIBLE_LINES := 26





#?######################################################################################
#& BASICS:
#?########
#region
#* Called when the node enters the scene tree for the first time:
func _ready() -> void:
	#@ Default to full screen:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	#@ Load Line List:
	var line_list := load("res://Scenes/Lines_List.tscn")
	if line_list == null:
		return

	var instance = line_list.instantiate()
	$"VBox/HBox/WorkArea".add_child(instance)
	instance.visible = true

	await get_tree().process_frame

	lines_vbox = $"VBox/HBox/WorkArea/Lines"

	_scan_all_resources()
	_capture_line_pool()

	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_check_resource_updates)

	#@ Create shared right-click popup menu:
	rc_menu.name = "RightClickMenu"
	rc_menu.add_item("Rename", 0)
	rc_menu.add_item("Delete", 5)
	add_child(rc_menu)
	rc_menu.id_pressed.connect(_on_right_click_menu_pressed)

	#@ Connect popup to all OptionButtons:
	$"VBox/TopBar/HBox/Conversations/Conversations".gui_input.connect(_on_option_gui_input.bind("conversation"))
	$"VBox/TopBar/HBox/Blocks/Blocks".gui_input.connect(_on_option_gui_input.bind("block"))

	if not file_popup.visibility_changed.is_connected(_on_file_popup_visibility_changed):
		file_popup.visibility_changed.connect(_on_file_popup_visibility_changed)

	#@ Load Writer:
	var writer_scene := load("res://Scenes/Writer.tscn")
	var writer_instance = writer_scene.instantiate()
	add_child(writer_instance)
	writer_instance.visible = false

	#@ Load Choice Editor:
	var choice_list_scene := load("res://Scenes/Choice_List_Editor.tscn")
	var choice_list_instance = choice_list_scene.instantiate()
	add_child(choice_list_instance)
	choice_list_instance.visible = false

	#@ Load Choice Status Editor:
	var choice_status_scene := load("res://Scenes/Choice_Status_Editor.tscn")
	var choice_status_instance = choice_status_scene.instantiate()
	add_child(choice_status_instance)
	choice_status_instance.visible = false

	#@ Main Menu:
	var main_menu_scene := load("res://Scenes/Main_Menu.tscn")
	var main_menu_instance = main_menu_scene.instantiate()
	add_child(main_menu_instance)
	main_menu_instance.visible = false

	#@ Load Settings Menu:
	var settings_scene := load("res://Scenes/Settings_Menu.tscn")
	var settings_instance = settings_scene.instantiate()
	add_child(settings_instance)
	settings_instance.visible = false

	#@ Load Export Menu:
	var export_scene := load("res://Scenes/Export_Menu.tscn")
	var export_instance = export_scene.instantiate()
	add_child(export_instance)
	export_instance.visible = false

	#@ Load Import Menu:
	var import_scene := load("res://Scenes/Import_Menu.tscn")
	var import_instance = import_scene.instantiate()
	add_child(import_instance)
	import_instance.visible = false

	#@ Load Profile Menu:
	var profile_scene := load("res://Scenes/Profile_Menu.tscn")
	var profile_instance = profile_scene.instantiate()
	add_child(profile_instance)
	profile_instance.visible = true

	#@ Load About Menu:
	var about_scene := load("res://Scenes/About.tscn")
	var about_instance = about_scene.instantiate()
	add_child(about_instance)
	about_instance.visible = false

	#@ Load Condition Editor:
	var condition_editor_scene := load("res://Scenes/Condition_Editor.tscn")
	var condition_editor_instance = condition_editor_scene.instantiate()
	add_child(condition_editor_instance)
	condition_editor_instance.visible = false

	#@ Load Data Editor:
	var data_editor_scene := load("res://Scenes/Data_Editor.tscn")
	var data_editor_instance = data_editor_scene.instantiate()
	add_child(data_editor_instance)
	data_editor_instance.visible = false

	await get_tree().process_frame

	#@ Set start conversation:
	var conv_btn := $"VBox/TopBar/HBox/Conversations/Conversations"
	conv_btn.clear()
	var idx := 0
	for conv_name in candy_dc.conversations.keys():
		conv_btn.add_item(conv_name)
		if conv_name == candy_dc.current_conversation:
			conv_btn.select(idx)
		idx += 1

	#@ Set start block:
	var block_btn := $"VBox/TopBar/HBox/Blocks/Blocks"
	block_btn.clear()
	if candy_dc.current_conversation == "":
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	idx = 0
	for block_name in conv.keys():
		block_btn.add_item(block_name)
		if block_name == candy_dc.current_block:
			block_btn.select(idx)
		idx += 1

	lines_data = conv[candy_dc.current_block]["Text"]
	scroll_bar.value = 0
	_update_visible_lines()

	scroll_bar.value_changed.connect(_on_scroll_lines_value_changed)
	scroll_bar.value = 0
	await _apply_scroll_limits()

	candy_dc.alt_click_target_set.connect(_on_alt_click_target_set)

	candy_dc.line_right_clicked.connect(_on_line_right_clicked)

	$"VBox/TopBar/HBox/Save".gui_input.connect(_on_save_gui_input)

	#@ Connect signals:
	#% Connect areas:
	$"VBox/HBox/WorkArea".connect("mouse_entered", Callable(self, "_on_work_area_mouse_entered"))
	$"VBox/HBox/ScrollLines".connect("mouse_entered", Callable(self, "_on_work_area_scrollbar_mouse_entered"))
	$"VBox/HBox/SideBar/VBox/Core".connect("mouse_entered", Callable(self, "_on_sidebar_core_mouse_entered"))
	$"VBox/HBox/SideBar/VBox/Presets".connect("mouse_entered", Callable(self, "_on_sidebar_presets_mouse_entered"))
	$"FileMenu/ScrollContainer".connect("mouse_entered", Callable(self, "_on_popup_file_menu_mouse_entered"))
	$"Writer/Main/HBox/VBoxContainer/LinesList".connect("mouse_entered", Callable(self, "_on_writer_lines_list_mouse_entered"))

	$"VBox/HBox/WorkArea".connect("mouse_exited", Callable(self, "_on_work_area_mouse_exited"))
	$"VBox/HBox/ScrollLines".connect("mouse_exited", Callable(self, "_on_work_area_scrollbar_mouse_exited"))
	$"VBox/HBox/SideBar/VBox/Core".connect("mouse_exited", Callable(self, "_on_sidebar_core_mouse_exited"))
	$"VBox/HBox/SideBar/VBox/Presets".connect("mouse_exited", Callable(self, "_on_sidebar_presets_exited"))
	$"FileMenu/ScrollContainer".connect("mouse_exited", Callable(self, "_on_popup_file_menu_mouse_exited"))
	$"Writer/Main/HBox/VBoxContainer/LinesList".connect("mouse_exited", Callable(self, "_on_writer_lines_list_mouse_exited"))

	#@ Connect command buttons:
	for command_category in $"VBox/HBox/SideBar/VBox/Core/VBox".get_children():
		for command_button in command_category.get_node("ItemList").get_children():
			command_button.connect("pressed", Callable(self, "_on_new_line_pressed").bind(command_button))
			command_button.connect("mouse_entered", Callable(self, "_on_command_mouse_entered"))
			command_button.connect("mouse_exited", Callable(self, "_on_command_mouse_exited"))

	#@ Connect spoken line button:
	var spoken_line_button = get_node("VBox/HBox/SideBar/VBox/Spoken/Spoken")
	spoken_line_button.connect("pressed", Callable(self, "_on_new_line_pressed").bind(spoken_line_button))
	spoken_line_button.connect("mouse_entered", Callable(self, "_on_command_mouse_entered"))
	spoken_line_button.connect("mouse_exited", Callable(self, "_on_command_mouse_exited"))

	record_browsing_point()
	save_undo_step()

	#@ Show Profile Selection at start:
	$"ProfileMenu".visible = true
	$"Intro".visible = true


func _on_work_area_mouse_entered():
	scroll_area = "Work Area"
func _on_work_area_scrollbar_mouse_entered():
	scroll_area = "Scrollbar"
func _on_sidebar_core_mouse_entered():
	scroll_area = "Core"
func _on_sidebar_presets_mouse_entered():
	scroll_area = "Presets"
func _on_popup_file_menu_mouse_entered():
	scroll_area = "Popup"
func _on_writer_lines_list_mouse_entered():
	scroll_area = "Writer Lines"

func _on_work_area_mouse_exited():
	if scroll_area == "Work Area":
		scroll_area = ""
func _on_work_area_scrollbar_mouse_exited():
	if scroll_area == "Scrollbar":
		scroll_area = ""
func _on_sidebar_core_mouse_exited():
	if scroll_area == "Core":
		scroll_area = ""
func _on_sidebar_presets_mouse_exited():
	if scroll_area == "Presets":
		scroll_area = ""
func _on_popup_file_menu_mouse_exited():
	if scroll_area == "Popup":
		scroll_area = ""
func _on_writer_lines_list_mouse_exited():
	if scroll_area == "Writer Lines":
		scroll_area = ""


func _process(_delta: float) -> void:
	if portrait_popup and portrait_popup.visible:
		var mouse_pos := get_global_mouse_position()
		var half_h := get_viewport_rect().size.y * 0.5

		#% If mouse is in upper half of the screen:
		if mouse_pos.y <= half_h:
			portrait_popup.position = mouse_pos + Vector2(1, 1)
		#% Mouse in lower-half of the screen:
		else:
			portrait_popup.position = mouse_pos + Vector2(1, -1 - portrait_popup.size.y)

	if candy_dc.refresh_conv_block_selectors == true:
		await get_tree().process_frame
		candy_dc.refresh_conv_block_selectors = false
		for i in range($"VBox/TopBar/HBox/Conversations/Conversations".item_count):
			if $"VBox/TopBar/HBox/Conversations/Conversations".get_item_text(i) == candy_dc.current_conversation:
				$"VBox/TopBar/HBox/Conversations/Conversations".select(i)

		for i in range($"VBox/TopBar/HBox/Blocks/Blocks".item_count):
			if $"VBox/TopBar/HBox/Blocks/Blocks".get_item_text(i) == candy_dc.current_block:
				$"VBox/TopBar/HBox/Blocks/Blocks".select(i)

		await get_tree().process_frame
		_update_visible_lines()


func _unhandled_input(event: InputEvent) -> void:
	#@ Scroll depending on area:
	if event is InputEventMouseButton and event.pressed:

		if candy_dc.editor_state == "ui":
			if scroll_area == "Work Area" or scroll_area == "Scrollbar":
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					scroll_bar.value = max(scroll_bar.min_value, scroll_bar.value - 1)
					_update_visible_lines()
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					scroll_bar.value = min(scroll_bar.max_value, scroll_bar.value + 1)
					_update_visible_lines()

			elif scroll_area == "Core":
				var scroll_container = get_node("VBox/HBox/SideBar/VBox/Core")
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					scroll_container.scroll_vertical -= 10
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					scroll_container.scroll_vertical += 10

			elif scroll_area == "Presets":
				var scroll_container = get_node("VBox/HBox/SideBar/VBox/Presets")
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					scroll_container.scroll_vertical -= 10
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					scroll_container.scroll_vertical += 10

			elif scroll_area == "Popup":
				var scroll_container = get_node("FileMenu/ScrollContainer")
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					scroll_container.scroll_vertical -= 10
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					scroll_container.scroll_vertical += 10
				return

		elif candy_dc.editor_state == "writer":
			if scroll_area == "Writer Lines":
				var writer_bar = get_node("Writer/Main/HBox/VBoxContainer/LinesList/HBox/VScrollBar")
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					writer_bar.value = max(writer_bar.min_value, writer_bar.value - 1)
					$"Writer".update_spoken_lines_list()
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					writer_bar.value = min(writer_bar.max_value, writer_bar.value + 1)
					$"Writer".update_spoken_lines_list()


func _input(event: InputEvent) -> void:
	#@ Keyboard shortcuts:
	var ctrl := Input.is_key_pressed(KEY_CTRL)
	var shift := Input.is_key_pressed(KEY_SHIFT)
	var alt := Input.is_key_pressed(KEY_ALT)

	if candy_dc.editor_state == "ui":
		if event is InputEventKey and event.pressed and not event.echo:
			#& Copy/Cut/Paste Lines:
			if not candy_dc.selected_lines.is_empty():
				#% Ctrl + C → Copy:
				if event.keycode == KEY_C and ctrl and not shift and not alt:
					_copy_selected_lines()

				#% Ctrl + X → Cut:
				elif event.keycode == KEY_X and ctrl and not shift and not alt:
					_cut_selected_lines()

				#% Ctrl + V → Paste Below:
				elif event.keycode == KEY_V and ctrl and not shift and not alt:
					if not candy_dc.clipboard_lines.is_empty():
						_paste_lines(candy_dc.selected_lines[-1], false)

				#% Ctrl + Shift + V → Paste Above:
				elif event.keycode == KEY_V and ctrl and shift and not alt:
					if not candy_dc.clipboard_lines.is_empty():
						_paste_lines(candy_dc.selected_lines[0], true)

			#& General:
			#% Escape → Main Menu:
			elif event.keycode == KEY_ESCAPE:
				_on_main_menu_pressed()

			#% Home → Spoken Line:
			elif event.keycode == KEY_HOME and not shift and not alt:
				var button := $"VBox/HBox/SideBar/VBox/Spoken/Spoken"
				button.grab_focus()				#/ Optional, if you want visual focus
				button.emit_signal("pressed")	#/ Emulates a real click

			#% F2 → Open Conversations:
			elif event.keycode == KEY_F2 and not ctrl and not shift and not alt:
				var button := $"VBox/TopBar/HBox/Conversations/Conversations"
				button.grab_focus()
				button.show_popup()

			#% ALT+F2 → New Conversation:
			elif event.keycode == KEY_F2 and not ctrl and not shift and alt:
				var button := $"VBox/TopBar/HBox/Conversations/NewConv"
				button.grab_focus()
				button.show_popup()

			#% F3 → Open Blocks:
			elif event.keycode == KEY_F3 and not ctrl and not shift and not alt:
				var button := $"VBox/TopBar/HBox/Blocks/Blocks"
				button.grab_focus()
				button.show_popup()

			#% ALT+F3 → New Block:
			elif event.keycode == KEY_F3 and not ctrl and not shift and alt:
				var button := $"VBox/TopBar/HBox/Blocks/NewBlock"
				button.grab_focus()
				button.show_popup()

			#% F4 → Save:
			elif event.keycode == KEY_F4 and not ctrl and not shift and not alt:
				perform_quicksave()

			#% F5 → Load:
			elif event.keycode == KEY_F5 and not ctrl and not shift and not alt:
				perform_quickload()

			#% F6 → Core Commands:
			elif event.keycode == KEY_F6 and not ctrl and not shift and not alt:
				_on_core_commands_pressed()

			#% F7 → Custom Presets:
			elif event.keycode == KEY_F7 and not ctrl and not shift and not alt:
				_on_command_presets_pressed()

			#% F8 → Custom Presets:
			elif event.keycode == KEY_F8 and not ctrl and not shift and not alt:
				_on_minimize_commands_pressed()

			#% F9 → Test:
			elif event.keycode == KEY_F9 and not ctrl and not shift and not alt:
				var button := $"VBox/TopBar/HBox/Test/Test"
				button.grab_focus()
				button.show_popup()

			#& Commands:
			#% CTRL+F1 → Control Commands:
			elif event.keycode == KEY_F1 and ctrl and not shift and not alt:
				var button := $"VBox/HBox/SideBar/VBox/ScrollC/Core/VBox/ControlCommands"
				button.grab_focus()

			#% CTRL+F2 → Condition Commands:
			elif event.keycode == KEY_F2 and ctrl and not shift and not alt:
				var button := $"VBox/HBox/SideBar/VBox/ScrollC/Core/VBox/ConditionCommands"
				button.grab_focus()

			#% CTRL+F3 → Transition Commands:
			elif event.keycode == KEY_F3 and ctrl and not shift and not alt:
				var button := $"VBox/HBox/SideBar/VBox/ScrollC/Core/VBox/TransitionCommands"
				button.grab_focus()

			#% CTRL+F4 → Input Commands:
			elif event.keycode == KEY_F4 and ctrl and not shift and not alt:
				var button := $"VBox/HBox/SideBar/VBox/ScrollC/Core/VBox/InputCommands"
				button.grab_focus()

			#% CTRL+F5 → Choice Commands:
			elif event.keycode == KEY_F5 and ctrl and not shift and not alt:
				var button := $"VBox/HBox/SideBar/VBox/ScrollC/Core/VBox/ChoiceCommands"
				button.grab_focus()

			#% CTRL+F6 → Background Commands:
			elif event.keycode == KEY_F6 and ctrl and not shift and not alt:
				var button := $"VBox/HBox/SideBar/VBox/ScrollC/Core/VBox/BGCommands"
				button.grab_focus()

			#% CTRL+F7 → Effect Commands:
			elif event.keycode == KEY_F7 and ctrl and not shift and not alt:
				var button := $"VBox/HBox/SideBar/VBox/ScrollC/Core/VBox/EffectCommands"
				button.grab_focus()

			#% CTRL+F8 → Image Commands:
			elif event.keycode == KEY_F8 and ctrl and not shift and not alt:
				var button := $"VBox/HBox/SideBar/VBox/ScrollC/Core/VBox/ImageCommands"
				button.grab_focus()

			#% CTRL+F9 → Video Commands:
			elif event.keycode == KEY_F9 and ctrl and not shift and not alt:
				var button := $"VBox/HBox/SideBar/VBox/ScrollC/Core/VBox/VideoCommands"
				button.grab_focus()

			#% CTRL+F10 → Audio Commands:
			elif event.keycode == KEY_F10 and ctrl and not shift and not alt:
				var button := $"VBox/HBox/SideBar/VBox/ScrollC/Core/VBox/AudioCommands"
				button.grab_focus()

			#% CTRL+F11 → VN Commands:
			elif event.keycode == KEY_F11 and ctrl and not shift and not alt:
				var button := $"VBox/HBox/SideBar/VBox/ScrollC/Core/VBox/VNCommands"
				button.grab_focus()

			#% CTRL+F12 → CS Commands:
			elif event.keycode == KEY_F12 and ctrl and not shift and not alt:
				var button := $"VBox/HBox/SideBar/VBox/ScrollC/Core/VBox/CutsceneCommands"
				button.grab_focus()

			#& Undo/Redo:
			#% CTRL+Y → Undo:
			elif event.keycode == KEY_Y and ctrl and not shift and not alt:
				var button := $"VBox/TopBar/HBox/Undo"
				button.grab_focus()
				button.emit_signal("pressed")

			#% CTRL+SHIFT+Y → Redo:
			elif event.keycode == KEY_Y and ctrl and shift and not alt:
				var button := $"VBox/TopBar/HBox/Redo"
				button.grab_focus()
				button.emit_signal("pressed")

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#% Ignore modified clicks (CTRL, SHIFT, ALT):
		if not (ctrl or shift or alt):
			#% If mouse is over a preset button, don't clear selection:
			if in_command_button:
				return
			_clear_selection()

	if candy_dc.editor_state == "writer":
		if event is InputEventKey and event.pressed and not event.echo:
			#% Escape → Main Menu:
			if event.keycode == KEY_ESCAPE:
				$"Writer"._on_enter_pressed()

			#% Home → Spoken Line:
			if event.keycode == KEY_HOME and not alt:
				var button := $"Writer/Main/HBox/WritingArea/NavButtons/AddLine"
				button.grab_focus()
				button.emit_signal("pressed")

			#% Page Up → Previous Line:
			if event.keycode == KEY_PAGEUP and ctrl and not shift and not alt:
				var button := $"Writer/Main/HBox/WritingArea/NavButtons/PreviousLine"
				button.grab_focus()
				button.emit_signal("pressed")

			#% Page Down → Next Line:
			if event.keycode == KEY_PAGEDOWN and ctrl and not shift and not alt:
				var button := $"Writer/Main/HBox/WritingArea/NavButtons/NextLine"
				button.grab_focus()
				button.emit_signal("pressed")

#endregion


#?######################################################################################
#& DISPLAY LINES:
#?###############
#region
#* Create a list of lines:
func _capture_line_pool() -> void:
	line_pool.clear()
	for n in lines_vbox.get_children():
		if line_pool.size() >= VISIBLE_LINES:
			break
		line_pool.append(n)
	if line_pool.size() != VISIBLE_LINES:
		push_warning("Expected 26 pooled line nodes, got " + str(line_pool.size()))


#* Ensure scrollbar values match the number of lines:
func _apply_scroll_limits() -> void:
	var total := lines_data.size()

	#% Let page be <= max so Godot doesn't clamp it down to 1:
	#% Use max = total (not total - visible).
	scroll_bar.min_value = 0
	scroll_bar.max_value = max(total, 1)
	scroll_bar.page = VISIBLE_LINES

	#% Keep value in a safe range (will clamp again when slicing):
	scroll_bar.value = clamp(int(scroll_bar.value), 0, int(scroll_bar.max_value))

	print("[SB] total=", total, " page=", int(scroll_bar.page),
		" max=", int(scroll_bar.max_value), " value=", int(scroll_bar.value))

	#% After layout, enforce again (themes/containers won't fight this now):
	await get_tree().process_frame
	scroll_bar.page = VISIBLE_LINES
	scroll_bar.queue_redraw()
	print("[SB enforced after frame] page=", scroll_bar.page)


#* Called when lines are scrolled - updates displayed line data.
func _on_scroll_lines_value_changed(_value: float) -> void:
	_update_visible_lines()


#* Refresh visible line nodes with data from candy_dc.conversations:
func _update_visible_lines() -> void:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return

	#% How many lines can fit on screen:
	var visible_count := line_pool.size()
	if visible_count == 0:
		return

	#% All entries in the current block:
	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var total_lines = block["Text"].size()

	#% Clamp scroll position so we don't exceed last page:
	var start_index = clamp(int(scroll_bar.value), 0, max(total_lines - visible_count, 0))

	for i in range(visible_count):
		var line = line_pool[i]
		var idx = start_index + i

		if idx < total_lines:
			line.hide()
			line.visible = false
			line.dictionary_index = idx
			line._apply_line_data_to_ui()
			line.get_node("HBox/Index").text = str(line.dictionary_index)

			#% Update highlight state based on current selection:
			if idx in candy_dc.selected_lines:
				line.get_node("HBox/Move").modulate = candy_dc.color_models[candy_dc.color_mode]["Selected"]
			else:
				line.get_node("HBox/Move").modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]

			line.visible = true
			line.show()
		else:
			line.visible = false


#* Blank & hide the 18 pooled panels so old data doesn't linger:
func _clear_line_pool_ui() -> void:
	for line in line_pool:
		if line == null:
			continue

		line.dictionary_index = -1

		#% Clear a few common text fields:
		var idx_lbl = line.get_node_or_null("HBox/Index")
		if idx_lbl:
			idx_lbl.text = ""
		var speech_txt = line.get_node_or_null("HBox/SpeechLine/Speech/Text")
		if speech_txt:
			speech_txt.text = ""

		#% Clear every OptionButton (selection + visible label):
		for n in line.get_children():
			_reset_optionbuttons_recursive(n)

		line.visible = false


#* Centralized loader: use after changing conversation or block:
func _load_active_block() -> void:
	#% 1) Clear UI immediately:
	_clear_line_pool_ui()

	#% 2) Reset writer/preview state:
	candy_dc.write_line_index = -1
	candy_dc.write_variant = ""
	stop_voice_preview()
	hide_portrait_panel()
	if has_node("Writer"):
		$"Writer".visible = false

	#% 3) Rebind lines_data from globals:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		lines_data = []
	else:
		var conv = candy_dc.conversations.get(candy_dc.current_conversation, {})
		var blk = conv.get(candy_dc.current_block, {})
		lines_data = blk.get("Text", [])

	#% 4) Reset scroll + limits, then repopulate the pool:
	scroll_bar.value = 0
	await _apply_scroll_limits()
	_update_visible_lines()

#* Helper: recursively reset OptionButtons:
func _reset_optionbuttons_recursive(node: Node) -> void:
	if node is OptionButton:
		var ob := node as OptionButton
		ob.select(-1)	#/ No selected item
		ob.text = ""	#/ Wipe the displayed label (important!)
	for c in node.get_children():
		_reset_optionbuttons_recursive(c)
#endregion


#?######################################################################################
#& RIGHT-CLICK MENUS:
#?###################
#region
#* Generic right-click handler for all option buttons:
func _on_option_gui_input(event: InputEvent, target_type: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		candy_dc.rc_target = target_type

		var clicked_name := ""
		if target_type == "conversation":
			var conv_opt := $"VBox/TopBar/HBox/Conversations/Conversations"
			clicked_name = conv_opt.get_item_text(conv_opt.get_selected_id())
		elif target_type == "block":
			var block_opt := $"VBox/TopBar/HBox/Blocks/Blocks"
			clicked_name = block_opt.get_item_text(block_opt.get_selected_id())

		#@ Don't show popup for the CUSTOM_PRESETS conversation:
		if target_type == "conversation" and clicked_name == "CUSTOM_PRESETS":
			return

		rc_menu.clear()

		#@ Conversations:
		if target_type == "conversation":
			var normal_count := 0
			for c in candy_dc.conversations.keys():
				if c != "CUSTOM_PRESETS":
					normal_count += 1

			rc_menu.add_item("Rename", 0)
			if normal_count > 1:
				rc_menu.add_item("Delete", 5)

		#@ Blocks:
		elif target_type == "block":
			var conv_name = candy_dc.current_conversation
			var block_count := 0
			if candy_dc.conversations.has(conv_name):
				block_count = candy_dc.conversations[conv_name].size()

			rc_menu.add_item("Rename", 0)
			if block_count > 1:
				rc_menu.add_item("Delete", 5)

		#@ Fallback:
		else:
			rc_menu.add_item("Delete", 5)

		var local_pos := get_global_mouse_position() - global_position
		rc_menu.position = local_pos
		rc_menu.popup()


#* Right-click handler for individual line Move buttons:
func _on_line_right_clicked(line_idx: int):
	candy_dc.rc_target = "line"
	candy_dc.line_delete_index = line_idx

	#@ Ensure the clicked line becomes the selection:
	if candy_dc.selected_lines.is_empty() or not candy_dc.selected_lines.has(line_idx):
		candy_dc.selected_lines.clear()
		candy_dc.selected_lines.append(line_idx)

	#@ Build NEW contextual menu for lines:
	rc_menu.clear()
	rc_menu.add_item("Copy", 1)
	rc_menu.add_item("Cut", 2)
	rc_menu.add_separator()
	rc_menu.add_item("Paste Above", 3)
	rc_menu.add_item("Paste Below", 4)
	rc_menu.add_separator()
	rc_menu.add_item("Move Up", 6)
	rc_menu.add_item("Move Down", 7)
	rc_menu.add_separator()
	rc_menu.add_item("Delete", 5)

	#@ Disable Paste options if clipboard empty:
	if candy_dc.clipboard_lines.is_empty():
		rc_menu.set_item_disabled(3, true)
		rc_menu.set_item_disabled(4, true)

	#@ Disable move options if at bounds:
	var lines_array: Array = candy_dc.conversations[candy_dc.current_conversation][candy_dc.current_block]["Text"]
	if line_idx <= 0:
		rc_menu.set_item_disabled(6, true)
	if line_idx >= lines_array.size() - 1:
		rc_menu.set_item_disabled(7, true)

	#@ Position & display:
	var local_pos: Vector2 = get_global_mouse_position() - global_position
	rc_menu.position = local_pos
	rc_menu.popup()


#* Handle popup menu actions depending on current target:
func _on_right_click_menu_pressed(id: int) -> void:
	match id:
		0:  #% Rename:
			match candy_dc.rc_target:
				"conversation":
					if candy_dc.current_conversation == "":
						return
					$"NameConvo".visible = true
					$"NameConvo/PanelC/VBox/HBox/Cancel".visible = false
					$"NameConvo/PanelC/VBox/LineEdit".text = candy_dc.current_conversation
					$"NameConvo/PanelC/VBox/LineEdit".grab_focus()

				"block":
					if candy_dc.current_block == "":
						return
					$"RenameBlock".visible = true
					$"RenameBlock/PanelC/VBox/HBox/Cancel".visible = false
					$"RenameBlock/PanelC/VBox/LineEdit".text = candy_dc.current_block
					$"RenameBlock/PanelC/VBox/LineEdit".grab_focus()

		1:  #% Copy:
			match candy_dc.rc_target:
				"line":
					_copy_selected_lines()

		2:  #% Cut:
			match candy_dc.rc_target:
				"line":
					_cut_selected_lines()

		3:  #% Paste Above:
			match candy_dc.rc_target:
				"line":
					_paste_lines(candy_dc.line_delete_index, true)

		4:  #% Paste Below:
			match candy_dc.rc_target:
				"line":
					_paste_lines(candy_dc.line_delete_index, false)

		5:  #% Delete:
			match candy_dc.rc_target:
				"conversation":
					if candy_dc.current_conversation == "":
						return
					$"ConfirmDeleteConv/Name".text = "[center]" + candy_dc.current_conversation + "[/center]"
					$"ConfirmDeleteConv".visible = true

				"block":
					if candy_dc.current_block == "":
						return
					$"ConfirmDeleteConv/Name".text = "[center]" + candy_dc.current_block + "[/center]"
					$"ConfirmDeleteConv".visible = true

				"line":
					if candy_dc.line_delete_index == -1:
						return
					if candy_dc.confirm_delete_line == true:
						var display_name = "Line " + str(candy_dc.line_delete_index + 1)
						$"ConfirmDeleteConv/Name".text = "[center]" + display_name + "[/center]"
						$"ConfirmDeleteConv".visible = true
					else:
						_delete_lines()

		6:  #% Move Up:
			match candy_dc.rc_target:
				"line":
					_move_line(candy_dc.line_delete_index, -1)

		7:  #% Move Down:
			match candy_dc.rc_target:
				"line":
					_move_line(candy_dc.line_delete_index, 1)


#* Copy selected lines into clipboard:
func _copy_selected_lines() -> void:
	candy_dc.clipboard_lines.clear()

	if candy_dc.selected_lines.is_empty():
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var blk = conv[candy_dc.current_block]
	var lines = blk["Text"]

	for idx in candy_dc.selected_lines:
		candy_dc.clipboard_lines.append(lines[idx].duplicate(true))

	#% Deselect after copying:
	candy_dc.selected_lines.clear()
	_load_active_block()


#* Cut selected lines:
func _cut_selected_lines() -> void:
	#@ Copy the lines:
	candy_dc.clipboard_lines.clear()

	if candy_dc.selected_lines.is_empty():
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var blk = conv[candy_dc.current_block]
	var lines = blk["Text"]

	for idx in candy_dc.selected_lines:
		candy_dc.clipboard_lines.append(lines[idx].duplicate(true))

	#@ Delete the lines:
	_delete_lines()


#* Paste lines above/below this line:
func _paste_lines(target_index: int, above: bool) -> void:
	if candy_dc.clipboard_lines.is_empty():
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var lines = block["Text"]

	var insert_index = target_index + (0 if above else 1)

	for entry in candy_dc.clipboard_lines:
		lines.insert(insert_index, entry.duplicate(true))
		insert_index += 1

	#% Deselect after pasting:
	candy_dc.selected_lines.clear()
	_load_active_block()

#* Move a line entry up or down within the current block:
func _move_line(line_idx: int, direction: int) -> void:
	var convo = candy_dc.current_conversation
	var block = candy_dc.current_block
	var text_array: Array = candy_dc.conversations[convo][block]["Text"]

	var new_index := line_idx + direction
	if new_index < 0 or new_index >= text_array.size():
		return

	#% Swap elements:
	var temp = text_array[line_idx]
	text_array[line_idx] = text_array[new_index]
	text_array[new_index] = temp

	#% Save back and update globals:
	candy_dc.conversations[convo][block]["Text"] = text_array
	candy_dc.line_delete_index = new_index
	candy_dc.selected_lines.clear()
	candy_dc.selected_lines.append(new_index)

	#% Refresh UI if applicable:
	_load_active_block()
#endregion


#?######################################################################################
#& UI STUFF:
#?##########
#region
#& Conversations and Blocks:
#region
#* Create new conversation:
func _on_new_conv_pressed() -> void:
	candy_dc.conversations["new_conversation"] = {}
	candy_dc.current_conversation = "new_conversation"

	#@ Automatically create the first block:
	candy_dc.conversations["new_conversation"]["Block_1"] = {"Text": []}
	_init_new_block(candy_dc.conversations["new_conversation"]["Block_1"])
	candy_dc.current_block = "Block_1"

	#@ Immediately rebuild dropdowns:
	var conv_btn := $"VBox/TopBar/HBox/Conversations/Conversations"
	conv_btn.clear()
	for key in candy_dc.conversations.keys():
		conv_btn.add_item(key)
		if key == candy_dc.current_conversation:
			conv_btn.select(conv_btn.item_count - 1)

	#@ Refresh block dropdown:
	var block_btn := $"VBox/TopBar/HBox/Blocks/Blocks"
	block_btn.clear()
	for block_name in candy_dc.conversations["new_conversation"].keys():
		block_btn.add_item(block_name)
		if block_name == candy_dc.current_block:
			block_btn.select(block_btn.item_count - 1)

	#@ Clear line area (now Block 1):
	await _load_active_block()

	#@ Show rename popup for conversation:
	$"NameConvo".visible = true
	$"NameConvo/PanelC/VBox/HBox/Cancel".visible = false
	$"NameConvo/PanelC/VBox/LineEdit".text = candy_dc.new_conversation_name
	$"NameConvo/PanelC/VBox/LineEdit".grab_focus()


#* Create new block:
func _on_new_block_pressed() -> void:
	if candy_dc.current_conversation == "":
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	conv["NewBlock"] = {"Text": []}
	_init_new_block(candy_dc.conversations[candy_dc.current_conversation]["NewBlock"])
	candy_dc.current_block = "NewBlock"

	#@ Refresh block dropdown:
	var block_btn := $"VBox/TopBar/HBox/Blocks/Blocks"
	block_btn.clear()
	for block_name in conv.keys():
		block_btn.add_item(block_name)
		if block_name == candy_dc.current_block:
			block_btn.select(block_btn.item_count - 1)

	#@ Load it immediately so the lines clear & bind:
	await _load_active_block()

	#@ Show rename popup:
	$"RenameBlock".visible = true
	$"RenameBlock/PanelC/VBox/HBox/Cancel".visible = false
	$"RenameBlock/PanelC/VBox/LineEdit".text = candy_dc.new_block_name
	$"RenameBlock/PanelC/VBox/LineEdit".grab_focus()


#* Initialize a new block with a default comment line:
func _init_new_block(block_dict: Dictionary) -> void:
	var default_comment = {
		"§Comment": {
			"Color": null,
			"Comment": ""
		}
	}
	block_dict["Text"].append(default_comment)


#* Open Block selection menu:
func _on_blocks_pressed() -> void:
	$"VBox/TopBar/HBox/Blocks/Blocks".clear()

	#% Nothing to show if no active conversation:
	if candy_dc.current_conversation == "":
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var idx := 0
	for block_name in conv.keys():
		$"VBox/TopBar/HBox/Blocks/Blocks".add_item(block_name)
		if block_name == candy_dc.current_block:
			$"VBox/TopBar/HBox/Blocks/Blocks".select(idx)
		idx += 1


#* Select another Block:
func _on_blocks_item_selected(index: int) -> void:
	if candy_dc.current_conversation == "":
		return

	if candy_dc.current_conversation == "CUSTOM_PRESETS":
		_build_command_presets()

	var block_name = $"VBox/TopBar/HBox/Blocks/Blocks".get_item_text(index)
	candy_dc.current_block = block_name

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	lines_data = conv[block_name]["Text"]

	#@ Update scroll bar limits:
	scroll_bar.value = 0

	await _apply_scroll_limits()

	_update_visible_lines()
	record_browsing_point()


#* Change Conversation:
func _on_conversations_pressed() -> void:
	$"VBox/TopBar/HBox/Conversations/Conversations".clear()
	var idx := 0
	for conv in candy_dc.conversations:
		$"VBox/TopBar/HBox/Conversations/Conversations".add_item(conv)
		if conv == candy_dc.current_conversation:
			$"VBox/TopBar/HBox/Conversations/Conversations".select(idx)
		idx += 1


#* Select another Conversation:
func _on_conversations_item_selected(index: int) -> void:
	if candy_dc.current_conversation == "CUSTOM_PRESETS":
		_build_command_presets()

	candy_dc.current_conversation = $"VBox/TopBar/HBox/Conversations/Conversations".get_item_text(index)

	#% Rebuild Blocks list for this conversation:
	$"VBox/TopBar/HBox/Blocks/Blocks".clear()

	var conv = candy_dc.conversations.get(candy_dc.current_conversation, {})
	var first_block := ""
	for block_name in conv.keys():
		$"VBox/TopBar/HBox/Blocks/Blocks".add_item(block_name)
		if first_block == "":
			first_block = block_name

	#% Choose current_block (first available or none):
	if first_block == "":
		candy_dc.current_block = ""
		$"VBox/TopBar/HBox/Blocks/Blocks".text = ""
		$"VBox/TopBar/HBox/Blocks/Blocks".select(-1)
	else:
		candy_dc.current_block = first_block
		$"VBox/TopBar/HBox/Blocks/Blocks".select(0)

	#% Load the block's lines into the line panels:
	await _load_active_block()
	record_browsing_point()


#* Record the current Conversation/Block in browsing history:
func record_browsing_point() -> void:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return

	var entry := {
		"conversation": candy_dc.current_conversation,
		"block": candy_dc.current_block
	}

	#@ If we’re in the middle of the list (after going back), trim future history:
	if candy_dc.browsing_index < candy_dc.browsing_history.size() - 1:
		candy_dc.browsing_history.resize(candy_dc.browsing_index + 1)

	#@ Don’t duplicate if identical to last:
	if not candy_dc.browsing_history.is_empty():
		var last = candy_dc.browsing_history.back()
		if last["conversation"] == entry["conversation"] and last["block"] == entry["block"]:
			return

	#@ Add and advance pointer:
	candy_dc.browsing_history.append(entry)
	candy_dc.browsing_index = candy_dc.browsing_history.size() - 1


#* Go back to the previous browsing history entry:
func go_back_in_history() -> void:
	if candy_dc.browsing_index <= 0:
		return
	candy_dc.browsing_index -= 1
	_apply_history_entry(candy_dc.browsing_history[candy_dc.browsing_index])


#* Go forward to the next browsing history entry:
func go_forward_in_history() -> void:
	if candy_dc.browsing_index >= candy_dc.browsing_history.size() - 1:
		return
	candy_dc.browsing_index += 1
	_apply_history_entry(candy_dc.browsing_history[candy_dc.browsing_index])


#* Internal helper: apply a recorded browsing entry:
func _apply_history_entry(entry: Dictionary, direction: int = 0) -> void:
	var convo = entry["conversation"]
	var block = entry["block"]

	#% If deleted, skip toward direction if given:
	if not candy_dc.conversations.has(convo):
		if direction != 0:
			_skip_invalid_history(direction)
		return
	if not candy_dc.conversations[convo].has(block):
		if direction != 0:
			_skip_invalid_history(direction)
		return

	#% Apply normally:
	candy_dc.current_conversation = convo
	candy_dc.current_block = block

	#% Update dropdowns visually:
	var conv_menu := $"VBox/TopBar/HBox/Conversations/Conversations"
	var block_menu := $"VBox/TopBar/HBox/Blocks/Blocks"

	#% Find the matching item index manually:
	var conv_idx := -1
	for i in range(conv_menu.item_count):
		if conv_menu.get_item_text(i) == convo:
			conv_idx = i
			break

	var block_idx := -1
	for i in range(block_menu.item_count):
		if block_menu.get_item_text(i) == block:
			block_idx = i
			break

	#% Apply selections only if valid:
	if conv_idx != -1:
		conv_menu.select(conv_idx)
	if block_idx != -1:
		block_menu.select(block_idx)

	await _load_active_block()


#* Move pointer until a valid history entry is found, or stop if none:
func _skip_invalid_history(direction: int) -> void:
	while true:
		candy_dc.browsing_index += direction
		if candy_dc.browsing_index < 0 or candy_dc.browsing_index >= candy_dc.browsing_history.size():
			return		#/ No more valid entries
		var e = candy_dc.browsing_history[candy_dc.browsing_index]
		if candy_dc.conversations.has(e["conversation"]) and candy_dc.conversations[e["conversation"]].has(e["block"]):
			_apply_history_entry(e, direction)
			return

#endregion


#& Hide UI Elements:
#region
#* 'Hide index' button pressed:
#% Toggle indexes for all lines.
func _on_hide_index_pressed() -> void:
	candy_dc.hide_indexes = !candy_dc.hide_indexes
	for line in $"VBox/HBox/WorkArea/Lines".get_children():
		line.get_node("HBox/Index").visible = not candy_dc.hide_indexes

	var btn = $"VBox/TopBar/HBox/Hide/HideIndex"
	btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"] if candy_dc.hide_indexes else candy_dc.color_models[candy_dc.color_mode]["Null"]
	get_node("ProfileMenu").save_profile()

#* 'Hide tags' button pressed:
#% Toggle 'Tag' buttons in Spoken Lines (LLM, TTS, etc).
func _on_hide_tags_pressed() -> void:
	candy_dc.hide_tags = !candy_dc.hide_tags
	for line in $"VBox/HBox/WorkArea/Lines".get_children():
		line.get_node("HBox/SpeechLine/LLM").visible = not candy_dc.hide_tags
		line.get_node("HBox/SpeechLine/BubbleExempt").visible = not candy_dc.hide_tags
		line.get_node("HBox/SpeechLine/ForcePortrait").visible = not candy_dc.hide_tags
		line.get_node("HBox/SpeechLine/TTS").visible = not candy_dc.hide_tags

	var btn = $"VBox/TopBar/HBox/Hide/HideTags"
	btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"] if candy_dc.hide_tags else candy_dc.color_models[candy_dc.color_mode]["Null"]
	get_node("ProfileMenu").save_profile()

#* 'Hide disposition' button pressed:
#% Toggle 'Disposition' field in Spoken Lines.
func _on_hide_disposition_pressed() -> void:
	candy_dc.hide_disposition = !candy_dc.hide_disposition
	for line in $"VBox/HBox/WorkArea/Lines".get_children():
		line.get_node("HBox/SpeechLine/Disposition").visible = not candy_dc.hide_disposition

	var btn = $"VBox/TopBar/HBox/Hide/HideDisposition"
	btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"] if candy_dc.hide_disposition else candy_dc.color_models[candy_dc.color_mode]["Null"]
	get_node("ProfileMenu").save_profile()

#* 'Hide voice' button pressed:
#% Toggle 'Voice' field in Spoken Lines.
func _on_hide_voice_pressed() -> void:
	candy_dc.hide_voice = !candy_dc.hide_voice
	for line in $"VBox/HBox/WorkArea/Lines".get_children():
		line.get_node("HBox/SpeechLine/Voice").visible = not candy_dc.hide_voice

	var btn = $"VBox/TopBar/HBox/Hide/HideVoice"
	btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"] if candy_dc.hide_voice else candy_dc.color_models[candy_dc.color_mode]["Null"]
	get_node("ProfileMenu").save_profile()

#* 'Hide text limit' button pressed:
#% Toggle text character count/limit in Spoken Lines.
func _on_hide_limit_pressed() -> void:
	candy_dc.hide_limit = !candy_dc.hide_limit
	for line in $"VBox/HBox/WorkArea/Lines".get_children():
		line.get_node("HBox/SpeechLine/PanelC").visible = not candy_dc.hide_limit

	var btn = $"VBox/TopBar/HBox/Hide/HideLimit"
	btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"] if candy_dc.hide_limit else candy_dc.color_models[candy_dc.color_mode]["Null"]
	get_node("ProfileMenu").save_profile()

#* 'Hide portrait' button pressed:
#% Toggle 'Portrait' field in Spoken Lines.
func _on_hide_portrait_pressed() -> void:
	candy_dc.hide_portrait = !candy_dc.hide_portrait
	for line in $"VBox/HBox/WorkArea/Lines".get_children():
		line.get_node("HBox/SpeechLine/Portrait").visible = not candy_dc.hide_portrait

	var btn = $"VBox/TopBar/HBox/Hide/HidePortrait"
	btn.modulate = candy_dc.color_models[candy_dc.color_mode]["Fade"] if candy_dc.hide_portrait else candy_dc.color_models[candy_dc.color_mode]["Null"]
	get_node("ProfileMenu").save_profile()

#endregion


#& Side Bar Stuff:
#region
#* Minimize/Maximize all commands:
func _on_minimize_commands_pressed() -> void:
	if candy_dc.command_groups_fold == 0:
		for group in $"VBox/HBox/SideBar/VBox/Core/VBox".get_children():
			group.folded = true
		candy_dc.command_groups_fold = 1

	elif candy_dc.command_groups_fold == 1:
		for group in $"VBox/HBox/SideBar/VBox/Core/VBox".get_children():
			group.folded = false
		candy_dc.command_groups_fold = 0

	#% Update button text:
	var btn = $"VBox/HBox/SideBar/VBox/Buttons/HBox/MinimizeCommands"
	btn.text = "🞅" if candy_dc.command_groups_fold == 1 else "🞊"


#* Display core commands:
func _on_core_commands_pressed() -> void:
	$"VBox/HBox/SideBar/VBox/Core".visible = true
	$"VBox/HBox/SideBar/VBox/Presets".visible = false


#* Display custom presets:
func _on_command_presets_pressed() -> void:
	$"VBox/HBox/SideBar/VBox/Core".visible = false
	$"VBox/HBox/SideBar/VBox/Presets".visible = true
#endregion
#endregion


#?######################################################################################
#& LINE ELEMENTS:
#?###############
#region
#& SPOKEN LINES:
#region
#* Open voice menu for a line:
func open_voice_menu(line: Node, field: LineEdit, char_name: String) -> void:
	#% Clear previous items:
	for c in file_box.get_children():
		c.queue_free()

	await get_tree().process_frame

	#% Ensure valid structure:
	if not (candy_dc.resources.has("*Voices")
	and candy_dc.resources["*Voices"].has(char_name)
	and candy_dc.resources["*Voices"][char_name].has(candy_dc.current_conversation)
	and candy_dc.resources["*Voices"][char_name][candy_dc.current_conversation].has(candy_dc.current_block)):
		var label := Label.new()
		label.text = "[No voice files found]"
		file_box.add_child(label)
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
		file_popup.popup()
		return

	#% Retrieve only matching files:
	var block_dict = candy_dc.resources["*Voices"][char_name][candy_dc.current_conversation][candy_dc.current_block]

	for filename in block_dict.keys():
		#% Skip folders:
		if candy_dc.resources["*Voices"][char_name][candy_dc.current_conversation][candy_dc.current_block][filename] is Dictionary:
			continue

		var btn := Button.new()
		btn.text = filename
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		#% Hover: start preview:
		btn.mouse_entered.connect(func():
			_preview_voice(char_name, filename))

		#% Unhover: stop preview:
		btn.mouse_exited.connect(func():
			stop_voice_preview())

		#% Select:
		btn.pressed.connect(func():
			stop_voice_preview()
			file_popup.hide()
			line._apply_selected_voice(filename))
		file_box.add_child(btn)

	#% Show popup:
	var max_width := 0.0
	var max_height: = 8.0
	for c in file_box.get_children():
		if c is Control:
			max_width = max(max_width, c.get_combined_minimum_size().x)
			max_height += 31.0

	if max_height > 480:
		max_height = 480

	#% Apply width to popup (add a bit of padding):
	file_popup.size.x = int(max_width + 32)
	file_popup.size.y = int(max_height)

	var line_number = int(line.name.substr(4))
	if line_number < VISIBLE_LINES/2.0 :
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	else:
		file_popup.position = field.get_global_position() + Vector2(0, 0 - max_height)

	file_popup.popup()


#* Play voice preview:
func _preview_voice(char_name: String, filename: String) -> void:
	#% Validate nested structure:
	if not (candy_dc.resources.has("*Voices")
	and candy_dc.resources["*Voices"].has(char_name)
	and candy_dc.resources["*Voices"][char_name].has(candy_dc.current_conversation)
	and candy_dc.resources["*Voices"][char_name][candy_dc.current_conversation].has(candy_dc.current_block)):
		return

	var block_dict = candy_dc.resources["*Voices"][char_name][candy_dc.current_conversation][candy_dc.current_block]

	#% Ensure the requested filename exists:
	if not block_dict.has(filename):
		return

	var path: String = block_dict[filename]
	if not FileAccess.file_exists(path):
		return

	#% Load file as AudioStream and play:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return

	var stream := AudioStreamMP3.new()
	stream.data = file.get_buffer(file.get_length())
	voice_preview.stop()
	voice_preview.stream = stream
	voice_preview.play()


#* Stop voice preview:
func stop_voice_preview() -> void:
	if voice_preview and voice_preview.playing:
		voice_preview.stop()


#* Display list of operator:
func open_operator_menu(line: Node, field: LineEdit):
	#% Rebuild the list:
	for c in file_box.get_children():
		c.queue_free()

	await get_tree().process_frame

	for operator in candy_dc.operator_list:
		var btn := Button.new()
		btn.text = operator
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		#% Select:
		btn.pressed.connect(func():
			file_popup.hide()
			hide_portrait_panel()
			line._set_apply_selected_operator(operator))
		file_box.add_child(btn)

	#% Show popup:
	var max_width := 0.0
	var max_height: = 8.0
	for c in file_box.get_children():
		if c is Control:
			max_width = max(max_width, c.get_combined_minimum_size().x)
			max_height += 31.0

	if max_height > 480:
		max_height = 480

	#% Add width to popup:
	file_popup.size.x = int(max_width + 32)
	file_popup.size.y = int(max_height)

	var line_number = int(line.name.substr(4))
	if line_number < VISIBLE_LINES/2.0 :
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	else:
		file_popup.position = field.get_global_position() + Vector2(0, 0 - max_height)

	file_popup.popup()

#* Display list of dispositions:
func open_flag_menu(line: Node, field: LineEdit):
	#% Rebuild the list:
	for c in file_box.get_children():
		c.queue_free()

	await get_tree().process_frame

	for flag in candy_dc.flag_list:
		var btn := Button.new()
		btn.text = flag
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		#% Select:
		btn.pressed.connect(func():
			file_popup.hide()
			hide_portrait_panel()
			line._set_apply_selected_flag(flag))
		file_box.add_child(btn)

	#% Show popup:
	var max_width := 0.0
	var max_height: = 8.0
	for c in file_box.get_children():
		if c is Control:
			max_width = max(max_width, c.get_combined_minimum_size().x)
			max_height += 31.0

	if max_height > 480:
		max_height = 480

	#% Add width to popup:
	file_popup.size.x = int(max_width + 32)
	file_popup.size.y = int(max_height)

	var line_number = int(line.name.substr(4))
	if line_number < VISIBLE_LINES/2.0 :
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	else:
		file_popup.position = field.get_global_position() + Vector2(0, 0 - max_height)

	file_popup.popup()


#* Display list of dispositions:
func open_disposition_menu(line: Node, field: LineEdit):
	#% Rebuild the list
	for c in file_box.get_children():
		c.queue_free()

	await get_tree().process_frame

	for disposition in candy_dc.disposition_list:
		var btn := Button.new()
		btn.text = disposition
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		#% Select:
		btn.pressed.connect(func():
			file_popup.hide()
			hide_portrait_panel()
			line._set_apply_selected_disposition(disposition))
		file_box.add_child(btn)

	#% Show popup:
	var max_width := field.size.x
	var max_height: = 8.0
	for c in file_box.get_children():
		if c is Control:
			max_width = max(max_width, c.get_combined_minimum_size().x)
			max_height += 31.0

	if max_height > 480:
		max_height = 480

	#% Add width to popup:
	file_popup.size.x = int(max_width + 16)
	file_popup.size.y = int(max_height)

	var line_number = int(line.name.substr(4))
	if line_number < VISIBLE_LINES/2.0 :
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	else:
		file_popup.position = field.get_global_position() + Vector2(0, 0 - max_height)

	file_popup.popup()


#* Display list of references:
func open_reference_menu(line: Node, field: LineEdit, role):
	#% Rebuild the list:
	for c in file_box.get_children():
		c.queue_free()

	await get_tree().process_frame

	if role == false:
		for ref in candy_dc.actor_list:
			var btn := Button.new()
			btn.text = ref
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

			#% Select:
			if candy_dc.editor_state == "ui":
				if field == line.get_node("HBox/Con/Reference/Ref"):	#/ Function called by §Name or §Disposition
					btn.pressed.connect(func():
						file_popup.hide()								#/ List closes
						hide_portrait_panel()
						line._set_apply_selected_reference(ref))
					file_box.add_child(btn)
				elif field == line.get_node("HBox/VN/Reference/Ref"):	#/ Function called by §VN command:
					btn.pressed.connect(func():
						file_popup.hide()								#/ List closes
						hide_portrait_panel()
						line._apply_selected_vn_reference(ref))
					file_box.add_child(btn)
				else:													#/ Function called by Spoken Line
					btn.pressed.connect(func():
						file_popup.hide()								#/ List closes
						hide_portrait_panel()
						line._apply_selected_reference(ref))
					file_box.add_child(btn)

			elif candy_dc.editor_state == "writer":
				btn.pressed.connect(func():
					file_popup.hide()								#/ List closes
					hide_portrait_panel()
					line._apply_selected_reference(ref))
				file_box.add_child(btn)


	elif role == true:
		for ref in candy_dc.role_list:
			var btn := Button.new()
			btn.text = ref
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

			#% Select:
			if candy_dc.editor_state == "ui":
				if field == line.get_node("HBox/Con/Role/Ref"):			#/ Function called by §Role
					btn.pressed.connect(func():
						file_popup.hide()								#/ List closes
						hide_portrait_panel()
						line._set_apply_selected_role(ref))
					file_box.add_child(btn)
				elif field == line.get_node("HBox/Con/Reference/Ref"):	#/ Function called by §Name or §Disposition
					btn.pressed.connect(func():
						file_popup.hide()								#/ List closes
						hide_portrait_panel()
						line._set_apply_selected_reference(ref))
					file_box.add_child(btn)
				else:													#/ Function called by Spoken Line
					btn.pressed.connect(func():
						file_popup.hide()								#/ List closes
						hide_portrait_panel()
						line._apply_selected_reference(ref))
					file_box.add_child(btn)

			elif candy_dc.editor_state == "writer":
				btn.pressed.connect(func():
					file_popup.hide()								#/ List closes
					hide_portrait_panel()
					line._apply_selected_reference(ref))
				file_box.add_child(btn)

	#% Show popup:
	var max_width := field.size.x
	var max_height: = 8.0
	for c in file_box.get_children():
		if c is Control:
			max_width = max(max_width, c.get_combined_minimum_size().x)
			max_height += 31.0

	if max_height > 480:
		max_height = 480

	#% Apply width to popup (add a bit of padding):
	file_popup.size.x = int(max_width + 16)
	file_popup.size.y = int(max_height)

	var line_number = int(line.name.substr(4))
	if line_number < VISIBLE_LINES/2.0 :
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	else:
		file_popup.position = field.get_global_position() + Vector2(0, 0 - max_height)

	file_popup.popup()


#* Open portrait menu for a line:
func open_portrait_menu(line: Node, field: LineEdit, char_name: String) -> void:
	#@ Clear old items:
	for c in file_box.get_children():
		c.queue_free()

	await get_tree().process_frame

	#@ Rebuild the list:
	if candy_dc.resources.has("*Portraits") and candy_dc.resources["*Portraits"].has(char_name):
		for filename in candy_dc.resources["*Portraits"][char_name].keys():
			#% Skip UID files and subfolders:
			if filename.ends_with(".uid") or filename.ends_with(".tscn") or typeof(candy_dc.resources["*Busts"][char_name][filename]) == TYPE_DICTIONARY:
				continue

			var btn := Button.new()
			btn.text = filename
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

			#% Hover: show preview image (keep panel open):
			btn.mouse_entered.connect(func():
				_preview_portrait(char_name, filename))

			#% Unhover: hide only the preview rect, NOT the popup panel:
			btn.mouse_exited.connect(func():
				hide_portrait_preview_only())

			#% Select:
			btn.pressed.connect(func():
				file_popup.hide()
				hide_portrait_panel()
				line._apply_selected_portrait(filename))
			file_box.add_child(btn)
	else:
		var label := Label.new()
		label.text = "[No portraits found]"
		file_box.add_child(label)

	#@ Show popup:
	var max_width := 0.0
	var max_height: = 8.0
	for c in file_box.get_children():
		if c is Control:
			max_width = max(max_width, c.get_combined_minimum_size().x)
			max_height += 31.0

	if max_height > 480:
		max_height = 480

	#% Apply width to popup (add a bit of padding):
	file_popup.size.x = int(max_width + 32)
	file_popup.size.y = int(max_height)

	var line_number = int(line.name.substr(4))
	if line_number < VISIBLE_LINES/2.0 :
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	else:
		file_popup.position = field.get_global_position() + Vector2(0, 0 - max_height)

	file_popup.popup()


#* Close portrait list:
func hide_portrait_panel() -> void:
	if portrait_popup:
		portrait_popup.visible = false


#* Show portrait preview:
func _preview_portrait(char_name: String, filename: String) -> void:
	if not (candy_dc.resources.has("*Portraits") and candy_dc.resources["*Portraits"].has(char_name)):
		hide_portrait_preview_only()
		return

	var dict = candy_dc.resources["*Portraits"][char_name]
	if not dict.has(filename):
		hide_portrait_preview_only()
		return

	var path: String = dict[filename]
	var img := Image.new()
	if img.load(path) != OK:
		hide_portrait_preview_only()
		return

	var tex := ImageTexture.create_from_image(img)
	if not (tex is Texture2D):
		hide_portrait_preview_only()
		return

	portrait_preview.texture = tex
	portrait_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT

	#% Respect global max size settings:
	var w = tex.get_width()
	var h = tex.get_height()
	var max_w = candy_dc.portrait_preview_max_w
	var max_h = candy_dc.portrait_preview_max_h
	if max_w > 0 or max_h > 0:
		var ratio = float(w) / float(h)
		if max_w > 0 and w > max_w:
			w = max_w
			h = w / ratio
		if max_h > 0 and h > max_h:
			h = max_h
			w = h * ratio

	portrait_preview.custom_minimum_size = Vector2(w, h)

	#% Show panel + rect; panel tracks cursor in _process:
	portrait_popup.visible = true
	portrait_preview.visible = true


#* Hide portrait preview:
func hide_portrait_preview_only() -> void:
	#% DO NOT close the Portrait popup, only its content:
	if portrait_preview:
		portrait_preview.visible = false


#* Close previews when list closes:
func _on_file_popup_visibility_changed() -> void:
	if file_popup.visible:
		return
	hide_portrait_panel()
	stop_voice_preview()
#endregion


#& MEDIA LINES:
#region
#* Open a list of media player nodes (for §Video, §Audio, §Image):
func open_media_player_menu(line: Node, field: LineEdit) -> void:
	#@ Clear existing items from the shared file list:
	for c in file_box.get_children():
		c.queue_free()

	await get_tree().process_frame

	#@ Determine which resource type to use based on the line’s Type:
	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var line_data = block["Text"][line.dictionary_index]

	var line_type := ""
	for key in line_data.keys():
		line_type = key
		break

	var media_key := ""
	match line_type:
		"§Image", "§I_Pause", "§I_Resume", "§I_Wait", "§I_Show", "§I_Stop":
			media_key = "Images"
		"§Video", "§V_Pause", "§V_Resume", "§V_Wait", "§V_Skip", "§V_Volume", "§V_Show", "§V_Stop":
			media_key = "Videos"
		"§Audio", "§A_Pause", "§A_Resume", "§A_Wait", "§A_Skip", "§A_Volume", "§A_Stop":
			media_key = "Audio"
		_:
			var label := Label.new()
			label.text = "[Unsupported media type]"
			file_box.add_child(label)
			file_popup.position = line.get_global_position() + Vector2(0, line.size.y)
			file_popup.popup()
			return

	#@ Step 1 - Verify resource dictionary exists:
	if not candy_dc.resources.has(media_key):
		var label := Label.new()
		label.text = "[No resources found]"
		file_box.add_child(label)
		file_popup.position = line.get_global_position() + Vector2(0, line.size.y)
		file_popup.popup()
		return

	var folder_dict = candy_dc.resources[media_key]

	#@ Step 2 - Populate popup with ALL subfolder names, even if empty:
	var found_any = false
	for subfolder_name in folder_dict.keys():
		var subfolder_content = folder_dict[subfolder_name]
		if typeof(subfolder_content) == TYPE_DICTIONARY:
			found_any = true
			var btn := Button.new()
			btn.text = subfolder_name
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.pressed.connect(func():
				file_popup.hide()
				line._apply_selected_media_player(subfolder_name))
			file_box.add_child(btn)

	#@ Step 3 - Handle case where absolutely no subfolders exist:
	if not found_any:
		var label := Label.new()
		label.text = "[No player nodes found]"
		file_box.add_child(label)

	#@ Step 4 - Position and display popup:
	var max_width := 0.0
	var max_height: = 8.0
	for c in file_box.get_children():
		if c is Control:
			max_width = max(max_width, c.get_combined_minimum_size().x)
			max_height += 31.0

	if max_height > 480:
		max_height = 480

	#% Apply width to popup (add a bit of padding):
	file_popup.size.x = int(max_width + 32)
	file_popup.size.y = int(max_height)

	var line_number = int(line.name.substr(4))
	if line_number < VISIBLE_LINES/2.0 :
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	else:
		file_popup.position = field.get_global_position() + Vector2(0, 0 - max_height)

	file_popup.popup()


#* Open a list of media files (BG, Image, Video, Audio, Music, etc.):
func open_media_menu(line: Node, field: LineEdit, node: String) -> void:
	#% Clear any existing items in the shared file list:
	for c in file_box.get_children():
		c.queue_free()

	await get_tree().process_frame

	#% Determine which resource type to use based on the line’s Type:
	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var line_data = block["Text"][line.dictionary_index]

	var line_type := ""
	for key in line_data.keys():
		line_type = key
		break

	var media_key := ""
	match line_type:
		"§BG":
			media_key = "Backgrounds"
		"§Image":
			media_key = "Images"
		"§Video":
			media_key = "Videos"
		"§Audio":
			media_key = "Audio"
		_:
			var label := Label.new()
			label.text = "[Unsupported media type]"
			file_box.add_child(label)
			file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
			file_popup.popup()
			return

	#@ Step 1 - Verify resource dictionary exists:
	if not candy_dc.resources.has(media_key):
		var label := Label.new()
		label.text = "[Not found]"
		file_box.add_child(label)
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
		file_popup.popup()
		return

	var folder_dict = candy_dc.resources[media_key]

	#@ Step 2 - For §Image, §Video, §Audio → use sub-folder pattern:
	if line_type in ["§Image", "§Video", "§Audio"]:
		if node == "":
			return
		if not folder_dict.has(node):
			var label := Label.new()
			label.text = "[Folder '" + node + "' not found]"
			file_box.add_child(label)
			file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
			file_popup.popup()
			return

		var node_folder = folder_dict[node]
		for filename in node_folder.keys():
			#% Skip UID files and subfolders:
			if filename.ends_with(".uid") or filename.ends_with(".tscn") or node_folder[filename] is Dictionary:
				continue

			var btn := Button.new()
			btn.text = filename
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

			#% Hover preview depending on media type:
			btn.mouse_entered.connect(func():
				if line_type == "§Image":
					_preview_media_image(node_folder[filename])
				elif line_type == "§Audio":
					_preview_media_audio(node_folder[filename])
				elif line_type == "§Video":
					_preview_media_video(node_folder[filename])
			)
			btn.mouse_exited.connect(func():
				hide_media_preview_only())

			#% Selection:
			btn.pressed.connect(func():
				file_popup.hide()
				line._apply_selected_media(filename))
			file_box.add_child(btn)

	#@ Step 3 - Display popup:
	var max_width := 0.0
	var max_height: = 8.0
	for c in file_box.get_children():
		if c is Control:
			max_width = max(max_width, c.get_combined_minimum_size().x)
			max_height += 31.0

	if max_height > 480:
		max_height = 480

	#% Apply width to popup (add a bit of padding):
	file_popup.size.x = int(max_width + 32)
	file_popup.size.y = int(max_height)
	print(max_height)

	var line_number = int(line.name.substr(4))
	if line_number < VISIBLE_LINES/2.0 :
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	else:
		file_popup.position = field.get_global_position() + Vector2(0, 0 - max_height)

	file_popup.popup()


#* Open a list of VN Bust files for the selected character:
func open_vn_bust_file_menu(line: Node, field: LineEdit, char_name: String) -> void:
	#@ Clear old items:
	for c in file_box.get_children():
		c.queue_free()

	await get_tree().process_frame

	#@ Rebuild the list:
	if candy_dc.resources.has("*Busts") and candy_dc.resources["*Busts"].has(char_name):
		for filename in candy_dc.resources["*Busts"][char_name].keys():
			#% Skip UID files and subfolders:
			if filename.ends_with(".uid") or filename.ends_with(".tscn") or typeof(candy_dc.resources["*Busts"][char_name][filename]) == TYPE_DICTIONARY:
				continue

			var btn := Button.new()
			btn.text = filename
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

			#% Hover: show preview image (keep panel open):
			btn.mouse_entered.connect(func():
				_preview_media_bust(char_name, filename))

			#% Unhover: hide only the preview rect, NOT the popup panel:
			btn.mouse_exited.connect(func():
				hide_media_preview_only())

			#% Select:
			btn.pressed.connect(func():
				file_popup.hide()
				line._apply_selected_vn_bust_file(filename))
			file_box.add_child(btn)

	else:
		var label := Label.new()
		label.text = "[No busts found]"
		file_box.add_child(label)

	#@ Show popup:
	var max_width := 0.0
	var max_height: = 8.0
	for c in file_box.get_children():
		if c is Control:
			max_width = max(max_width, c.get_combined_minimum_size().x)
			max_height += 31.0

	if max_height > 480:
		max_height = 480

	#% Apply width to popup (add a bit of padding):
	file_popup.size.x = int(max_width + 32)
	file_popup.size.y = int(max_height)

	var line_number = int(line.name.substr(4))
	if line_number < VISIBLE_LINES/2.0 :
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	else:
		file_popup.position = field.get_global_position() + Vector2(0, 0 - max_height)

	file_popup.popup()

#* Open a list of VN Bust files for the selected character:
func open_bg_file_menu(line: Node, field: LineEdit, layer_name: String) -> void:
	#@ Clear old items:
	for c in file_box.get_children():
		c.queue_free()

	await get_tree().process_frame

	#@ Rebuild the list:
	if candy_dc.resources.has("Backgrounds") and candy_dc.resources["Backgrounds"].has(layer_name):
		for filename in candy_dc.resources["Backgrounds"][layer_name].keys():
			#% Skip UID files and subfolders:
			if filename.ends_with(".uid") or filename.ends_with(".tscn") or filename is Dictionary:
				continue

			var btn := Button.new()
			btn.text = filename
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

			#% Hover: show preview image (keep panel open):
			btn.mouse_entered.connect(func():
				_preview_media_bg(layer_name, filename))

			#% Unhover: hide only the preview rect, NOT the popup panel:
			btn.mouse_exited.connect(func():
				hide_media_preview_only())

			#% Select:
			btn.pressed.connect(func():
				file_popup.hide()
				line._apply_selected_bg(filename))
			file_box.add_child(btn)

	else:
		var label := Label.new()
		label.text = "[No backgrounds found]"
		file_box.add_child(label)

	#@ Show popup:
	var max_width := 0.0
	var max_height: = 8.0
	for c in file_box.get_children():
		if c is Control:
			max_width = max(max_width, c.get_combined_minimum_size().x)
			max_height += 31.0

	if max_height > 480:
		max_height = 480

	#% Apply width to popup (add a bit of padding):
	file_popup.size.x = int(max_width + 32)
	file_popup.size.y = int(max_height)

	var line_number = int(line.name.substr(4))
	if line_number < VISIBLE_LINES/2.0 :
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	else:
		file_popup.position = field.get_global_position() + Vector2(0, 0 - max_height)

	file_popup.popup()


#* Preview an image file:
func _preview_media_image(path: String) -> void:
	if not FileAccess.file_exists(path):
		hide_media_preview_only()
		return
	var img := Image.new()
	if img.load(path) != OK:
		hide_media_preview_only()
		return
	var tex := ImageTexture.create_from_image(img)
	if tex == null:
		hide_media_preview_only()
		return
	media_image_preview.texture = tex
	media_image_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT

	#% Respect global max size settings:
	var w = tex.get_width()
	var h = tex.get_height()
	var max_w = candy_dc.image_preview_max_w
	var max_h = candy_dc.image_preview_max_h
	if max_w > 0 or max_h > 0:
		var ratio = float(w) / float(h)
		if max_w > 0 and w > max_w:
			w = max_w
			h = w / ratio
		if max_h > 0 and h > max_h:
			h = max_h
			w = h * ratio

	media_image_preview.custom_minimum_size = Vector2(w, h)

	portrait_popup.visible = true
	media_image_preview.visible = true


#* Preview an audio file:
func _preview_media_audio(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var stream := AudioStreamMP3.new()
	stream.data = file.get_buffer(file.get_length())
	media_audio_preview.stop()
	media_audio_preview.stream = stream
	media_audio_preview.play()


#*Preview a video file:
func _preview_media_video(path: String) -> void:
	if not FileAccess.file_exists(path):
		hide_media_preview_only()
		return

	var stream := VideoStreamTheora.new()
	stream.file = path

	media_video_preview.stop()
	media_video_preview.stream = stream
	media_video_preview.autoplay = false
	media_video_preview.visible = true
	media_video_preview.play()

	video_popup.visible = true
	media_video_preview.visible = true


#* Preview a background:
func _preview_media_bg(layer_name: String, filename: String) -> void:
	if not (candy_dc.resources.has("Backgrounds") and candy_dc.resources["Backgrounds"].has(layer_name)):
		hide_media_preview_only()
		return

	var dict = candy_dc.resources["Backgrounds"][layer_name]
	if not dict.has(filename):
		hide_media_preview_only()
		return

	var path: String = dict[filename]
	var img := Image.new()
	if img.load(path) != OK:
		hide_media_preview_only()
		return

	var tex := ImageTexture.create_from_image(img)
	if not (tex is Texture2D):
		hide_media_preview_only()
		return

	bust_preview.texture = tex
	bust_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT

	#% Respect global max size settings:
	var w = tex.get_width()
	var h = tex.get_height()
	var max_w = candy_dc.bg_preview_max_w
	var max_h = candy_dc.bg_preview_max_h
	if max_w > 0 or max_h > 0:
		var ratio = float(w) / float(h)
		if max_w > 0 and w > max_w:
			w = max_w
			h = w / ratio
		if max_h > 0 and h > max_h:
			h = max_h
			w = h * ratio

	bust_preview.custom_minimum_size = Vector2(w, h)

	#% Show panel + rect; panel tracks cursor in _process:
	portrait_popup.visible = true
	bust_preview.visible = true



#* Internal: preview a VN Bust:
func _preview_media_bust(char_name: String, filename: String) -> void:
	if not (candy_dc.resources.has("*Busts") and candy_dc.resources["*Busts"].has(char_name)):
		hide_media_preview_only()
		return

	var dict = candy_dc.resources["*Busts"][char_name]
	if not dict.has(filename):
		hide_media_preview_only()
		return

	var path: String = dict[filename]
	var img := Image.new()
	if img.load(path) != OK:
		hide_media_preview_only()
		return

	var tex := ImageTexture.create_from_image(img)
	if not (tex is Texture2D):
		hide_media_preview_only()
		return

	bust_preview.texture = tex
	bust_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT

	#% Respect global max size settings:
	var w = tex.get_width()
	var h = tex.get_height()
	var max_w = candy_dc.bust_preview_max_w
	var max_h = candy_dc.bust_preview_max_h
	if max_w > 0 or max_h > 0:
		var ratio = float(w) / float(h)
		if max_w > 0 and w > max_w:
			w = max_w
			h = w / ratio
		if max_h > 0 and h > max_h:
			h = max_h
			w = h * ratio

	bust_preview.custom_minimum_size = Vector2(w, h)

	#% Show panel + rect; panel tracks cursor in _process:
	portrait_popup.visible = true
	bust_preview.visible = true


func hide_media_preview_only() -> void:
	#% DO NOT close the preview popup, only its content:
	portrait_preview.visible = false
	media_image_preview.visible = false
	background_preview.visible = false
	portrait_preview.visible = false
	media_audio_preview.stop()
	media_video_preview.stop()
	media_video_preview.visible = false
	video_popup.visible = false

#* Open a list of Scenes:
func open_scene_menu(line: Node, field: LineEdit, type: String) -> void:
	#% Clear any existing items in the shared file list:
	for c in file_box.get_children():
		c.queue_free()

	await get_tree().process_frame

	#@ Match type:
	if type == "VN":
		#% Get the files dictionary from candy_dc.resources:
		if not candy_dc.resources.has("VN Scenes"):
			var label := Label.new()
			label.text = "[Not found]"
			file_box.add_child(label)
		else:
			var dict = candy_dc.resources["VN Scenes"]
			for filename in dict.keys():
				var btn := Button.new()
				btn.text = filename
				btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				btn.pressed.connect(func():
					file_popup.hide()
					line._apply_selected_vn_scene(filename)
					)
				file_box.add_child(btn)

	elif type == "BG":
		#% Get the files dictionary from candy_dc.resources:
		if not candy_dc.resources.has("BG Scenes"):
			var label := Label.new()
			label.text = "[Not found]"
			file_box.add_child(label)
		else:
			var dict = candy_dc.resources["BG Scenes"]
			for filename in dict.keys():
				var btn := Button.new()
				btn.text = filename
				btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				btn.pressed.connect(func():
					file_popup.hide()
					line._apply_selected_vn_scene(filename)
					)
				file_box.add_child(btn)

	elif type == "Input_UI":
		#% Get the files dictionary from candy_dc.resources:
		if not candy_dc.resources.has("Input Menus"):
			var label := Label.new()
			label.text = "[Not found]"
			file_box.add_child(label)
		else:
			var dict = candy_dc.resources["Input Menus"]
			for filename in dict.keys():
				var btn := Button.new()
				btn.text = filename
				btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				btn.pressed.connect(func():
					file_popup.hide()
					line._apply_selected_input_scene(filename)
					)
				file_box.add_child(btn)

	elif type == "General_ChoiceMenuSc":
		#% Get the files dictionary from candy_dc.resources:
		if not candy_dc.resources.has("Choice Menus"):
			var label := Label.new()
			label.text = "[Not found]"
			file_box.add_child(label)
		else:
			var dict = candy_dc.resources["Choice Menus"]
			for filename in dict.keys():
				var btn := Button.new()
				btn.text = filename
				btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				btn.pressed.connect(func():
					file_popup.hide()
					$"ChoiceListEditor"._apply_selected_general_scene(field, filename)
					)
				file_box.add_child(btn)

	elif type == "General_ChoiceCategoriesSc":
		#% Get the files dictionary from candy_dc.resources:
		if not candy_dc.resources.has("Choice Categories"):
			var label := Label.new()
			label.text = "[Not found]"
			file_box.add_child(label)
		else:
			var dict = candy_dc.resources["Choice Categories"]
			for filename in dict.keys():
				var btn := Button.new()
				btn.text = filename
				btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				btn.pressed.connect(func():
					file_popup.hide()
					$"ChoiceListEditor"._apply_selected_general_cat_sc_scene(field, filename)
					)
				file_box.add_child(btn)

	elif type == "General_ChoiceButtonsSc":
		#% Get the files dictionary from candy_dc.resources:
		if not candy_dc.resources.has("Choice Buttons"):
			var label := Label.new()
			label.text = "[Not found]"
			file_box.add_child(label)
		else:
			var dict = candy_dc.resources["Choice Buttons"]
			for filename in dict.keys():
				var btn := Button.new()
				btn.text = filename
				btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				btn.pressed.connect(func():
					file_popup.hide()
					$"ChoiceListEditor"._apply_selected_general_button_sc_scene(field, filename)
					)
				file_box.add_child(btn)

	elif type == "Category_ChoiceCategorySc":
		#% Get the files dictionary from candy_dc.resources:
		if not candy_dc.resources.has("Choice Categories"):
			var label := Label.new()
			label.text = "[Not found]"
			file_box.add_child(label)
		else:
			var dict = candy_dc.resources["Choice Categories"]
			for filename in dict.keys():
				var btn := Button.new()
				btn.text = filename
				btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				btn.pressed.connect(func():
					file_popup.hide()
					$"ChoiceListEditor"._apply_category_sc_select_scene(field, filename)
					)
				file_box.add_child(btn)

	elif type == "Category_ChoiceButtonsSc":
		#% Get the files dictionary from candy_dc.resources:
		if not candy_dc.resources.has("Choice Buttons"):
			var label := Label.new()
			label.text = "[Not found]"
			file_box.add_child(label)
		else:
			var dict = candy_dc.resources["Choice Buttons"]
			for filename in dict.keys():
				var btn := Button.new()
				btn.text = filename
				btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				btn.pressed.connect(func():
					file_popup.hide()
					$"ChoiceListEditor"._apply_category_button_sc_select_scene(field, filename)
					)
				file_box.add_child(btn)

	elif type == "Button_ChoiceButtonsSc":
		#% Get the files dictionary from candy_dc.resources:
		if not candy_dc.resources.has("Choice Buttons"):
			var label := Label.new()
			label.text = "[Not found]"
			file_box.add_child(label)
		else:
			var dict = candy_dc.resources["Choice Buttons"]
			for filename in dict.keys():
				var btn := Button.new()
				btn.text = filename
				btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				btn.pressed.connect(func():
					file_popup.hide()
					$"ChoiceListEditor"._apply_button_sc_select_scene(field, filename)
					)
				file_box.add_child(btn)

	#@ Display popup:
	var max_width := 0.0
	var max_height: = 8.0
	for c in file_box.get_children():
		if c is Control:
			max_width = max(max_width, c.get_combined_minimum_size().x)
			max_height += 31.0

	if max_height > 480:
		max_height = 480

	#% Apply width to popup (add a bit of padding):
	file_popup.size.x = int(max_width + 32)
	file_popup.size.y = int(max_height)

	#% Function called from a line panel:
	if line != null:
		var line_number = int(line.name.substr(4))
		#% Line panel in top half of the screen:
		if line_number < VISIBLE_LINES/2.0 :
			file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
		#% Line panel in bottom half of the screen:
		else:
			file_popup.position = field.get_global_position() + Vector2(0, 0 - max_height)

	#% Function called from an editor:
	else:
		file_popup.position = field.get_global_position() + Vector2(0, 0 + max_height)

	file_popup.popup()


func open_vn_bust_node_menu(line: Node, field: LineEdit):
	#% Rebuild the list
	for c in file_box.get_children():
		c.queue_free()

	await get_tree().process_frame

	for bust_node in candy_dc.bust_list:
		var btn := Button.new()
		btn.text = bust_node
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		#% Select:
		btn.pressed.connect(func():
			file_popup.hide()				#/ List closes
			hide_portrait_panel()
			line._apply_selected_vn_bust_node(bust_node))
		file_box.add_child(btn)

	#% Show popup:
	var max_width := 0.0
	var max_height: = 8.0
	for c in file_box.get_children():
		if c is Control:
			max_width = max(max_width, c.get_combined_minimum_size().x)
			max_height += 31.0

	if max_height > 480:
		max_height = 480

	#% Apply width to popup (add a bit of padding):
	file_popup.size.x = int(max_width + 32)
	file_popup.size.y = int(max_height)

	var line_number = int(line.name.substr(4))
	if line_number < VISIBLE_LINES/2.0 :
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	else:
		file_popup.position = field.get_global_position() + Vector2(0, 0 - max_height)

	file_popup.popup()


func open_vn_layer_node_menu(line: Node, field: LineEdit):
	#% Rebuild the list:
	for c in file_box.get_children():
		c.queue_free()

	await get_tree().process_frame

	#% Get the folders dictionary from candy_dc.resources:
	if not candy_dc.resources.has("Backgrounds"):
		var label := Label.new()
		label.text = "[Not found]"
		file_box.add_child(label)
	else:
		var bg_dict = candy_dc.resources["Backgrounds"]

		#% Create a button for each folder under Backgrounds:
		for folder_name in bg_dict.keys():
			var btn := Button.new()
			btn.text = folder_name
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

			#% When pressed, handle folder selection:
			btn.pressed.connect(func():
				file_popup.hide()
				line._apply_selected_vn_layer(folder_name))

			file_box.add_child(btn)

	#% Show popup:
	var max_width := 0.0
	var max_height: = 8.0
	for c in file_box.get_children():
		if c is Control:
			max_width = max(max_width, c.get_combined_minimum_size().x)
			max_height += 31.0

	if max_height > 480:
		max_height = 480

	#% Apply width to popup (add a bit of padding):
	file_popup.size.x = int(max_width + 32)
	file_popup.size.y = int(max_height)

	var line_number = int(line.name.substr(4))
	if line_number < VISIBLE_LINES/2.0 :
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	else:
		file_popup.position = field.get_global_position() + Vector2(0, 0 - max_height)

	file_popup.popup()


func open_vn_actors_menu(line: Node, field: LineEdit):
	#% Rebuild the list:
	for c in file_box.get_children():
		c.queue_free()

	await get_tree().process_frame

	if field.text.ends_with(candy_dc.role_symbol):
		for role in candy_dc.role_list:
			var btn := Button.new()
			btn.text = role
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

			#% Select:
			btn.pressed.connect(func():
				file_popup.hide()				#/ List closes
				hide_portrait_panel()
				line._add_selected_actor(role))
			file_box.add_child(btn)

	else:
		for actor in candy_dc.actor_list:
			var btn := Button.new()
			btn.text = actor
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

			#% Select:
			btn.pressed.connect(func():
				file_popup.hide()				#/ List closes
				hide_portrait_panel()
				line._add_selected_actor(actor))
			file_box.add_child(btn)

	#% Show popup:
	var max_width := 0.0
	var max_height: = 8.0
	for c in file_box.get_children():
		if c is Control:
			max_width = max(max_width, c.get_combined_minimum_size().x)
			max_height += 31.0

	if max_height > 480:
		max_height = 480

	#% Apply width to popup (add a bit of padding):
	file_popup.size.x = int(max_width + 32)
	file_popup.size.y = int(max_height)

	var line_number = int(line.name.substr(4))
	if line_number < VISIBLE_LINES/2.0 :
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	else:
		file_popup.position = field.get_global_position() + Vector2(0, 0 - max_height)

	file_popup.popup()


#* Open a list of Animation Library files (for VN or BG commands):
func open_vn_library_menu(line: Node, field: LineEdit, type: String):
	#% Clear any existing items in the shared file list:
	for c in file_box.get_children():
		c.queue_free()

	await get_tree().process_frame

	var dict := {}

	if type == "VN":
		#@ Step 1: Get the character name (Reference):
		var char_name := ""
		if line.line_data.has("Reference"):
			char_name = str(line.line_data["Reference"]).strip_edges()
		else:
			var ref_field := line.get_node_or_null("HBox/VN/Reference/Ref")
			if ref_field:
				char_name = str(ref_field.text).strip_edges()

		#% Stop if invalid:
		if char_name == "" or not candy_dc.resources.has("*Busts") or not candy_dc.resources["*Busts"].has(char_name):
			var label := Label.new()
			label.text = "[Not found]"
			file_box.add_child(label)
			#% Display popup immediately:
			file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
			file_popup.popup()
			return

		#@ Step 2: Access the "Animation Libraries" subfolder inside the Bust folder:
		var bust_dict = candy_dc.resources["*Busts"][char_name]
		if not bust_dict.has("Animation Libraries"):
			var label := Label.new()
			label.text = "[No Animation Libraries]"
			file_box.add_child(label)
			file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
			file_popup.popup()
			return

		dict = bust_dict["Animation Libraries"]

	elif type == "BG":
		#@ Step 1: Locate Animation Libraries folder in Backgrounds path:
		if not candy_dc.resources.has("Backgrounds"):
			var label := Label.new()
			label.text = "[Not found]"
			file_box.add_child(label)
			file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
			file_popup.popup()
			return

		var bg_dict = candy_dc.resources["Backgrounds"]
		if not bg_dict.has("Animation Libraries"):
			var label := Label.new()
			label.text = "[No Animation Libraries]"
			file_box.add_child(label)
			file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
			file_popup.popup()
			return

		dict = bg_dict["Animation Libraries"]

	else:
		var label := Label.new()
		label.text = "[Invalid type]"
		file_box.add_child(label)
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
		file_popup.popup()
		return


	#@ Step 3: Populate file buttons:
	for filename in dict.keys():
		if filename.begins_with(".") or filename.ends_with(".uid"):
			continue
		var btn := Button.new()
		btn.text = filename
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(func():
			file_popup.hide()
			line._apply_selected_media(filename))
		file_box.add_child(btn)

	#@ Step 4: Display popup:
	var max_width := 0.0
	var max_height := 8.0
	for c in file_box.get_children():
		if c is Control:
			max_width = max(max_width, c.get_combined_minimum_size().x)
			max_height += 31.0

	if max_height > 480:
		max_height = 480

	file_popup.size.x = int(max_width + 32)
	file_popup.size.y = int(max_height)

	var line_number = int(line.name.substr(4))
	if line_number < VISIBLE_LINES / 2.0:
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	else:
		file_popup.position = field.get_global_position() + Vector2(0, -max_height)

	file_popup.popup()


func open_vn_effects_menu(line: Node, field: LineEdit):
	#% Rebuild the list:
	for c in file_box.get_children():
		c.queue_free()

	await get_tree().process_frame

	for effect in candy_dc.effect_list:
		var btn := Button.new()
		btn.text = effect
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		#% Select:
		btn.pressed.connect(func():
			file_popup.hide()				#/ List closes
			hide_portrait_panel()
			line._apply_selected_vn_effect(effect))
		file_box.add_child(btn)

	#% Show popup:
	var max_width := 0.0
	var max_height: = 8.0
	for c in file_box.get_children():
		if c is Control:
			max_width = max(max_width, c.get_combined_minimum_size().x)
			max_height += 31.0

	if max_height > 480:
		max_height = 480

	#% Apply width to popup (add a bit of padding):
	file_popup.size.x = int(max_width + 32)
	file_popup.size.y = int(max_height)

	var line_number = int(line.name.substr(4))
	if line_number < VISIBLE_LINES/2.0 :
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	else:
		file_popup.position = field.get_global_position() + Vector2(0, 0 - max_height)

	file_popup.popup()
#endregion


#& CHOICES:
#region
#* Open a list of choice menu scenes:
func open_choice_menus_menu(menu: String, field) -> void:
	#% Rebuild the list:
	for c in file_box.get_children():
		c.queue_free()

	await get_tree().process_frame

	if candy_dc.resources.has("Choice Menus"):
		for scene in candy_dc.resources["Choice Menus"]:
			var btn := Button.new()
			btn.text = scene
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

			#% Select:
			btn.pressed.connect(func():
				file_popup.hide()				#/ List closes
				hide_portrait_panel()
				choice_or_alter(menu, field, btn.text))
			file_box.add_child(btn)
	else:
		var label := Label.new()
		label.text = "[No choice menus found]"
		file_box.add_child(label)

	#% Show popup:
	var max_width := 0.0
	var max_height: = 8.0
	for c in file_box.get_children():
		if c is Control:
			max_width = max(max_width, c.get_combined_minimum_size().x)
			max_height += 31.0

	if max_height > 480:
		max_height = 480

	#% Apply width to popup (add a bit of padding):
	file_popup.size.x = int(max_width + 32)
	file_popup.size.y = int(max_height)

	file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	file_popup.popup()


#* Open a list of choice buttons scenes:
func open_choice_buttons_menu(menu: String, field) -> void:
	#% Rebuild the list:
	for c in file_box.get_children():
		c.queue_free()

	await get_tree().process_frame

	if candy_dc.resources.has("Choice Buttons"):
		for scene in candy_dc.resources["Choice Buttons"]:
			var btn := Button.new()
			btn.text = scene
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

			#% Select:
			btn.pressed.connect(func():
				file_popup.hide()				#/ List closes
				hide_portrait_panel()
				choice_or_alter(menu, field, btn.text))
			file_box.add_child(btn)
	else:
		var label := Label.new()
		label.text = "[No choice buttons found]"
		file_box.add_child(label)

	#% Show popup:
	var max_width := 0.0
	var max_height: = 8.0
	for c in file_box.get_children():
		if c is Control:
			max_width = max(max_width, c.get_combined_minimum_size().x)
			max_height += 31.0

	if max_height > 480:
		max_height = 480

	#% Apply width to popup (add a bit of padding):
	file_popup.size.x = int(max_width + 32)
	file_popup.size.y = int(max_height)

	file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	file_popup.popup()


func choice_or_alter(menu, field, scene):
	if menu == "Choice":
		$"ChoiceEditor".apply_menu_or_button_scene(field, scene)

	if menu == "Alter":
		$"AlterEditor".apply_menu_or_button_scene(field, scene)


#endregion


#?######################################################################################
#& SCAN PROJECT FILES:
#?####################
#region
#* Build a dictionary of all files in a directory:
#% If nested = true, include subfolders as sub-dictionaries (for *Portraits, *Voices, etc.):
func scan_dir(path: String, nested: bool = false) -> Dictionary:
	var dir := DirAccess.open(path)
	if dir == null:
		return {}

	var result := {}

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				var subpath = path.path_join(file_name)
				#% Always recurse when nested = true (for multi-level folders like Voices/Speaker/Conversation/Block):
				result[file_name] = scan_dir(subpath, nested)
		else:
			if not file_name.begins_with(".") and not file_name.ends_with(".import") and not file_name.ends_with(".uid"):
				result[file_name] = path.path_join(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	return result


#* Compute folder signature: file count + latest modified time:
func _get_folder_signature(path: String) -> String:
	var dir := DirAccess.open(path)
	if dir == null:
		return ""

	var count := 0
	var latest_mtime := 0

	dir.list_dir_begin()
	var f = dir.get_next()
	while f != "":
		if not dir.current_is_dir() and not f.begins_with(".") and not f.ends_with(".import"):
			var fp = path.path_join(f)
			var mtime = FileAccess.get_modified_time(fp)
			latest_mtime = max(latest_mtime, mtime)
			count += 1
		f = dir.get_next()
	dir.list_dir_end()

	return str(count) + "_" + str(latest_mtime)


#* Initial scan of all resource paths:
func _scan_all_resources() -> void:
	candy_dc.resources.clear()
	for key in candy_dc.resource_paths.keys():
		var path = candy_dc.resource_paths[key]
		var nested = key.begins_with(candy_dc.role_symbol)
		var clean_key = key.trim_prefix(candy_dc.role_symbol)
		candy_dc.resources[clean_key] = scan_dir(path, nested)
		candy_dc.folder_mtimes[key] = _get_folder_signature(path)


#* Periodically check for folder changes and rescan if modified:
func _check_resource_updates() -> void:
	for key in candy_dc.resource_paths.keys():
		var path = candy_dc.resource_paths[key]
		var sig = _get_folder_signature(path)
		if not candy_dc.folder_mtimes.has(key) or candy_dc.folder_mtimes[key] != sig:
			print("Rescanning:", key)
			var nested = key.begins_with(candy_dc.role_symbol)
			var clean_key = key.trim_prefix(candy_dc.role_symbol)
			candy_dc.resources[clean_key] = scan_dir(path, nested)
			candy_dc.folder_mtimes[key] = sig


#* Manual refresh button:
func _on_refresh_resources_pressed() -> void:
	_check_resource_updates()
	_build_command_presets()
#endregion


#?######################################################################################
#& MENUS:
#?#######
#region
func _on_main_menu_pressed() -> void:
	$"MainMenu".visible = true
	candy_dc.editor_state = "main_menu"


#& RENAME MENUS
#region
#* Cancel rename Conversation:
func _on_name_convo_cancel_pressed() -> void:
	$"NameConvo/PanelC/VBox/LineEdit".text = ""
	$"NameConvo/PanelC/VBox/Error".text = ""
	$"NameConvo".visible = false


func _on_name_convo_enter_pressed() -> void:
	var new_name = $"NameConvo/PanelC/VBox/LineEdit".text.strip_edges()

	var regex = RegEx.new()
	regex.compile('(?<!\\\\)"')
	new_name = regex.sub(new_name, "'", true)

	if new_name in candy_dc.conversations:
		$"NameConvo/PanelC/VBox/Error".text = "A Conversation with that name already exists!"
		return
	elif new_name == "new_conversation":
		$"NameConvo/PanelC/VBox/Error".text = "This name can not be used. Please choose another."
		return
	elif new_name == "":
		$"NameConvo/PanelC/VBox/Error".text = "Conversation names must have at least one character."
		return

	#% Move data from temp to renamed key:
	candy_dc.conversations[new_name] = candy_dc.conversations[candy_dc.current_conversation]
	candy_dc.conversations.erase(candy_dc.current_conversation)
	#% Update browsing-history references:
	_rename_history_conversation(candy_dc.current_conversation, new_name)
	candy_dc.current_conversation = new_name

	#% Clear popup:
	$"NameConvo/PanelC/VBox/LineEdit".text = ""
	$"NameConvo/PanelC/VBox/Error".text = ""
	$"NameConvo".visible = false
	$"NameConvo/PanelC/VBox/HBox/Cancel".visible = true

	#% Refresh conversation dropdown:
	var button := $"VBox/TopBar/HBox/Conversations/Conversations"
	button.clear()
	var idx := 0
	for key in candy_dc.conversations.keys():
		button.add_item(key)
		if key == candy_dc.current_conversation:
			button.select(idx)
		idx += 1

	sort_conversations_and_blocks()

	record_browsing_point()
	save_undo_step()


func _on_name_convo_text_submitted(raw_name):
	var regex = RegEx.new()
	regex.compile('(?<!\\\\)"')
	raw_name = regex.sub(raw_name, "'", true)

	var new_name = raw_name.strip_edges()
	if new_name in candy_dc.conversations:
		$"NameConvo/PanelC/VBox/Error".text = "A Conversation with that name already exists!"
		return
	elif new_name == "new_conversation":
		$"NameConvo/PanelC/VBox/Error".text = "This name can not be used. Please choose another."
		return
	elif new_name == "":
		$"NameConvo/PanelC/VBox/Error".text = "Conversation names must have at least one character."
		return

	#% Move data from temp to renamed key:
	candy_dc.conversations[new_name] = candy_dc.conversations[candy_dc.current_conversation]
	candy_dc.conversations.erase(candy_dc.current_conversation)
	#% Update browsing-history references:
	_rename_history_conversation(candy_dc.current_conversation, new_name)
	candy_dc.current_conversation = new_name

	#% Clear popup:
	$"NameConvo/PanelC/VBox/LineEdit".text = ""
	$"NameConvo/PanelC/VBox/Error".text = ""
	$"NameConvo".visible = false
	$"NameConvo/PanelC/VBox/HBox/Cancel".visible = true

	#% Refresh conversation dropdown:
	var button := $"VBox/TopBar/HBox/Conversations/Conversations"
	button.clear()
	var idx := 0
	for key in candy_dc.conversations.keys():
		button.add_item(key)
		if key == candy_dc.current_conversation:
			button.select(idx)
		idx += 1

	sort_conversations_and_blocks()

	record_browsing_point()
	save_undo_step()


#* Cancel rename Block:
func _on_rename_block_cancel_pressed() -> void:
	candy_dc.renaming_tab = -1
	$"RenameBlock/PanelC/VBox/LineEdit".text = ""
	$"RenameBlock/PanelC/VBox/Error".text = ""
	$"RenameBlock".visible = false


#* Confirm rename Block:
func _on_rename_block_enter_pressed() -> void:
	var new_name = $"RenameBlock/PanelC/VBox/LineEdit".text.strip_edges()
	var conv = candy_dc.conversations[candy_dc.current_conversation]

	var regex = RegEx.new()
	regex.compile('(?<!\\\\)"')
	new_name = regex.sub(new_name, "'", true)

	if new_name in conv:
		$"RenameBlock/PanelC/VBox/Error".text = "A Block with that name already exists!"
		return
	elif new_name.begins_with("NewBlock"):
		$"RenameBlock/PanelC/VBox/Error".text = "A Block name can't start with 'NewBlock'."
		return
	elif new_name == "":
		$"RenameBlock/PanelC/VBox/Error".text = "Block names must have at least one character."
		return

	#% Move block data to renamed key:
	conv[new_name] = conv[candy_dc.current_block]
	conv.erase(candy_dc.current_block)
	#% Update browsing-history references:
	_rename_history_block(candy_dc.current_conversation, candy_dc.current_block, new_name)
	candy_dc.current_block = new_name

	#% Hide rename UI:
	$"RenameBlock/PanelC/VBox/LineEdit".text = ""
	$"RenameBlock/PanelC/VBox/Error".text = ""
	$"RenameBlock".visible = false
	$"RenameBlock/PanelC/VBox/HBox/Cancel".visible = true

	#% Update block selector dropdown:
	var block_selector := $"VBox/TopBar/HBox/Blocks/Blocks"
	block_selector.clear()
	for block_name in conv.keys():
		block_selector.add_item(block_name)
	if block_selector.item_count > 0:
		block_selector.select(block_selector.item_count - 1)

	sort_conversations_and_blocks()

	record_browsing_point()
	save_undo_step()


func _on_rename_block_text_submitted(raw_name):
	var regex = RegEx.new()
	regex.compile('(?<!\\\\)"')
	raw_name = regex.sub(raw_name, "'", true)

	var new_name = raw_name.strip_edges()
	var conv = candy_dc.conversations[candy_dc.current_conversation]

	if new_name in conv:
		$"RenameBlock/PanelC/VBox/Error".text = "A Block with that name already exists!"
		return
	elif new_name.begins_with("NewBlock"):
		$"RenameBlock/PanelC/VBox/Error".text = "A Block name can't start with 'NewBlock'."
		return
	elif new_name == "":
		$"RenameBlock/PanelC/VBox/Error".text = "Block names must have at least one character."
		return

	#% Move block data to renamed key:
	conv[new_name] = conv[candy_dc.current_block]
	conv.erase(candy_dc.current_block)
	#% Update browsing-history references:
	_rename_history_block(candy_dc.current_conversation, candy_dc.current_block, new_name)
	candy_dc.current_block = new_name

	#@ Sort conversations alphabetically:
	candy_dc.sort_conversations()
	candy_dc.sort_blocks(candy_dc.current_conversation)

	#% Hide rename UI:
	$"RenameBlock/PanelC/VBox/LineEdit".text = ""
	$"RenameBlock/PanelC/VBox/Error".text = ""
	$"RenameBlock".visible = false
	$"RenameBlock/PanelC/VBox/HBox/Cancel".visible = true

	#% Update block selector dropdown:
	var block_selector := $"VBox/TopBar/HBox/Blocks/Blocks"
	block_selector.clear()
	for block_name in conv.keys():
		block_selector.add_item(block_name)
	if block_selector.item_count > 0:
		block_selector.select(block_selector.item_count - 1)

	sort_conversations_and_blocks()

	record_browsing_point()
	save_undo_step()

#* Rebuild all conversations and their blocks alphabetically:
func sort_conversations_and_blocks() -> void:
	#% Sort blocks inside each conversation:
	for conv_name in candy_dc.conversations.keys():
		var conv = candy_dc.conversations[conv_name]
		if conv is Dictionary:
			var block_keys = conv.keys()
			block_keys.sort()
			var sorted_blocks := {}
			for b in block_keys:
				sorted_blocks[b] = conv[b]
			candy_dc.conversations[conv_name] = sorted_blocks

	#% Sort the conversation dictionary itself:
	var convo_keys = candy_dc.conversations.keys()
	convo_keys.sort()
	var sorted_convos := {}
	for c in convo_keys:
		sorted_convos[c] = candy_dc.conversations[c]
	candy_dc.conversations = sorted_convos


#* Update history entries when a conversation is renamed:
func _rename_history_conversation(old_name: String, new_name: String) -> void:
	for e in candy_dc.browsing_history:
		if e["conversation"] == old_name:
			e["conversation"] = new_name


#* Update history entries when a block is renamed:
func _rename_history_block(conv_name: String, old_block: String, new_block: String) -> void:
	for e in candy_dc.browsing_history:
		if e["conversation"] == conv_name and e["block"] == old_block:
			e["block"] = new_block


#endregion

#& DELETE CONFIRM
#region
#* Cancel deletion:
func _on_cancel_delete_pressed() -> void:
	$"ConfirmDeleteConv/Name".text = ""
	$"ConfirmDeleteConv".visible = false


#* Confirm deletion:
func _on_confirm_delete_pressed() -> void:
	match candy_dc.rc_target:
		"conversation":
			_delete_conversation()
		"block":
			_delete_block()

		"line":
			_delete_lines()

	$"ConfirmDeleteConv".visible = false


#* Delete Conversations:
func _delete_conversation() -> void:
	if candy_dc.current_conversation == "":
		return

	var convo_name = candy_dc.current_conversation
	var convo_names = candy_dc.conversations.keys()
	var current_index = convo_names.find(convo_name)

	#% Remove the conversation itself:
	candy_dc.conversations.erase(convo_name)

	#% Purge browsing history entries that referenced it:
	_purge_history_of_conversation(convo_name)

	#% Choose a new current conversation if any remain:
	if candy_dc.conversations.size() > 0:
		var new_index = clamp(current_index - 1, 0, candy_dc.conversations.size() - 1)
		candy_dc.current_conversation = candy_dc.conversations.keys()[new_index]
	else:
		candy_dc.current_conversation = ""

	#% Rebuild dropdown menu:
	var button := $"VBox/TopBar/HBox/Conversations/Conversations"
	button.clear()
	var idx := 0
	for key in candy_dc.conversations.keys():
		button.add_item(key)
		if key == candy_dc.current_conversation:
			button.select(idx)
		idx += 1

	if candy_dc.current_conversation == "":
		button.text = ""
		button.select(-1)

	save_undo_step()
	_load_active_block()


#* Delete Blocks:
func _delete_block() -> void:
	if candy_dc.current_block == "" or candy_dc.current_conversation == "":
		return

	var conv_name = candy_dc.current_conversation
	var block_name = candy_dc.current_block
	var conv = candy_dc.conversations[conv_name]

	#@ Remove the block itself:
	conv.erase(block_name)

	#@ Purge browsing history entries that referenced it:
	_purge_history_of_block(conv_name, block_name)

	#% Refresh block dropdown:
	var block_btn := $"VBox/TopBar/HBox/Blocks/Blocks"
	block_btn.clear()
	var idx := 0
	for key in conv.keys():
		block_btn.add_item(key)
		if idx == 0:
			candy_dc.current_block = key
		idx += 1

	if conv.size() == 0:
		candy_dc.current_block = ""
		block_btn.text = ""
		block_btn.select(-1)

	await get_tree().process_frame
	save_undo_step()
	_load_active_block()


#* Remove all history entries that reference a deleted conversation:
func _purge_history_of_conversation(conv_name: String) -> void:
	var new_hist := []
	for e in candy_dc.browsing_history:
		if e["conversation"] != conv_name:
			new_hist.append(e)
	candy_dc.browsing_history = new_hist
	candy_dc.browsing_index = clamp(candy_dc.browsing_index, 0, candy_dc.browsing_history.size() - 1)


#* Remove all history entries that reference a deleted block of a conversation:
func _purge_history_of_block(conv_name: String, block_name: String) -> void:
	var new_hist := []
	for e in candy_dc.browsing_history:
		if not (e["conversation"] == conv_name and e["block"] == block_name):
			new_hist.append(e)
	candy_dc.browsing_history = new_hist
	candy_dc.browsing_index = clamp(candy_dc.browsing_index, 0, candy_dc.browsing_history.size() - 1)


#* Delete selected lines:
func _delete_lines() -> void:
	#% Safety: ensure valid context:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return

	var idx = candy_dc.line_delete_index
	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var text_array: Array = block["Text"]

	#% Determine which lines to delete:
	var to_delete: Array = []
	if candy_dc.selected_lines.size() > 0:
		candy_dc.selected_lines.sort()
		to_delete = candy_dc.selected_lines.duplicate()
	else:
		to_delete = [idx]

	#% Remove lines in reverse order (so indices remain valid):
	for i in range(to_delete.size() - 1, -1, -1):
		var remove_idx = to_delete[i]
		if remove_idx >= 0 and remove_idx < text_array.size():
			text_array.remove_at(remove_idx)

	#% Save updated block:
	block["Text"] = text_array
	candy_dc.conversations[candy_dc.current_conversation][candy_dc.current_block] = block


	#% Clear selection & reset move state:
	_clear_selection()
	candy_dc.alt_click_line_index = -1
	candy_dc.alt_click_move_below = false

	#% Reset selection state:
	candy_dc.selected_lines.clear()
	candy_dc.last_clicked_line = -1

	save_undo_step()

	#% Refresh the visible pool:
	_load_active_block()

#endregion
#endregion


#?######################################################################################
#& CONDITION EDITOR:
#?##################
#region



#* Update condition in both dictionary and visible line as user types:
func _on_condition_editor_text_changed() -> void:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var text_array: Array = block["Text"]

	if candy_dc.condition_line_index < 0 or candy_dc.condition_line_index >= text_array.size():
		return

	var line_data = text_array[candy_dc.condition_line_index]

	#% Re-save updated dictionary back to globals:
	text_array[candy_dc.condition_line_index] = line_data
	block["Text"] = text_array
	candy_dc.conversations[candy_dc.current_conversation][candy_dc.current_block] = block




#* Update data in both dictionary and visible line as user types:
func _on_data_editor_text_changed() -> void:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var text_array: Array = block["Text"]

	if candy_dc.condition_line_index < 0 or candy_dc.condition_line_index >= text_array.size():
		return

	var line_data = text_array[candy_dc.condition_line_index]

	#% Re-save updated dictionary back to globals:
	text_array[candy_dc.condition_line_index] = line_data
	block["Text"] = text_array
	candy_dc.conversations[candy_dc.current_conversation][candy_dc.current_block] = block

#endregion


#?######################################################################################
#& INSERT LINES:
#?##############
#region
#* Add a new line to the current block based on the given template:
func _add_line(template_name: String) -> void:
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return

	if not candy_dc.command_templates.has(template_name):
		push_warning("Unknown command template: " + template_name)
		return

	#@ Duplicate template and record key order for export:
	var payload: Dictionary = candy_dc.command_templates[template_name].duplicate(true)
	if not payload.has("__order__"):
		payload["__order__"] = payload.keys()	#/ Preserve field order for exporter

	#@ If this is a Spoken Line, auto-add variants with Auto = true:
	if template_name == "Spoken Line":
		if not payload.has("Variants") or typeof(payload["Variants"]) != TYPE_ARRAY:
			payload["Variants"] = []

		var existing := {}
		for entry in payload["Variants"]:
			for k in entry.keys():
				existing[k] = true

		for vname in candy_dc.variants_dict.keys():
			var vdata = candy_dc.variants_dict[vname]
			if bool(vdata.get("Auto", false)) == true:
				if not existing.has(vname):
					var new_entry := {
						vname: {
							"Text": "",
							"Weight": "",
							"Enabled": true,
							"Hide": false,
							"Direction": str(vdata.get("Direction", "ltr")),
						}
					}
					payload["Variants"].append(new_entry)

	var wrapped_line: Dictionary = {}
	wrapped_line[template_name] = payload

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var text_array: Array = block["Text"]

	#@ Insert before or after selected lines depending on CTRL:
	if candy_dc.selected_lines.size() > 0:
		var sorted_selection = candy_dc.selected_lines.duplicate()
		sorted_selection.sort()

		var offset := 0
		for idx in sorted_selection:
			var insert_index := 0
			if Input.is_key_pressed(KEY_CTRL):
				#% CTRL → insert before selected line:
				insert_index = clamp(idx + offset, 0, text_array.size())
			else:
				#% no modifier → insert after selected line:
				insert_index = clamp(idx + 1 + offset, 0, text_array.size())

			text_array.insert(insert_index, wrapped_line.duplicate(true))
			offset += 1
	else:
		#% No selection → append at end (or insert at start if CTRL):
		if Input.is_key_pressed(KEY_CTRL):
			text_array.insert(0, wrapped_line.duplicate(true))
		else:
			text_array.append(wrapped_line.duplicate(true))

	block["Text"] = text_array
	lines_data = text_array

	await _apply_scroll_limits()

	var total := text_array.size()
	if total > VISIBLE_LINES:
		var target_scroll := 0
		if candy_dc.selected_lines.size() > 0:
			target_scroll = candy_dc.selected_lines[0] - int(VISIBLE_LINES / 2.0)
		else:
			target_scroll = total - VISIBLE_LINES
		target_scroll = clamp(target_scroll, 0, total - VISIBLE_LINES)
		scroll_bar.value = target_scroll

	save_undo_step()
	_clear_selection()
	_update_visible_lines()


#* Handles all "New Line" button presses automatically:
func _on_new_line_pressed(button: Button) -> void:
	var btn_name = button.name
	var template_name = "§" + btn_name if btn_name != "Spoken" else "Spoken Line"
	print(str("Added Line: " + template_name))
	_add_line(template_name)


#* Open a list of Conversations for If/Elif/Else/Go/Bridge commands:
func open_conversation_menu(field: LineEdit) -> void:
	#% Clear old buttons:
	for c in file_box.get_children():
		c.queue_free()

	var button_count = 0
	#% Create one button per conversation:
	for conv_name in candy_dc.conversations.keys():
		if conv_name == "CUSTOM_PRESETS":
			continue
		var btn := Button.new()
		btn.text = conv_name
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		#% Selection:
		btn.pressed.connect(func():
			file_popup.hide()
			field.text = conv_name)

		file_box.add_child(btn)
		button_count += 1

	#% Position & show list:
	file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	file_popup.size.x = int(field.size.x)
	file_popup.size.y = 8 + button_count * 31
	file_popup.popup()


#* Open a list of Blocks for If/Elif/Else/Go/Bridge commands:
func open_block_menu(o_convo_field, field: LineEdit) -> void:
	#% Clear old buttons
	for c in file_box.get_children():
		c.queue_free()

	#% Determine which conversation to use:
	var convo_field: LineEdit = o_convo_field
	var convo_name := convo_field.text.strip_edges()
	var convo_to_use := ""

	if convo_name == "":
		convo_to_use = candy_dc.current_conversation
	elif candy_dc.conversations.has(convo_name):
		convo_to_use = convo_name
	else:
		#% Invalid name or missing conversation — show a warning:
		var label := Label.new()
		label.text = "[Not found]"
		file_box.add_child(label)
		file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
		file_popup.size.x = int(field.size.x)
		file_popup.size.y = 39
		file_popup.popup()
		return

	#% Populate blocks for the chosen conversation:
	var button_count = 0
	var conv = candy_dc.conversations[convo_to_use]
	for block_name in conv.keys():
		var btn := Button.new()
		btn.text = block_name
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		btn.pressed.connect(func():
			file_popup.hide()
			field.text = block_name)

		file_box.add_child(btn)
		button_count += 1

	#% Position & show list:
	file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	file_popup.size.y = 8 + button_count * 31
	file_popup.popup()


#* Open a list of Lines (LM Commands) for If/Elif/Else/Go/Bridge commands:
func open_line_menu(o_convo_field, o_block_field, field: LineEdit) -> void:
	#% Clear old buttons
	for c in file_box.get_children():
		c.queue_free()

	#% Retrieve Conversation and Block fields:
	var convo_name: String = o_convo_field.text.strip_edges()
	var block_name: String = o_block_field.text.strip_edges()

	var convo_to_use := ""
	var block_to_use := ""

	#% Determine which conversation/block to use:
	if convo_name == "" and block_name == "":
		#% Both empty: current conversation & block:
		convo_to_use = candy_dc.current_conversation
		block_to_use = candy_dc.current_block

	elif convo_name == "" and block_name != "":
		#% Conversation empty, block given: use current conversation if block exists:
		convo_to_use = candy_dc.current_conversation
		if candy_dc.conversations.has(convo_to_use) and candy_dc.conversations[convo_to_use].has(block_name):
			block_to_use = block_name
		else:
			_show_line_menu_error(field, "[Not found]")
			return

	elif convo_name != "" and block_name != "":
		#% Both provided: verify both exist:
		if candy_dc.conversations.has(convo_name) and candy_dc.conversations[convo_name].has(block_name):
			convo_to_use = convo_name
			block_to_use = block_name
		else:
			_show_line_menu_error(field, "[Not found]")
			return

	elif convo_name != "" and block_name == "":
		#% Conversation given, block missing: invalid:
		_show_line_menu_error(field, "[Not found]")
		return

	#% Now collect LM Command lines for the given block:
	var conv = candy_dc.conversations[convo_to_use]
	var blk = conv[block_to_use]
	if not blk.has("Text"):
		_show_line_menu_error(field, "[Not found]")
		return

	var lines_array: Array = blk["Text"]
	var found_any := false

	var button_count = 0
	for line_dict in lines_array:
		if line_dict.has("§LM"):
			var ref_name = str(line_dict["§LM"].get("Reference", "")).strip_edges()
			if ref_name != "":
				var btn := Button.new()
				btn.text = ref_name
				btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				btn.pressed.connect(func():
					file_popup.hide()
					field.text = ref_name)
				file_box.add_child(btn)
				found_any = true
				button_count += 1

	if not found_any:
		_show_line_menu_error(field, "[Not found]")
		return

	#% Position and show popup:
	file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	file_popup.size.x = int(field.size.x)
	file_popup.size.y = 8 + button_count * 31
	file_popup.popup()


#* Helper: show a single warning label:
func _show_line_menu_error(field: LineEdit, message: String) -> void:
	var label := Label.new()
	label.text = message
	file_box.add_child(label)
	file_popup.position = field.get_global_position() + Vector2(0, field.size.y)
	file_popup.size.x = int(field.size.x)
	file_popup.size.y = 39
	file_popup.popup()
#endregion


#?######################################################################################
#& COLOR PICKER:
#?##############
#region
#* Select new color:
func _on_color_picker_color_changed(color: Color) -> void:
	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var text_array: Array = block["Text"]
	var line_data

	if candy_dc.color_pick_mode == "comment":
		if candy_dc.comment_line_index < 0 or candy_dc.comment_line_index >= text_array.size():
			return

		line_data = text_array[candy_dc.comment_line_index]

		line_data["§Comment"]["Color"] = color
		candy_dc.comment_line.get_node("HBox/Comment/Comment").add_theme_color_override("font_color", color)
		candy_dc.comment_line.get_node("HBox/Comment/Color").modulate = color

	elif candy_dc.color_pick_mode == "cs_light_color":
		if candy_dc.cs_line_index < 0 or candy_dc.cs_line_index >= text_array.size():
			return

		line_data = text_array[candy_dc.cs_line_index]

		line_data["§CS_Light"]["Color"] = str(color)
		candy_dc.cs_line.get_node("HBox/CS/Color").text = str(color)
		candy_dc.cs_line.get_node("HBox/CS/ColorPicker").modulate = color

	elif candy_dc.color_pick_mode == "writer":
		$"Writer/Main/HBox/RightPanel/BBCode/Color2/ColorValue".text = "\u0023" + color.to_html()
		$"Writer/Main/HBox/RightPanel/BBCode/Color2/PickColor".modulate = color


#* Close color picker:
func _on_color_picker_close_pressed() -> void:
	$"Color".visible = false
	candy_dc.color_pick_mode = ""
#endregion


#?######################################################################################
#& REORDER LINES:
#?###############
#region
func _on_alt_click_target_set(target_idx: int, move_below: bool):
	#% Only execute if we have a selection:

	if candy_dc.selected_lines.size() == 0:
		return

	if move_below:
		call_deferred("_move_selection_below", target_idx)
	else:
		call_deferred("_move_selection_above", target_idx)


#* Clear all selections:
func _clear_selection() -> void:
	for idx in candy_dc.selected_lines:
		var line = get_node("VBox/HBox/WorkArea/Lines").get_child(idx)
		if line:
			line.get_node("HBox/Move").modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]
	candy_dc.selected_lines.clear()
	candy_dc.last_clicked_line = -1

	#% Optional: clear cyan on visible pool if needed:
	for n in line_pool:
		if n:
			n.get_node("HBox/Move").modulate = candy_dc.color_models[candy_dc.color_mode]["Null"]


#* Copy one or more selected lines above or below a target index:
func copy_lines(target_index: int, below: bool) -> void:
	#% Skip if no valid context
	if candy_dc.current_conversation == "" or candy_dc.current_block == "":
		return

	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var text_array: Array = block["Text"]

	if target_index < 0 or target_index >= text_array.size():
		return

	#% Determine which lines to copy:
	var lines_to_copy: Array = []
	if candy_dc.selected_lines.size() > 0:
		candy_dc.selected_lines.sort()
		for idx in candy_dc.selected_lines:
			if idx >= 0 and idx < text_array.size():
				lines_to_copy.append(text_array[idx].duplicate(true))
	else:
		lines_to_copy.append(text_array[target_index].duplicate(true))

	#% Compute insertion slot:
	var insert_at := target_index
	if below:
		insert_at += 1

	#% Clamp within range:
	insert_at = clamp(insert_at, 0, text_array.size())

	#% Insert all copies in order:
	for line_copy in lines_to_copy:
		text_array.insert(insert_at, line_copy)
		insert_at += 1

	#% Save back to globals:
	block["Text"] = text_array
	candy_dc.conversations[candy_dc.current_conversation][candy_dc.current_block] = block

	#% Clear selection & reset move state:
	_clear_selection()
	candy_dc.alt_click_line_index = -1
	candy_dc.alt_click_move_below = false


	save_undo_step()

	#% Refresh the visible lines:
	_update_visible_lines()


#* Move candy_dc.selected_lines below the given target index:
func _move_selection_below(target_index: int) -> void:
	print("_move_selection_below called with target_index = ", target_index)
	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var text_array: Array = block["Text"]

	#% Pull out selected items in order, remove from end to keep indices valid:
	candy_dc.selected_lines.sort()
	var moving: Array = []
	for i in range(candy_dc.selected_lines.size() - 1, -1, -1):
		var idx: int = candy_dc.selected_lines[i]
		moving.insert(0, text_array[idx])
		text_array.remove_at(idx)

	#% Compute insertion slot below target (adjust for removed lines):
	var insert_at := target_index + 1
	for idx in candy_dc.selected_lines:
		if idx < target_index:
			insert_at -= 1
	insert_at = clamp(insert_at, 0, text_array.size())

	print(insert_at)

	#% Insert all lines in order:
	for item in moving:
		text_array.insert(insert_at, item)
		insert_at += 1

	print(insert_at)

	#% Clear selection & reset move state:
	_clear_selection()
	candy_dc.alt_click_line_index = -1
	candy_dc.alt_click_move_below = false

	save_undo_step()

	#% Refresh the visible lines:
	_update_visible_lines()


#* Move candy_dc.selected_lines above the given target index:
func _move_selection_above(target_index: int) -> void:
	print("_move_selection_above called with target_index = ", target_index)
	var conv = candy_dc.conversations[candy_dc.current_conversation]
	var block = conv[candy_dc.current_block]
	var text_array: Array = block["Text"]

	#% Pull out selected items in order, remove from end to keep indices valid:
	candy_dc.selected_lines.sort()
	var moving: Array = []
	for i in range(candy_dc.selected_lines.size() - 1, -1, -1):
		var idx: int = candy_dc.selected_lines[i]
		moving.insert(0, text_array[idx])
		text_array.remove_at(idx)

	#% Compute insertion slot above the target (account for left-shifts):
	var insert_at := target_index
	for idx in candy_dc.selected_lines:
		if idx < target_index:
			insert_at -= 1
	insert_at = clamp(insert_at, 0, text_array.size())

	print(insert_at)

	#% Insert all lines in order:
	for item in moving:
		text_array.insert(insert_at, item)
		insert_at += 1

	print(insert_at)

	#% Clear selection & reset move state:
	_clear_selection()
	candy_dc.alt_click_line_index = -1
	candy_dc.alt_click_move_below = false


	save_undo_step()

	#% Refresh the visible lines:
	_update_visible_lines()
#endregion


#?######################################################################################
#& SAVE/LOAD:
#?###########
#region

#* Export all conversations to a .txt file (Variant format with metadata wrapper):
func _on_test_export_pressed() -> void:
	var path = candy_dc.resource_paths["Dialogues"].path_join("test_dialogue.txt")
	var file := FileAccess.open(path, FileAccess.WRITE)

	if not file:
		push_error("Failed to open file for writing: " + path)
		return

	#@ Create a deep duplicate so we don’t modify candy_dc.conversations:
	var export_data = candy_dc.conversations.duplicate(true)

	#@ Remove the CUSTOM_PRESETS conversation if present:
	if export_data.has("CUSTOM_PRESETS"):
		export_data.erase("CUSTOM_PRESETS")

	#@ Iterate over conversations → blocks → lines:
	for conv_key in export_data.keys():
		var conv = export_data[conv_key]

		for block_key in conv.keys():
			var block = conv[block_key]
			var lines = block.get("Text", [])

			for i in range(lines.size()):
				var entry = lines[i]

				if entry.has("Spoken Line"):
					var spoken_line = entry["Spoken Line"]
					var variants = spoken_line.get("Variants", [])
					var cleaned_variants := []

					#% Keep only variants that contain non-empty text:
					for variant_dict in variants:
						for variant_name in variant_dict.keys():
							var text_val := str(
								variant_dict[variant_name].get("Text", "")
							).strip_edges()

							if text_val != "":
								cleaned_variants.append(variant_dict)
								break

					spoken_line["Variants"] = cleaned_variants
					entry["Spoken Line"] = spoken_line
					lines[i] = entry

			block["Text"] = lines
			conv[block_key] = block

		export_data[conv_key] = conv

	#@ Wrap with metadata:
	var final_export: Dictionary = {
		"Meta": {
			"Exported By": "Candy Dialogue Creator",
			"Creator Version": candy_dc.dc_version,
			"Dialogue Version": candy_dc.dialogue_version
		},
		"Dialogue": export_data
	}

	#@ Write using Godot’s native Variant text format:
	var text_data := to_gdstring(final_export)
	file.store_string(text_data)
	file.close()

	print("Exported dialogues to:", path)


#* Recursively format any Variant (Dictionary, Array, etc.) into a GDScript-like text block:
#% Preserves key order if dictionary includes a "__order__" array.
func to_gdstring(value: Variant, indent_level := 0) -> String:
	var indent := "\t".repeat(indent_level)

	match typeof(value):
		TYPE_DICTIONARY:
			var lines: Array = []
			var keys: Array = value["__order__"] if value.has("__order__") else value.keys()

			for k in keys:
				var v = value[k]
				var formatted_val = to_gdstring(v, indent_level + 1)
				lines.append(indent + "\t" + '"' + str(k).replace('"', '\\"') + '": ' + formatted_val + ",")
			return "{\n" + "\n".join(lines) + "\n" + indent + "}"

		TYPE_ARRAY:
			var items: Array = []
			for v in value:
				items.append(to_gdstring(v, indent_level + 1))
			return "[ " + ", ".join(items) + " ]"

		TYPE_STRING:
			return '"' + value.replace('"', '\\"') + '"'

		TYPE_COLOR:
			return "Color(%s, %s, %s, %s)" % [str(value.r), str(value.g), str(value.b), str(value.a)]

		TYPE_VECTOR2:
			return "Vector2(%s, %s)" % [str(value.x), str(value.y)]

		TYPE_VECTOR3:
			return "Vector3(%s, %s, %s)" % [str(value.x), str(value.y), str(value.z)]

		TYPE_VECTOR4:
			return "Vector4(%s, %s, %s, %s)" % [str(value.x), str(value.y), str(value.z), str(value.w)]

		TYPE_OBJECT:
			if value is Node:
				return '"' + value.get_path() + '"'
			else:
				return '"<Object:' + value.get_class() + '>"'

		_:
			return str(value)


#* Save right-click:
func _on_save_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_show_save_popup()


#* Show save right-click pop-up:
func _show_save_popup() -> void:
	#% Clear existing items:
	for c in file_box.get_children():
		c.queue_free()

	#% Create buttons:
	var btn_save := Button.new()
	btn_save.text = "Save"
	btn_save.pressed.connect(func():
		file_popup.hide()
		_on_save_pressed())

	var btn_save_as := Button.new()
	btn_save_as.text = "Save As"
	btn_save_as.pressed.connect(func():
		file_popup.hide()
		$"SaveLoad".visible = true
		$"SaveLoad/SaveMenu".visible = true)

	var btn_save_incr := Button.new()
	btn_save_incr.text = "Save Incremental"
	btn_save_incr.pressed.connect(func():
		file_popup.hide()
		_on_save_incremental_pressed()
		print("Save Incremental clicked"))

	file_box.add_child(btn_save)
	file_box.add_child(btn_save_as)
	file_box.add_child(btn_save_incr)

	#% Position and show popup:
	var save_button := $"VBox/TopBar/HBox/Save"
	file_popup.position = save_button.get_global_position() + Vector2(0, save_button.size.y)
	file_popup.size.y = 8 + save_button.size.y * 3
	file_popup.popup()


#* Helper to save dialogues to a .txt file in GDScript-like format:
func _save_dialogue_to_txt(path: String, save_type: String = "ManualSave") -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: " + path)
		return

	#@ Exclude "CUSTOM_PRESETS" from saving:
	var conversations_to_save = candy_dc.conversations.duplicate()
	conversations_to_save.erase("CUSTOM_PRESETS")

	var save_data := {
		"Type": save_type,
		"Profile": candy_dc.active_profile,
		"Exported By": "Candy Dialogue Creator",
		"Version": candy_dc.dc_version,
		"Dialogue Version": candy_dc.dialogue_version,
		"Dialogue": candy_dc.conversations,
	}

	#% Write as formatted text:
	var txt := to_gdstring(save_data, 0)
	file.store_string(txt)
	file.close()

	print("Saved", save_type, "dialogue file to:", path)


#* Save the current editor state to .txt (GDScript-like format):
func _on_save_pressed() -> void:
	#% Ensure there is a target file path:
	if candy_dc.loaded_save == "":
		$"SaveLoad".visible = true
		$"SaveLoad/SaveMenu".current_dir = ProjectSettings.globalize_path("user://Profiles".path_join(candy_dc.current_profile).path_join("Saves").path_join("Manual Saves"))
		$"SaveLoad/SaveMenu".visible = true
		return  #/ Return and let user select a path

	var path = candy_dc.loaded_save

	#% Write dialogue file in GDScript-style format:
	_save_dialogue_to_txt(path, "ManualSave")

	#% Handle post-save actions:
	if candy_dc.after_save == "new":
		candy_dc.after_save = ""
		new_dialogue()
	elif candy_dc.after_save == "quit":
		candy_dc.after_save = ""
		$"MainMenu"._on_exit_yes_pressed()



#* Save to the file selected in the FileDialog:
func _on_save_menu_file_selected(path: String) -> void:
	candy_dc.loaded_save = path

	#% Write dialogue data as formatted .txt:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for writing: " + path)
		return

	var save_data := {
		"Type": "ManualSave",
		"Profile": candy_dc.active_profile,
		"Exported By": "Candy Dialogue Creator",
		"Version": candy_dc.dc_version,
		"Dialogue Version": candy_dc.dialogue_version,
		"Dialogue": candy_dc.conversations,
	}

	#% Use the pretty GDScript-like format
	var text := to_gdstring(save_data, 0)
	file.store_string(text)
	file.close()

	print("Saved manual file to:", path)

	#% Hide menus after saving:
	$"SaveLoad".visible = false
	$"SaveLoad/SaveMenu".visible = false


func _on_save_menu_canceled() -> void:
	$"SaveLoad".visible = false
	$"SaveLoad/SaveMenu".visible = false

func _on_load_menu_canceled() -> void:
	$"SaveLoad".visible = false
	$"SaveLoad/LoadMenu".visible = false


#* Save a new incremental version of the current file with timestamped name:
func _on_save_incremental_pressed() -> void:
	var path = candy_dc.loaded_save
	if path == "":
		push_error("No file loaded. Use Save or Save As first.")
		return

	#% Strip previous timestamp if any:
	var regex := RegEx.new()
	regex.compile("_?〔\\d{4}-\\d{2}-\\d{2}[-_]?\\d{2}-\\d{2}-\\d{2}〕$")
	var base = path.get_basename()
	base = regex.sub(base, "", true)

	#% Replace .txt (or append if missing):
	var stamp = Time.get_datetime_string_from_system().replace(":", "-")
	var without_ext = path.substr(0, path.rfind(".txt"))
	if without_ext == "":
		without_ext = path
	var new_path = without_ext + "〔" + stamp + "〕.txt"

	#% Ensure no duplicate 'res://':
	new_path = new_path.replace("res://res://", "res://")

	#% Save formatted dialogue:
	_save_dialogue_to_txt(new_path, "ManualSave")

	candy_dc.loaded_save = new_path
	print("Saved incremental file to:", new_path)



#* Perform a quick-save (e.g. on F5):
func perform_quicksave() -> void:
	var base := "user://Profiles".path_join(candy_dc.current_profile).path_join("Saves").path_join("QuickSaves")
	DirAccess.make_dir_recursive_absolute(base)

	var path: String

	#% If quick_saves <= 0 → infinite quick-saves (timestamped):
	if candy_dc.quick_saves <= 0:
		var stamp := Time.get_datetime_string_from_system().replace(":", "-")
		path = base.path_join("QuickSave〔%s〕.txt" % stamp)
	else:
		#% Rotate indices within the configured limit:
		if not candy_dc.has_method("quick_save_index"):
			candy_dc.quick_save_index = 0
		candy_dc.quick_save_index = (candy_dc.quick_save_index + 1) % candy_dc.quick_saves
		var filename := "QuickSave_%d.txt" % candy_dc.quick_save_index
		path = base.path_join(filename)

	#% Save the dialogue data to file:
	_save_dialogue_to_txt(path, "QuickSave")

	print("Quick-saved to:", path)

	#% Reset autosave timer:
	$"AutoSaveTimer".wait_time = candy_dc.auto_saves_frequency * 60


#* Called automatically by the "AutoSaveTimer" node when it reaches 0:
func _on_auto_save_timeout() -> void:
	#% Check auto saves are not disabled:
	if candy_dc.auto_saves < 0:
		return

	#% Build autosave base folder:
	var base := "user://Profiles".path_join(candy_dc.current_profile).path_join("Saves").path_join("AutoSaves")
	DirAccess.make_dir_recursive_absolute(base)

	#% Compose timestamped file name:
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var file_path := base.path_join("Auto〔%s〕.txt" % stamp)

	#% Write autosave file:
	_save_dialogue_to_txt(file_path, "AutoSave")
	print("Auto-saved:", file_path)

	#% If auto_saves <= 0 → infinite auto-saves (no cleanup)
	if candy_dc.auto_saves == 0:
		return

	#% Otherwise keep only the N newest autosave files:
	var dir := DirAccess.open(base)
	if dir == null:
		return

	var files := []
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".txt"):
			files.append(base.path_join(f))
		f = dir.get_next()
	dir.list_dir_end()

	if files.size() > candy_dc.auto_saves:
		#% Sort by modification time (oldest first):
		files.sort_custom(func(a, b):
			return FileAccess.get_modified_time(a) < FileAccess.get_modified_time(b))

		#% Remove oldest files beyond the allowed count:
		var excess = files.size() - candy_dc.auto_saves
		for i in range(excess):
			var old_file = files[i]
			if DirAccess.remove_absolute(old_file) == OK:
				print("Removed old autosave:", old_file)
			else:
				push_warning("Failed to remove old autosave: " + old_file)


func _on_load_pressed() -> void:
	$"SaveLoad".visible = true
	$"SaveLoad/LoadMenu".current_dir = ProjectSettings.globalize_path("user://Profiles".path_join(candy_dc.current_profile).path_join("Saves").path_join("Manual Saves"))
	$"SaveLoad/LoadMenu".visible = true


#* Parse a .txt file saved with to_gdstring() back into a Dictionary or Array
func from_gdstring(text: String) -> Variant:
	text = text.replace("<null>", "null").replace("<Null>", "null")
	var regex_trailing := RegEx.new()
	regex_trailing.compile(",(\\s*[}\\]])")
	text = regex_trailing.sub(text, "$1", true)
	text = text.strip_edges()
	if text.ends_with(","):
		text = text.substr(0, text.length() - 1)
	var expr := Expression.new()
	if expr.parse(text) != OK:
		push_error("Failed to parse .txt dialogue file")
		return null
	var result = expr.execute()
	if expr.has_execute_failed():
		push_error("Runtime error while evaluating .txt dialogue file")
		return null
	return result

#* Load editor state from a previously saved .txt file:
func _on_load_menu_file_selected(path: String) -> void:
	#% Try to open file
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Failed to open file: " + path)
		return
	var text := f.get_as_text()
	f.close()

	#% Sanitize formatting for Expression parser (handle <null>, stray commas, etc.)
	text = text.replace("<null>", "null").replace("<Null>", "null")

	var regex_trailing := RegEx.new()
	regex_trailing.compile(",(\\s*[}\\]])")
	text = regex_trailing.sub(text, "$1", true)
	text = text.strip_edges()
	if text.ends_with(","):
		text = text.substr(0, text.length() - 1)

	#% Parse .txt structure using Expression
	var expr := Expression.new()
	if expr.parse(text) != OK:
		push_error("Failed to parse .txt dialogue file: " + path)
		return
	var data = expr.execute()
	if expr.has_execute_failed():
		push_error("Runtime error while evaluating .txt dialogue file: " + path)
		return

	if typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid .txt structure in: " + path)
		return

	#% Validate expected keys:
	if not data.has("Type") or not data.has("Dialogue"):
		push_error("File missing required keys (Type/Conversations): " + path)
		return

	#% Extract project and conversations:
	candy_dc.loaded_save = path

	#% Get the loaded dialogue, stripping CUSTOM_PRESETS if it was accidentally saved:
	var loaded_dialogue: Dictionary = data["Dialogue"]
	loaded_dialogue.erase("CUSTOM_PRESETS")

	#% Restore CUSTOM_PRESETS from live data:
	candy_dc.conversations.clear()
	candy_dc.conversations["CUSTOM_PRESETS"] = candy_dc.custom_presets.duplicate(true)
	candy_dc.conversations.merge(loaded_dialogue)

	print("Loaded save file:", path)

	#% Hide load menu UI
	$"SaveLoad".visible = false
	$"SaveLoad/LoadMenu".visible = false

	#% Refresh displayed content
	_validate_current_selection()


#* Load the most recent QuickSave file for the current project:
func perform_quickload() -> void:
	var base := "user://Profiles".path_join(candy_dc.current_profile).path_join("Saves").path_join("QuickSaves")
	var dir := DirAccess.open(base)
	if dir == null:
		push_error("Quick-save folder not found: " + base)
		return

	#% Gather all quick-save TXT files:
	var files: Array = []
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".txt"):
			files.append(base.path_join(f))
		f = dir.get_next()
	dir.list_dir_end()

	if files.is_empty():
		push_error("No quick-save files found in: " + base)
		return

	#% Find newest file by modification time:
	files.sort_custom(func(a, b):
		return FileAccess.get_modified_time(a) > FileAccess.get_modified_time(b))
	var newest = files[0]

	#% Read and parse file:
	var file := FileAccess.open(newest, FileAccess.READ)
	if file == null:
		push_error("Failed to open quick-save file: " + newest)
		return
	var text := file.get_as_text()
	file.close()

	#% Parse GDScript-style text into dictionary:
	var data = from_gdstring(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid data structure in: " + newest)
		return
	if not data.has("Dialogue"):
		push_error("Missing Dialogue key in: " + newest)
		return

	#% Apply loaded data:
	candy_dc.loaded_save = ""	#/ Clear loaded save so manual saves don't overwrite quicksave file.

	var loaded_dialogue: Dictionary = data["Dialogue"]
	loaded_dialogue.erase("CUSTOM_PRESETS")

	#% Restore CUSTOM_PRESETS from live data, clear all other keys, then merge in the loaded ones:
	candy_dc.conversations.clear()
	candy_dc.conversations["CUSTOM_PRESETS"] = candy_dc.custom_presets.duplicate(true)
	candy_dc.conversations.merge(loaded_dialogue)

	print("Quick-loaded from:", newest)

	#% Refresh current editor view:
	_validate_current_selection()


#* Validate current conversation / block and refresh both dropdowns:
func _validate_current_selection() -> void:
	var convo_btn: OptionButton = get_node("VBox/TopBar/HBox/Conversations/Conversations")
	var block_btn: OptionButton = get_node("VBox/TopBar/HBox/Blocks/Blocks")

	#% Ensure current conversation is valid:
	if not candy_dc.conversations.has(candy_dc.current_conversation):
		candy_dc.current_conversation = convo_btn.get_item_text(0) if convo_btn.item_count > 0 else ""

	#% Blocks:
	if candy_dc.current_conversation != "":
		var conv = candy_dc.conversations[candy_dc.current_conversation]
		var valid_block = conv.has(candy_dc.current_block)
		if not valid_block:
			candy_dc.current_block = block_btn.get_item_text(0) if block_btn.item_count > 0 else ""

	print(candy_dc.conversations)
	candy_dc.refresh_conv_block_selectors = true


#* Start new dialogue after saving:
func new_dialogue():
	candy_dc.conversations = {}
	candy_dc.conversations = {"CUSTOM_PRESETS": {"Preset 1": {"Text": []}},"Conversation 1": {"Block 1": {"Text": []}}}
	candy_dc.loaded_save = ""

	candy_dc.current_conversation = "Conversation 1"
	candy_dc.current_block = "Block 1"
	candy_dc.editor_state = "ui"

	#@ Update the Conversations dropdown:
	var conv_btn := $"VBox/TopBar/HBox/Conversations/Conversations"
	conv_btn.clear()
	for conv_name in candy_dc.conversations.keys():
		conv_btn.add_item(conv_name)
		if conv_name == candy_dc.current_conversation:
			conv_btn.select(conv_btn.item_count - 1)

	#@ Update the Blocks dropdown:
	var block_btn := $"VBox/TopBar/HBox/Blocks/Blocks"
	block_btn.clear()
	var conv = candy_dc.conversations[candy_dc.current_conversation]
	for block_name in conv.keys():
		block_btn.add_item(block_name)
		if block_name == candy_dc.current_block:
			block_btn.select(block_btn.item_count - 1)

	#@ Refresh the visible line panels:
	await _load_active_block()
#endregion


#?######################################################################################
#& UNDO/REDO:
#?###########
#region
#* Save an Undo step:
func save_undo_step() -> void:
	if not "undo_array" in candy_dc:
		candy_dc.undo_array = []
	if not "undo_step" in candy_dc:
		candy_dc.undo_step = 0

	#% If we're not at the end, remove any redo steps:
	if candy_dc.undo_step < candy_dc.undo_array.size() - 1:
		candy_dc.undo_array = candy_dc.undo_array.slice(0, candy_dc.undo_step + 1)

	#@ Build snapshot dictionary with all relevant state:
	var snapshot := {
		"conversations": JSON.parse_string(JSON.stringify(candy_dc.conversations)),
		"browsing_history": JSON.parse_string(JSON.stringify(candy_dc.browsing_history)),
		"browsing_index": candy_dc.browsing_index
	}

	candy_dc.undo_array.append(snapshot)
	candy_dc.undo_step = candy_dc.undo_array.size() - 1

	#% Trim old states if memory exceeds limit:
	var limit_bytes = candy_dc.undo_memory * 1024 * 1024
	var total_bytes := 0
	for i in range(candy_dc.undo_array.size() - 1, -1, -1):
		var entry_bytes = len(JSON.stringify(candy_dc.undo_array[i]))
		total_bytes += entry_bytes
		if total_bytes > limit_bytes:
			candy_dc.undo_array = candy_dc.undo_array.slice(i + 1, candy_dc.undo_array.size())
			candy_dc.undo_step = candy_dc.undo_array.size() - 1
			break

#* Apply a snapshot from undo_array by absolute index:
func _apply_undo_snapshot(abs_index: int) -> void:
	var snap: Dictionary = candy_dc.undo_array[abs_index]

	#% 1) Restore conversations:
	candy_dc.conversations = JSON.parse_string(JSON.stringify(snap["conversations"]))

	#% 2) Restore browsing history (if available):
	if snap.has("browsing_history"):
		candy_dc.browsing_history = JSON.parse_string(JSON.stringify(snap["browsing_history"]))
	if snap.has("browsing_index"):
		candy_dc.browsing_index = snap["browsing_index"]
	else:
		candy_dc.browsing_index = clamp(candy_dc.browsing_index, 0, candy_dc.browsing_history.size() - 1)

	#% 3) Rebuild current selection safely:
	_load_active_block()

	if not candy_dc.conversations.has(candy_dc.current_conversation):
		var first_conv := ""
		for c in candy_dc.conversations.keys():
			first_conv = c
			break
		candy_dc.current_conversation = first_conv

	if candy_dc.current_conversation != "":
		var blocks_dict: Dictionary = candy_dc.conversations[candy_dc.current_conversation]
		if not blocks_dict.has(candy_dc.current_block):
			var first_block := ""
			for b in blocks_dict.keys():
				first_block = b
				break
			candy_dc.current_block = first_block

	#% 4) Refresh UI selectors:
	_refresh_conversation_block_selectors()

#* Undo:
func _on_undo_pressed() -> void:
	if candy_dc.undo_step > 0:
		candy_dc.undo_step -= 1
		_apply_undo_snapshot(candy_dc.undo_step)

		#@ Restore the browsing position as it was in that snapshot:
		if candy_dc.browsing_history.size() > 0:
			var idx = clamp(candy_dc.browsing_index, 0, candy_dc.browsing_history.size() - 1)
			var entry = candy_dc.browsing_history[idx]
			await _apply_history_entry(entry)

#* Redo:
func _on_redo_pressed() -> void:
	if candy_dc.undo_step < candy_dc.undo_array.size() - 1:
		candy_dc.undo_step += 1
		_apply_undo_snapshot(candy_dc.undo_step)

		#@ Do NOT use browsing_index here — use current conversation/block directly:
		if candy_dc.current_conversation != "" and candy_dc.current_block != "":
			var entry := {
				"conversation": candy_dc.current_conversation,
				"block": candy_dc.current_block
			}
			await _apply_history_entry(entry)

#* Rebuild the $"VBox/TopBar/HBox/Conversations/Conversations" and $"VBox/TopBar/HBox/Blocks/Blocks" OptionButtons:
func _refresh_conversation_block_selectors() -> void:
	var conv_ob: OptionButton = $"VBox/TopBar/HBox/Conversations/Conversations"
	var blk_ob: OptionButton = $"VBox/TopBar/HBox/Blocks/Blocks"

	#% Conversations:
	conv_ob.clear()
	var convo_index := 0
	var select_conv_idx := 0
	for c in candy_dc.conversations.keys():
		conv_ob.add_item(c)
		if c == candy_dc.current_conversation:
			select_conv_idx = convo_index
		convo_index += 1
	conv_ob.select(select_conv_idx)

	#% Blocks for the selected conversation:
	blk_ob.clear()
	var blk_index := 0
	var select_blk_idx := 0
	if candy_dc.current_conversation != "":
		for b in candy_dc.conversations[candy_dc.current_conversation].keys():
			blk_ob.add_item(b)
			if b == candy_dc.current_block:
				select_blk_idx = blk_index
			blk_index += 1
	blk_ob.select(select_blk_idx)
#endregion


#?######################################################################################
#& COMMAND PRESETS:
#?#################
#region
#* Build command preset buttons and categories from CUSTOM_PRESETS:
func _build_command_presets() -> void:
	#% Clear previous presets:
	var presets_root = $"VBox/HBox/SideBar/VBox/Presets/VBox"
	for child in presets_root.get_children():
		child.queue_free()

	#% Ensure CUSTOM_PRESETS exists:
	if not candy_dc.conversations.has("CUSTOM_PRESETS"):
		return

	var presets_conv = candy_dc.conversations["CUSTOM_PRESETS"]

	#% Group presets by category:
	var grouped := {}
	for block_name in presets_conv.keys():
		if not block_name.begins_with("[") or not block_name.contains("]"):
			continue

		var cat_start = block_name.find("[") + 1
		var cat_end = block_name.find("]")
		var category = block_name.substr(cat_start, cat_end - cat_start)
		var preset_name = block_name.substr(cat_end + 1, block_name.length()).strip_edges()

		if not grouped.has(category):
			grouped[category] = []
		grouped[category].append({
			"name": preset_name,
			"block": block_name
		})

	#% Create FoldableContainers for each category:
	for category in grouped.keys():
		var fold := FoldableContainer.new()
		fold.name = category
		fold.title = category
		fold.custom_minimum_size.x = 256	#/ Minimum horizontal size
		fold.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var inner_vbox := VBoxContainer.new()
		fold.add_child(inner_vbox)
		presets_root.add_child(fold)

		#% Create buttons for each preset:
		for preset_data in grouped[category]:
			var btn := Button.new()
			btn.text = preset_data["name"]
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size.y = 32	#/ Minimum vertical size
			btn.connect("mouse_entered", Callable(self, "_on_command_mouse_entered"))
			btn.connect("mouse_exited", Callable(self, "_on_command_mouse_exited"))
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			btn.connect("pressed", Callable(self, "_on_preset_button_pressed").bind(preset_data["block"]))
			inner_vbox.add_child(btn)

	update_custom_presets()


#* Copy the "CUSTOM_PRESETS" conversation into a separate dictionary:
func update_custom_presets() -> void:
	#% Ensure the source exists:
	if not candy_dc.conversations.has("CUSTOM_PRESETS"):
		candy_dc.custom_presets = {}		#/ Reset to empty if missing
		return

	#% Deep copy the data so edits don't affect the source:
	candy_dc.custom_presets = JSON.parse_string(JSON.stringify(candy_dc.conversations["CUSTOM_PRESETS"]))


#* Hover began on any preset button:
func _on_command_mouse_entered() -> void:
	in_command_button = true


#* Hover ended on any preset button:
func _on_command_mouse_exited() -> void:
	in_command_button = false


#* Insert preset lines into current block:
func _on_preset_button_pressed(block_name: String) -> void:
	if not candy_dc.conversations.has("CUSTOM_PRESETS"):
		return
	if not candy_dc.conversations["CUSTOM_PRESETS"].has(block_name):
		return

	var preset_lines = candy_dc.conversations["CUSTOM_PRESETS"][block_name]["Text"]
	if preset_lines.is_empty():
		return

	#@ Deep copy the preset data:
	var copied_lines: Array = []
	for line in preset_lines:
		copied_lines.append(JSON.parse_string(JSON.stringify(line)))

	var target_conv = candy_dc.conversations[candy_dc.current_conversation]
	var target_block = target_conv[candy_dc.current_block]["Text"]

	#@ Insert above each selected line (sorted ascending so offsets accumulate):
	if candy_dc.selected_lines.size() > 0:
		var sorted_selection = candy_dc.selected_lines.duplicate()
		sorted_selection.sort()
		var offset := 0
		for idx in sorted_selection:
			var insert_index = clamp(idx + offset, 0, target_block.size())
			for line in copied_lines:
				target_block.insert(insert_index, JSON.parse_string(JSON.stringify(line)))
				insert_index += 1
			offset += copied_lines.size()

	#@ If nothing is selected, append to the end:
	else:
		for line in copied_lines:
			target_block.append(JSON.parse_string(JSON.stringify(line)))

	#@ Save and refresh:
	candy_dc.conversations[candy_dc.current_conversation][candy_dc.current_block]["Text"] = target_block
	save_undo_step()
	_clear_selection()
	_load_active_block()

#endregion


#* Open About menu:
func _on_about_pressed() -> void:
	$"About".visible = true




#?######################################################################################
#& WINDOW HANDLING:
#?#################

#* Minimize button pressed:
func _on_minimize_pressed():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

#* Windowed button pressed:
func _on_windowed_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


#* Open exit confirmation prompt:
func _on_exit_pressed() -> void:
	$"ExitMenu".visible = true
	candy_dc.editor_state = "exit"


#* Cancel exit:
func _on_exit_no_pressed() -> void:
	$"ExitMenu".visible = false
	candy_dc.editor_state = "ui"


#* Confirm exit:
func _on_exit_yes_pressed() -> void:
	#% Save profile data:
	await $"ProfileMenu".save_profile()
	get_tree().quit()

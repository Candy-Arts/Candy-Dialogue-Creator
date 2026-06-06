extends PanelContainer

@onready var main = get_node("/root/MainUI")
@onready var select_user = get_node("VBox/HBox/Center/VBox/UserButtons/UserSelect")
@onready var select_profile_btn = get_node("VBox/HBox/Center/VBox/Buttons/ProfileButtons/Select")
@onready var rename_profile_btn = get_node("VBox/HBox/Center/VBox/Buttons/ProfileButtons2/Rename")
@onready var delete_profile_btn = get_node("VBox/HBox/Center/VBox/Buttons/ProfileButtons2/Delete")
@onready var profile_list = get_node("VBox/HBox/Center/VBox/ProfileList/ScrollContainer/VBox")

var selected_user = ""
var selected_profile = ""



#* Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func display() -> void:
	globals.editor_state = "Profile"
	self.visible = true
	populate_user_list()
	populate_profile_list()

#* Create User folder:
func create_user(user_name) -> void:
	#% Create User folder:
	DirAccess.make_dir_absolute("user://Users")
	DirAccess.make_dir_absolute("user://Users/" + user_name)

	#% Refresh the UserSelect button:
	populate_user_list()

	#% Select newly created user:
	for i in range(select_user.item_count):
		if select_user.get_item_text(i) == user_name:
			select_user.select(i)
			selected_user = user_name
			break

	#% Temporarily make current_user:
	globals.current_user = user_name

	#% Create user presets file:
	globals.user_presets = {
		"USER PRESETS": {
			"[Category_1] User_Preset_1": {
				"Text": [
					{"§Comment": {
						"Color": "",
						"Comment": "",
					}},
				]
			}
		}
	}
	main.export_user_presets()

	#% Clear current_user:
	globals.current_user = ""

	populate_profile_list()


#* Create new profile folder:
func create_profile(profile_name):
	var profile_path = "user://Users/" + selected_user + "/" + profile_name
	DirAccess.make_dir_absolute(profile_path)

	#% Create ProfileSettings.txt:
	var file = FileAccess.open(profile_path + "/ProfileSettings.txt", FileAccess.WRITE)
	if file:
		file.store_string("{}")
		file.close()

	#% Create Saves folder and subfolders:
	DirAccess.make_dir_absolute(profile_path + "/Saves")
	DirAccess.make_dir_absolute(profile_path + "/Saves/Manual_Saves")
	DirAccess.make_dir_absolute(profile_path + "/Saves/Quick_Saves")
	DirAccess.make_dir_absolute(profile_path + "/Saves/Auto_Saves")

	#% Temporarly assign user and profile to globals for saving:
	globals.current_user = selected_user
	globals.current_profile = profile_name

	#% Save profile:
	main.save_profile()

	#% Create profile presets file:
	globals.profile_presets = {
		"PROFILE PRESETS": {
			"[Category_1] Profile_Preset_1": {
				"Text": [
					{"§Comment": {
						"Color": "",
						"Comment": "",
					}},
				]
			}
		}
	}
	main.export_profile_presets()

	#% Clear user and profile:
	globals.current_user = ""
	globals.current_profile = ""

	#% Update profile list:
	populate_profile_list()



#* Rename the selected profile:
func rename_profile(new_name: String) -> void:
	var old_path = "user://Users/" + selected_user + "/" + selected_profile
	var new_path = "user://Users/" + selected_user + "/" + new_name
	DirAccess.rename_absolute(old_path, new_path)

	#@ Update Profile Name in ProfileSettings.txt:
	var settings_path = new_path + "/ProfileSettings.txt"
	if FileAccess.file_exists(settings_path):
		var file = FileAccess.open(settings_path, FileAccess.READ)
		if file:
			var data = str_to_var(file.get_as_text())
			file.close()
			if data is Dictionary:
				data["Profile Name"] = new_name
				var f_write = FileAccess.open(settings_path, FileAccess.WRITE)
				if f_write:
					f_write.store_string(var_to_str(data))
					f_write.close()

	populate_profile_list()
	for child in profile_list.get_children():
		if child is Button and child.text == new_name:
			_on_profile_selected(new_name, child)
			break


#* Delete the selected profile:
func delete_profile() -> void:
	var profile_path = "user://Users/" + selected_user + "/" + selected_profile
	_delete_folder_recursive(profile_path)
	selected_profile = ""
	populate_profile_list()


#* Recursively delete a folder and all its contents:
func _delete_folder_recursive(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var item = dir.get_next()
	while item != "":
		var full_path = path + "/" + item
		if dir.current_is_dir():
			_delete_folder_recursive(full_path)
		else:
			DirAccess.remove_absolute(full_path)
		item = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)


#* Read User folders and populate the UserSelect button:
#% Also selects the first item.
func populate_user_list() -> void:
	select_user.clear()

	if not DirAccess.dir_exists_absolute("user://Users"):
		return

	var dir = DirAccess.open("user://Users")
	if dir == null:
		return

	dir.list_dir_begin()
	var folder = dir.get_next()
	while folder != "":
		if dir.current_is_dir():
			select_user.add_item(folder)
		folder = dir.get_next()
	dir.list_dir_end()

	if select_user.item_count > 0:
		selected_user = select_user.get_item_text(0)
		select_user.select(0)


#* Read Profile folders for the selected user and populate the profile list:
func populate_profile_list() -> void:
	#% Clear existing buttons:
	for c in profile_list.get_children():
		c.queue_free()

	if selected_user == "":
		return

	var user_path = "user://Users/" + selected_user
	if not DirAccess.dir_exists_absolute(user_path):
		return

	var dir = DirAccess.open(user_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var folder = dir.get_next()

	#% Create profile buttons:
	while folder != "":
		if dir.current_is_dir():
			var btn := Button.new()
			btn.text = folder
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.toggle_mode = true

			var normal_style = StyleBoxFlat.new()
			normal_style.set_content_margin_all(4)
			normal_style.bg_color = Color(0, 0, 0, 125.0 / 255.0)
			btn.add_theme_stylebox_override("normal", normal_style)

			var hover_style = StyleBoxFlat.new()
			hover_style.set_content_margin_all(4)
			hover_style.bg_color = Color(0.25, 0.25, 0.25, 125.0 / 255.0)
			btn.add_theme_stylebox_override("hover", hover_style)
			btn.add_theme_stylebox_override("focus", hover_style)

			var pressed_style = StyleBoxFlat.new()
			pressed_style.set_content_margin_all(4)
			pressed_style.set_border_width_all(1)
			pressed_style.bg_color = Color(0, 0, 0, 125.0 / 255.0)
			hover_style.border_color = Color(1, 1, 1)
			btn.add_theme_stylebox_override("pressed", pressed_style)

			btn.pressed.connect(func():
				_on_profile_selected(folder, btn))
			profile_list.add_child(btn)

		folder = dir.get_next()
	dir.list_dir_end()


#* Select user:
func _on_user_selected(index: int) -> void:
	selected_user = select_user.get_item_text(index)
	selected_profile = ""
	select_profile_btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	rename_profile_btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	delete_profile_btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	populate_profile_list()


#* Click a profile in the list:
func _on_profile_selected(profile: String, button: Button) -> void:
	selected_profile = profile
	for child in profile_list.get_children():
		if child is Button:
			child.button_pressed = false
	button.button_pressed = true
	select_profile_btn.add_theme_color_override("font_color", Color(0.0, 0.85, 0.0))
	rename_profile_btn.add_theme_color_override("font_color", Color(0.898, 0.918, 0.0))
	delete_profile_btn.add_theme_color_override("font_color", Color(0.878, 0.0, 0.0))


#* New user:
func _on_new_user_pressed() -> void:
	main.prompt_menu.setup("New User")


#* New profile:
func _on_new_profile_pressed() -> void:
	main.prompt_menu.setup("New Profile")


#* Use the selected profile:
func _on_select_profile_pressed() -> void:
	if selected_user != "" and selected_profile != "":
		globals.current_user = selected_user
		globals.current_profile = selected_profile
		globals.editor_state = "Main"
		main.load_profile()
		self.visible = false


#* Delete profile:
func _on_delete_pressed() -> void:
	main.prompt_menu.setup("Delete Profile")

#* Rename profile:
func _on_rename_pressed() -> void:
	main.prompt_menu.setup("Rename Profile")


#* Minimize button pressed:
func _on_minimize_pressed():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

#* Windowed button pressed:
func _on_window_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

#* Open exit confirmation prompt:
func _on_exit_pressed() -> void:
	get_tree().quit()

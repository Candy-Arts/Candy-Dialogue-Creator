#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends PanelContainer

const CONTENT := "VBox/Body/Scroll/Column/Center/Card/Margin/Content"

enum Action { NEW_USER, RENAME_USER, DELETE_USER, NEW_PROFILE, RENAME_PROFILE, DELETE_PROFILE }

@onready var _user_select: OptionButton = get_node(CONTENT + "/UserRow/UserSelect")
@onready var _new_user_button: Button = get_node(CONTENT + "/UserRow/NewUser")
@onready var _rename_user_button: Button = get_node(CONTENT + "/UserRow/RenameUser")
@onready var _delete_user_button: Button = get_node(CONTENT + "/UserRow/DeleteUser")
@onready var _tree: Tree = get_node(CONTENT + "/ProfileTree")
@onready var _new_profile_button: Button = get_node(CONTENT + "/ProfileRow/NewProfile")
@onready var _rename_profile_button: Button = get_node(CONTENT + "/ProfileRow/RenameProfile")
@onready var _delete_profile_button: Button = get_node(CONTENT + "/ProfileRow/DeleteProfile")
@onready var _open_button: Button = get_node(CONTENT + "/ProfileRow/OpenProfile")
@onready var _status: Label = get_node(CONTENT + "/Status")
@onready var _title_label: Label = $VBox/TopBar/HBox/AppTitle

var selected_user: String = ""
var selected_profile: String = ""

var _name_dialog: ConfirmationDialog
var _name_edit: LineEdit
var _confirm_dialog: ConfirmationDialog
var _action: Action = Action.NEW_USER


#* Translate the scene's own texts, before its children set theirs in their _ready():
func _enter_tree() -> void:
	CandyLocale.translate_scene(self)


func _ready() -> void:
	theme = CandyTheme.landing_theme
	_title_label.text = "Candy Dialogue Creator v" + CandyProfiles.VERSION
	_build_dialogs()

	_user_select.item_selected.connect(_on_user_selected)
	_new_user_button.pressed.connect(_start_action.bind(Action.NEW_USER))
	_rename_user_button.pressed.connect(_start_action.bind(Action.RENAME_USER))
	_delete_user_button.pressed.connect(_start_action.bind(Action.DELETE_USER))
	_new_profile_button.pressed.connect(_start_action.bind(Action.NEW_PROFILE))
	_rename_profile_button.pressed.connect(_start_action.bind(Action.RENAME_PROFILE))
	_delete_profile_button.pressed.connect(_start_action.bind(Action.DELETE_PROFILE))
	_open_button.pressed.connect(_open_selected)

	_tree.item_selected.connect(_on_tree_item_selected)
	_tree.item_activated.connect(_open_selected)
	_tree.nothing_selected.connect(_on_nothing_selected)

	$VBox/TopBar/HBox/WindowButtons.close_pressed.connect(_on_exit_pressed)

	CandyProfiles.profile_closed.connect(_on_profile_closed)

	var session := CandyProfiles.get_last_session()
	refresh_users(str(session.get("user", "")))
	_select_profile_in_tree(str(session.get("profile", "")))


#& Lists

func refresh_users(preferred: String = "") -> void:
	var users := CandyProfiles.list_users()
	_user_select.clear()
	for user in users:
		_user_select.add_item(user)

	if users.is_empty():
		selected_user = ""
	else:
		var wanted := selected_user
		if preferred != "":
			wanted = preferred
		var index := users.find(wanted)
		if index < 0:
			index = 0
		_user_select.select(index)
		selected_user = users[index]

	_user_select.disabled = users.is_empty()
	refresh_profiles()


func refresh_profiles() -> void:
	_tree.clear()
	selected_profile = ""

	_tree.columns = 3
	_tree.column_titles_visible = true
	_tree.hide_root = true
	_tree.select_mode = Tree.SELECT_ROW
	_tree.set_column_title(0, CandyLocale.t("Profile"))
	_tree.set_column_title(1, CandyLocale.t("Godot Project"))
	_tree.set_column_title(2, CandyLocale.t("Modified"))
	_tree.set_column_expand_ratio(0, 3)
	_tree.set_column_expand_ratio(1, 5)
	_tree.set_column_expand_ratio(2, 2)

	var root := _tree.create_item()
	for profile in CandyProfiles.list_profiles(selected_user):
		var path := CandyProfiles.settings_path(selected_user, profile)
		var data := CandyProfiles.read_settings_file(path)
		var item := _tree.create_item(root)
		item.set_text(0, profile)
		item.set_text(1, str(data.get("project_path", "")))
		item.set_text(2, _modified_text(path))
		item.set_tooltip_text(1, str(data.get("project_path", "")))
		item.set_metadata(0, profile)

	_update_buttons()


func _select_profile_in_tree(profile: String) -> void:
	if profile == "":
		return
	var item: TreeItem = null
	if _tree.get_root() != null:
		item = _tree.get_root().get_first_child()
	while item != null:
		if str(item.get_metadata(0)) == profile:
			item.select(0)
			_tree.scroll_to_item(item)
			return
		item = item.get_next()


func _modified_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "—"
	var stamp := Time.get_datetime_dict_from_unix_time(int(FileAccess.get_modified_time(path)))
	return "%04d-%02d-%02d %02d:%02d" % [stamp.year, stamp.month, stamp.day, stamp.hour, stamp.minute]


func _update_buttons() -> void:
	var has_user := selected_user != ""
	var has_profile := selected_profile != ""
	_rename_user_button.disabled = not has_user
	_delete_user_button.disabled = not has_user
	_new_profile_button.disabled = not has_user
	_rename_profile_button.disabled = not has_profile
	_delete_profile_button.disabled = not has_profile
	_open_button.disabled = not has_profile


#& Selection

func _on_user_selected(index: int) -> void:
	selected_user = _user_select.get_item_text(index)
	_set_status("")
	refresh_profiles()


func _on_tree_item_selected() -> void:
	var item := _tree.get_selected()
	if item != null:
		selected_profile = str(item.get_metadata(0))
	else:
		selected_profile = ""
	_update_buttons()


func _on_nothing_selected() -> void:
	_tree.deselect_all()
	selected_profile = ""
	_update_buttons()


func _open_selected() -> void:
	if selected_user == "" or selected_profile == "":
		return
	if CandyProfiles.open_profile(selected_user, selected_profile):
		visible = false
	else:
		_set_status(CandyLocale.t("Could not open that profile."))


func _on_profile_closed() -> void:
	visible = true
	refresh_users(CandyProfiles.current_user)


#& Dialogs

func _build_dialogs() -> void:
	_name_dialog = ConfirmationDialog.new()
	_name_dialog.title = CandyLocale.t("Name")
	_name_dialog.min_size = Vector2i(360, 0)
	var box := VBoxContainer.new()
	_name_dialog.add_child(box)
	_name_edit = LineEdit.new()
	_name_edit.custom_minimum_size.x = 320
	box.add_child(_name_edit)
	_name_dialog.register_text_enter(_name_edit)
	_name_dialog.confirmed.connect(_on_name_confirmed)
	add_child(_name_dialog)

	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.title = CandyLocale.t("Confirm")
	_confirm_dialog.confirmed.connect(_on_delete_confirmed)
	add_child(_confirm_dialog)


func _start_action(action: Action) -> void:
	_action = action
	_set_status("")
	match action:
		Action.NEW_USER:
			_prompt_name(CandyLocale.t("New User"), "")
		Action.RENAME_USER:
			if selected_user != "":
				_prompt_name(CandyLocale.t("Rename User"), selected_user)
		Action.NEW_PROFILE:
			if selected_user != "":
				_prompt_name(CandyLocale.t("New Project Profile"), "")
		Action.RENAME_PROFILE:
			if selected_profile != "":
				_prompt_name(CandyLocale.t("Rename Project Profile"), selected_profile)
		Action.DELETE_USER:
			if selected_user != "":
				_confirm(CandyLocale.t("Delete user \"%s\" and all of its project profiles and saves?") % selected_user)
		Action.DELETE_PROFILE:
			if selected_profile != "":
				_confirm(CandyLocale.t("Delete project profile \"%s\", including its settings and saves?") % selected_profile)


func _prompt_name(title: String, initial: String) -> void:
	_name_dialog.title = title
	_name_edit.text = initial
	_name_dialog.popup_centered()
	_name_edit.grab_focus()
	_name_edit.select_all()


func _confirm(message: String) -> void:
	_confirm_dialog.dialog_text = message
	_confirm_dialog.popup_centered()


func _on_name_confirmed() -> void:
	var new_name := _name_edit.text.strip_edges()
	var problem := CandyProfiles.validate_name(new_name)
	if _action == Action.NEW_PROFILE or _action == Action.RENAME_PROFILE:
		problem = CandyProfiles.validate_profile_name(new_name)
	if problem != "":
		_set_status(problem)
		return

	match _action:
		Action.NEW_USER:
			if CandyProfiles.create_user(new_name):
				refresh_users(new_name)
			else:
				_set_status(CandyLocale.t("A user called \"%s\" already exists.") % new_name)
		Action.RENAME_USER:
			if CandyProfiles.rename_user(selected_user, new_name):
				refresh_users(new_name)
			else:
				_set_status(CandyLocale.t("Could not rename that user."))
		Action.NEW_PROFILE:
			if CandyProfiles.create_profile(selected_user, new_name):
				refresh_profiles()
				_select_profile_in_tree(new_name)
			else:
				_set_status(CandyLocale.t("A profile called \"%s\" already exists for this user.") % new_name)
		Action.RENAME_PROFILE:
			if CandyProfiles.rename_profile(selected_user, selected_profile, new_name):
				refresh_profiles()
				_select_profile_in_tree(new_name)
			else:
				_set_status(CandyLocale.t("Could not rename that profile."))
		_:
			pass


func _on_delete_confirmed() -> void:
	match _action:
		Action.DELETE_USER:
			CandyProfiles.delete_user(selected_user)
			refresh_users()
		Action.DELETE_PROFILE:
			CandyProfiles.delete_profile(selected_user, selected_profile)
			refresh_profiles()
		_:
			pass


func _set_status(message: String) -> void:
	if message != "":
		_status.text = message
	else:
		_status.text = " "


#& Window buttons

func _on_exit_pressed() -> void:
	get_tree().quit()

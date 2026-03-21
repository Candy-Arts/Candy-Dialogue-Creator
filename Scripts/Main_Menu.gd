extends CanvasLayer

@onready var main = get_node("/root/UI")



func _on_new_dialogue_pressed() -> void:
	$"SaveCheck".visible = true


func _on_profiles_pressed() -> void:
	main.get_node("ProfileMenu").save_profile()
	main.get_node("ProfileMenu").visible = true
	candy_dc.editor_state = "profiles"


func _on_export_pressed() -> void:
	if candy_dc.project_path == "":
		main.get_node("ExportMenu/FileDialog").current_dir = ProjectSettings.globalize_path("user://Profiles".path_join(candy_dc.current_profile).path_join("Exported Dialogues"))
	else:
		main.get_node("ExportMenu/FileDialog").current_dir = candy_dc.project_path

	main.get_node("ExportMenu").spawn_convo_buttons()
	main.get_node("ExportMenu").visible = true
	candy_dc.editor_state = "export"


func _on_import_pressed() -> void:
	main.get_node("ImportMenu").open_import_menu()
	if candy_dc.project_path == "":
		main.get_node("ImportMenu/FileDialog").current_dir = ProjectSettings.globalize_path("user://Profiles".path_join(candy_dc.current_profile).path_join("Exported Dialogues"))
	else:
		main.get_node("ImportMenu/FileDialog").current_dir = candy_dc.project_path

	main.get_node("ImportMenu").visible = true
	candy_dc.editor_state = "import"


func _on_settings_pressed() -> void:
	main.get_node("SettingsMenu").setup_menu()
	main.get_node("SettingsMenu").visible = true
	candy_dc.editor_state = "settings"


func _on_close_pressed() -> void:
	self.visible = false
	candy_dc.editor_state = "ui"


func _on_save_confirm_cancel_pressed() -> void:
	$"SaveCheck".visible = false
	candy_dc.editor_state = "main_menu"


func _on_save_confirm_no_pressed() -> void:
	$"SaveCheck".visible = false
	self.visible = false
	main.new_dialogue()


func _on_save_confirm_yes_pressed() -> void:
	$"SaveCheck".visible = false
	self.visible = false
	main._on_save_pressed()

extends FileDialog


@onready var main = get_node("/root/MainUI")

var convert_mode := ""

func setup(new_mode: String) -> void:
	self.visible = true
	convert_mode = new_mode
	file_mode = FileDialog.FILE_MODE_OPEN_FILES
	filters = ["*.txt"]

	var start_path := ""
	match convert_mode:
		"Dialogue":
			var dialogue_path = globals.project_path.path_join(globals.custom_project_paths.get("Dialogues", ""))
			if globals.project_path != "" and DirAccess.dir_exists_absolute(dialogue_path):
				start_path = dialogue_path
		"Save":
			var saves_path = "user://Profiles"
			if DirAccess.dir_exists_absolute(saves_path):
				start_path = saves_path

		"Presets":
			var presets_path = "user://Profiles"
			if DirAccess.dir_exists_absolute(presets_path):
				start_path = presets_path	

	if start_path == "":
		start_path = "user://"

	current_dir = ProjectSettings.globalize_path(start_path)
	popup_centered()


func _on_file_selected(path: String) -> void:
	match convert_mode:
		"Dialogue":
			main.convert_dialogue_1_0_to_1_1([path])
		"Save":
			main.convert_saves_1_0_to_1_1([path])
		"Presets":
			main.convert_presets_1_0_to_1_1([path])

	globals.editor_state = "Main"


func _on_files_selected(paths: PackedStringArray) -> void:
	match convert_mode:
		"Dialogue":
			main.convert_dialogue_1_0_to_1_1(Array(paths))
		"Save":
			main.convert_saves_1_0_to_1_1(Array(paths))
		"Presets":
			main.convert_presets_1_0_to_1_1([paths])

	globals.editor_state = "Main"


func _on_canceled() -> void:
	self.visible = false




extends HBoxContainer

@onready var main = get_node("/root/MainUI")

@onready var label = get_node("HBox/Label")
@onready var input = get_node("HBox/LineEdit")

@export var path_key = ""
@export var label_text = ""


var titles = {
	"Dialogues": "Select Dialogues Folder:",

	"*Portraits": "Select Portraits Folder:",
	"*Busts": "Select Busts Folder:",
	"*Voice_Files": "Select Voice Files Folder:",
	"*Sprites": "Select Sprites Folder:",

	"Backgrounds": "Select Background Files Folder:",
	"Images": "Select Image Files Folder:",
	"Audio": "Select Audio Files Folder:",
	"Videos": "Select Video Files Folder:",

	"BG_Scenes": "Select Background Scenes Folder:",
	"VN_Scenes": "Select VN Scenes Folder:",
	"Player_Input_Scenes": "Select Input Scenes Folder:",
	"Choice_Menu_Scenes": "Select Choice Menu Scenes Folder:",
	"Choice_Category_Scenes": "Select Choice Category Scenes Folder:",
	"Choice_Button_Scenes": "Select Choice Button Scenes Folder:",
}


#* Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#% Set label text at start:
	label.text = label_text


#* Update the data in the input field from the globals script:
func update_data() -> void:
	input.text = globals.custom_project_paths[path_key]


#* Display the chosen project path in the input:
func set_path_text():
	input.text = globals.custom_project_paths[path_key]


#* Reset the path to Candy DE default:
func reset_path_text():
	input.text = globals.default_project_paths[path_key]
	globals.custom_project_paths[path_key] = globals.default_project_paths[path_key]


#* Type new path:
func _on_path_changed(new_text: String) -> void:
	globals.custom_project_paths[path_key] = new_text


#* Open the folder:
func _on_open_pressed() -> void:
	#@ Android safeguard:
	if OS.get_name() == "Android":
		main.show_warning("Opening folders in the file browser is not supported by Android.")
		return

	var folder_path = globals.project_path.path_join(globals.custom_project_paths.get(path_key, ""))
	if DirAccess.dir_exists_absolute(folder_path):
		OS.shell_open(ProjectSettings.globalize_path(folder_path))
	elif not DirAccess.dir_exists_absolute(globals.project_path):
		main.show_warning("The Project Path is incorrect.")
	else:
		main.show_warning("This subfolder doesn't exist.")


#* Open the file browser:
func _on_file_browser_pressed() -> void:
	main.path_dialogue.target_path = path_key

	#% Open to the project folder:
	if globals.project_path != "" and DirAccess.dir_exists_absolute(globals.project_path):
		main.path_dialogue.current_path = globals.project_path + "/"
		main.path_dialogue.root_subfolder = globals.project_path

	else:
		if globals.project_path == "":
			main.show_warning("[color=d0d400]Please provide a Project Path first.[/color]")
		else:
			main.show_warning("[color=d0d400]The Project Path you provided does not point to a valid folder.[/color]")
		return

	main.shield.visible = true
	main.path_dialogue.title = titles[path_key]
	main.path_dialogue.visible = true


#* Check that the path is valid:
func _on_line_edit_focus_exited() -> void:
	pass # Replace with function body.

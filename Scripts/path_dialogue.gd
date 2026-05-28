extends FileDialog

@onready var main = get_node("/root/MainUI")


var target_path = ""


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func _on_confirmed() -> void:
	if target_path == "Project":
		globals.project_path = main.path_dialogue.current_path

	else:
		var full = main.path_dialogue.current_path
		if full.begins_with(globals.project_path):
			globals.custom_project_paths[target_path] = full.trim_prefix(globals.project_path).trim_prefix("/")
		else:
			globals.custom_project_paths[target_path] = full

	main.path_dialogue.visible = false
	main.shield.visible = false
	main.settings_menu.setup()

func _on_close_requested() -> void:
	main.path_dialogue.visible = false
	main.shield.visible = false

func _on_canceled() -> void:
	main.path_dialogue.visible = false
	main.shield.visible = false

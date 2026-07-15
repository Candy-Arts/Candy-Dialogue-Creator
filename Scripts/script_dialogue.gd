extends FileDialog

@onready var main = get_node("/root/MainUI")

var target_script


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_canceled() -> void:
	main.script_dialogue.visible = false
	main.shield.visible = false


func _on_confirmed(_path: String) -> void:
	var path = current_path
	if not path.ends_with(".gd"):
		main.show_warning("A .gd script file is required.")
		return
	if globals.project_path == "":
		main.show_warning("No Project Path provided. Defaulting to main directory.")
		return
	elif not DirAccess.dir_exists_absolute(globals.project_path):
		main.show_warning("The Project Path is incorrect.")
		return
	var relative_path = path.trim_prefix(globals.project_path)
	if relative_path.begins_with("/"):
		relative_path = relative_path.substr(1)

	if target_script == main.settings_menu:
		main.settings_menu.symbol_script_path_field.text = relative_path
	else:
		target_script.get_node("VBox/Script/LineEdit").text = relative_path
	main.script_dialogue.visible = false
	main.shield.visible = false

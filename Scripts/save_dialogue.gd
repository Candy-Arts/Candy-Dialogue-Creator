extends FileDialog

@onready var main = get_node("/root/MainUI")

var save_mode: = -1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_file_selected(path: String) -> void:
	main._save_dialogue_to_txt(path, "Normal Save", save_mode)
	globals.editor_state = "Main"

func _on_confirmed() -> void:
	var path = main.save_dialogue.current_path
	if path == "" or DirAccess.dir_exists_absolute(path):
		return
	main._save_dialogue_to_txt(path, "Normal Save", save_mode)
	globals.editor_state = "Main"

func _on_close_requested() -> void:
	main.save_dialogue.visible = false
	main.shield.visible = false
	globals.editor_state = "Main"

func _on_canceled() -> void:
	main.save_dialogue.visible = false
	main.shield.visible = false
	globals.editor_state = "Main"

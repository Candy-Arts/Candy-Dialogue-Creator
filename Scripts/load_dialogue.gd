extends FileDialog

@onready var main = get_node("/root/MainUI")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_file_selected(path: String) -> void:
	main._load_dialogue_from_txt(path)
	globals.editor_state = "Main"

func _on_confirmed() -> void:
	var path = main.load_dialogue.current_path
	if path == "" or DirAccess.dir_exists_absolute(path):
		return
	main._load_dialogue_from_txt(path)
	globals.editor_state = "Main"

func _on_close_requested() -> void:
	main.load_dialogue.visible = false
	main.shield.visible = false
	globals.editor_state = "Main"

func _on_canceled() -> void:
	main.load_dialogue.visible = false
	main.shield.visible = false
	globals.editor_state = "Main"



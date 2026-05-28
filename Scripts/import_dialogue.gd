extends FileDialog

@onready var main = get_node("/root/MainUI")


func _on_file_selected(path: String) -> void:
	main.import_menu.file.text = path
	main.import_menu.load_file(path)
	visible = false
	main.shield.visible = false

func _on_confirmed() -> void:
	var path = current_path
	if path == "" or DirAccess.dir_exists_absolute(path):
		return
	main.import_menu.file.text = path
	main.import_menu.load_file(path)
	visible = false
	main.shield.visible = false

func _on_close_requested() -> void:
	visible = false
	main.shield.visible = false

func _on_canceled() -> void:
	visible = false
	main.shield.visible = false
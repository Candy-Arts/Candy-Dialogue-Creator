extends CanvasLayer

@onready var main = get_node("/root/UI")

var line_data

#* Close data editor:
func _on_data_editor_enter_pressed() -> void:
	self.visible = false
	candy_dc.editor_state = "ui"
	main._update_visible_lines()

func _on_data_text_changed() -> void:
	line_data["Data"] = $"Data".text

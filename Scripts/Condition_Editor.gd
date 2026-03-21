extends CanvasLayer

@onready var main = get_node("/root/UI")

var line_data

#* Close condition editor:
func _on_condition_editor_enter_pressed() -> void:
	self.visible = false
	candy_dc.editor_state = "ui"
	main._update_visible_lines()

func _on_condition_text_changed() -> void:
	if candy_dc.editor_state == "variable_editor":
		line_data["Expression"] = $"Condition".text

	elif candy_dc.editor_state == "condition_editor":
		line_data["Condition"] = $"Condition".text
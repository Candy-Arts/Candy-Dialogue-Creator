extends CanvasLayer

@onready var main = get_node("/root/UI")


var line_type = ""
var line_data



#* Setup:
func setup():
	match line_type:
		"Choice Status":
			$"PanelC/PanelC/VBox/Top/Title".text = "Choice Status Editor"
			
			$"PanelC/PanelC/VBox/Categories".visible = true
			$"PanelC/PanelC/VBox/CategoryTags".visible = true
			$"PanelC/PanelC/VBox/Choices".visible = true
			$"PanelC/PanelC/VBox/ChoiceTags".visible = true
			$"PanelC/PanelC/VBox/ChoiceStatus".visible = true
			$"PanelC/PanelC/VBox/Label".visible = true
			$"PanelC/PanelC/VBox/Tooltip".visible = true
			$"PanelC/PanelC/VBox/Timers".visible = false
			$"PanelC/PanelC/VBox/TimerTags".visible = false
			$"PanelC/PanelC/VBox/TimerStatus".visible = false

			$"PanelC/PanelC/VBox/MenuTags".text = line_data["Menu Tags"]
			$"PanelC/PanelC/VBox/CategoryTags".text = line_data["Category Tags"]
			$"PanelC/PanelC/VBox/ChoiceTags".text = line_data["Choice Tags"]
			$"PanelC/PanelC/VBox/Label".text = line_data["Label"]
			$"PanelC/PanelC/VBox/Tooltip".text = line_data["Tooltip"]

			_apply_option_value($"PanelC/PanelC/VBox/Menus/MenuMode", line_data, "Menu Mode")
			_apply_option_value($"PanelC/PanelC/VBox/Categories/CategoryMode", line_data, "Category Mode")
			_apply_option_value($"PanelC/PanelC/VBox/Choices/ChoiceMode", line_data, "Choice Mode")
			_apply_option_value($"PanelC/PanelC/VBox/ChoiceStatus/Enable", line_data, "Enable")
			_apply_option_value($"PanelC/PanelC/VBox/ChoiceStatus/Activate", line_data, "Activate")
			_apply_option_value($"PanelC/PanelC/VBox/ChoiceStatus/Show", line_data, "Show")

		"Timer Status":
			$"PanelC/PanelC/VBox/Top/Title".text = "Timer Status Editor"

			$"PanelC/PanelC/VBox/Categories".visible = false
			$"PanelC/PanelC/VBox/CategoryTags".visible = false
			$"PanelC/PanelC/VBox/Choices".visible = false
			$"PanelC/PanelC/VBox/ChoiceTags".visible = false
			$"PanelC/PanelC/VBox/ChoiceStatus".visible = false
			$"PanelC/PanelC/VBox/Label".visible = false
			$"PanelC/PanelC/VBox/Tooltip".visible = false
			$"PanelC/PanelC/VBox/Timers".visible = true
			$"PanelC/PanelC/VBox/TimerTags".visible = true
			$"PanelC/PanelC/VBox/TimerStatus".visible = true

			$"PanelC/PanelC/VBox/MenuTags".text = line_data["Menu Tags"]
			$"PanelC/PanelC/VBox/TimerTags".text = line_data["Timer Tags"]
			$"PanelC/PanelC/VBox/TimerStatus/Time".text = line_data["Time"]
			$"PanelC/PanelC/VBox/TimerStatus/Loop".text = line_data["Loop"]

			_apply_option_value($"PanelC/PanelC/VBox/Menus/MenuMode", line_data, "Menu Mode")
			_apply_option_value($"PanelC/PanelC/VBox/Timers/TimerMode", line_data, "Timer Mode")
			_apply_option_value($"PanelC/PanelC/VBox/TimerStatus/TimerNode", line_data, "Timer Node")
			_apply_option_value($"PanelC/PanelC/VBox/TimerStatus/TimerStatus", line_data, "Status")



#* Close menu:
func _on_close_pressed() -> void:
	self.visible = false
	candy_dc.editor_state = "ui"

	#% Refresh main UI lines:
	main._load_active_block()


#* Targeting logic:
func _on_menu_mode_item_selected(index: int) -> void:
	var mode_button = $"PanelC/PanelC/VBox/Menus/MenuMode"
	var mode = mode_button.get_item_text(index)
	line_data["Menu Mode"] = mode

func _on_menu_tags_text_changed() -> void:
	line_data["Menu Tags"] = $"PanelC/PanelC/VBox/MenuTags".text

func _on_category_mode_item_selected(index: int) -> void:
	var mode_button = $"PanelC/PanelC/VBox/Categories/CategoryMode"
	var mode = mode_button.get_item_text(index)
	line_data["Category Mode"] = mode

func _on_category_tags_text_changed() -> void:
	line_data["Category Tags"] = $"PanelC/PanelC/VBox/CategoryTags".text

func _on_choice_mode_item_selected(index: int) -> void:
	var mode_button = $"PanelC/PanelC/VBox/Choices/ChoiceMode"
	var mode = mode_button.get_item_text(index)
	line_data["Choice Mode"] = mode

func _on_choice_tags_text_changed() -> void:
	line_data["Choice Tags"] = $"PanelC/PanelC/VBox/ChoiceTags".text

func _on_timer_mode_item_selected(index: int) -> void:
	var mode_button = $"PanelC/PanelC/VBox/Timers/TimerMode"
	var mode = mode_button.get_item_text(index)
	line_data["Timer Mode"] = mode

func _on_timer_tags_text_changed() -> void:
	line_data["Timer Tags"] = $"PanelC/PanelC/VBox/TimerTags".text


#* Choice status:
func _on_enable_item_selected(index: int) -> void:
	var status_button = $"PanelC/PanelC/VBox/ChoiceStatus/Enable"
	var status = status_button.get_item_text(index)
	line_data["Enable"] = status

func _on_activate_item_selected(index: int) -> void:
	var status_button = $"PanelC/PanelC/VBox/ChoiceStatus/Activate"
	var status = status_button.get_item_text(index)
	line_data["Activate"] = status

func _on_show_item_selected(index: int) -> void:
	var status_button = $"PanelC/PanelC/VBox/ChoiceStatus/Show"
	var status = status_button.get_item_text(index)
	line_data["Show"] = status


#* Choice label:
func _on_label_text_changed(new_text: String) -> void:
	line_data["Label"] = new_text

#* Choice tooltip:
func _on_tooltip_text_changed() -> void:
	line_data["Tooltip"] = $"PanelC/PanelC/VBox/Tooltip".text


#* Timer status:
func _on_timer_node_item_selected(index: int) -> void:
	var status_button = $"PanelC/PanelC/VBox/TimerStatus/TimerNode"
	var status = status_button.get_item_text(index)
	line_data["Timer Node"] = status

func _on_time_text_changed(new_text: String) -> void:
	line_data["Time"] = new_text

func _on_loop_text_changed(new_text: String) -> void:
	line_data["Loop"] = new_text

func _on_timer_status_item_selected(index: int) -> void:
	var status_button = $"PanelC/PanelC/VBox/TimerStatus/TimerStatus"
	var status = status_button.get_item_text(index)
	line_data["Status"] = status


#* Universal helper for restoring OptionButtons from dictionary data:
func _apply_option_value(btn: OptionButton, data: Dictionary, key: String) -> void:
	if btn == null:
		return

	#% 1) Reset any stale label/selection:
	btn.select(-1)
	btn.text = ""

	#% 2) Get stored value and reselect if present:
	if not data.has(key):
		return
	var value := str(data[key])
	if value == "":
		return

	for i in range(btn.item_count):
		if btn.get_item_text(i) == value:
			btn.select(i)
			break






















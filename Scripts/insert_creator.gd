extends PanelContainer

@onready var main = get_node("/root/MainUI")

@onready var title = get_node("Menu/VBox/Label")
@onready var insert_name = get_node("Menu/VBox/InsertName")
@onready var type_button = get_node("Menu/VBox/OptionButton")
@onready var category_field = get_node("Menu/VBox/Category")
@onready var before_field = get_node("Menu/VBox/BeforeString")
@onready var after_field = get_node("Menu/VBox/AfterString")
@onready var create_button = get_node("Menu/VBox/Buttons/Create")


var current_mode = ""
var current_insert = ""
var current_insert_category = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func setup(mode: String, category: String = "", insert: String = "") -> void:
	globals.editor_state = "Insert Creator"
	current_mode = mode
	current_insert = insert
	current_insert_category = category
	match current_mode:
		"New":
			title.text = "Create Insert"
			type_button.selected = 0
			category_field.text = category
			insert_name.text = ""
			before_field.text = ""
			after_field.text = ""
			create_button.text = "Create"
		"Edit":
			title.text = "Edit Insert"
			create_button.text = "Confirm"
			insert_name.text = current_insert
			var insert_data = {}
			if globals.profile_inserts.has(category) and globals.profile_inserts[category].has(insert):
				type_button.selected = 0
				insert_data = globals.profile_inserts[category][insert]
			elif globals.user_inserts.has(category) and globals.user_inserts[category].has(insert):
				type_button.selected = 1
				insert_data = globals.user_inserts[category][insert]
			category_field.text = category
			before_field.text = insert_data.get("Before", "")
			after_field.text = insert_data.get("After", "")
	self.visible = true


func clear():
	category_field.text = ""
	before_field.text = ""
	after_field.text = ""


func _on_create_pressed() -> void:
	var target = globals.profile_inserts if type_button.selected == 0 else globals.user_inserts
	var insert_data = {
		"Before": before_field.text,
		"After": after_field.text
	}
	var category = category_field.text
	var new_name = insert_name.text

	match current_mode:
		"New":
			if not target.has(category):
				target[category] = {}
			target[category][new_name] = insert_data
		"Edit":
			#% Remove old entry:
			var old_target = globals.profile_inserts if type_button.selected == 0 else globals.user_inserts
			if old_target.has(current_insert_category):
				old_target[current_insert_category].erase(current_insert)
				if old_target[current_insert_category].is_empty():
					old_target.erase(current_insert_category)
			#% Add new entry:
			if not target.has(category):
				target[category] = {}
			target[category][new_name] = insert_data

	main.save_undo_step()
	self.visible = false
	clear()
	main.refresh_insert_lists()
	main.export_user_inserts()
	main.export_profile_inserts()
	globals.editor_state = "Main"

func _on_cancel_pressed() -> void:
	self.visible = false
	current_mode = ""
	current_insert = ""
	clear()
	globals.editor_state = "Main"

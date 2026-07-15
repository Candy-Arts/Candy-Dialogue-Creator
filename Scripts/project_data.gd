extends PanelContainer

@onready var main = get_node("/root/MainUI")

@onready var project_title = get_node("VBox/Label")
@onready var project_script = get_node("VBox/Script/LineEdit")
@onready var project_variable = get_node("VBox/Variable/LineEdit")
@onready var project_data = get_node("VBox/Data/TextEdit")



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func save_data() -> void:
	var key = get_meta("project_data_key")
	globals.project_scripts[key]["Script"] = project_script.text
	globals.project_scripts[key]["Variable"] = project_variable.text
	globals.project_scripts[key]["Data"] = project_data.text


func load_data() -> void:
	var key = get_meta("project_data_key")
	project_script.text = globals.project_scripts[key]["Script"]
	project_variable.text = globals.project_scripts[key]["Variable"]
	project_data.text = globals.project_scripts[key]["Data"]
	project_title.text = key


func _on_import_pressed() -> void:
	#@ Step 1 - Retrieve script path and variable name:
	var script_path = project_script.text.strip_edges()
	var var_name = project_variable.text.strip_edges()
	if script_path == "" or var_name == "":
		return

	var full_path = globals.project_path.path_join(script_path)
	if not FileAccess.file_exists(full_path):
		push_error("Script file not found: " + full_path)
		return

	#@ Step 2 - Read script contents:
	var file := FileAccess.open(full_path, FileAccess.READ)
	if not file:
		push_error("Failed to open file: " + full_path)
		return
	var content := file.get_as_text()
	file.close()

	#@ Step 3 - Find the dictionary or array definition:
	var regex_dict := RegEx.new()
	regex_dict.compile("var\\s+" + var_name + "\\s*=\\s*\\{([\\s\\S]*)\\}")
	var regex_array := RegEx.new()
	regex_array.compile("var\\s+" + var_name + "\\s*=\\s*\\[([\\s\\S]*)\\]")

	var result_dict := regex_dict.search(content)
	var result_array := regex_array.search(content)

	var data_str := ""
	if result_dict:
		data_str = "{" + result_dict.get_string(1) + "}"
	elif result_array:
		data_str = "[" + result_array.get_string(1) + "]"
	else:
		push_error("Variable not found or unsupported format: " + var_name)
		return

	#@ Step 4 - Sanitize:
	var ascii_hash := "\u0023"
	var full_hash := "\uFF03"

	var clean_lines := []
	for line in data_str.split("\n"):
		var cut := line
		cut = cut.split("%s/" % ascii_hash)[0]
		cut = cut.split("%s" % ascii_hash)[0]
		cut = cut.split("%s/" % full_hash)[0]
		cut = cut.split("%s" % full_hash)[0]
		cut = cut.split("//")[0]
		clean_lines.append(cut)
	data_str = "\n".join(clean_lines)

	data_str = data_str.replace("\r", "")
	data_str = data_str.replace("\t", "")
	data_str = data_str.replace(",\n\t}", "\n}")
	data_str = data_str.replace(",\n}", "\n}")
	data_str = data_str.replace(", }", "}")
	data_str = data_str.replace(",}", "}")
	data_str = data_str.replace(", ]", "]")
	data_str = data_str.replace(",]", "]")

	var open_brace := data_str.count("{")
	var close_brace := data_str.count("}")
	var open_bracket := data_str.count("[")
	var close_bracket := data_str.count("]")

	if open_brace > close_brace:
		data_str += "}"
	if open_bracket > close_bracket:
		data_str += "]"

	#@ Step 5 - Parse:
	var expr := Expression.new()
	var parse_error := expr.parse(data_str, [])
	if parse_error != OK:
		push_error("Failed to parse structure: " + var_name)
		return

	var eval_result = expr.execute()
	var entries: Array = []

	if typeof(eval_result) == TYPE_DICTIONARY:
		entries = eval_result.keys()
	elif typeof(eval_result) == TYPE_ARRAY:
		for item in eval_result:
			entries.append(str(item))
	else:
		push_error("Parsed variable is neither Dictionary nor Array: " + var_name)
		return

	#@ Step 6 - Append new entries to project_data:
	var existing = []
	if project_data.text.strip_edges() != "":
		for item in project_data.text.strip_edges().trim_suffix(",").strip_edges().split(","):
			existing.append(item.strip_edges())

	for entry in entries:
		if not (str(entry) in existing):
			existing.append(str(entry))

	project_data.text = ", ".join(existing)


#* Open a file dialogue menu to select the script:
func _on_browse_pressed() -> void:
	main.script_dialogue.target_script = self
	if globals.project_path != "" and DirAccess.dir_exists_absolute(globals.project_path):
		main.script_dialogue.current_path = globals.project_path + "/"
		main.script_dialogue.root_subfolder = globals.project_path
	else:
		main.script_dialogue.current_path = "user://"
	main.shield.visible = true
	main.script_dialogue.visible = true

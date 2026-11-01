#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyDialogueHistory
extends RefCounted

signal changed

enum Kind { STRUCTURE, LINE }

#^ Older steps are dropped past this many:
const MAX_STEPS := 200

var _model: CandyDialogueModel
var _undo: Array = []    #/ Steps, oldest first
var _redo: Array = []    #/ Steps, the next to redo last
var _group_depth := 0
var _group_label := ""
var _group_typing_id := 0
#^ The open group's step, once its first edit is recorded:
var _group_step: Dictionary = {}


func _init(model: CandyDialogueModel) -> void:
	_model = model


#& Reading

func can_undo() -> bool:
	return not _undo.is_empty()


func can_redo() -> bool:
	return not _redo.is_empty()


#* List the labels undo() would undo, next first:
func undo_labels() -> Array:
	var labels: Array = []
	for i in range(_undo.size() - 1, -1, -1):
		labels.append(_undo[i]["label"])
	return labels


#* List the labels redo() would redo, next first:
func redo_labels() -> Array:
	var labels: Array = []
	for i in range(_redo.size() - 1, -1, -1):
		labels.append(_redo[i]["label"])
	return labels


#& Recording

#* Record the structure before an edit to conversations, blocks or line lists:
#? view: the reference of the view the edit is made from.
func record_structure(label: String, view: String) -> void:
	var step := _current_step(label, view)
	for record in step["records"]:
		if record["kind"] == Kind.STRUCTURE:
			return
	step["records"].append({
		"kind": Kind.STRUCTURE,
		"dialogue": _copy_structure(_model.dialogue),
		"presets": _copy_structure(_model.presets),
	})


#* Record a top-level line before an edit inside it:
func record_line(line: Dictionary, label: String, view: String) -> void:
	var step := _current_step(label, view)
	for record in step["records"]:
		if record["kind"] == Kind.LINE and is_same(record["line"], line):
			return
	step["records"].append({"kind": Kind.LINE, "line": line, "data": line.duplicate(true)})


#* Note the blocks the last step renamed or moved:
func note_renames(renames: Array) -> void:
	if _undo.is_empty():
		return
	_undo[_undo.size() - 1]["renames"].append_array(renames.duplicate(true))


#* Open a step every edit joins until the matching end_step() (groups nest):
#? label "": the first edit's.
func begin_step(label: String = "", typing_id: int = 0) -> void:
	if _group_depth == 0:
		_group_label = label
		_group_step = {}
		_group_typing_id = typing_id
		#% A typing_id equal to the last step's continues it (if nothing was undone since):
		if typing_id != 0 and _redo.is_empty() and not _undo.is_empty() \
				and _undo[_undo.size() - 1]["typing_id"] == typing_id:
			_group_step = _undo[_undo.size() - 1]
			#Ł Not done after all - retake its "after" state:
			_group_step["after"] = {}
			changed.emit()
	_group_depth += 1


func end_step() -> void:
	if _group_depth == 0:
		return
	_group_depth -= 1
	if _group_depth == 0:
		_group_step = {}
		_group_typing_id = 0


func clear() -> void:
	if _undo.is_empty() and _redo.is_empty():
		return
	_undo.clear()
	_redo.clear()
	_group_step = {}
	changed.emit()


#* Get the step an edit records into (the open group's, or a new one):
func _current_step(label: String, view: String) -> Dictionary:
	if _group_depth > 0:
		if _group_step.is_empty():
			var group_label := _group_label
			if group_label == "":
				group_label = label
			_group_step = _push(group_label, view)
			_group_step["typing_id"] = _group_typing_id
		return _group_step
	return _push(label, view)


#* Take the last step's "after" state, if not taken yet:
#! Call before selection changes and new steps.
func seal() -> void:
	#% Not mid-group - its edits aren't done:
	if _group_depth == 0:
		_seal_last()


func _seal_last() -> void:
	if _undo.is_empty():
		return
	var step: Dictionary = _undo[_undo.size() - 1]
	if step["after"].is_empty():
		step["after"] = _model.selection_state(step["reference"])


#* Push a new step (sealing the last, clearing redo):
func _push(label: String, view: String) -> Dictionary:
	_seal_last()
	var step := {"label": label, "reference": view, "records": [], "renames": [],
		"before": _model.selection_state(view), "after": {}, "typing_id": 0}
	_undo.append(step)
	while _undo.size() > MAX_STEPS:
		_undo.remove_at(0)
	_redo.clear()
	changed.emit()
	return step


#& Undo and redo

#* Undo the last step and return it ({} if none):
func undo() -> Dictionary:
	if _undo.is_empty() or _group_depth > 0:
		return {}
	seal()
	var step: Dictionary = _undo.pop_back()
	var records: Array = step["records"]
	for i in range(records.size() - 1, -1, -1):
		_swap(records[i])
	_redo.append(step)
	changed.emit()
	return step


#* Redo the last undone step and return it ({} if none):
func redo() -> Dictionary:
	if _redo.is_empty() or _group_depth > 0:
		return {}
	var step: Dictionary = _redo.pop_back()
	for record in step["records"]:
		_swap(record)
	_undo.append(step)
	changed.emit()
	return step


func _swap(record: Dictionary) -> void:
	if record["kind"] == Kind.STRUCTURE:
		var dialogue: Dictionary = _model.dialogue
		var presets: Dictionary = _model.presets
		_model.dialogue = record["dialogue"]
		_model.presets = record["presets"]
		record["dialogue"] = dialogue
		record["presets"] = presets
		return

	var line: Dictionary = record["line"]
	var stored: Dictionary = record["data"]
	var current := line.duplicate(true)
	#Ł Editor data isn't the dialogue's - keep it as it is now:
	var meta = _model.line_data(line).get(CandyDialogueModel.META_KEY)
	line.clear()
	for key in stored:
		line[key] = stored[key]
	var data := _model.line_data(line)
	if meta != null:
		data[CandyDialogueModel.META_KEY] = meta
	else:
		data.erase(CandyDialogueModel.META_KEY)
	record["data"] = current


#* Copy a { conversation = { block = { "Text" = [lines] } } } tree down to its line lists:
func _copy_structure(tree: Dictionary) -> Dictionary:
	var result := {}
	for conversation in tree:
		var blocks = tree[conversation]
		if not blocks is Dictionary:
			result[conversation] = _copy_value(blocks)
			continue
		var blocks_copy := {}
		for block in blocks:
			var block_data = blocks[block]
			if not block_data is Dictionary:
				blocks_copy[block] = _copy_value(block_data)
				continue
			var block_copy := {}
			for key in block_data:
				#? The lists hold the same line dictionaries.
				if str(key) == CandyDialogueModel.TEXT_KEY and block_data[key] is Array:
					block_copy[key] = block_data[key].duplicate()
				else:
					block_copy[key] = _copy_value(block_data[key])
			blocks_copy[block] = block_copy
		result[conversation] = blocks_copy
	return result


func _copy_value(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value

#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyDialogueMerge

enum Mode { OVERWRITE, ADD, UPDATE, ADD_UPDATE }
enum Unit { CONVERSATIONS, BLOCKS }

#^ What a merge does to one conversation or block:
enum Status {
	NEW,              #/ Written, the target didn't have it
	REPLACED,         #/ Written over the target's
	UPDATED,          #/ A conversation some of whose blocks change
	UNCHANGED,        #/ A checked conversation none of whose blocks change
	REMOVED,          #/ The target's, taken out
	SKIPPED_EXISTS,   #/ Checked, not written: the target has it (Add)
	SKIPPED_MISSING,  #/ Checked, not written: the target lacks it (Update)
	NOT_INCLUDED,     #/ Not checked
	KEPT,             #/ Only in the target, left as it is
}

#^ Settings values, by Mode and Unit:
const MODE_IDS := ["overwrite", "add", "update", "add_update"]
const MODE_LABELS := ["Overwrite", "Add", "Update", "Add & Update"]  #/ translatable
const UNIT_IDS := ["conversations", "blocks"]
const UNIT_LABELS := ["Conversations", "Blocks"]  #/ translatable


static func run(target: Dictionary, source: Dictionary, selection: Dictionary, mode: int, unit: int, build: bool) -> Dictionary:
	#Ł What the source writes, { conversation = { block = true } }, and which conversations are whole:
	var written := {}
	var whole := {}
	for conversation in source:
		if not selection.has(conversation):
			continue
		var chosen := _chosen_blocks(source, selection, conversation)
		var in_target := target.has(conversation)
		if mode == Mode.OVERWRITE:
			whole[conversation] = true
			written[conversation] = _as_set(chosen)
		elif unit == Unit.CONVERSATIONS or not in_target:
			if _writes(mode, in_target):
				whole[conversation] = true
				written[conversation] = _as_set(chosen)
		else:
			var blocks := {}
			for block in chosen:
				if _writes(mode, _blocks_of(target, conversation).has(block)):
					blocks[block] = true
			if not blocks.is_empty():
				written[conversation] = blocks

	var result := {}
	if build:
		result = _build(target, source, written, whole, mode)
	return {"result": result, "rows": _rows(target, source, selection, written, whole, mode, unit)}


#* Get the selected part of the source, sharing its data:
static func selected_part(source: Dictionary, selection: Dictionary) -> Dictionary:
	var part := {}
	for conversation in source:
		if not selection.has(conversation):
			continue
		part[conversation] = {}
		var blocks := _blocks_of(source, conversation)
		for block in _chosen_blocks(source, selection, conversation):
			part[conversation][block] = blocks[block]
	return part


#* Count rows per Status:
static func count(rows: Array) -> Dictionary:
	var conversations := {}
	var blocks := {}
	for row in rows:
		conversations[row["status"]] = int(conversations.get(row["status"], 0)) + 1
		for block_row in row["blocks"]:
			blocks[block_row["status"]] = int(blocks.get(block_row["status"], 0)) + 1
	return {"conversations": conversations, "blocks": blocks}


#& Internals

#* Check whether a mode writes something the target has (or lacks):
static func _writes(mode: int, in_target: bool) -> bool:
	match mode:
		Mode.ADD:
			return not in_target
		Mode.UPDATE:
			return in_target
	return true


static func _blocks_of(dialogue: Dictionary, conversation: String) -> Dictionary:
	var blocks = dialogue.get(conversation)
	if blocks is Dictionary:
		return blocks
	return {}


#* Get a source conversation's checked blocks, in the source's order:
static func _chosen_blocks(source: Dictionary, selection: Dictionary, conversation: String) -> Array:
	var checked = selection.get(conversation, [])
	var chosen: Array = []
	if not checked is Array:
		return chosen
	for block in _blocks_of(source, conversation):
		if checked.has(block):
			chosen.append(block)
	return chosen


static func _as_set(names: Array) -> Dictionary:
	var result := {}
	for item in names:
		result[item] = true
	return result


static func _build(target: Dictionary, source: Dictionary, written: Dictionary, whole: Dictionary, mode: int) -> Dictionary:
	var result := {}
	if mode != Mode.OVERWRITE:
		for conversation in target:
			result[conversation] = _blocks_of(target, conversation).duplicate()
	for conversation in source:
		if not written.has(conversation):
			continue
		#? Assigning an existing key keeps its place.
		if whole.has(conversation):
			result[conversation] = {}
		var blocks := _blocks_of(source, conversation)
		for block in blocks:
			if written[conversation].has(block):
				var data = blocks[block]
				if data is Dictionary:
					data = data.duplicate(true)
				result[conversation][block] = data
	return result


static func _rows(target: Dictionary, source: Dictionary, selection: Dictionary, written: Dictionary, whole: Dictionary, mode: int, unit: int) -> Array:
	var rows: Array = []
	var names: Array = source.keys()
	for conversation in target:
		if not source.has(conversation):
			names.append(conversation)
	for conversation in names:
		var in_source := source.has(conversation)
		var status := _conversation_status(conversation, in_source, target.has(conversation),
			selection.has(conversation), written, whole, mode, unit)
		var block_names: Array = _blocks_of(source, conversation).keys()
		for block in _blocks_of(target, conversation):
			if not block_names.has(block):
				block_names.append(block)
		var block_rows: Array = []
		for block in block_names:
			block_rows.append({
				"name": block,
				"status": _block_status(conversation, block, source, target, selection, written, whole, mode, unit, status),
				"in_source": _blocks_of(source, conversation).has(block),
			})
		rows.append({"name": conversation, "status": status, "in_source": in_source, "blocks": block_rows})
	return rows


static func _conversation_status(conversation: String, in_source: bool, in_target: bool, selected: bool, written: Dictionary, whole: Dictionary, mode: int, unit: int) -> int:
	if whole.has(conversation):
		if in_target:
			return Status.REPLACED
		return Status.NEW
	if in_target and mode == Mode.OVERWRITE:
		return Status.REMOVED
	if written.has(conversation):
		return Status.UPDATED
	if in_source and selected:
		if not in_target:
			return Status.SKIPPED_MISSING
		if unit == Unit.CONVERSATIONS:
			return Status.SKIPPED_EXISTS
		return Status.UNCHANGED
	if in_source:
		return Status.NOT_INCLUDED
	return Status.KEPT


static func _block_status(conversation: String, block: String, source: Dictionary, target: Dictionary, selection: Dictionary, written: Dictionary, whole: Dictionary, mode: int, unit: int, conversation_status: int) -> int:
	var in_source := _blocks_of(source, conversation).has(block)
	var in_target := _blocks_of(target, conversation).has(block)
	var selected := in_source and _chosen_blocks(source, selection, conversation).has(block)
	if written.get(conversation, {}).has(block):
		if in_target:
			return Status.REPLACED
		return Status.NEW
	var kept := in_target and mode != Mode.OVERWRITE and not whole.has(conversation)
	if in_target and not kept:
		return Status.REMOVED
	if selected:
		#% Unit is conversations - blocks follow their conversation:
		if unit == Unit.CONVERSATIONS and mode != Mode.OVERWRITE:
			return conversation_status
		if in_target:
			return Status.SKIPPED_EXISTS
		return Status.SKIPPED_MISSING
	if in_source:
		return Status.NOT_INCLUDED
	return Status.KEPT

#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandySettingsDraft
extends RefCounted

#^ Marks a pending removal (a StringName no setting is ever written as):
const _ERASED := &"__candy_draft_erased__"

var _pending: Dictionary = {}


func clear() -> void:
	_pending.clear()


func is_dirty() -> bool:
	return not _pending.is_empty()


func get_value(key: String, default_value: Variant = null) -> Variant:
	if _pending.has(key):
		if _is_erased(_pending[key]):
			return default_value
		return _pending[key]

	var parts := key.split("/", false)
	var value = _base(parts[0], null)
	for i in range(1, parts.size()):
		if value is Dictionary and value.has(parts[i]):
			value = value[parts[i]]
		else:
			return default_value
	if value != null:
		return value
	return default_value


#* Check whether a key will have a value once applied:
func has_value(key: String) -> bool:
	var parts := key.split("/", false)
	if parts.size() == 1:
		return get_value(key) != null
	#% Nested - through get_dictionary(), so a replaced dictionary counts:
	var current: Variant = get_dictionary(parts[0])
	for i in range(1, parts.size()):
		if not current is Dictionary or not current.has(parts[i]):
			return false
		current = current[parts[i]]
	return current != null


func set_value(key: String, value: Variant) -> void:
	_pending[key] = value


#* Remove a nested key on apply ("theme_overrides/candy_dark/accent"):
func erase_value(key: String) -> void:
	_pending[key] = _ERASED


#* Replace a whole dictionary setting, dropping its pending nested edits:
func replace_dictionary(key: String, value: Dictionary) -> void:
	var prefix := key + "/"
	for pending_key in _pending.keys():
		if str(pending_key).begins_with(prefix):
			_pending.erase(pending_key)
	_pending[key] = value.duplicate(true)


#* Get a dictionary setting as it will be once applied:
func get_dictionary(key: String) -> Dictionary:
	var result: Dictionary = {}
	#@ Step 1 - The profile's, or its replacement:
	var stored = _base(key, {})
	if stored is Dictionary:
		result = stored.duplicate(true)
	#@ Step 2 - Pending nested edits:
	var prefix := key + "/"
	for pending_key in _pending:
		if not str(pending_key).begins_with(prefix):
			continue
		var parts := str(pending_key).substr(prefix.length()).split("/", false)
		if parts.is_empty():
			continue
		if _is_erased(_pending[pending_key]):
			_remove(result, parts)
		else:
			_assign(result, parts, _pending[pending_key])
	return result


func get_color(key: String, default_value: Color = Color.WHITE) -> Color:
	var value = get_value(key, null)
	if value is Color:
		return value
	if value is String:
		var parsed = str_to_var(value)
		if parsed is Color:
			return parsed
	return default_value


#* Write everything to the profile, then save the file once:
func apply() -> void:
	if _pending.is_empty():
		return

	#Ł Group nested keys, so each dictionary is rebuilt once:
	var groups: Dictionary = {}
	for key in _pending:
		var parts := str(key).split("/", false)
		if parts.size() == 1:
			if not _is_erased(_pending[key]):
				CandyProfiles.set_setting(parts[0], _pending[key], false)
			continue
		if not groups.has(parts[0]):
			var existing = _base(parts[0], {})
			if existing is Dictionary:
				groups[parts[0]] = existing.duplicate(true)
			else:
				groups[parts[0]] = {}
		if _is_erased(_pending[key]):
			_remove(groups[parts[0]], parts.slice(1))
		else:
			_assign(groups[parts[0]], parts.slice(1), _pending[key])

	for top_key in groups:
		CandyProfiles.set_setting(top_key, groups[top_key], false)

	_pending.clear()
	CandyProfiles.save_settings()


func discard() -> void:
	_pending.clear()


#* Get a top-level setting before its nested edits:
func _base(top_key: String, default_value: Variant) -> Variant:
	if _pending.has(top_key):
		if _is_erased(_pending[top_key]):
			return default_value
		return _pending[top_key]			#/ See replace_dictionary()
	return CandyProfiles.get_setting(top_key, default_value)


func _assign(container: Dictionary, path: PackedStringArray, value: Variant) -> void:
	var current := container
	for i in path.size() - 1:
		if not current.get(path[i]) is Dictionary:
			current[path[i]] = {}
		current = current[path[i]]
	current[path[path.size() - 1]] = value


func _remove(container: Dictionary, path: PackedStringArray) -> void:
	var current := container
	for i in path.size() - 1:
		if not current.get(path[i]) is Dictionary:
			return
		current = current[path[i]]
	current.erase(path[path.size() - 1])


func _is_erased(value: Variant) -> bool:
	return value is StringName and value == _ERASED

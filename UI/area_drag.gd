#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyAreaDrag
extends RefCounted

#^ The keys held while dropping to copy or swap (Settings > UI > Editor):
const COPY_KEY_SETTING := "layout_drag_copy_key"
const SWAP_KEY_SETTING := "layout_drag_swap_key"
const DEFAULT_COPY_KEY := "ctrl"
const DEFAULT_SWAP_KEY := "alt"
const KEYS := {"ctrl": KEY_CTRL, "alt": KEY_ALT, "shift": KEY_SHIFT, "meta": KEY_META}
const KEY_LABELS := {"ctrl": "Ctrl", "alt": "Alt", "shift": "Shift", "meta": "Meta (Super / Cmd)"}      #/ translatable
const KEY_NAMES := {"ctrl": "Ctrl", "alt": "Alt", "shift": "Shift", "meta": "Meta"}      #/ translatable

#^ What a drop does, shown on the Area it would go to:
const ACTION_REPLACE := "Replace"      #/ translatable
const ACTION_MOVE := "Move here"      #/ translatable
const ACTION_COPY_REPLACE := "Replace with a copy"      #/ translatable
const ACTION_COPY := "Copy here"      #/ translatable
const ACTION_SWAP := "Swap"      #/ translatable

const DATA_KEY := "candy_area_drag"

#^ title_of(area) -> String: the dragged Area's name, under the pointer:
var title_of: Callable
#^ allows(source, target, zone, mode) -> bool:
var allows: Callable
#^ drop(source, target, zone, mode):
var drop: Callable


#* One layout's drags: Areas only drop on Areas of the same CandyAreaDrag:
func _init(p_title_of: Callable, p_allows: Callable, p_drop: Callable) -> void:
	title_of = p_title_of
	allows = p_allows
	drop = p_drop


func drag_data(area: CandyAreaData) -> Dictionary:
	return {DATA_KEY: self, "area": area}


#* The dragged Area, if data is a drag of this layout, else null:
func source_of(data: Variant) -> CandyAreaData:
	if data is Dictionary and data.get(DATA_KEY) == self:
		return data.get("area")
	return null


#* What a drop on a zone does, with the keys held now:
#? The copy key wins over the swap key, and swapping is only on an Area (CENTER).
static func current_mode(zone: CandyAreaDrop.Zone) -> CandyAreaDrop.Mode:
	if _is_held(COPY_KEY_SETTING, DEFAULT_COPY_KEY):
		return CandyAreaDrop.Mode.COPY
	if zone == CandyAreaDrop.Zone.CENTER and _is_held(SWAP_KEY_SETTING, DEFAULT_SWAP_KEY):
		return CandyAreaDrop.Mode.SWAP
	return CandyAreaDrop.Mode.MOVE


static func _is_held(setting: String, default_key: String) -> bool:
	var key: String = str(CandyProfiles.get_setting(setting, default_key))
	return Input.is_key_pressed(KEYS.get(key, KEYS[default_key]))


static func action_label(zone: CandyAreaDrop.Zone, mode: CandyAreaDrop.Mode) -> String:
	if mode == CandyAreaDrop.Mode.SWAP:
		return CandyLocale.t(ACTION_SWAP)
	if zone == CandyAreaDrop.Zone.CENTER:
		if mode == CandyAreaDrop.Mode.COPY:
			return CandyLocale.t(ACTION_COPY_REPLACE)
		return CandyLocale.t(ACTION_REPLACE)
	if mode == CandyAreaDrop.Mode.COPY:
		return CandyLocale.t(ACTION_COPY)
	return CandyLocale.t(ACTION_MOVE)


#* The Area button's tooltip line about dragging, with the keys set now:
static func hint() -> String:
	return CandyLocale.t("Drag onto another area to replace it, or near one of its sides to put it beside it.\nHold {copy_key} to copy instead of moving, {swap_key} to swap the two.").format({
		"copy_key": _key_name(COPY_KEY_SETTING, DEFAULT_COPY_KEY), "swap_key": _key_name(SWAP_KEY_SETTING, DEFAULT_SWAP_KEY)})


static func _key_name(setting: String, default_key: String) -> String:
	var key: String = str(CandyProfiles.get_setting(setting, default_key))
	return CandyLocale.t(str(KEY_NAMES.get(key, KEY_NAMES[default_key])))


#* The keys, for a settings choice:
static func key_options() -> Array:
	var options: Array = []
	for key in KEYS:
		options.append({"label": CandyLocale.t(KEY_LABELS[key]), "value": key})
	return options

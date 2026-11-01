#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends RefCounted

#^ RichTextLabel tags with no closing tag:
const SINGLE_TAGS := ["lb", "rb", "lrm", "rlm", "lre", "rle", "lro", "rlo", "pdf", "alm", "zwj", "zwnj",
	"wj", "shy", "br", "char", "hr"]


func check(_config: Dictionary, context: CandyCheckContext) -> Array:
	var text := context.value
	if text.strip_edges() == "":
		return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("Empty: this variation is ignored, and left out of exports."))]
	var result: Array = []
	var names: Array = []    #/ The actors the text names
	var plain := _variables(text, names, result)
	plain = _substitutions(plain, names, result)
	_actors(names, result)
	_bbcode(plain, result)
	return result


#* Check the text variables, and return the text without them:
func _variables(text: String, names: Array, result: Array) -> String:
	var start := CandyChecks.symbol("text_var_start")
	var end := CandyChecks.symbol("text_var_end")
	if start == "" or end == "":
		return text
	var plain := ""
	var position := 0
	while true:
		var found := text.find(start, position)
		if found == -1:
			break
		if _is_doubled(text, found, start):
			plain += text.substr(position, found - position + start.length())
			position = found + start.length() * 2
			continue
		var closing := text.find(end, found + start.length())
		if closing == -1:
			result.append(CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Text variable not closed. Write {start}{start} to display {start}.").format({"start": start})))
			return plain + text.substr(position)
		plain += text.substr(position, found - position)
		names.append(_actor_of(text.substr(found + start.length(), closing - found - start.length())))
		position = closing + end.length()
	return plain + text.substr(position)


#* Check the word substitutions, and return the text without them:
func _substitutions(text: String, names: Array, result: Array) -> String:
	var start := CandyChecks.symbol("substitution_start")
	var end := CandyChecks.symbol("substitution_end")
	var separator := CandyChecks.symbol("separator")
	if start == "" or end == "":
		return text
	var plain := ""
	var position := 0
	while true:
		var found := text.find(start, position)
		if found == -1:
			break
		if _is_doubled(text, found, start):
			plain += text.substr(position, found - position + start.length())
			position = found + start.length() * 2
			continue
		var closing := text.find(end, found + start.length())
		if closing == -1:
			result.append(CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Word substitution not closed. Write {start}{start} to display {start}.").format({"start": start})))
			return plain + text.substr(position)
		plain += text.substr(position, found - position)
		var inside := text.substr(found + start.length(), closing - found - start.length())
		if separator == "" or not inside.contains(separator):
			result.append(CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Word substitution needs %s.") % separator))
		else:
			names.append(inside.split(separator)[1].strip_edges())
		position = closing + end.length()
	return plain + text.substr(position)


#* Whether the symbol at "at" is doubled, which displays it ("¤¤" → "¤"):
#? Read left to right: in "¤A¤¤B¤" the middle pair closes one token and opens the next.
func _is_doubled(text: String, at: int, symbol: String) -> bool:
	return text.substr(at + symbol.length(), symbol.length()) == symbol


#* The actor a text variable names ("Alice" in "Alice.Age"):
func _actor_of(inside: String) -> String:
	var trimmed := inside.strip_edges()
	for key in ["vardict", "expression"]:
		var symbol := CandyChecks.symbol(key)
		if symbol != "" and trimmed.begins_with(symbol):
			return ""			#/ Not an actor's
	var cut := trimmed.length()
	for mark in [".", "["]:
		var at := trimmed.find(mark)
		if at != -1 and at < cut:
			cut = at
	return trimmed.substr(0, cut).strip_edges()


#* Check the named actors and roles exist:
func _actors(names: Array, result: Array) -> void:
	var actors := CandyChecks.project_data("Actors")
	var roles := CandyChecks.project_data("Roles")
	for actor_name in names:
		var value := str(actor_name)
		if value == "":
			continue
		var role := CandyChecks.role_name(value)
		if role != "":
			if not roles.is_empty() and not CandyChecks.has_text(roles, role) and not CandyChecks.has_text(roles, value):
				result.append(CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("No role %s in the project's roles.") % role))
				return
		elif not actors.is_empty() and not CandyChecks.has_text(actors, value):
			result.append(CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("No actor %s in the project's actors.") % value))
			return


#* Report the first BBCode tag left open, or closed without being opened:
func _bbcode(text: String, result: Array) -> void:
	var open: Array = []
	for found in RegEx.create_from_string("\\[(/?)([A-Za-z_][A-Za-z0-9_]*)[^\\]]*\\]").search_all(text):
		var tag := found.get_string(2).to_lower()
		if SINGLE_TAGS.has(tag):
			continue
		if found.get_string(1) == "":
			open.append(tag)
			continue
		var at := open.rfind(tag)
		if at == -1:
			result.append(CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("[%s] isn't opened.") % tag))
			return
		if at != open.size() - 1:
			result.append(CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("[%s] isn't closed.") % open[open.size() - 1]))
			return
		open.remove_at(at)
	if not open.is_empty():
		result.append(CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("[%s] isn't closed.") % open[open.size() - 1]))

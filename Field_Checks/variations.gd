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


func check(_config: Dictionary, context: CandyCheckContext) -> Array:
	var shown: Array = []    #/ Variations with text, TTS ones left out
	if context.data is Array:
		for entry in context.data:
			if not entry is Dictionary or entry.is_empty():
				continue
			var variation_name := str(entry.keys()[0])
			var data = entry[entry.keys()[0]]
			if CandyVariations.is_tts(variation_name) or not data is Dictionary:
				continue
			if str(data.get("Text", "")).strip_edges() != "":
				shown.append(variation_name)
	if shown.is_empty():
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("No variation has text."))]

	#Ł Each language needs a plain variation (no tag), Candy DE's fallback:
	var languages: Array = []
	var plain: Dictionary = {}
	for variation_name in shown:
		var language := str(CandyVariations.name_parts(variation_name)["language"])
		if not languages.has(language):
			languages.append(language)
		if str(CandyVariations.split_variation(variation_name)["base"]) == language:
			plain[language] = true
	for language in languages:
		if not plain.has(language):
			return [CandyChecks.message(CandyChecks.WARNING,
				CandyLocale.t("No plain {language} variation: in {language}, the line is skipped when no tagged variation matches.").format({"language": language}))]
	return []

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
	if context.value.strip_edges().to_lower() != "advanced":
		return []
	var languages: Array = []
	var voiced: Dictionary = {}
	var variations = context.line_data().get("Variations", [])
	if not variations is Array:
		return []
	for entry in variations:
		if not entry is Dictionary or entry.is_empty():
			continue
		var variation_name := str(entry.keys()[0])
		var data = entry[entry.keys()[0]]
		if not data is Dictionary or str(data.get("Text", "")).strip_edges() == "":
			continue
		var language := str(CandyVariations.name_parts(variation_name)["language"])
		if CandyVariations.is_tts(variation_name):
			voiced[language] = true
		elif not languages.has(language):
			languages.append(language)
	for language in languages:
		if not voiced.has(language):
			return [CandyChecks.message(CandyChecks.WARNING,
				CandyLocale.t("No {language}_TTS variation: TTS Advanced Fallback is used in {language}.").format({"language": language}))]
	return []

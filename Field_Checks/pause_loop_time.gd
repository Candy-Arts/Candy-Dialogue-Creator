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


func check(config: Dictionary, context: CandyCheckContext) -> Array:
	var value := context.value.strip_edges()
	var other_id := str(config.get("other", ""))
	if value == "" or value == CandyChecks.NOT_SET_VALUE:
		var other := context.sibling(other_id)
		if other_id == "" or other == "" or other == CandyChecks.NOT_SET_VALUE:
			return []
		return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Empty: the pause point."))]

	var moves := CandyChecks.relative_frames(value)
	if moves["frames"]:
		if not moves["valid"]:
			return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("f+ / f- needs a number of frames."))]
		var frames_text := CandyLocale.t("%s frames before the pause point.")
		if moves["forward"]:
			frames_text = CandyLocale.t("%s frames after the pause point.")
		return [CandyChecks.message(CandyChecks.NOTICE, frames_text % moves["count"])]

	var direction := ""
	var target := value
	if value.begins_with("+"):
		direction = "after"
		target = value.substr(1).strip_edges()
	elif value.begins_with("-"):
		direction = "before"
		target = value.substr(1).strip_edges()

	var frames := CandyChecks.frame_target(target)
	if frames["frames"]:
		if direction != "":
			return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("To move by frames, write f+N / f-N."))]
		if not frames["valid"]:
			return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("f= needs a frame number."))]
		return []

	var seconds := CandyChecks.time_seconds(target)
	if seconds < 0.0:
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Value is not a time."))]
	if direction == "after":
		return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("%s s after the pause point.") % CandyChecks.seconds_text(seconds))]
	if direction == "before":
		return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("%s s before the pause point.") % CandyChecks.seconds_text(seconds))]

	#% Both bounds are positions - the end must come after the start:
	if bool(config.get("end", false)) and other_id != "":
		var start := context.sibling(other_id)
		if start != "" and not context.is_unknown(start) and not start.begins_with("+") and not start.begins_with("-") \
				and not CandyChecks.frame_target(start)["frames"]:
			var start_seconds := CandyChecks.time_seconds(start)
			if start_seconds >= 0.0 and seconds <= start_seconds:
				return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("The loop must end after it starts."))]
	return []

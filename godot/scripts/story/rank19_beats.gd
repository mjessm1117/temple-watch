extends RefCounted
## Campaign rank events become persistent, one-time Temple conversations.
const BEATS := {
	"j2": ["The First Mark", "Kira Venn", "The practice blade leaves a red mark on {unit}'s wrist.\nKira Venn says, 'Keep it. Tomorrow you will know why you earned it.'"],
	"j3": ["The Trials", "Satele Shan", "{unit} returns from the Trials with a torn sleeve and a steady hand.\nSatele Shan sets a Knight's cloak beside them. 'Tell me what you chose when no one could see.'\n{unit} answers. The Council lets the silence stand before it names them Knight."],
	"j4": ["A Knight's Watch", "Knight Sava Orrin", "Knight Sava Orrin finds {unit} still studying the mission map after the others sleep.\n'You can carry a decision,' she says. 'You cannot carry every life alone.'"],
	"j5": ["A Place Beside Them", "Satele Shan", "Satele Shan offers {unit} the Master's place at the training circle.\n'It is a place beside a student,' she says, 'never above one.'"],
	"j6": ["The Quiet Lesson", "Knight Sava Orrin", "Knight Sava Orrin watches {unit} put away the practice sabers.\n'Your students remember the pauses,' she says. 'Make room for them.'"],
	"j7": ["The Council Seat", "Satele Shan", "The empty Council chair has been polished so often its arms have worn smooth.\nSatele Shan waits while {unit} sits. 'The names of the absent belong in this room too.'"],
	"j8": ["Grand Master", "Satele Shan", "The Temple gathers before dawn. {unit} takes the Grand Master's charge without a procession.\nSatele Shan places the roster in their hands. 'Begin with the living.'"],
	"s2": ["First Watch", "Jace Malcom", "Jace Malcom signs {unit}'s first watch into the duty book.\n'You came back,' he says. 'Now learn how to bring the next one back.'"],
	"s3": ["The Second Route", "Jace Malcom", "Jace Malcom finds {unit} drawing a second exit on every map.\n'Keep doing that. One day the first one will be gone.'"],
	"s4": ["Sergeant's Roll", "Jace Malcom", "Jace Malcom hands {unit} the roll before the briefing.\n'The names come before the orders. Read them all.'"],
	"s5": ["A Harder Order", "Jace Malcom", "The new lieutenant, {unit}, leaves space on the board for dissent.\nJace Malcom notices. 'Good. Now listen when someone uses it.'"],
	"s6": ["Captain's Table", "Jace Malcom", "Jace Malcom pulls out a chair for {unit} at the captain's table.\nThe first report is a list of repairs. The second is a list of people."],
	"s7": ["Commander of the Returned", "Jace Malcom", "Jace Malcom gives {unit} a commander's marker, scratched from years of use.\n'Every mark is a squad that made it home. Add yours carefully.'"],
	"first_pupil": ["The First Student", "Satele Shan", "{master} waits while {unit} misses the same movement again.\nSatele Shan says, 'A Master's first lesson is patience with someone else's beginning.'"],
	"knighted_pupil": ["The Master's Line", "{master}", "{master} watches {unit} cross the floor in a Knight's cloak.\n'I taught you where to place your feet,' {master} says. 'You found your own way forward.'"],
	"memorial": ["What Remains", "Satele Shan", "The Temple sets {master}'s name among those who did not return from {where}.\n{count} Padawan{plural} still carry the lessons they were given. Satele Shan leaves room beside the inscription for their names."],
}

static func _ensure(s: Dictionary) -> void:
	if not s.has("rank_story_seen"): s.rank_story_seen = {}
	if not s.has("rank_story_queue"): s.rank_story_queue = []
	if not s.has("rank_story_journal"): s.rank_story_journal = []

static func _queue(s: Dictionary, key: String, beat: String, substitutions: Dictionary) -> void:
	_ensure(s)
	if s.rank_story_seen.has(key): return
	var row: Array = BEATS[beat]
	var title: String = row[0]
	var speaker: String = row[1]
	var body: String = row[2]
	for token in substitutions:
		speaker = speaker.replace("{" + token + "}", str(substitutions[token]))
		body = body.replace("{" + token + "}", str(substitutions[token]))
	var scene := {"kind":"grief", "rank19":true, "id":key, "name":speaker, "title":title,
		"eyebrow":"TEMPLE RECORD · SERVICE", "text":body,
		"choices":[{"id":"rank19:continue", "label":"Keep this record", "fx":{}}]}
	s.rank_story_seen[key] = true
	s.rank_story_queue.append(scene)
	s.rank_story_journal.append("%s — %s" % [title, body.replace("\n", " ")])

static func on_rank(s: Dictionary, unit: Dictionary, previous: int, current: int) -> void:
	var side := "j" if preload("res://scripts/campaign/progression.gd").is_jedi(unit) else "s"
	var beat := side + str(current)
	if BEATS.has(beat): _queue(s, str(unit.id) + ":" + beat, beat, {"unit":str(unit.n)})
	if side == "j" and previous < 3 and current == 3 and str(unit.get("mentor_id", "")) != "":
		for master in s.roster:
			if str(master.get("id", "")) == str(unit.mentor_id):
				_queue(s, str(unit.id) + ":knighted_pupil", "knighted_pupil", {"unit":str(unit.n), "master":str(master.n)})
				break

static func on_first_pupil(s: Dictionary, master: Dictionary, pupil: Dictionary) -> void:
	_queue(s, str(master.id) + ":first_pupil", "first_pupil", {"master":str(master.n), "unit":str(pupil.n)})

static func on_death(s: Dictionary, master: Dictionary, where: String) -> void:
	var count: int = master.get("trained_padawans", []).size()
	if count == 0: return
	_queue(s, str(master.id) + ":memorial", "memorial", {"master":str(master.n), "where":where, "count":str(count), "plural":"s" if count != 1 else ""})

static func next(s: Dictionary) -> Dictionary:
	_ensure(s)
	if s.rank_story_queue.is_empty(): return {}
	var scene: Dictionary = s.rank_story_queue.pop_front()
	s.pending = scene
	return scene

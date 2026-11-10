extends RefCounted
## Split authored prose at sentence boundaries; hard-split only unusually long sentences.

static func word_count(value: String) -> int:
	return value.strip_edges().split(" ", false).size() if not value.strip_edges().is_empty() else 0

static func pages(value: String, limit: int = 60) -> PackedStringArray:
	var out := PackedStringArray()
	var current := ""
	var sentence := ""
	for character in value.replace("\n", " "):
		sentence += character
		if character in [".", "!", "?"]:
			current = _append_sentence(out, current, sentence.strip_edges(), limit)
			sentence = ""
	if not sentence.strip_edges().is_empty(): current = _append_sentence(out, current, sentence.strip_edges(), limit)
	if not current.is_empty(): out.append(current)
	if out.is_empty(): out.append("")
	return out

static func _append_sentence(out: PackedStringArray, current: String, sentence: String, limit: int) -> String:
	if sentence.is_empty(): return current
	if word_count(current) + word_count(sentence) <= limit:
		return sentence if current.is_empty() else current + " " + sentence
	if not current.is_empty(): out.append(current)
	if word_count(sentence) <= limit: return sentence
	var words := sentence.split(" ", false)
	var chunk := ""
	for word in words:
		if word_count(chunk) >= limit:
			out.append(chunk)
			chunk = ""
		chunk = word if chunk.is_empty() else chunk + " " + word
	return chunk

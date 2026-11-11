extends RefCounted
const Data = preload("res://scripts/campaign/data.gd")
const Events = preload("res://scripts/campaign/events11_engine.gd")

static func ensure(s: Dictionary) -> void:
	if not s.has("w25_contacts"): s.w25_contacts = ["outer"]
	if not s.has("w25_scans_done"): s.w25_scans_done = []
	if not s.has("w25_scan_progress"): s.w25_scan_progress = {}
	if not s.has("w25_leads"): s.w25_leads = []
	if not s.has("w25_selected_mission_id"): s.w25_selected_mission_id = ""
	if not s.has("w25_contact_income_paid_month"): s.w25_contact_income_paid_month = 1

static func contacted(s: Dictionary, region: String) -> bool:
	ensure(s)
	return region in s.w25_contacts

static func operation_region(c, op: Dictionary) -> String:
	var offer: Dictionary = c.state.get("sith", {}).get("missions", {}).get(str(op.get("mission_id", "")), {})
	return c.region_for_mission(str(offer.get("mission", "")))

static func operation_display(c, op: Dictionary) -> Dictionary:
	if not operation_known(c,op): return op
	for raw in c.state.sith.ops:
		if str(raw.id) != str(op.id): continue
		var definition: Dictionary = c.sith.data.operations.get(str(raw.key), {})
		if definition.is_empty(): break
		var revealed := op.duplicate(true)
		revealed.n = str(definition.n)
		revealed.desc = str(definition.desc)
		return revealed
	return op

static func operation_known(c, op: Dictionary) -> bool:
	if op.get("revealed",false) or contacted(c.state,operation_region(c,op)): return true
	var concealed := []
	for candidate in c.sith.operations():
		if not candidate.get("revealed",false): concealed.append(str(candidate.id))
	var index := concealed.find(str(op.id))
	return index >= 0 and index < c.state.w25_leads.size()

static func contact_capacity(s: Dictionary) -> int:
	var count := 2
	if str(s.get("staff", {}).get("comms", "")) != "": count += 1
	if "holonet" in s.get("research", {}).get("done", []): count += 1
	return count

static func contact_cost(region: String) -> Dictionary:
	var row: Dictionary = Data.get_table("galaxy", "CONTACTS").get(region, {"intel": 3, "credits": 120})
	return {"intel": int(row.intel), "credits": int(row.credits)}

static func make_contact(c, region: String) -> bool:
	var s: Dictionary = c.state
	ensure(s)
	if contacted(s, region) or s.w25_contacts.size() >= contact_capacity(s): return false
	if not Data.get_table("galaxy", "CONTACTS").has(region): return false
	var cost := contact_cost(region)
	if not c.can_afford(cost) or not c.spend(cost): return false
	s.w25_contacts.append(region)
	s.news.append("Contact established: %s. Monthly income +%d Cr." % [region, int(Data.get_table("galaxy", "CONTACTS")[region].income)])
	return true

static func monthly_income(s: Dictionary) -> int:
	ensure(s)
	var sum := 0
	for region in s.w25_contacts:
		sum += int(Data.get_table("galaxy", "CONTACTS").get(region, {}).get("income", 0))
	return sum

static func settle_months(c) -> int:
	var s: Dictionary = c.state
	ensure(s)
	var count := maxi(0, int(s.month) - int(s.w25_contact_income_paid_month))
	if count == 0: return 0
	var amount := count * monthly_income(s)
	if amount > 0: c.gain("credits", amount)
	s.w25_contact_income_paid_month = int(s.month)
	return amount

static func active_scans(s: Dictionary) -> Array:
	ensure(s)
	var result := []
	var sites: Array = Data.get_table("galaxy", "SCAN_SITES")
	for site in sites:
		if not site.id in s.w25_scans_done: result.append(site)
		if result.size() == 3: break
	if result.size() < 3:
		for id in s.w25_scans_done:
			for site in sites:
				if str(site.id) == str(id): result.append(site); break
			if result.size() == 3: break
	return result

static func scan(c, site_id: String) -> Dictionary:
	var s: Dictionary = c.state
	ensure(s)
	if not c.has_method("advance_strategy_day25"): return {"days_advanced": 0, "events": [], "message": "Scanning unavailable until strategy time is ready."}
	if not Events.pending(s).is_empty(): return {"days_advanced": 0, "events": [Events.pending(s)], "message": "Resolve the galaxy event before scanning."}
	var site: Dictionary = {}
	for row in active_scans(s):
		if str(row.id) == site_id: site = row; break
	if site.is_empty(): return {"days_advanced": 0, "events": [], "message": "Scan site unavailable."}
	var advanced := 0
	var found := []
	var progress := int(s.w25_scan_progress.get(site_id,0))
	for day in maxi(0,int(site.days)-progress):
		var receipt: Dictionary = c.call("advance_strategy_day25", 1, "Scan: " + str(site.n))
		var step := int(receipt.get("days_advanced", 0))
		advanced += step
		progress += step
		s.w25_scan_progress[site_id] = progress
		found.append_array(receipt.get("events", []))
		if step <= 0 or not found.is_empty() or not Events.pending(s).is_empty() or c.sith.project_status().defeated: break
	if progress >= int(site.days) and found.is_empty() and not c.sith.project_status().defeated:
		for key in site.reward:
			if str(key) == "lead": s.w25_leads.append(site_id)
			else: c.gain(str(key), int(site.reward[key]))
		s.w25_scan_progress.erase(site_id)
		if site_id in s.w25_scans_done: s.w25_scans_done.erase(site_id)
		s.w25_scans_done.append(site_id)
		return {"days_advanced": advanced, "events": [], "message": "%s complete: %s" % [site.n, str(site.reward)]}
	return {"days_advanced": advanced, "events": found, "message": "Scan paused after %d day%s: %s" % [advanced, "" if advanced == 1 else "s", "event needs your attention" if not found.is_empty() or not Events.pending(s).is_empty() else "time stopped"]}

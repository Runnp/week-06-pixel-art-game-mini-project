extends Node

signal entry_unlocked(entry_id: String)

const ENTRIES := {
	# ── HISTORY ───────────────────────────────────────
	"aral_sea_history": {
		"category": "History",
		"title":    "The Aral Sea",
		"text":     "Once the fourth largest lake on Earth. Shared between Soviet Kazakhstan and Uzbekistan. Fed by two rivers — the Amu Darya from the south and Syr Darya from the north. In 1960 it covered 68,000 square kilometres. Sailors called it the Blue Sea.",
		"unlock":   "visit_hometown"
	},
	"soviet_cotton": {
		"category": "History",
		"title":    "The Cotton Mandate",
		"text":     "Soviet central planning designated Central Asia as the USSR's primary cotton producer in the 1940s. The Amu Darya and Syr Darya rivers were diverted through thousands of kilometres of irrigation canals. Cotton yield increased dramatically. The Aral Sea began to shrink.",
		"unlock":   "interact_signpost"
	},
	"muynak_history": {
		"category": "History",
		"title":    "Muynak",
		"text":     "Once a thriving port city and fishing hub. The Muynak fish cannery processed 12,000 tonnes per year at its peak. By 1982 the sea had retreated 40 kilometres. The fishing boats were left where they were. The cannery imported fish from the Baltic Sea to stay operational.",
		"unlock":   "visit_muynak"
	},
	"kokaral_dam": {
		"category": "History",
		"title":    "The Kokaral Dam",
		"text":     "Built in 2005 with World Bank funding. A 13-kilometre dam separating the North Aral Sea from the dry southern basin. Within one year the North Aral Sea water level rose by 3 metres. Fish returned. The nearby town of Aralsk began recovering. The South Aral Sea remains dry.",
		"unlock":   "interact_water_marker"
	},
	"ussr_1953": {
		"category": "History",
		"title":    "Tashkent 1953",
		"text":     "Stalin is still in power. The Soviet Ministry of Agriculture operates from the Tashkent administrative complex. River diversion orders are signed here. No public consultation. No environmental review. The hydrologists who raised concerns were reassigned or ignored.",
		"unlock":   "visit_ussr"
	},

	# ── ENVIRONMENT ───────────────────────────────────
	"salt_dust": {
		"category": "Environment",
		"title":    "Salt Dust Syndrome",
		"text":     "As the Aral Sea dried, its exposed bed became a source of toxic dust. Salt, pesticide residue from decades of runoff, and heavy metals are carried by wind up to 500 kilometres. The Karakalpakstan region has among the highest rates of throat cancer, anaemia, and respiratory disease in the world.",
		"unlock":   "talk_bibi"
	},
	"soil_remediation": {
		"category": "Environment",
		"title":    "Soil Treatment",
		"text":     "The exposed seabed can be partially rehabilitated through halophyte planting — salt-tolerant plants that stabilise the ground and reduce wind erosion. Chemical treatment of the top soil layer can reduce toxicity. Recovery is measured in decades, not years.",
		"unlock":   "first_spray"
	},
	"saxaul_tree": {
		"category": "Environment",
		"title":    "The Saxaul Tree",
		"text":     "Haloxylon ammodendron. Native to Central Asian deserts. Deep root system stabilises loose sandy soil and prevents erosion. Kazakhstan has planted over 100 million saxaul trees on the former Aral seabed since 2018. Each tree can anchor several tonnes of sand.",
		"unlock":   "plant_first_tree"
	},
	"fish_ecology": {
		"category": "Environment",
		"title":    "The Fish That Remained",
		"text":     "As salinity increased beyond normal seawater levels, most native species died. A small population of flounder adapted to hyper-saline conditions and survived in isolated pools. When the North Aral Sea refilled after the Kokaral Dam, fish were reintroduced from rivers. The ecosystem is slowly recovering.",
		"unlock":   "add_fish_aquarium"
	},

	# ── PEOPLE ────────────────────────────────────────
	"bibi_profile": {
		"category": "People",
		"title":    "Bibi",
		"text":     "Rustam's grandmother. Born near the Aral Sea in 1944. Grew up swimming in water she describes as blue and cold and alive. Watched the shoreline retreat throughout her adult life. Never left. Keeps a photograph from 1962. Believes the sea will return.",
		"unlock":   "talk_bibi"
	},
	"kamola_profile": {
		"category": "People",
		"title":    "Dr. Kamola",
		"text":     "Environmental scientist. Specialises in soil remediation and saline ecology. Has been conducting field research at Muynak for three months after her team returned home. Her published papers on minimum ecological water flow were cited in the 2004 World Bank feasibility report for the Kokaral Dam.",
		"unlock":   "talk_kamola"
	},
	"malik_profile": {
		"category": "People",
		"title":    "Malik",
		"text":     "Community activist and driver. Has lived in the region his entire life. Runs an informal network connecting environmental volunteers with field researchers. Talks too fast. Knows every road in Karakalpakstan. Has driven the Muynak road more than fifty times watching it get worse.",
		"unlock":   "talk_malik"
	},
	"fisherman_profile": {
		"category": "People",
		"title":    "The Old Fisherman",
		"text":     "No name given. Sits beside Ship 01 in Muynak daily. Was a commercial fisherman for 31 years. Mends nets that will never be used again. Comes to the same spot every morning out of habit. Says the sea will come back. Says he will not. Says that is okay.",
		"unlock":   "talk_fisherman"
	},
	"zorin_profile": {
		"category": "People",
		"title":    "Minister Zorin",
		"text":     "Fictional. Represents the Soviet agricultural planners of the early 1950s who signed river diversion orders. Not a villain — a bureaucrat executing policy handed down from Moscow. Added Clause 7, Sub-paragraph C to the 1953 diversion order after an unrecorded conversation with an unknown visitor. The clause mandated minimum ecological water flow to the Aral Sea. It was largely ignored for decades. It was also never formally repealed.",
		"unlock":   "convince_zorin"
	},
}

var _unlocked : Array = []


func _ready() -> void:
	GameManager.chapter_changed.connect(_on_chapter_changed)


func unlock(entry_id: String) -> void:
	if entry_id in _unlocked:
		return
	if not ENTRIES.has(entry_id):
		push_warning("Codex: Unknown entry %s" % entry_id)
		return

	_unlocked.append(entry_id)
	emit_signal("entry_unlocked", entry_id)

	var entry := ENTRIES[entry_id]
	var hud   := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_prompt"):
		hud.show_prompt("Codex updated: %s" % entry["title"])
		await get_tree().create_timer(2.0).timeout
		hud.hide_prompt()


func get_entry(entry_id: String) -> Dictionary:
	return ENTRIES.get(entry_id, {})


func get_unlocked_by_category(category: String) -> Array:
	var result := []
	for id in _unlocked:
		if ENTRIES[id]["category"] == category:
			result.append(id)
	return result


func is_unlocked(entry_id: String) -> bool:
	return entry_id in _unlocked


func _on_chapter_changed(chapter: int) -> void:
	match chapter:
		1: unlock("aral_sea_history")
		2: unlock("muynak_history")
		3: unlock("soil_remediation")
		4: unlock("kokaral_dam")
		5: unlock("ussr_1953")

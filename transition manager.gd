# PUSH 50 — Scene Transition Manager + Chapter Title Cards
# Commit: "Push 50: Transition manager, chapter title cards, loading screen"
# File: res://scripts/systems/transition_manager.gd
# REGISTER AS AUTOLOAD: Name it "TransitionManager"
# ═══════════════════════════════════════════════════════════════
# WHAT THIS DOES:
#   Replaces raw GameManager.change_scene() calls everywhere.
#   Adds chapter title cards between levels ("Chapter 2 — Muynak")
#   Shows a brief loading overlay for scene changes.
#   Handles the greyscale flash when entering USSR chapter.
# ═══════════════════════════════════════════════════════════════

extends CanvasLayer

# Title card data per chapter
const CHAPTER_CARDS := {
	1: {
		"chapter":  "Chapter One",
		"title":    "Coming Home",
		"subtitle": "Karakalpakstan, Uzbekistan",
		"year":     "Present Day",
	},
	2: {
		"chapter":  "Chapter Two",
		"title":    "The Graveyard",
		"subtitle": "Muynak — Former Port City",
		"year":     "Present Day",
	},
	3: {
		"chapter":  "Chapter Three",
		"title":    "The Seafloor",
		"subtitle": "The Dry Aral Seabed",
		"year":     "Present Day",
	},
	4: {
		"chapter":  "Chapter Four",
		"title":    "The Border",
		"subtitle": "Uzbekistan — Kazakhstan",
		"year":     "Present Day",
	},
	5: {
		"chapter":  "Chapter Five",
		"title":    "The Gate",
		"subtitle": "Tashkent, Soviet Uzbek SSR",
		"year":     "1953",
	},
}

@onready var bg          : ColorRect = $Background
@onready var chapter_lbl : Label     = $VBox/ChapterLabel
@onready var title_lbl   : Label     = $VBox/TitleLabel
@onready var subtitle_lbl: Label     = $VBox/SubtitleLabel
@onready var year_lbl    : Label     = $VBox/YearLabel
@onready var vbox        : VBoxContainer = $VBox

var _transitioning : bool = false

layer = 90


func _ready() -> void:
	bg.color      = Color.BLACK
	bg.visible    = false
	vbox.visible  = false
	bg.modulate.a = 0.0


func go_to_chapter(chapter: int) -> void:
	if _transitioning:
		return
	_transitioning = true

	# Fade out
	await ScreenFade.fade_out(0.6)

	# Show title card
	await _show_title_card(chapter)

	# Load scene
	var scene_path := GameManager.CHAPTER_SCENES.get(chapter, "")
	if scene_path != "":
		get_tree().change_scene_to_file(scene_path)

	# Fade in handled by the level's _ready()
	_transitioning = false


func go_to_scene(path: String, show_card: bool = false,
				  card_title: String = "") -> void:
	if _transitioning:
		return
	_transitioning = true

	await ScreenFade.fade_out(0.5)

	if show_card and card_title != "":
		await _show_custom_card(card_title)

	get_tree().change_scene_to_file(path)
	_transitioning = false


func _show_title_card(chapter: int) -> void:
	var data := CHAPTER_CARDS.get(chapter, {})
	if data.is_empty():
		await get_tree().create_timer(0.5).timeout
		return

	bg.visible      = true
	bg.modulate.a   = 1.0
	vbox.visible    = true
	vbox.modulate.a = 0.0

	# Special background for USSR chapter
	if chapter == 5:
		bg.color = Color(0.08, 0.07, 0.06)   # sepia dark
	else:
		bg.color = Color(0.02, 0.03, 0.06)   # deep blue-black

	chapter_lbl.text  = data.get("chapter",  "")
	title_lbl.text    = data.get("title",    "")
	subtitle_lbl.text = data.get("subtitle", "")
	year_lbl.text     = data.get("year",     "")

	# Special color for USSR year
	if chapter == 5:
		year_lbl.modulate = Color(0.9, 0.7, 0.4)   # aged paper yellow
	else:
		year_lbl.modulate = Color(0.6, 0.8, 1.0)   # cool blue

	# Fade in title card elements one by one
	var tween := create_tween()
	tween.tween_property(vbox, "modulate:a", 1.0, 0.8)
	await tween.finished

	# Animate chapter label sliding in
	chapter_lbl.position.x = -40.0
	var slide := create_tween()
	slide.tween_property(chapter_lbl, "position:x", 0.0, 0.6).set_trans(
		Tween.TRANS_SINE)
	await slide.finished

	# Hold
	await get_tree().create_timer(2.5).timeout

	# Fade out title card
	var fade_out := create_tween()
	fade_out.tween_property(vbox, "modulate:a", 0.0, 0.5)
	await fade_out.finished

	vbox.visible = false
	bg.visible   = false
	bg.color     = Color.BLACK


func _show_custom_card(title: String) -> void:
	bg.visible      = true
	bg.modulate.a   = 1.0
	vbox.visible    = true
	vbox.modulate.a = 0.0
	chapter_lbl.text  = ""
	title_lbl.text    = title
	subtitle_lbl.text = ""
	year_lbl.text     = ""

	var tween := create_tween()
	tween.tween_property(vbox, "modulate:a", 1.0, 0.5)
	await tween.finished
	await get_tree().create_timer(1.5).timeout
	tween = create_tween()
	tween.tween_property(vbox, "modulate:a", 0.0, 0.4)
	await tween.finished
	vbox.visible = false
	bg.visible   = false


# ── REPLACE ALL GameManager.change_scene() CALLS ──────────────
# Find/replace in project:
#   GameManager.change_scene(CHAPTER_SCENES[n])
#   → TransitionManager.go_to_chapter(n)
#
#   GameManager.change_scene("res://scenes/ui/Credits.tscn")
#   → TransitionManager.go_to_scene("res://scenes/ui/Credits.tscn")
#
#   GameManager.change_scene("res://scenes/ui/MainMenu.tscn")
#   → TransitionManager.go_to_scene("res://scenes/ui/MainMenu.tscn")
#
# ── SCENE STRUCTURE ───────────────────────────────────────────
# CanvasLayer (transition_manager.gd, layer: 90)
# ├── ColorRect (name: Background) fullrect color:black
# └── VBoxContainer (name: VBox) centered fullrect
#     ├── Label (name: ChapterLabel) size:7  grey  centered
#     ├── Label (name: TitleLabel)   size:12 white centered bold
#     ├── Label (name: SubtitleLabel)size:7  grey  centered
#     └── Label (name: YearLabel)    size:9  blue  centered

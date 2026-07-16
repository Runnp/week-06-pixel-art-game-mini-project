# PUSH 43 — Credits Scene + Ending Slideshow
# Commit: "Push 43: Credits with real facts, ending slideshow, satellite image sequence"
# File: res://scripts/ui/credits.gd
# Attach to: Control root of Credits.tscn
# ═══════════════════════════════════════════════════════════════

extends Control

@onready var bg_rect      : ColorRect = $Background
@onready var slide_rect   : TextureRect = $SlideRect
@onready var scroll_label : Label     = $ScrollContainer/CreditsLabel
@onready var fact_label   : Label     = $FactLabel

const SCROLL_SPEED : float = 18.0
var _scroll_done   : bool  = false
var _slide_index   : int   = 0

# Real facts shown between credit blocks
const REAL_FACTS := [
	"The Aral Sea was once the fourth largest lake on Earth.",
	"By 2007 it had shrunk to 10% of its original size.",
	"The Kokaral Dam was completed in 2005. The North Aral Sea began recovering immediately.",
	"Kazakhstan has planted over 100 million saxaul trees on the former seabed.",
	"The town of Aralsk, once landlocked by 80km, is now 17km from the water.",
	"The South Aral Sea remains dry. Restoration efforts continue.",
	"Over 40,000 fishing jobs were lost as the sea disappeared.",
	"Salt dust from the dry seabed reaches as far as Greenland and Antarctica.",
	"This game is dedicated to everyone working to restore the Aral Sea.",
]

const CREDITS_TEXT := """
ARAL SEA REVIVAL



Story inspired by the life of
Rustam
Environmental activist · Yale University Class of 2026
Raised in Karakalpakstan, Uzbekistan



Game Design, Art & Code
Nurmuhammad Mirzaahmadov
(Runnp)



Built with
Godot Engine 4
Open source · godotengine.org



Special Thanks
The people of Karakalpakstan
and the Aral Sea region
who live with this every day



Historical Consultation
The Aral Sea crisis is real.
The ships are real.
The dust is real.
The fisherman exists.



The North Aral Sea is recovering.
The work continues.



For Bibi.
And for every grandmother
who remembers the water.


"""

var _fact_timer : float = 0.0
var _fact_index : int   = 0
var _facts_shown: bool  = false


func _ready() -> void:
	bg_rect.color      = Color(0.04, 0.03, 0.06)
	scroll_label.text  = CREDITS_TEXT
	fact_label.visible = false
	slide_rect.visible = false

	# Start with satellite image slideshow if zorin was convinced
	if GameManager.zorin_convinced:
		_play_good_ending_slides()
	else:
		_start_scroll()


func _play_good_ending_slides() -> void:
	slide_rect.visible = true
	var slides := [
		"res://assets/sprites/ui/slide_aral_1960.png",
		"res://assets/sprites/ui/slide_aral_1984.png",
		"res://assets/sprites/ui/slide_aral_2000.png",
		"res://assets/sprites/ui/slide_aral_2020.png",
		"res://assets/sprites/ui/slide_aral_restored.png",
	]
	var captions := [
		"1960 — The Aral Sea at full size. 68,000 km².",
		"1984 — Shrinking. The fishing industry collapses.",
		"2000 — Nearly gone. Salt flats where the water was.",
		"2020 — The North Aral Sea recovering after the Kokaral Dam.",
		"One day — What restoration could look like.",
	]

	for i in slides.size():
		# Try to load the slide texture
		if ResourceLoader.exists(slides[i]):
			slide_rect.texture = load(slides[i])
		else:
			# Placeholder color if no image yet
			bg_rect.color = [
				Color(0.1, 0.2, 0.5),
				Color(0.2, 0.3, 0.5),
				Color(0.5, 0.45, 0.3),
				Color(0.2, 0.4, 0.5),
				Color(0.1, 0.5, 0.3),
			][i]

		fact_label.visible = true
		fact_label.text    = captions[i]
		fact_label.modulate.a = 0.0

		var tween := create_tween()
		tween.tween_property(fact_label, "modulate:a", 1.0, 1.0)
		await tween.finished
		await get_tree().create_timer(3.0).timeout

		var tween2 := create_tween()
		tween2.tween_property(fact_label, "modulate:a", 0.0, 0.8)
		await tween2.finished

	slide_rect.visible = false
	bg_rect.color      = Color(0.04, 0.03, 0.06)
	_start_scroll()


func _start_scroll() -> void:
	scroll_label.position.y = 200.0   # start below screen
	_fact_timer             = 8.0     # first fact after 8 seconds


func _process(delta: float) -> void:
	if _scroll_done:
		return

	scroll_label.position.y -= SCROLL_SPEED * delta

	# Show real facts between credits
	_fact_timer -= delta
	if _fact_timer <= 0.0 and _fact_index < REAL_FACTS.size():
		_show_next_fact()
		_fact_timer = 12.0

	# Credits finished — return to main menu
	if scroll_label.position.y < -scroll_label.size.y - 60.0:
		_scroll_done = true
		_finish()


func _show_next_fact() -> void:
	if _fact_index >= REAL_FACTS.size():
		return
	fact_label.text       = REAL_FACTS[_fact_index]
	fact_label.visible    = true
	fact_label.modulate.a = 0.0
	_fact_index          += 1

	var tween := create_tween()
	tween.tween_property(fact_label, "modulate:a", 1.0, 1.0)
	await tween.finished
	await get_tree().create_timer(5.0).timeout
	var tween2 := create_tween()
	tween2.tween_property(fact_label, "modulate:a", 0.0, 1.0)
	await tween2.finished
	fact_label.visible = false


func _finish() -> void:
	await ScreenFade.fade_out(2.0)
	SaveSystem.delete_save()   # new game next time
	GameManager.change_scene("res://scenes/ui/MainMenu.tscn")


func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("ui_accept") or \
	   event.is_action_just_pressed("ui_cancel"):
		if not _scroll_done:
			_scroll_done = true
			_finish()

# ═══════════════════════════════════════════════════════════════
# CREDITS.TSCN SCENE STRUCTURE
# ═══════════════════════════════════════════════════════════════
#
# Control (fullrect, credits.gd)
# ├── ColorRect         (name: Background)  fullrect
# ├── TextureRect       (name: SlideRect)   fullrect, visible:false
# ├── ScrollContainer   (fullrect)
# │   └── Label         (name: CreditsLabel)
# │         AutoWrap: OFF   HAlign: CENTER
# │         Custom font: pixel font, size 8
# └── Label             (name: FactLabel)
#       position: center, y:140    HAlign: CENTER
#       modulate: white  Custom font size 7  italic
#
# SLIDE IMAGES TO CREATE (even placeholder colored PNGs work):
#   assets/sprites/ui/slide_aral_1960.png    320x180
#   assets/sprites/ui/slide_aral_1984.png    320x180
#   assets/sprites/ui/slide_aral_2000.png    320x180
#   assets/sprites/ui/slide_aral_2020.png    320x180
#   assets/sprites/ui/slide_aral_restored.png 320x180
#
# For now: use solid color rectangles as placeholders
# Replace with real satellite imagery (public domain NASA images)
# NASA Earthdata: earthdata.nasa.gov — search "Aral Sea"
# All NASA Earth imagery is public domain, free to use

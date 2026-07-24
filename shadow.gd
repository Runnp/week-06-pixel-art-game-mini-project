extends Node2D

@export var shadow_color   : Color = Color(0, 0, 0, 0.28)
@export var shadow_width   : float = 14.0
@export var shadow_height  : float = 5.0
@export var offset_y       : float = 10.0   # how far below feet


func _ready() -> void:
	z_index = -1   # always behind the character sprite


func _draw() -> void:
	draw_ellipse(
		Vector2(0, offset_y),
		shadow_width,
		shadow_height,
		shadow_color
	)


func draw_ellipse(center: Vector2, w: float, h: float,
				  color: Color, steps: int = 16) -> void:
	var points := PackedVector2Array()
	for i in steps:
		var angle := (float(i) / float(steps)) * TAU
		points.append(center + Vector2(cos(angle) * w, sin(angle) * h))
	draw_colored_polygon(points, color)

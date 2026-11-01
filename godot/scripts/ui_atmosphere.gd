extends Control
var time := 0.0
func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	time += delta
	queue_redraw()
func _draw() -> void:
	for i in 45:
		var p := Vector2(fmod(i*137.1+time*(2+i%3),size.x+1), fmod(i*71.7-time*3+size.y*10,size.y+1))
		draw_circle(p,1.0,Color(0.5,0.85,0.9,0.12+0.09*sin(time+i)))
	for y in range(0,int(size.y),4): draw_line(Vector2(0,y),Vector2(size.x,y),Color(0,0.06,0.08,0.045))

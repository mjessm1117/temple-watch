extends Control
## Font independent HP and action marks for the battle unit panel.
var hp := 0
var max_hp := 0
var ap := 0
var max_ap := 2

func update(unit: Dictionary) -> void:
	hp = maxi(0,int(unit.get("hp",0)))
	max_hp = maxi(1,int(unit.get("max_hp",1)))
	ap = maxi(0,int(unit.get("ap",0)))
	max_ap = maxi(1,int(unit.get("max_ap",2)))
	queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(190,34)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var width := minf(size.x,190.0)
	var step := width/float(max_hp)
	for i in max_hp:
		var center := Vector2((float(i)+0.5)*step,8)
		draw_circle(center,minf(5.0,step*0.38),Color("8fe3b8") if i < hp else Color("42565b"))
	for i in max_ap:
		var rect := Rect2(Vector2(float(i)*30.0,22),Vector2(23,8))
		draw_rect(rect,Color("7fc8f7") if i < ap else Color("3f525d"))
		draw_rect(rect,Color("9ee6ff"),false,1.0)

extends Node2D
# Non-interactive cinematic ambience. Does not modify visibility rules or navigation.
var origins := PackedVector2Array()
var clock := 0.0
var smoke_texture: Texture2D
var smoke_count := 8

func _ready() -> void:
	smoke_count = 6 if OS.has_feature("web") else 10
	var image := Image.create(64,64,false,Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var p := (Vector2(x,y)-Vector2(31.5,31.5))/31.5
			var r := p.length()
			var grain := 0.82+0.18*sin(float(x)*1.73+float(y)*2.31)
			var a := pow(maxf(0.0,1.0-r*r),2.0)*grain
			image.set_pixel(x,y,Color(0.15,0.14,0.15,a))
	smoke_texture = ImageTexture.create_from_image(image)

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	if smoke_texture == null:
		return
	for j in range(origins.size()):
		var origin := origins[j]
		for i in range(smoke_count):
			var t := fposmod(clock*0.26+float(i)/float(smoke_count)+float(j)*0.13,1.0)
			var drift := Vector2(22.0*t+sin(t*8.0+float(j))*9.0*t,-74.0*t)
			var size := 19.0+65.0*t
			var alpha := sin(PI*t)*0.48
			draw_texture_rect(smoke_texture,Rect2(origin+drift-Vector2.ONE*size*0.5,Vector2.ONE*size),false,Color(1,1,1,alpha))
		draw_circle(origin,4.0+sin(clock*5.0+float(j))*1.5,Color(0.91,0.42,0.12,0.40),true,-1,true)

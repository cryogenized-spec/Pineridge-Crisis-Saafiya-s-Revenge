extends RefCounted
# General-purpose adult character looks, independent of narrative role.
const LOOKS := [
	{"name":"T-shirt / shorts","skin":Color("#b57c54"),"shirt":Color("#bc946a"),"pants":Color("#414e64"),"hair":Color("#302a2d"),"jacket":false,"long_pants":false,"hat":0,"hair_style":0,"build":1.02},
	{"name":"Windbreaker / jeans","skin":Color("#8d593e"),"shirt":Color("#537775"),"pants":Color("#344358"),"hair":Color("#241f24"),"jacket":true,"long_pants":true,"hat":1,"hair_style":1,"build":0.92},
	{"name":"Vest / board shorts","skin":Color("#ad704b"),"shirt":Color("#e1d8bd"),"pants":Color("#657e86"),"hair":Color("#31252b"),"jacket":false,"long_pants":false,"hat":2,"hair_style":0,"build":1.08},
	{"name":"Denim jacket / trousers","skin":Color("#c38d66"),"shirt":Color("#62728c"),"pants":Color("#625b50"),"hair":Color("#3b2524"),"jacket":true,"long_pants":true,"hat":0,"hair_style":2,"build":0.90},
	{"name":"Sports tee / shorts","skin":Color("#82543e"),"shirt":Color("#873f4b"),"pants":Color("#514c54"),"hair":Color("#252129"),"jacket":false,"long_pants":false,"hat":1,"hair_style":0,"build":1.00},
	{"name":"Light jacket / jeans","skin":Color("#b17b59"),"shirt":Color("#aa8150"),"pants":Color("#3c455a"),"hair":Color("#332629"),"jacket":true,"long_pants":true,"hat":2,"hair_style":2,"build":0.95},
	{"name":"Plain tee / shorts","skin":Color("#9b674a"),"shirt":Color("#65878d"),"pants":Color("#93856d"),"hair":Color("#28252c"),"jacket":false,"long_pants":false,"hat":3,"hair_style":1,"build":1.06},
	{"name":"Track jacket / trousers","skin":Color("#d29a72"),"shirt":Color("#7b5270"),"pants":Color("#45424c"),"hair":Color("#44302e"),"jacket":true,"long_pants":true,"hat":0,"hair_style":1,"build":0.94},
	{"name":"Graphic tee / board shorts","skin":Color("#b9855f"),"shirt":Color("#6c6f47"),"pants":Color("#474f61"),"hair":Color("#282227"),"jacket":false,"long_pants":false,"hat":0,"hair_style":0,"build":0.91},
	{"name":"Windbreaker / trousers","skin":Color("#95664d"),"shirt":Color("#4c5d78"),"pants":Color("#7a7464"),"hair":Color("#29272b"),"jacket":true,"long_pants":true,"hat":3,"hair_style":2,"build":1.07},
	{"name":"Plain tee / jeans","skin":Color("#b27a55"),"shirt":Color("#b76e55"),"pants":Color("#41485e"),"hair":Color("#39262b"),"jacket":false,"long_pants":true,"hat":1,"hair_style":2,"build":0.96},
	{"name":"Light jacket / shorts","skin":Color("#a16b52"),"shirt":Color("#777c75"),"pants":Color("#615b64"),"hair":Color("#30262b"),"jacket":true,"long_pants":false,"hat":0,"hair_style":0,"build":1.00}
]

static func look(index: int) -> Dictionary:
	return LOOKS[posmod(index, LOOKS.size())]

static func limb(canvas: Node2D, a: Vector2, b: Vector2, color: Color, width: float) -> void:
	canvas.draw_line(a, b, color.darkened(0.27), width + 0.8, true)
	canvas.draw_line(a, b, color, width, true)
	canvas.draw_circle(b, width * 0.48, color, true, -1, true)

static func oval(canvas: Node2D, p: Vector2, radii: Vector2, color: Color, angle: float = 0.0) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var t := TAU * float(i) / 32.0
		points.append(p + Vector2(cos(t) * radii.x, sin(t) * radii.y).rotated(angle))
	canvas.draw_colored_polygon(points, color)

static func render(canvas: Node2D, index: int, travel: float, facing: float, phase: float, motion: float, running: bool) -> void:
	var d := look(index)
	var skin: Color = d.skin
	var shirt: Color = d.shirt
	var pants: Color = d.pants
	var hair: Color = d.hair
	var build: float = d.build
	var sleeves: bool = d.jacket
	var long_pants: bool = d.long_pants
	var hat: int = d.hat
	var hair_style: int = d.hair_style
	var stride := 6.3 if running else 3.8
	canvas.draw_set_transform(Vector2.ZERO, travel)
	for side in [-1, 1]:
		var wave := sin(phase + (PI if side > 0 else 0.0)) * motion
		var hip := Vector2(-1.5, side * 3.0 * build)
		var knee := Vector2(-2.0 + wave * stride * 0.62, side * 3.4 * build)
		var ankle := Vector2(-3.0 + wave * stride, side * 3.7 * build)
		limb(canvas, hip, knee, pants, 4.0 * build)
		limb(canvas, knee, ankle, pants if long_pants else skin, 2.8 * build)
		if not long_pants and index % 3 == 0:
			oval(canvas, ankle + Vector2(1.2, 0), Vector2(3.0, 1.65), skin)
			canvas.draw_line(ankle + Vector2(1.2,-1.1), ankle + Vector2(1.2,1.1), Color("#3c3435"), 1.1, true)
		else:
			oval(canvas, ankle + Vector2(1.0,0), Vector2(3.1,1.8), Color("#302e33"))
			canvas.draw_line(ankle + Vector2(1.8,-1.1), ankle + Vector2(2.3,1.0), Color("#aaa09a"),0.65,true)
	canvas.draw_set_transform(Vector2.ZERO, facing)
	oval(canvas, Vector2(-0.8,0), Vector2(5.8,6.7*build), shirt.darkened(0.30))
	oval(canvas, Vector2(-0.6,0), Vector2(5.1,6.2*build), shirt)
	oval(canvas, Vector2(0.7,-1.7), Vector2(3.5,3.8*build),shirt.lightened(0.11))
	for side in [-1,1]:
		var swing := sin(phase + (PI if side > 0 else 0.0)) * motion
		var shoulder := Vector2(-0.9,side*5.0*build)
		var elbow := Vector2(-0.4+swing*2.2,side*7.0*build)
		var wrist := Vector2(1.4+swing*(4.0 if running else 2.5),side*7.5*build)
		limb(canvas,shoulder,elbow,shirt,3.9*build)
		limb(canvas,elbow,wrist,shirt if sleeves else skin,2.9*build)
		oval(canvas,wrist,Vector2(1.9,1.6),skin)
		if sleeves:
			canvas.draw_line(elbow.lerp(wrist,0.6),wrist,shirt.darkened(0.20),0.6,true)
	if sleeves:
		canvas.draw_line(Vector2(-4.2,0),Vector2(3.6,0),shirt.darkened(0.30),0.9,true)
		canvas.draw_line(Vector2(-4.2,0.6),Vector2(3.6,0.6),shirt.lightened(0.25),0.45,true)
	else:
		canvas.draw_arc(Vector2(2.3,0),2.8,PI*0.5,PI*1.5,12,shirt.darkened(0.35),0.7,true)
	oval(canvas,Vector2(2.1,0),Vector2(4.8,4.25),skin.darkened(0.20))
	oval(canvas,Vector2(2.5,0),Vector2(4.5,3.95),skin)
	oval(canvas,Vector2(1.1,0),Vector2(3.8,3.9),hair)
	if hair_style == 1:
		for i in range(8):
			var a := float(i)*TAU/8.0
			oval(canvas,Vector2(0.6,0)+Vector2(cos(a)*2.6,sin(a)*3.0),Vector2(1.7,1.5),hair.lightened(0.10))
	elif hair_style == 2:
		oval(canvas,Vector2(-2.6,0),Vector2(2.5,3.3),hair)
	if hat == 1:
		oval(canvas,Vector2(0.7,0.5),Vector2(4.0,4.4),Color("#343642"),-0.35)
		canvas.draw_arc(Vector2(0.7,0.5),3.0,0,TAU,20,Color("#696673"),0.65,true)
	elif hat == 2:
		oval(canvas,Vector2(1.5,0),Vector2(4.2,3.9),Color("#565960"))
		oval(canvas,Vector2(5.0,0),Vector2(2.2,2.7),Color("#565960"))
	elif hat == 3:
		canvas.draw_arc(Vector2(1.6,0),4.1,-1.25,1.25,16,Color("#b79d78"),1.3,true)
		canvas.draw_arc(Vector2(1.6,0),4.1,-1.25,1.25,16,Color("#69533f"),0.5,true)
	canvas.draw_set_transform(Vector2.ZERO)

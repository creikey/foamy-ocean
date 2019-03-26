tool
extends MeshInstance

func _ready():
	var noise = OpenSimplexNoise.new()
	noise.seed = randi()
	noise.octaves = 4
	noise.period = 20.0
	noise.persistence = 0.8
#	noise.get_image(512, 512).save_png("res://noise.png")
#	mesh.get("material").set_shader_param("two_d_noise", noise.get_image(512, 512))
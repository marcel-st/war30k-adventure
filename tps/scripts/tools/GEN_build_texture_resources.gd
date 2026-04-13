extends SceneTree

const SOURCES: Dictionary = {
	"res://assets/textures/environment/concrete_ao.png": "res://assets/textures/environment/concrete_ao.res",
	"res://assets/textures/environment/concrete_color.png": "res://assets/textures/environment/concrete_color.res",
	"res://assets/textures/environment/concrete_normal.png": "res://assets/textures/environment/concrete_normal.res",
	"res://assets/textures/environment/concrete_roughness.png": "res://assets/textures/environment/concrete_roughness.res",
	"res://assets/textures/environment/metalplates_color.png": "res://assets/textures/environment/metalplates_color.res",
	"res://assets/textures/environment/metalplates_metallic.png": "res://assets/textures/environment/metalplates_metallic.res",
	"res://assets/textures/environment/metalplates_normal.png": "res://assets/textures/environment/metalplates_normal.res",
	"res://assets/textures/environment/metalplates_roughness.png": "res://assets/textures/environment/metalplates_roughness.res",
	"res://assets/textures/skyboxes/studio_small_09.jpg": "res://assets/textures/skyboxes/studio_small_09.res"
}

func _initialize() -> void:
	var had_error: bool = false
	for source_path in SOURCES.keys():
		var image: Image = Image.new()
		var err: Error = image.load(source_path)
		if err != OK:
			push_error("Failed loading source image: %s" % source_path)
			had_error = true
			continue
		var texture: ImageTexture = ImageTexture.create_from_image(image)
		var save_path: String = str(SOURCES[source_path])
		err = ResourceSaver.save(texture, save_path, ResourceSaver.FLAG_CHANGE_PATH)
		if err != OK:
			push_error("Failed saving texture resource: %s" % save_path)
			had_error = true
		else:
			print("Saved: %s" % save_path)
	if had_error:
		quit(1)
		return
	print("Texture resources generated.")
	quit()

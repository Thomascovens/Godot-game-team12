# res://tools/clean_tileset_by_source.gd
@tool
extends EditorScript

func _run() -> void:
	var path: String = "res://tilesets/main_tileset_pm3ni.tres"  # ← adjust to your external .tres
	var ts := load(path) as TileSet
	if ts == null:
		printerr("❌ Couldn’t load Tileset at ", path)
		return

	# Iterate all sources in the TileSet
	var sc := ts.get_source_count()
	for i in sc:
		var sid: int = ts.get_source_id(i)
		var src := ts.get_source(sid)
		if src is TileSetAtlasSource:
			# This will strip out every out-of-bounds atlas tile
			(src as TileSetAtlasSource).clear_tiles_outside_texture()  

	# Save the cleaned Tileset back to disk
	var err: int = ResourceSaver.save(ts, path)
	if err == OK:
		print("✅ Tileset cleaned & saved: ", path)
	else:
		printerr("✖ Failed to save Tileset: error ", err)

	# Reminder: reopen or reload your scene (click the ⟳ next to Tile Set in each layer)
	# so Godot picks up the cleaned resource and your 404 errors will vanish.

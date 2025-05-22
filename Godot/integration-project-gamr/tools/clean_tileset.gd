# res://tools/clean_tileset_manual.gd
@tool
extends EditorScript

func _run() -> void:
	# ← Point this at your Tileset
	var path := "res://path/to/YourTileset.tres"
	var tileset: TileSet = ResourceLoader.load<TileSet>(path)
	if tileset == null:
		printerr("Couldn’t load Tileset at ", path)
		return

	var removed := 0
	for tile_id in tileset.get_tiles_ids():
		if tileset.tile_get_type(tile_id) != TileSet.TILE_TYPE_ATLAS:
			continue

		var size   := tileset.tile_get_region_size(tile_id)
		var tex: Texture2D = tileset.tile_get_texture(tile_id)
		if tex == null:
			continue

		var max_cols := int(tex.get_width()  / size.x)
		var max_rows := int(tex.get_height() / size.y)

		# Loop through every alternative bitmask entry
		for bitmask in tileset.tile_get_alternative_bitmasks(tile_id):
			var coord := tileset.tile_get_alternative_atlas_coord(tile_id, bitmask)
			if coord.x >= max_cols or coord.y >= max_rows:
				tileset.tile_remove_alternative_atlas_coords(tile_id, bitmask)
				removed += 1
	if removed > 0:
		print("Removed ", removed, " invalid atlas entries.")
		var err := ResourceSaver.save(tileset, path)
		if err != OK:
			printerr("Failed to save Tileset: error ", err)
			return
		print("Tileset saved clean.")
	else:
		print("No invalid atlas entries found.")

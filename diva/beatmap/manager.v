module beatmap

import wakasagihime.diva.beatmap.database

[heap]
pub struct DivaBeatmapManager {
pub mut:
	database &database.DivaDatabase
}

// Public
pub fn (mut manager DivaBeatmapManager) parse(path string) !&DivaBeatmap {
	if opcodes := i_diva_parse_beatmap_return_op_codes(path) {
		mut beatmap := &DivaBeatmap{
			opcodes: opcodes
			manager: manager
		}

		beatmap.evaluate_opcodes_to_native_objects()

		return beatmap
	}

	return error('failed.')
}

// Factory
pub fn create_beatmap_manager(mut loaded_database database.DivaDatabase) &DivaBeatmapManager {
	mut bm := &DivaBeatmapManager{
		database: loaded_database
	}

	return bm
}

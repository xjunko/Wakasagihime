module beatmap

import os
import wakasagihime.osu.internal.beatmap.object

pub fn parse(path string) &Beatmap {
	mut beatmap := &Beatmap{}

	beatmap.general.root_path = os.dir(path)
	beatmap.general.version_filename = os.base(path)

	mut lines := os.read_lines(path) or { panic('[osu!] Failed to read beatmap file: ${path}') }
	mut category := ''

	//
	mut i_unhandled := []string{}

	for line in lines {
		// Skip nothing
		if line.trim_space().len == 0 {
			continue
		}

		// Found a category
		if line.starts_with('[') {
			category_might_be_broken := get_category(line)

			if category_might_be_broken.len >= 0 {
				category = category_might_be_broken
				continue
			}
		}

		// Read based off category
		match category {
			'General' {
				items := parse_common_k_v(':', line)
				parse_osu_common_data_with_the_type_of[BeatmapInfoGeneral](mut beatmap.general,
					items[0], items[1])
			}
			'Editor' {
				// dont care
			}
			'Metadata' {
				items := parse_common_k_v(':', line)
				parse_osu_common_data_with_the_type_of[BeatmapInfoMetadata](mut beatmap.metadata,
					items[0], items[1])
			}
			'Difficulty' {
				items := parse_common_k_v(':', line)
				parse_osu_common_data_with_the_type_of[BeatmapInfoDifficulty](mut beatmap.difficulty,
					items[0], items[1])
			}
			'Events' {
				if beatmap.general.background_filename.len == 0 {
					items := parse_common_k_v(',', line)

					if items.len >= 2 {
						beatmap.general.background_filename = items[2].replace('"', '')
					}
				}
			}
			'HitObjects' {
				beatmap.objects << object.parse_hitobject(parse_common_k_v(',', line))
			}
			else {
				if category !in i_unhandled {
					println('[osu!] Unhandled category: ${category}')
					i_unhandled << category
				}
			}
		}
	}

	return beatmap
}

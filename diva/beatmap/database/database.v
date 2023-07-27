module database

import os

pub struct DivaData {
pub mut:
	name   string
	lyrics []string
}

[heap]
pub struct DivaDatabase {
pub mut:
	data []DivaData
}

pub fn create_database() &DivaDatabase {
	mut db := &DivaDatabase{}

	// Init Fallbacks
	for i := 0; i < 1000; i++ {
		db.data << DivaData{
			name: 'pv_${i:03d}'
		}
	}

	// Read database
	if lines := os.read_lines('/run/media/junko/2nd/Projects/Echidna/src/wakasagihime/diva/assets/db/pv_db.txt') {
		for line in lines {
			if line.trim_space().len == 0 {
				continue
			}

			items := line.split('.')

			if items.len <= 2 {
				continue
			}

			song_id := items[0].split('_')[1].int()

			// Song name
			if items[1].starts_with('song_name=') {
				db.data[song_id].name = items[1].split_nth('=', 2)[1]
			}

			// Lyrics
			if items[1].starts_with('lyric') {
				lyrics_data := items[2].split_nth('=', 2)
				lyrics_index := lyrics_data[0].int()
				lyrics_str := lyrics_data[1]

				// Resize
				to_add := (lyrics_index + 1) - db.data[song_id].lyrics.len

				for i := 0; i < to_add; i++ {
					db.data[song_id].lyrics << ''
				}

				db.data[song_id].lyrics[lyrics_index] = lyrics_str
			}
		}
	}

	return db
}

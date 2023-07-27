module beatmap

import os
import math
import encoding.binary
import beatrice.math.time
import wakasagihime.diva.beatmap.opcodes
import wakasagihime.diva.beatmap.objects

// Internal
fn i_diva_parse_beatmap_return_op_codes(path string) ![]opcodes.OPCode {
	if raw_file_data := os.read_bytes(path) {
		mut commands := []opcodes.OPCode{}

		// Start reading, 4 bytes per each header
		for i := 0; i < raw_file_data.len; i += 4 {
			current_opcode := int(binary.little_endian_u32(raw_file_data[i..i + 4]))

			// Read OPCodes
			if current_opcode in opcodes.codes {
				mut current_operation := opcodes.codes[current_opcode].clone()
				mut operation_params := []int{}

				for j := 0; j < current_operation.length; j++ {
					i += 4 // Skip 4 bytes in main buffer
					operation_params << int(binary.little_endian_u32(raw_file_data[i..i + 4]))
				}

				if operation_params.len > 0 {
					current_operation.arguments << operation_params
				}

				commands << current_operation
			}
		}

		return commands
	}

	return error('failed to read beatmap!')
}

//

pub struct DivaBeatmap {
mut:
	opcodes []opcodes.OPCode
	manager &DivaBeatmapManager
pub mut:
	objects []&objects.Note
	lyrics  []&objects.Lyric

	play_music_at f64
}

pub fn (mut beatmap DivaBeatmap) update(update_time f64) {
	// TODO: !!!!
}

// nice function name
pub fn (mut beatmap DivaBeatmap) evaluate_opcodes_to_native_objects() {
	// Simulate gameplay loop

	mut current_line := 0
	mut current_time := f64(0.0)
	mut current_bpm := 0
	mut current_tft := 0 // current target flying time

	for current_line < beatmap.opcodes.len {
		current_opcode := beatmap.opcodes[current_line]

		match current_opcode.action {
			'TIME' { // 0x01
				current_time = f64(current_opcode.arguments[0]) / 100.0
			}
			'TARGET' { // 0x06
				// TODO: Position is in nintendo ds's resolution screen
				//       This could be reversed with transforms
				//       But I prefer if we just convert it to
				//       native resolution here without doing the extra work.

				// FROM PD MODDING 2nd Server:
				/*
				yep, 3 place fixed point decimal (common in dsc) so / by 1000 to get coord
					then divide by 480 (for width) to convert from PSP coord to 0-1
					then multiply by 1280 ofc
					((1 / 1000) / 480) * 1280 = 0.002666666...
				*/
				mut note := &objects.Note{}

				// note.position.x = f64(current_opcode.arguments[1]) * 256 / 480000 - 16
				// note.position.y = f64(current_opcode.arguments[2]) * 192.0 / 270000 - 16
				note.position.x = f64(current_opcode.arguments[1]) * 0.002666667
				note.position.y = f64(current_opcode.arguments[2]) * 0.002666667
				note.angle = f64(current_opcode.arguments[3])
				note.distance = f64(current_opcode.arguments[4])

				// HACK: TODO: Assume everything is a single note, for now.
				note.typ = current_opcode.arguments[0]

				// TODO: Eyeballing this one
				// TODO: The fuck is going on here
				note.offset.x = note.position.x +
					math.sin((f64(note.angle) / 1000.0) * math.pi / 180.0) * (f64(note.distance) / 500)
				note.offset.y = note.position.y - math.cos((f64(note.angle) / 1000.0) * math.pi / 180.0) * (f64(note.distance) / 500)

				note.time.start = current_time - current_tft
				note.time.end = current_time

				beatmap.objects << note
			}
			'LYRIC' { // 0x18
				// TODO: hardcode
				lyrics := unsafe { &beatmap.manager.database.data[639].lyrics }

				if current_opcode.arguments[0] < lyrics.len {
					lyric := unsafe { &lyrics[current_opcode.arguments[0]] }

					beatmap.lyrics << &objects.Lyric{
						time: time.Time[f64]{current_time, current_time}
						text: lyric
					}
				}
			}
			'MUSIC_PLAY' {
				beatmap.play_music_at = current_time
			}
			'BAR_TIME_SET' { // 0x28
				current_bpm = current_opcode.arguments[0]
				// current_tft = 1000 / (current_bpm / ((current_opcode.arguments[1] + 1) * 60))
				current_tft = int((60.0 / f64(current_bpm)) * 4.0)
			}
			'TARGET_FLYING_TIME' { // 0x58
				current_tft = current_opcode.arguments[0] // in MS
				// current_bpm = 240000 / current_tft // TODO: Unused
			}
			else {}
		}

		current_line++
	}
}

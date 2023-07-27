module beatmap

// Code is based on
// https://github.com/nastys/nastys.github.io/blob/master/dsceditor/dsc_worker_read.js
import os
import math
import encoding.binary
import beatrice.math.vector
import beatrice.math.time
import beatrice.audio
import wakasagihime.diva.beatmap.opcodes

const (
	ft_fmts = [
		353510679,
		285614104,
		335874337,
		369295649,
		352458520,
		335745816,
		335618838,
		319956249,
		319296802,
		318845217,
	]
)

pub fn read_raw_beatmap(path string) []opcodes.OPCode {
	raw_file_data := os.read_bytes(path) or { panic('Fucked up: ${err}') }

	mut commands := []opcodes.OPCode{}

	for i := 0; i < raw_file_data.len; i += 4 {
		number := int(binary.little_endian_u32(raw_file_data[i..i + 4]))

		// Verify
		if i == 0 {
			if beatmap.ft_fmts.contains(number) {
				println('Detected format: AFT')
			}
		}

		// Read OPCODEs
		if number in opcodes.codes {
			mut operation := opcodes.codes[number].clone()
			mut params := []int{}

			for j := 0; j < operation.length; j++ {
				i += 4
				params << int(binary.little_endian_u32(raw_file_data[i..i + 4]))
			}

			if params.len > 0 {
				operation.arguments << params
			}

			commands << operation
		}
	}

	return commands
}

// Abstracted struct
// TODO: Move this
pub struct Note {
mut:
	command  opcodes.OPCode
	finished bool
pub mut:
	typ        int
	time       time.Time[f64]
	position   vector.Vector2[f64]
	angle      int
	wave_count int
	distance   int
	amplitude  int
	tft        int
	ts         int
}

pub fn (mut note Note) update(time f64) {
	if time >= note.time.end && !note.finished {
		// TODO: Play `hit-sfx`
		note.finished = true
	}
}

pub fn (mut note Note) get_note_sprite() string {
	return match note.typ {
		0, 4, 8, 18 { 'm_triangle' }
		1, 5, 9, 19 { 'm_circle' }
		2, 6, 10, 20 { 'm_cross' }
		3, 7, 11, 21 { 'm_square' }
		else { 'm_circle' }
	}
}

pub fn (mut note Note) get_note_background_sprite() string {
	return note.get_note_sprite() + '_bg'
}

pub struct Beatmap {
mut:
	internal_repr_of_commands []opcodes.OPCode
pub mut:
	objects   []&Note
	objects_i int
	queue     []&Note
}

pub fn (mut beatmap Beatmap) reset() {
}

pub fn (mut beatmap Beatmap) transform_commands_to_notes() {
	// Simulate gameplay loop
	mut current_line := 0
	mut current_time := 0
	mut current_bpm := 0
	mut current_tft := 0

	for current_line < beatmap.internal_repr_of_commands.len {
		current_command := beatmap.internal_repr_of_commands[current_line]

		match current_command.action {
			'TIME' { // 0x1
				current_time = current_command.arguments[0] / 100
			}
			'TARGET' { // 0x06
				// TODO: Position is in nintendo ds's resolution screen
				//       This could be reversed with transforms
				//       But I prefer if we just convert it to
				//       native resolution here without doing the extra work.

				beatmap.objects << &Note{
					typ: current_command.arguments[0]
					time: time.Time[f64]{f64(current_time), f64(current_time)}
					position: vector.Vector2[f64]{
						x: f64(current_command.arguments[1]) * 256.0 / 480000 - 16
						y: f64(current_command.arguments[2]) * 192.0 / 270000 - 16
					}
					angle: current_command.arguments[3]
					distance: current_command.arguments[4]
					amplitude: current_command.arguments[5]
					tft: current_tft
					ts: -1
				}
			}
			'BAR_TIME_SET' { // 0x28
				current_bpm = current_command.arguments[0]
				current_tft = 1000 / (current_bpm / ((current_command.arguments[1] + 1) * 60))
			}
			'TARGET_FLYING_TIME' { // 0x58
				current_tft = current_command.arguments[0]
				current_bpm = 240000 / current_tft
			}
			'LYRIC' { // 0x24
				println(current_command)
			}
			else {}
		}

		// Last
		current_line++
	}
}

pub fn (mut beatmap Beatmap) update(time f64) {
	// Add to queue
	preempt := 5000.0 // diva is abit unique cuz the
	// start time can be varied,
	// so fuck it, 5 second time window it is.
	for i := beatmap.objects_i; i < beatmap.objects.len; i++ {
		if time >= beatmap.objects[i].time.start - preempt {
			beatmap.queue << beatmap.objects[i]
			beatmap.objects_i++
			continue
		}
	}

	// Remove from queue
	for i := 0; i < beatmap.queue.len; i++ {
		if time >= beatmap.queue[i].time.end + preempt {
			beatmap.queue = beatmap.queue[1..]
			i--
			continue
		}

		// If not update
		beatmap.queue[i].update(time)
	}
}

pub fn (mut beatmap Beatmap) draw() {
}

pub fn parse(path string) &Beatmap {
	mut beatmap := &Beatmap{}

	beatmap.internal_repr_of_commands = read_raw_beatmap(path)
	beatmap.transform_commands_to_notes()

	return beatmap
}

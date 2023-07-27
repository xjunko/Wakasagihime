module beatmap

import os

// Dumb
pub struct Line {
pub:
	left  string
	right string
}

pub struct MeasureChange {
pub:
	index int
	value int
}

pub struct RawObject {
pub:
	tick  int
	value string
}

pub struct NoteObject {
pub mut:
	tick  int
	lane  int
	width int
	typ   int
}

pub struct BarLength {
pub mut:
	measure int
	length  int
}

pub struct Score {
pub mut:
	tap_notes         []NoteObject
	directional_notes []NoteObject
	slides            [][]NoteObject
}

pub fn (mut score Score) to_time(tick int) int {
	println('TODO::TICK')
	return 0
}

pub fn parse(path string) Score {
	mut score := Score{}

	mut meta := map[string]string{}
	mut lines := []Line{}
	mut measure_changes := []MeasureChange{}

	mut sus := os.read_lines(path) or { panic('Skill issue: ${err}') }

	sus = sus
		.map(it.trim_space())
		.filter(it.starts_with('#'))

	for line in sus {
		is_line := line.contains(':')

		index := line.index([' ', ':'][int(is_line)]) or { continue }

		left := line[1..index]
		right := line[index + 1..]

		if is_line {
			lines << Line{
				left: left
				right: right
			}
		} else if left == 'MEASUREBS' {
			measure_changes << MeasureChange{
				index: lines.len
				value: right.int()
			}
		} else {
			meta[left] = right
		}
	}

	mut bar_length_objects := []BarLength{}

	for index, line in lines {
		header, data := line.left, line.right

		if header.len != 5 {
			continue
		}
		if !header.starts_with('02') {
			continue
		}

		measure := header[0..3].int() +
			retarded_javascript_find[MeasureChange](measure_changes, index).value

		println(header[0..3] + '|' + header)
	}

	// Ours
	println('=== Echidna ===')
	println('Lines = ${lines.len}')
	println('MeasureChanges = ${measure_changes.len}')
	println('TapNotes = ${score.tap_notes.len}')
	println('Directionals = ${score.directional_notes.len}')
	println('Slides = ${score.slides.len}')

	return score
}

fn retarded_javascript_find[T](array []T, index int) T {
	for array_index, _ in array {
		if array_index <= index {
			return array[array_index]
		}
	}

	return T{}
}

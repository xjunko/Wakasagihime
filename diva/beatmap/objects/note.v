module objects

import beatrice.math.vector
import beatrice.math.time

pub struct Note {
	BaseNode
pub mut:
	done     bool
	typ      int
	time     time.Time[f64]
	position vector.Vector2[f64]
	offset   vector.Vector2[f64]
	angle    f64
	distance f64
}

pub fn (note &Note) i_get_note_sprite() string {
	return match note.typ {
		0, 4, 8, 18 { 'm_triangle' }
		1, 5, 9, 19 { 'm_circle' }
		2, 6, 10, 20 { 'm_cross' }
		3, 7, 11, 21 { 'm_square' }
		else { 'm_circle' }
	}
}

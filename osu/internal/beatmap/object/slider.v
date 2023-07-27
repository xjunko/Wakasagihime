module object

import beatrice.math.vector

pub struct Slider {
	HitObject
pub mut:
	points []vector.Vector2[f64] // TODO: Replace this with Curve
}

pub fn new_slider(data []string) &Slider {
	mut slider := &Slider{
		HitObject: parse_hitobject_internal(data)
	}

	// index 0 is slider type
	for point_data in data[5].split('|')[1..] {
		items := point_data.split(':')

		slider.points << vector.Vector2[f64]{
			x: items[0].f64()
			y: items[1].f64()
		}
	}

	return slider
}

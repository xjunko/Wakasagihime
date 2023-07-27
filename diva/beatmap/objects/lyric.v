module objects

import beatrice.math.time

pub struct Lyric {
	BaseNode
pub mut:
	text string
	time time.Time[f64]
}

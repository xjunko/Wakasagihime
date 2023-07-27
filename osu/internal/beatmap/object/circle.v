module object

import beatrice.graphic.sprite
import wakasagihime.osu.internal.skin
import beatrice.math.time

const (
	is_hidden = false
)

pub struct DiffTODO {
pub mut:
	preempt f64 = 1000.0
	fade_in f64 = 200.0
	hit50   f64 = 300.0
}

pub struct Circle {
	HitObject
mut:
	hitcircle         &sprite.Sprite = unsafe { nil }
	hitcircle_overlay &sprite.Sprite = unsafe { nil }
	approach_circle   &sprite.Sprite = unsafe { nil }
pub mut:
	sample  int
	sprites []&sprite.Sprite
}

pub fn (mut circle Circle) init(mut current_skin skin.Skin) {
	circle.HitObject.init(mut current_skin)

	// TODO: Le bootleg osu
	circle.hitcircle = &sprite.Sprite{}
	circle.hitcircle_overlay = &sprite.Sprite{}
	circle.approach_circle = &sprite.Sprite{}

	//
	mut diff := DiffTODO{}
	start_time := circle.time.start - diff.preempt
	end_time := circle.time.start

	//
	circle.hitcircle.textures << current_skin.get_asset_with_name('hitcircle.png')
	circle.hitcircle_overlay.textures << current_skin.get_asset_with_name('hitcircleoverlay.png')
	circle.approach_circle.textures << current_skin.get_asset_with_name('approachcircle.png')

	circle.sprites << circle.hitcircle
	circle.sprites << circle.hitcircle_overlay
	circle.sprites << circle.approach_circle

	mut circles := []&sprite.Sprite{}
	circles << circle.hitcircle
	circles << circle.hitcircle_overlay
	circles << circle.approach_circle

	for mut c in circles {
		c.add_transform(
			typ: .move
			time: time.Time[f64]{start_time, start_time}
			before: [
				circle.position.x,
				circle.position.y,
			]
		)

		if object.is_hidden {
			c.add_transform(
				typ: .fade
				time: time.Time[f64]{start_time, start_time + diff.preempt * 0.4}
				before: [0.0]
				after: [255.0]
			)
			c.add_transform(
				typ: .fade
				time: time.Time[f64]{start_time + diff.preempt * 0.4, start_time +
					diff.preempt * 0.7}
				before: [255.0]
				after: [0.0]
			)
		} else {
			c.add_transform(
				typ: .fade
				time: time.Time[f64]{start_time, start_time + diff.fade_in}
				before: [0.0]
				after: [255.0]
			)
			c.add_transform(
				typ: .fade
				time: time.Time[f64]{end_time, end_time + diff.hit50}
				before: [
					255.0,
				]
			)
		}

		// Done
		// s.reset_size_based_on_texture(factor: (circle.diff.circle_radius * 1.05 * 2) / 128)
		c.reset_attributes_based_on_transforms()
	}
}

pub fn new_circle(data []string) &Circle {
	mut circle := &Circle{
		HitObject: parse_hitobject_internal(data)
		sample: data[4].int()
	}

	return circle
}

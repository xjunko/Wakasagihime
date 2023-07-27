module hitsystem

import beatrice.math.time
import beatrice.math.vector
import beatrice.math.easing
import beatrice.graphic.backend
import beatrice.graphic.sprite
import wakasagihime.diva.beatmap.objects

pub struct HitNote {
mut:
	last_update f64
	data        &objects.Note
	done        bool
	backend     &backend.IBackend = &backend.BaseBackend{}
pub mut:
	sprites []&sprite.Sprite
}

pub fn (mut hitnote HitNote) init(mut current_backend backend.IBackend) {
	hitnote.backend = unsafe { current_backend }

	// NOTE: This is the most crude attempt at doing note animations ever
	// NOTE: This is fucked but it's the only way of doing this easily
	// 0 - Fly
	// 1 - Slot
	// 2 - Rotating Bar
	for i, tex_name in ['${hitnote.data.i_get_note_sprite()}.png',
		'${hitnote.data.i_get_note_sprite()}_bg.png', 'm_arrow.png'] {
		mut note_sprite := &sprite.Sprite{
			textures: [
				current_backend.create_image('/run/media/junko/2nd/Projects/Echidna/src/wakasagihime/diva/assets/textures/${tex_name}'),
			]
		}

		// Rotating shit offset cuz shits rotating
		if i == 2 {
			note_sprite.origin = vector.bottom_centre
			note_sprite.origin_offset.y = -8.0
		}

		// Common
		mut extra_y := 0.0

		if i == 2 {
			extra_y = 8.0
		}

		note_sprite.add_transform(
			typ: .move
			time: hitnote.data.time
			before: [[hitnote.data.offset.x, hitnote.data.offset.y],
				[hitnote.data.position.x, hitnote.data.position.y + extra_y]][int(i != 0)]
			after: [hitnote.data.position.x, hitnote.data.position.y + extra_y]
		)

		note_sprite.add_transform(
			typ: .scale
			time: hitnote.data.time
			easing: [easing.linear, easing.elastic_out][int(i == 1)]
			before: [[0.5, 0.5], [0.8, 0.8]][int(i == 1)]
			after: [0.5, 0.5]
		)

		// Angle
		if i == 2 {
			note_sprite.add_transform(
				typ: .angle
				time: hitnote.data.time
				before: [-3.142 * 2.0]
				after: [0.0]
			)
		}

		// Scale and fade out
		note_sprite.add_transform(
			typ: .fade
			time: hitnote.data.time
			before: [255.0]
			after: [255.0]
		)

		note_sprite.add_transform(
			typ: .fade
			time: time.Time[f64]{hitnote.data.time.end, hitnote.data.time.end + 100.0}
			before: [0.0]
			after: [0.0]
		)
		note_sprite.reset_size_based_on_texture()

		note_sprite.reset_attributes_based_on_transforms()

		// Add
		hitnote.sprites << note_sprite
	}

	// Move the flying thing to the last index (so that it draws ontop)
	hitnote.sprites << hitnote.sprites[0]
	hitnote.sprites = hitnote.sprites[1..]
}

pub fn (mut hitnote HitNote) update(update_time f64) {
	hitnote.last_update = update_time

	for i := 0; i < hitnote.sprites.len; i++ {
		hitnote.sprites[i].update(update_time)
	}
}

pub fn (mut hitnote HitNote) draw(current_backend &backend.IBackend) {
	if hitnote.last_update < hitnote.data.time.start
		|| hitnote.last_update > hitnote.data.time.end + 1000.0 {
		return
	}

	// HACK: Fake hit
	if hitnote.last_update >= hitnote.data.time.end && !hitnote.done {
		hitnote.done = true
		hitnote.hit(false)
	}

	for i := 0; i < hitnote.sprites.len; i++ {
		hitnote.sprites[i].draw(backend: unsafe { current_backend })
	}
}

// Anim
pub fn (mut hitnote HitNote) hit(miss bool) {
	if miss {
		return
	}

	// This kinda sucks but whatever
	for i, tex_name in ['m_hit.png', 'm_hit_effect.png'] {
		mut hit_sprite := &sprite.Sprite{
			textures: [
				hitnote.backend.create_image('/run/media/junko/2nd/Projects/Echidna/src/wakasagihime/diva/assets/textures/${tex_name}'),
			]
			effects: .add
		}

		hit_sprite.add_transform(
			typ: .move
			time: hitnote.data.time
			before: [hitnote.data.position.x, hitnote.data.position.y]
			after: [hitnote.data.position.x, hitnote.data.position.y]
		)

		hit_sprite.add_transform(
			typ: .fade
			time: time.Time[f64]{hitnote.data.time.end, hitnote.data.time.end + 100.0}
			easing: easing.quad_out
			before: [0.0]
			after: [255.0]
		)

		if i == 0 {
			hit_sprite.add_transform(
				typ: .scale
				time: time.Time[f64]{hitnote.data.time.end, hitnote.data.time.end + 300.0}
				easing: easing.elastic_out
				before: [0.3, 0.3]
				after: [0.7, 0.7]
			)

			hit_sprite.add_transform(
				typ: .fade
				time: time.Time[f64]{hitnote.data.time.end + 200.0, hitnote.data.time.end + 300.0}
				easing: easing.quad_out
				before: [255.0]
				after: [0.0]
			)
		} else {
			hit_sprite.add_transform(
				typ: .scale
				time: time.Time[f64]{hitnote.data.time.end, hitnote.data.time.end + 400.0}
				easing: easing.elastic_out
				before: [0.3, 0.3]
				after: [0.9, 0.9]
			)

			hit_sprite.add_transform(
				typ: .fade
				time: time.Time[f64]{hitnote.data.time.end + 300.0, hitnote.data.time.end + 400.0}
				easing: easing.quad_out
				before: [255.0]
				after: [0.0]
			)
		}

		hit_sprite.reset_size_based_on_texture(
			keep_ratio: true
			resize_to: vector.Vector2[f64]{
				x: 200.0
				y: 200.0
			}
		)

		hit_sprite.reset_attributes_based_on_transforms()

		hitnote.sprites << hit_sprite
	}
}

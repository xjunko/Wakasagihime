module object

import beatrice.math.vector
import beatrice.math.time
import beatrice.component.object
import wakasagihime.osu.internal.skin
import beatrice.graphic.backend

pub interface IHitObject {
mut:
	typ HitObjectType
	time time.Time[f64]
	position vector.Vector2[f64]
	combo_new bool
	combo_number int
	combo_color object.GameObjectColor[f64]
	combo_color_offset int
	init(mut skin skin.Skin)
	update(time f64)
	draw(arg backend.DrawConfig)
}

pub enum HitObjectType {
	note = 1 << 0
	slider = 1 << 1
	spinner = 1 << 3
}

pub struct HitObject {
	object.GameObject
mut:
	id   int
	skin &skin.Skin = unsafe { nil }
pub mut:
	typ HitObjectType

	start_position vector.Vector2[f64]
	end_position   vector.Vector2[f64]

	combo_new          bool
	combo_number       int
	combo_color        object.GameObjectColor[f64]
	combo_color_offset int
}

pub fn (mut hitobject HitObject) init(mut current_skin skin.Skin) {
	hitobject.skin = current_skin
}

pub fn (mut hitobject HitObject) update(update_time f64) {
}

pub fn (mut hitobject HitObject) draw(arg backend.DrawConfig) {
}

// Parse
pub fn parse_hitobject_internal(data []string) &HitObject {
	position := vector.Vector2[f64]{data[0].f64(), data[1].f64()}
	object_time := time.Time[f64]{data[2].f64(), data[2].f64()}
	object_type := data[3].u32()

	return &HitObject{
		position: position
		start_position: position
		end_position: position
		time: object_time
		combo_new: (object_type & 4) == 4
		combo_color_offset: int((object_type >> 4) & 7)
	}
}

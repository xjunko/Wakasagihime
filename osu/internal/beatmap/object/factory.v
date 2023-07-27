module object

pub fn parse_hitobject(data []string) IHitObject {
	object_type := data[3].int()

	if (object_type & int(HitObjectType.note)) > 0 {
		return new_circle(data)
	} else if (object_type & int(HitObjectType.slider)) > 0 {
		return new_slider(data)
	} else if (object_type & int(HitObjectType.spinner)) > 0 {
		return new_circle(data) // TODO: im too lazy
	}

	println('[${@FN}] Weird ass object type: ${object_type}')

	return new_circle(data)
}

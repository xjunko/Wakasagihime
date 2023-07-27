module beatmap

// Utils
fn parse_osu_common_data_with_the_type_of[T](mut target T, name string, value string) {
	$for field in T.fields {
		if field.attrs.len >= 1 {
			for possible_alias in field.attrs {
				if possible_alias == name {
					// This is ugly but itll do for now
					$if field.typ is string {
						target.$(field.name) = value
					} $else $if field.typ is int {
						target.$(field.name) = value.int()
					} $else $if field.typ is f32 {
						target.$(field.name) = value.f32()
					} $else $if field.typ is i64 {
						target.$(field.name) = value.i64()
					} $else $if field.typ is f64 {
						target.$(field.name) = value.f64()
					} $else $if field.typ is bool {
						target.$(field.name) = value == '1'
					} $else {
						panic('Type not supported: ${field.typ}')
					}
				}
			}
		}
	}
}

fn get_category(line string) string {
	return line.replace('[', '').replace(']', '').trim_space()
}

fn parse_common_k_v(sep string, line string) []string {
	return line.split(sep).map(it.trim_space())
}

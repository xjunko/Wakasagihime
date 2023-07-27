// This entire thing is a hack
// I am very sorry
module skin

import beatrice.graphic.backend
import beatrice.graphic.texture
import os

const (
	manager = &SkinManager{
		backend: &backend.BaseBackend{}
	}
)

//
pub struct SkinManager {
pub mut:
	backend &backend.IBackend
	skins   map[string]&Skin
}

pub fn (mut skin_manager SkinManager) init(mut current_backend backend.IBackend) {
	skin_manager.backend = unsafe { current_backend }

	// TODO: Default skin
	skin_manager.skins['default'] = &Skin{
		backend: skin_manager.backend
		root: '/run/media/junko/2nd/Projects/dementia/assets/osu/skins/default/'
	}
}

//
[heap]
pub struct Skin {
mut:
	backend &backend.IBackend
	cache   map[string]texture.ITexture
pub mut:
	root string
}

pub fn (mut skin Skin) get_asset_with_name(name string) texture.ITexture {
	// If not in cache, load the image
	if name !in skin.cache {
		mut might_be_our_file_path := os.join_path(skin.root, name)

		// Literal Search
		if os.exists(might_be_our_file_path) {
			skin.cache[name] = skin.backend.create_image(might_be_our_file_path)
		}

		// Lossy Search (if not in cache still)
		if name !in skin.cache {
			for file in os.glob(os.join_path(skin.root, '*')) or { [''] } {
				if os.base(file).to_lower() == name.to_lower() {
					skin.cache[name] = skin.backend.create_image(file)
				}
			}
		}
	}

	// Somehow not in cache,
	if name !in skin.cache {
		println("[Skin.${@FN}] File doesn't exists, what the fuck man. | ${name}")
	}

	return skin.cache[name]
}

// "utils" of some kind
pub fn get_manager() &SkinManager {
	return unsafe { skin.manager }
}

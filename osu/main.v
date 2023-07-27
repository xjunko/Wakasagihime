module osu

import wakasagihime.osu.internal.beatmap
import beatrice.graphic.window as cwindow
import beatrice.audio
import wakasagihime.osu.internal.skin
import beatrice.graphic.sprite
import beatrice.math.vector
import beatrice.math.time

const (
	fade_in_intro_time = f64(2000.0)
)

pub struct Window {
	cwindow.CommonWindow
mut:
	audio &audio.IAudioBackend
pub mut:
	// vfmt off
	beatmap &beatmap.Beatmap = unsafe { nil }
	skin_manager    &skin.SkinManager = unsafe { nil }
	// vfmt on
}

pub fn (mut window Window) init(_ voidptr) {
	window.audio.init()

	window.beatmap = beatmap.parse('/run/media/junko/2nd/Games/osu!/Songs/1569012 Wakeshima Kanon - Not For Sale Fossil (Cut Ver)/Wakeshima Kanon - Not For Sale Fossil (Cut Ver.) (-Nenu- 3) [Reliquiae].osu')

	window.skin_manager = skin.get_manager()
	window.skin_manager.init(mut window.backend)

	window.beatmap.init_objects(mut window.skin_manager.skins['default'] or { panic('Fucked up!') })

	// Load background (with fade in, very cool)
	mut beatmap_background := &sprite.Sprite{
		textures: [window.backend.create_image(window.beatmap.get_background_file())]
		size: vector.Vector2[f64]{1280.0, 720.0}
		position: vector.Vector2[f64]{1280.0, 720.0}.scale(0.5)
		origin: vector.centre
		always_visible: true
	}

	beatmap_background.add_transform(
		typ: .fade
		time: time.Time[f64]{0.0, osu.fade_in_intro_time}
		before: [
			0.0,
		]
		after: [255.0]
	)
	beatmap_background.reset_attributes_based_on_transforms()
	window.sprite_manager.add(mut beatmap_background)

	// Update thread
	spawn fn (mut window Window) {
		mut counter := time.TimeCounter{}
		mut limiter := time.Limiter{
			fps: 240
		}

		counter.reset()

		for {
			window.mutex.@lock()

			counter.tick()

			window.sprite_manager.update(counter.time)
			window.beatmap.update(counter.time)

			window.mutex.unlock()

			limiter.sync()
		}
	}(mut window)
}

pub fn (mut window Window) draw(_ voidptr) {
	window.mutex.@lock()

	window.backend.begin()

	window.sprite_manager.draw(backend: window.backend)
	window.beatmap.draw(backend: window.backend)

	window.backend.end()

	window.mutex.unlock()
}

pub fn play() {
	mut audio_backend := &audio.IAudioBackend(&audio.MABackend{})

	$if bass_audio_backend ? {
		audio_backend = &audio.BASSBackend{}
	}

	mut window := &Window{
		audio: audio_backend
	}

	window.start(
		width: 1280
		height: 720
		init_fn: window.init
		frame_fn: window.draw
	)
}

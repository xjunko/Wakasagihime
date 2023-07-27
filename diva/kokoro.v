module diva

import gx
import beatrice.audio
import beatrice.math.time
import beatrice.math.vector
import beatrice.graphic.window as cwindow
import beatrice.graphic.window.input
import beatrice.graphic.sprite
import beatrice.component.object
import wakasagihime.diva.beatmap
import wakasagihime.diva.beatmap.database
import wakasagihime.diva.beatmap.objects
import wakasagihime.diva.beatmap.hitsystem

pub const (
	preempt_intro = 1000.0
)

pub struct DivaWindow {
	cwindow.CommonWindow
mut:
	audio &audio.IAudioBackend = unsafe { nil }
pub mut:
	// vfmt off
	database &database.DivaDatabase = unsafe { nil }
	manager  &beatmap.DivaBeatmapManager = unsafe { nil }
	beatmap  &beatmap.DivaBeatmap	= unsafe { nil }

	//
	objects []&hitsystem.HitNote

	// Temporary
	current_lyric &objects.Lyric = &objects.Lyric{text: "b"} //unsafe { nil }
	hit_sfx       audio.ISample 
	// vfmt on
	// Layers
	slot_layer &sprite.Manager = sprite.new_manager()
	fly_layer  &sprite.Manager = sprite.new_manager()
}

pub fn (mut window DivaWindow) init(_ voidptr) {
	window.database = database.create_database()
	window.manager = beatmap.create_beatmap_manager(mut window.database)

	window.beatmap = window.manager.parse('/run/media/junko/2nd/Projects/Echidna/src/wakasagihime/diva/assets/maps/tokyoteddybear/pv_639_extreme.dsc') or {
		panic(err)
	}

	// Graphic
	window.i_init_ui()
	window.i_init_objects()

	// Audio
	window.audio.init()

	// Hit sfx
	window.hit_sfx = window.audio.load_sample('/run/media/junko/2nd/Projects/Echidna/src/wakasagihime/diva/assets/sfx/hit.ogg')

	window.hit_sfx.set_volume(0.4)

	// Update thread
	spawn fn (mut window DivaWindow) {
		mut limiter := &time.Limiter{
			fps: 120
		}
		mut counter := &time.TimeCounter{}

		//
		counter.reset()

		// Music
		mut song := window.audio.load_audio('/run/media/junko/2nd/Projects/Echidna/src/wakasagihime/diva/assets/maps/tokyoteddybear/pv_639.ogg')

		song.set_volume(0.25)

		for {
			window.mutex.@lock()

			// Update
			if counter.time - diva.preempt_intro >= window.beatmap.play_music_at && !song.playing {
				song.play()
			}

			counter.tick()
			window.update(counter.time - diva.preempt_intro)

			window.mutex.unlock()
			limiter.sync()
		}
	}(mut window)
}

pub fn (mut window DivaWindow) i_init_ui() {
	// Background
	mut background := &sprite.Sprite{
		textures: [
			window.backend.create_image('/run/media/junko/2nd/Projects/Echidna/src/wakasagihime/diva/assets/textures/g_default_bg.png'),
		]
		always_visible: true
		origin: vector.top_left
	}
	background.color.a = 100

	background.reset_size_based_on_texture(
		keep_ratio: true
		resize_to: vector.Vector2[f64]{
			x: 1280.0
			y: 720.0
		}
	)

	window.sprite_manager.add(mut background)
}

pub fn (mut window DivaWindow) i_init_objects() {
	for i := 0; i < window.beatmap.objects.len; i++ {
		current_note := unsafe { window.beatmap.objects[i] }

		mut note := &hitsystem.HitNote{
			data: current_note
		}

		note.init(mut window.backend)

		window.objects << note
	}
}

pub fn (mut window DivaWindow) update(update_time f64) {
	// HACK: bro
	// Refer to line 223
	game_update_offset := 1220.0

	// Sprite
	window.sprite_manager.update(update_time - game_update_offset)
	window.fly_layer.update(update_time - game_update_offset)
	window.slot_layer.update(update_time - game_update_offset)

	// Objects
	for i := 0; i < window.objects.len; i++ {
		window.objects[i].update(update_time - game_update_offset)
	}

	// Find current lyric
	for lyric in window.beatmap.lyrics {
		if update_time >= lyric.time.start - 500.0 && update_time <= lyric.time.end {
			window.current_lyric = unsafe { lyric }
			break
		}
	}

	// Play hit sound
	// HACK: Note time is offset by -1700.0 for some reason
	// TODO: Found out why.
	for mut note in window.beatmap.objects {
		if (update_time - game_update_offset) >= note.time.end && !note.done {
			// window.hit_sfx.play()
			note.done = true
		}
	}
}

pub fn (mut window DivaWindow) draw(_ voidptr) {
	window.mutex.@lock()
	window.backend.begin()

	// Draw
	window.sprite_manager.draw(backend: window.backend)
	window.slot_layer.draw(backend: window.backend)
	window.fly_layer.draw(backend: window.backend)

	// Objects
	for i := 0; i < window.objects.len; i++ {
		window.objects[i].draw(window.backend)
	}

	// Lyric
	if !isnil(window.current_lyric) {
		font_size := 30
		subtitle_pos := [1280.0 / 2.0, 720 - 100.0]!
		sub_size := [
			(f64(window.backend.text_width('D')) / 16.0) * font_size * window.current_lyric.text.len,
			50.0,
		]!

		window.backend.draw_rect_filled(subtitle_pos[0] - sub_size[0] / 2, subtitle_pos[1],
			sub_size[0], sub_size[1], object.GameObjectColor[f64]{0.0, 0.0, 0.0, 100.0})

		window.backend.draw_text(subtitle_pos[0], (subtitle_pos[1] + sub_size[1] / 2) - (font_size / 2),
			window.current_lyric.text, gx.TextCfg{
			color: gx.white
			align: .center
			size: font_size
		})
	}

	window.backend.end()
	window.mutex.unlock()
}

pub fn play() {
	mut window := &DivaWindow{
		audio: &audio.BASSBackend{}
		hit_sfx: unsafe { nil }
	}

	// TEST: input
	// vfmt off
	window.input.mouse.subscribe(fn [mut window] (state input.InputState, button input.ButtonType, pos vector.Vector2[f64]) {
		// vfmt on
		match state {
			.mouse_click {
				window.hit_sfx.play()
			}
			else {}
		}
	})

	window.start(
		width: 1280
		height: 720
		init_fn: window.init
		frame_fn: window.draw
		vsync: false
	)
}

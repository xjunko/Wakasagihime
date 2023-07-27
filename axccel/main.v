module axccel

import gx
import time as vtime
import beatrice.audio
import beatrice.math.time
import beatrice.math.vector
import beatrice.graphic.sprite
import beatrice.graphic.export
import beatrice.graphic.window as cwindow
import beatrice.graphic.backend
import beatrice.component.object

pub const (
	render_to_video  = false
	resolution       = vector.Vector2[f64]{1280.0, 720.0}
	resolution_ratio = resolution.y / 720.0
)

pub struct MusicData {
pub mut:
	title  string
	artist string

	thumbnail  &sprite.Sprite = unsafe { nil }
	background &sprite.Sprite = unsafe { nil }

	audio    audio.IAudio = audio.BaseAudio{}
	position f64
	duration f64

	color_scheme object.GameObjectColor[f64] = object.GameObjectColor[f64]{255.0, 192.0, 203.0, 255.0}
}

pub struct AquaWindow {
	cwindow.CommonWindow
mut:
	audio_backend &audio.IAudioBackend = unsafe { nil }
pub mut:
	music &MusicData    = unsafe { nil }
	video &export.Video = unsafe { nil }
}

pub fn (mut window AquaWindow) init(_ voidptr) {
	// Init audio backend
	window.audio_backend.init()

	// Initialize everything
	if axccel.render_to_video {
		window.video = &export.Video{
			resolution: axccel.resolution
			audio: &audio.BASSOffscreenBackend(window.audio_backend) // HACK: ?? lol nice
		}
	}

	// TODO: Music is hardcoded
	window.music = &MusicData{}

	// Meta
	window.music.title = 'w/WWW'
	window.music.artist = 'Kijibato feat. 星宮とと'

	// Background & Thumbnail
	// window.music.background = &sprite.Sprite{
	// 	textures: [
	// 		window.backend.create_image('/run/media/junko/2nd/Projects/wWWW/assets/last_friday_night/background.jpg'),
	// 	]
	// 	always_visible: true
	// 	position: axccel.resolution.scale(0.5)
	// }

	window.music.thumbnail = &sprite.Sprite{
		textures: [
			window.backend.create_image('/run/media/junko/2nd/Projects/wWWW/assets/WWW/thumbnail.png'),
		]
		always_visible: true
	}

	// Thumbnail Position
	window.music.thumbnail.add_transform(
		typ: .move
		time: time.Time[f64]{0.0, 1.0}
		before: [
			350.0 * axccel.resolution_ratio,
			360.0 * axccel.resolution_ratio,
		]
		after: [
			350.0 * axccel.resolution_ratio,
			360.0 * axccel.resolution_ratio,
		]
	)

	// Reset
	// window.music.background.reset_size_based_on_texture(
	// 	keep_ratio: true
	// 	keep_height: true
	// 	resize_to: axccel.resolution
	// )

	window.music.thumbnail.reset_size_based_on_texture(
		resize_to: vector.Vector2[f64]{500.0, 500.0}
	)

	window.music.thumbnail.reset_attributes_based_on_transforms()

	// Load music
	window.music.audio = window.audio_backend.load_audio('/run/media/junko/2nd/Projects/wWWW/assets/WWW/audio.mp3')
	window.music.duration = window.music.audio.get_length()

	window.music.audio.set_volume(0.25)

	// Update thread
	spawn fn (mut window AquaWindow) {
		vtime.sleep(500 * vtime.millisecond)
		window.music.audio.play()

		// Limiter
		mut limiter := &time.Limiter{
			fps: 240
		}
		mut counter := &time.TimeCounter{}

		counter.reset()

		for {
			window.mutex.@lock()
			counter.tick()

			// Update
			window.music.position = window.music.audio.get_position()
			window.update(counter.time)

			window.mutex.unlock()
			limiter.sync()
		}
	}(mut window)
}

pub fn (mut window AquaWindow) update(update_time f64) {
	// NOTE: Unused
	window.sprite_manager.update(update_time)
}

pub fn (mut window AquaWindow) draw(_ voidptr) {
	window.mutex.@lock()
	window.backend.begin()

	// Background color
	window.backend.draw_rect_filled(0, 0, axccel.resolution.x, axccel.resolution.y, window.music.color_scheme)

	// Background Image
	if !isnil(window.music.background) {
		window.music.background.draw(backend: window.backend)
	}

	// Background Dim
	window.backend.draw_rect_filled(0, 0, axccel.resolution.x, axccel.resolution.y, object.GameObjectColor[f64]{0.0, 0.0, 0.0, 0.0})

	// Thumbnail
	thumbnail_bg_rect_outline := vector.Vector2[f64]{350.0 - (510.0 / 2), 360.0 - (510.0 / 2)}.scale(axccel.resolution_ratio)
	thumbnail_bg_rect_inline := vector.Vector2[f64]{350.0 - (500.0 / 2), 360.0 - (500.0 / 2)}.scale(axccel.resolution_ratio)

	window.backend.draw_rect_filled(thumbnail_bg_rect_outline.x, thumbnail_bg_rect_outline.y,
		510.0 * axccel.resolution_ratio, 510.0 * axccel.resolution_ratio, object.GameObjectColor[f64]{0.0, 0.0, 0.0, 25.0})

	window.backend.draw_rect_filled(thumbnail_bg_rect_inline.x, thumbnail_bg_rect_inline.y,
		500.0 * axccel.resolution_ratio, 500.0 * axccel.resolution_ratio, object.GameObjectColor[f64]{255.0, 255.0, 255.0, 255.0})

	window.music.thumbnail.draw(backend: window.backend)

	// Title, currently only supports GG backend
	mut ptr_backend := unsafe { window.backend }

	if mut ptr_backend is backend.GGBackend {
		// Title
		C.fonsSetBlur(ptr_backend.ctx.ft.fons, 2.0)
		window.backend.draw_text(650.0 * axccel.resolution_ratio, (125.0 + 2) * axccel.resolution_ratio,
			window.music.title, gx.TextCfg{
			color: gx.Color{0, 0, 0, 100}
			size: int(64 * int(axccel.resolution_ratio))
			bold: true
		})
		C.fonsSetBlur(ptr_backend.ctx.ft.fons, 0.0)
		window.backend.draw_text(650.0 * axccel.resolution_ratio, (125.0 + 0.0) * axccel.resolution_ratio,
			window.music.title, gx.TextCfg{
			color: gx.white
			size: int(64 * int(axccel.resolution_ratio))
			bold: true
		})

		// Artist
		C.fonsSetBlur(ptr_backend.ctx.ft.fons, 2.0)
		window.backend.draw_text(650.0 * axccel.resolution_ratio, (195.0 + 2.0) * axccel.resolution_ratio,
			window.music.artist, gx.TextCfg{
			color: gx.Color{0, 0, 0, 100}
			size: int(25 * int(axccel.resolution_ratio))
			bold: true
		})
		C.fonsSetBlur(ptr_backend.ctx.ft.fons, 0.0)
		window.backend.draw_text(650.0 * axccel.resolution_ratio, (195.0 + 0.0) * axccel.resolution_ratio,
			window.music.artist, gx.TextCfg{
			color: gx.white
			size: int(25 * int(axccel.resolution_ratio))
			bold: true
		})
	}

	// Progress Line
	bar_rect_outline := vector.Vector2[f64]{900.0 - (510.0 / 2), 240.0 - (12.0 / 2)}.scale(axccel.resolution_ratio)
	bar_rect_inline := vector.Vector2[f64]{900.0 - (500.0 / 2), 240.0 - (5.0 / 2)}.scale(axccel.resolution_ratio)

	window.backend.draw_rect_filled(bar_rect_outline.x, bar_rect_outline.y, 510.0 * axccel.resolution_ratio,
		15.0 * axccel.resolution_ratio, object.GameObjectColor[f64]{0.0, 0.0, 0.0, 25.0})

	window.backend.draw_rect_filled(bar_rect_inline.x, bar_rect_inline.y, 500.0 * axccel.resolution_ratio,
		5.0 * axccel.resolution_ratio, object.GameObjectColor[f64]{255.0 - 20.0, 255.0 - 20.0, 255.0 - 20.0, 100.0})

	progress := (window.music.position / window.music.duration) * (500.0 * axccel.resolution_ratio)
	window.backend.draw_rect_filled(bar_rect_inline.x, bar_rect_inline.y, progress, 5.0 * axccel.resolution_ratio,
		object.GameObjectColor[f64]{255.0, 255.0, 255.0, 255.0})

	window.backend.end()
	window.mutex.unlock()
}

pub fn play() {
	mut audio_backend := &audio.IAudioBackend(&audio.BASSBackend{})

	if axccel.render_to_video {
		audio_backend = &audio.BASSOffscreenBackend{}
	}

	mut window := &AquaWindow{
		audio_backend: audio_backend
	}

	window.start(
		width: int(axccel.resolution.x)
		height: int(axccel.resolution.y)
		init_fn: window.init
		frame_fn: window.draw
	)
}

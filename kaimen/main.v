module kaimen

import gx
import math
import beatrice.graphic.window as cwindow
import beatrice.graphic.window.input
import beatrice.graphic.backend
import beatrice.graphic.sprite
import beatrice.math.time
import beatrice.math.vector
import beatrice.component.object
import beatrice.component.ui

// Window
pub struct Window {
	cwindow.CommonWindow
mut:
	last_time f64
	ui        &ui.UIManager = unsafe { nil }
}

pub fn (mut window Window) init(_ voidptr) {
	window.ui = &ui.UIManager{
		backend: window.backend
	}

	window.ui.init()

	// bg
	mut her := &sprite.Sprite{
		always_visible: true
		origin: vector.top_left
	}
	her.textures << window.backend.create_image('assets/her.jpg')
	her.size.x = 1280
	her.size.y = 720

	window.sprite_manager.add(mut her)

	// Update thread
	spawn fn (mut window Window) {
		mut time_counter := &time.TimeCounter{}
		mut limiter := &time.Limiter{
			fps: 240
		}

		time_counter.reset()

		for {
			time_counter.tick()
			window.mutex.@lock()
			window.update(time_counter.time)
			window.mutex.unlock()
			limiter.sync()
		}
	}(mut window)
}

pub fn (mut window Window) update(update_time f64) {
	window.last_time = update_time

	window.sprite_manager.update(update_time)
}

pub fn (mut window Window) draw(_ voidptr) {
	window.backend.begin()

	window.backend.draw_rect_filled(0, 0, 1280, 720, object.GameObjectColor[f64]{0.0, 0.0, 0.0, 255.0})
	window.sprite_manager.draw(backend: window.backend)

	window.draw_ui()
	window.backend.draw_text(70, 240, 'Cuck Life', gx.TextCfg{ color: gx.white, size: 80 })
	window.backend.end()
}

pub fn (mut window Window) draw_ui() {
	window.ui.begin()
	window.ui.demo_ui()
	window.ui.end()
	window.ui.draw()
}

pub fn play() {
	mut window := &Window{}

	// Subscribe
	// vfmt off
	window.input.mouse.subscribe(fn [mut window] (state input.InputState, button input.ButtonType, pos vector.Vector2[f64]) {
		// vfmt on
		match state {
			.mouse_click {
				window.ui.on_click(button, pos)
			}
			.mouse_unclick {
				window.ui.on_unclick(button, pos)
			}
			.mouse_move {
				window.ui.on_move(pos)
			}
			else {}
		}
	})

	window.start(
		width: 1280
		height: 720
		init_fn: window.init
		frame_fn: window.draw
	)
}

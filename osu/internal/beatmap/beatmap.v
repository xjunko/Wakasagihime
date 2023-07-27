module beatmap

import os
import wakasagihime.osu.internal.beatmap.object
import wakasagihime.osu.internal.skin
import beatrice.graphic.backend

pub struct Beatmap {
pub mut:
	// Info(s)
	general    BeatmapInfoGeneral
	metadata   BeatmapInfoMetadata
	difficulty BeatmapInfoDifficulty
	// Stuff
	objects []object.IHitObject
}

//
pub fn (mut beatmap Beatmap) init_objects(mut current_skin skin.Skin) {
	for i := 0; i < beatmap.objects.len; i++ {
		beatmap.objects[i].init(mut current_skin)
	}
}

pub fn (mut beatmap Beatmap) update(time f64) {
	for i := 0; i < beatmap.objects.len; i++ {
		beatmap.objects[i].update(time)
	}
}

pub fn (mut beatmap Beatmap) draw(arg backend.DrawConfig) {
	for i := 0; i < beatmap.objects.len; i++ {
		beatmap.objects[i].draw(arg)
	}
}

// dumb helper
pub fn (mut beatmap Beatmap) get_root() string {
	return beatmap.general.root_path
}

pub fn (mut beatmap Beatmap) get_osu_file() string {
	return os.join_path(beatmap.general.root_path, beatmap.general.version_filename)
}

pub fn (mut beatmap Beatmap) get_audio_file() string {
	return os.join_path(beatmap.general.root_path, beatmap.general.audio_filename)
}

pub fn (mut beatmap Beatmap) get_background_file() string {
	return os.join_path(beatmap.general.root_path, beatmap.general.background_filename)
}

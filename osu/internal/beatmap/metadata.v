module beatmap

pub struct BeatmapInfoGeneral {
pub mut:
	root_path           string // Not part of the osu! spec
	version_filename    string // Not part of the osu! spec
	background_filename string // Not part of the osu! spec
	audio_filename      string [AudioFilename]
	audio_lead_in       int    [AudioLeadIn]
	preview_time        int    [PreviewTime]
	count_down          int    [Countdown]
	sample_set          string [SampleSet]
	stack_leniency      f64    [StackLeniency]
	mode                int    [Mode]
}

pub struct BeatmapInfoMetadata {
pub mut:
	title          string [Title]
	title_unicode  string [TitleUnicode]
	artist         string [Artist]
	artist_unicode string [ArtistUnicode]
	creator        string [Creator]
	version        string [Version]
}

pub struct BeatmapInfoDifficulty {
pub mut:
	hp_drain_rate      f64 [HPDrainRate]
	circle_size        f64 [CircleSize]
	overall_difficulty f64 [OverallDifficulty]
	approach_rate      f64 [ApproachRate]
	slider_multiplier  f64 [SliderMultiplier]
	slider_tick_rate   f64 [SliderTickRate]
}

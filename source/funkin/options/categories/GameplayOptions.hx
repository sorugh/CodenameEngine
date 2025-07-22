package funkin.options.categories;

import flixel.util.FlxTimer;
import funkin.backend.system.Conductor;

class GameplayOptions extends OptionsScreen {
	var __metronome = FlxG.sound.load(Paths.sound('editors/charter/metronome'));

	var offsetSetting:NumOption;

	public override function new(title:String, desc:String) {
		super(title, desc, "GameplayOptions.");
		add(new Checkbox(
			getName("downscroll"),
			getDesc("downscroll"),
			"downscroll"));
		add(new Checkbox(
			getName("ghostTapping"),
			getDesc("ghostTapping"),
			"ghostTapping"));
		add(new Checkbox(
			getName("naughtyness"),
			getDesc("naughtyness"),
			"naughtyness"));
		add(new Checkbox(
			getName("camZoomOnBeat"),
			getDesc("camZoomOnBeat"),
			"camZoomOnBeat"));
		add(new Checkbox(
			getName("autoPause"),
			getDesc("autoPause"),
			"autoPause"));
		add(new MeterOption(
			getName("volumeSFX"),
			getDesc("volumeSFX"),
			0, // minimum
			1, // maximum
			0.1, // change
			"volumeSFX"));
		add(offsetSetting = new NumOption(
			getName("songOffset"),
			getDesc("songOffset"),
			-999, // minimum
			999, // maximum
			1, // change
			"songOffset", // save name or smth
			__changeOffset)); // callback
		add(new TextOption('optionsMenu.advanced', 'optionsTree.gameplay.advanced-desc', ' >', () ->
			parent.add(new AdvancedGameplayOptions('optionsMenu.advanced', 'optionsTree.gameplay.advanced-desc'))));
	}

	private function __changeOffset(offset)
		Conductor.songOffset = offset;

	var __lastBeat:Int = 0;
	var __lastSongBeat:Int = 0;

	override function update(elapsed) {
		super.update(elapsed);
		FlxG.camera.zoom = CoolUtil.fpsLerp(FlxG.camera.zoom, 1, 0.04);

		if (offsetSetting.selected) {
			FlxG.sound.music.volume = 0.5;
			if (__lastBeat != Conductor.curBeat) {
				FlxG.camera.zoom += 0.03;
				__lastBeat = Conductor.curBeat;
			}

			var beat = Math.floor(Conductor.getTimeInBeats(FlxG.sound.music.time));
			if (__lastSongBeat != beat) {
				__metronome.replay();
				__lastSongBeat = beat;
			}
		}
		else
			FlxG.sound.music.volume = 1;
	}

	override function close() {
		FlxG.camera.zoom = 1;
		FlxG.sound.music.volume = 1;
		super.close();
	}
}

class AdvancedGameplayOptions extends OptionsScreen {
	public override function new(title:String, desc:String) {
		super(title, desc, "GameplayOptions.Advanced.");
		add(new Checkbox(
			getName("streamedMusic"),
			getDesc("streamedMusic"),
			"streamedMusic"));
		add(new Checkbox(
			getName("streamedVocals"),
			getDesc("streamedVocals"),
			"streamedVocals"));
	}
}

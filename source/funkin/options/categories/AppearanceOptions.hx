package funkin.options.categories;

class AppearanceOptions extends TreeMenuScreen {
	public function new() {
		super('optionsTree.appearance-name', 'optionsTree.appearance-desc', 'AppearanceOptions.');

		add(new NumOption(getNameID('framerate'), getDescID('framerate'),
			30, 240, 1,
			'framerate', __changeFPS
		));
		add(new Checkbox(getNameID('flashingMenu'), getDescID('flashingMenu'), 'flashingMenu'));
		add(new ArrayOption(getNameID('quality'), getDescID('quality'),
			[0, 1, 2], [getID('quality-low'), getID('quality-high'), getID('quality-custom')],
			'quality', __changeQuality, null
		));
		add(new Checkbox(getNameID('colorHealthBar'), getDescID('colorHealthBar'), 'colorHealthBar'));
		add(new Checkbox(getNameID('week6PixelPerfect'), getDescID('week6PixelPerfect'), 'week6PixelPerfect'));

		add(new Separator());
		add(new TextOption('optionsMenu.advanced', 'optionsTree.appearance.advanced-desc', ' >', () ->
			parent.addMenu(new AdvancedAppearanceOptions())));
	}

	private function __changeFPS(value:Float) {
		var framerate = Math.floor(value);
		if (FlxG.updateFramerate < framerate) FlxG.drawFramerate = FlxG.updateFramerate = framerate;
		else FlxG.updateFramerate = FlxG.drawFramerate = framerate;
	}
	
	private function __changeQuality(value:Dynamic) {
		var antialiasing = value == 0 ? false : (value == 1 ? true : Options.antialiasing);
		FlxG.game.stage.quality = (FlxG.enableAntialiasing = antialiasing) ? BEST : LOW;
	}
}

class AdvancedAppearanceOptions extends TreeMenuScreen {
	public function new() {
		super('optionsMenu.advanced', 'optionsTree.appearance.advanced-desc', 'AppearanceOptions.Advanced.');

		for (option in [
			new Checkbox(getNameID('antialiasing'), getDescID('antialiasing'), 'antialiasing', __changeAntialiasing),
			new Checkbox(getNameID('lowMemoryMode'), getDescID('lowMemoryMode'), 'lowMemoryMode'),
			new Checkbox(getNameID('gameplayShaders'), getDescID('gameplayShaders'), 'gameplayShaders')
		]) {
			add(option);
			if (option.locked = Options.quality != 2) option.rawDesc = 'AppearanceOptions.quality-optionDisabled-desc';
		}

		add(new Checkbox(getNameID('gpuOnlyBitmaps'), getDescID('gpuOnlyBitmaps'), 'gpuOnlyBitmaps'));
	}

	private function __changeAntialiasing() {
		FlxG.game.stage.quality = (FlxG.enableAntialiasing = Options.antialiasing) ? BEST : LOW;
	}
}
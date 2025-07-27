package funkin.options.categories;

class AppearanceOptions extends OptionsScreen {
	public override function new(title:String, desc:String) {
		super(title, desc, "AppearanceOptions.");
		add(new NumOption(
			getName("framerate"),
			getDesc("framerate"),
			30, // minimum
			240, // maximum
			10, // change
			"framerate", // save name or smth
			__changeFPS)); // callback
		add(new Checkbox(
			getName("antialiasing"),
			getDesc("antialiasing"),
			"antialiasing"));
		add(new Checkbox(
			getName("colorHealthBar"),
			getDesc("colorHealthBar"),
			"colorHealthBar"));
		add(new Checkbox(
			getName("week6PixelPerfect"),
			getDesc("week6PixelPerfect"),
			"week6PixelPerfect"));
		add(new Checkbox(
			getName("gameplayShaders"),
			getDesc("gameplayShaders"),
			"gameplayShaders"));
		add(new Checkbox(
			getName("flashingMenu"),
			getDesc("flashingMenu"),
			"flashingMenu"));
		add(new Checkbox(
			getName("lowMemoryMode"),
			getDesc("lowMemoryMode"),
			"lowMemoryMode"));
		#if sys
		if (!Main.forceGPUOnlyBitmapsOff) {
			add(new Checkbox(
				getName("gpuOnlyBitmaps"),
				getDesc("gpuOnlyBitmaps"),
				"gpuOnlyBitmaps"));
		}
		#end
	}

	private function __changeFPS(change:Float) {
		// if statement cause of the flixel warning
		if(FlxG.updateFramerate < Std.int(change))
			FlxG.drawFramerate = FlxG.updateFramerate = Std.int(change);
		else
			FlxG.updateFramerate = FlxG.drawFramerate = Std.int(change);
	}
}
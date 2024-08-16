package funkin.editors;

import funkin.backend.utils.NativeAPI;
import funkin.options.OptionsScreen;
import funkin.options.TreeMenu;
import funkin.options.type.*;

class DebugOptions extends TreeMenu {
	public override function create() {
		super.create();

		FlxG.camera.fade(0xFF000000, 0.5, true);

		var bg:FlxSprite = new FlxSprite(-80).loadAnimatedGraphic(Paths.image('menus/menuBGBlue'));
		// bg.scrollFactor.set();
		bg.scale.set(1.15, 1.15);
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		bg.antialiasing = true;
		add(bg);

		main = new DebugOptionsScreen();
	}
}

class DebugOptionsScreen extends OptionsScreen {
	public override function new() {
		prefix = "DebugOptions";
		super(translate("title"), translate("desc"), prefix);
		#if windows
		add(new TextOption(
			getName("showConsole"),
			getDesc("showConsole"),
			function() {
				NativeAPI.allocConsole();
			}));
		#end
		add(new Checkbox(
			getName("editorSFX"),
			getDesc("editorSFX"),
			"editorSFX"));
		add(new Checkbox(
			getName("editorPrettyPrint"),
			getDesc("editorPrettyPrint"),
			"editorPrettyPrint"));
		add(new Checkbox(
			getName("intensiveBlur"),
			getDesc("intensiveBlur"),
			"intensiveBlur"));
		add(new Checkbox(
			getName("charterAutoSaves"),
			getDesc("charterAutoSaves"),
			"charterAutoSaves"));
		add(new NumOption(
			getName("charterAutoSaveTime"),
			getDesc("charterAutoSaveTime"),
			60, 60*10, 30,
			"charterAutoSaveTime"
		));
		add(new NumOption(
			getName("charterAutoSaveWarningTime"),
			getDesc("charterAutoSaveWarningTime"),
			0, 15, 1,
			"charterAutoSaveWarningTime"
		));
		add(new Checkbox(
			getName("charterAutoSavesSeperateFolder"),
			getDesc("charterAutoSavesSeperateFolder"),
			"charterAutoSavesSeperateFolder"));
	}
}
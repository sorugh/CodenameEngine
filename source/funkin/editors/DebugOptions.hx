package funkin.editors;

import funkin.backend.utils.NativeAPI;
import funkin.options.TreeMenu;
import funkin.options.TreeMenuScreen;
import funkin.options.type.*;

class DebugOptions extends TreeMenu {
	var bg:FlxSprite;

	override function create() {
		super.create();

		add(bg = new FlxSprite().loadAnimatedGraphic(Paths.image('menus/menuBGBlue')));
		bg.antialiasing = true;
		bg.scrollFactor.set();

		addMenu(new DebugOptionsScreen());

		FlxG.camera.fade(0xFF000000, 0.5, true);
		UIState.setResolutionAware();
	}

	public function updateBG() {
		var scaleX:Float = FlxG.width / bg.width;
		var scaleY:Float = FlxG.height / bg.height;
		bg.scale.x = bg.scale.y = Math.max(scaleX, scaleY) * 1.15;
		bg.screenCenter();
	}

	override function onResize(width:Int, height:Int) {
		super.onResize(width, height);
		if (!UIState.resolutionAware) return;

		updateBG();
	}
}

class DebugOptionsScreen extends TreeMenuScreen {
	public function new() {
		super('DebugOptions.title', 'DebugOptions.desc', 'DebugOptions.');

		#if windows
		add(new TextOption(getNameID("showConsole"), getDescID("showConsole"), () -> NativeAPI.allocConsole()));
		#end
		add(new Checkbox(getNameID("editorsResizable"), getDescID("editorsResizable"), "editorsResizable"));
		add(new Checkbox(getNameID("bypassEditorsResize"), getDescID("bypassEditorsResize"), "bypassEditorsResize"));
		add(new Checkbox(getNameID("editorSFX"), getDescID("editorSFX"), "editorSFX"));
		add(new Checkbox(getNameID("editorPrettyPrint"), getDescID("editorPrettyPrint"), "editorPrettyPrint"));
		add(new Checkbox(getNameID("intensiveBlur"), getDescID("intensiveBlur"), "intensiveBlur"));
		add(new Checkbox(getNameID("charterAutoSaves"), getDescID("charterAutoSaves"), "charterAutoSaves"));
		add(new NumOption(getNameID("charterAutoSaveTime"), getDescID("charterAutoSaveTime"), 60, 60*10, 1, "charterAutoSaveTime"));
		add(new NumOption(getNameID("charterAutoSaveWarningTime"), getDescID("charterAutoSaveWarningTime"), 0, 15, 1, "charterAutoSaveWarningTime"));
		add(new Checkbox(getNameID("charterAutoSavesSeparateFolder"), getDescID("charterAutoSavesSeparateFolder"), "charterAutoSavesSeparateFolder"));
	}
}
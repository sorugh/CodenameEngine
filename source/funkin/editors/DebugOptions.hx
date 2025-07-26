package funkin.editors;

import funkin.backend.utils.NativeAPI;
import funkin.options.OptionsScreen;
import funkin.options.TreeMenu;
import funkin.options.type.*;

class DebugOptions extends TreeMenu {
	public override function create() {
		super.create();

		FlxG.camera.fade(0xFF000000, 0.5, true);
	}
}

class DebugOptionsScreen extends OptionsScreen {

}
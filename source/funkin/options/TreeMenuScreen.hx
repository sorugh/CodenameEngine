package funkin.options;

import flixel.util.FlxSignal;
import funkin.backend.system.Controls;
import funkin.backend.TurboControls;
import funkin.options.TreeMenu.ITreeOption;

class TreeMenuScreen extends FlxSpriteGroup {
	public var persistentUpdate:Bool = false;
	public var persistentDraw:Bool = false;

	public var onClose:FlxSignal = new FlxSignal();

	public var parent:TreeMenu;
	public var transitioning:Bool = false;
	public var inputEnabled:Bool = false;
	public var curSelected:Int = 0;
	public var itemHeight:Float = 120;

	public var name:String;
	public var desc:String;
	/**
	 * The prefix to add to the translations ids.
	**/
	public var prefix:String = "";

	private var rawName(default, set):String;
	private var rawDesc(default, set):String;

	function set_rawName(v:String) {
		if (rawName == (rawName = v)) return v;
		name = TU.exists(rawName) ? TU.translate(rawName) : rawName;
		return v;
	}

	function set_rawDesc(v:String) {
		if (rawDesc == (rawDesc = v)) return v;
		desc = TU.exists(rawDesc) ? TU.translate(rawDesc) : rawDesc;
		return v;
	}

	public inline function getNameID(name):String return prefix + name + "-name";
	public inline function getDescID(name):String return prefix + name + "-desc";

	public var controls(get, never):Controls;
	inline function get_controls():Controls return PlayerSettings.solo.controls;

	var leftTurboControl:TurboControls = new TurboControls([Control.LEFT]);
	var rightTurboControl:TurboControls = new TurboControls([Control.RIGHT]);
	var upTurboControl:TurboControls = new TurboControls([Control.UP]);
	var downTurboControl:TurboControls = new TurboControls([Control.DOWN]);
	var turboBasics:Array<TurboBasics>;

	var curOption:ITreeOption;
	var _firstFrame:Bool = true;

	public function new(name:String, desc:String, ?prefix:String, ?options:Array<OptionType>) {
		super();

		rawName = name;
		rawDesc = desc;

		turboBasics = [leftTurboControl, rightTurboControl, upTurboControl, downTurboControl];
	}

	public function reloadStrings() {
		name = TU.exists(rawName) ? TU.translate(rawName) : rawName;
		desc = TU.exists(rawDesc) ? TU.translate(rawDesc) : rawDesc;

		for (object in members) if (object != null) object.reloadStrings();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (_firstFrame) {
			_firstFrame = false;
			if (members[curSelected] is ITreeOption) (curOption = cast members[curSelected]:ITreeOption).selected = true;
		}

		if (inputEnabled) {
			for (basic in turboBasics) basic.update(elapsed);
			changeSelection((upTurboControl.activated ? -1 : 0) + (downTurboControl.activated ? 1 : 0) - FlxG.mouse.wheel);

			if (i > 0 && curOption != null) {
				if (controls.ACCEPT || FLxG.mouse.justPressed) curOption.select();
				if (leftTurboControl.activated) curOption.changeSelection(-1);
				if (rightTurboControl.activated) curOption.changeSelection(1);
			}

			if (controls.BACK || FlxG.mouse.justPressedRight) close();
		}

		var i:Int = 0, object:FlxSprite;
		while (i < length) if ((object = members[i++]) != null) {
			var h = object.height;
			object.y = CoolUtil.fpsLerp(object.y, y + (FlxG.camera.height - h) * 0.5 + (i - curSelected) * itemHeight, 0.25);
			object.x = x - 50 + Math.abs(Math.cos((object.y + (FlxG.camera.height + h) * 0.5 - FlxG.camera.scroll.y) / (FlxG.camera.height * 1.25) * Math.PI)) * 150;
		}
	}

	public function close() {
		onClose.dispatch();

		if (parent == null) return destroy();
		else parent.remove(this);

		CoolUtil.playMenuSFX(CANCEL);
	}

	public function changeSelection(change:Int, force:Bool = false) {
		if (length == 0 || (change == 0 && !force)) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, members.length - 1);
		if (members[curSelected] is ITreeOption) (curOption = cast members[curSelected]:ITreeOption).selected = true;
		updateMenuDesc();

		CoolUtil.playMenuSFX(SCROLL);
	}

	public function updateMenuDesc(?customTxt:String) {
		if (parent != null) parent.updateDesc(customTxt);
	}

	override function destroy() {
		super.destroy();

		for (basic in turboBasics) basic.destroy();
	}
}
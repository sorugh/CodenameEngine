package funkin.options.type;

import flixel.group.FlxSpriteGroup;
import funkin.backend.system.Controls;

/**
 * Base class for all option types.
 * Used in OptionsMenu.
**/
class OptionType extends FlxSpriteGroup {
	public var controls(get, never):Controls;
	public var selected:Bool = false;
	public var desc:String;
	public var rawDesc(default, set):String;

	public function new(desc:String) {
		super();
		rawDesc = desc;
	}

	function set_rawDesc(v:String) {
		rawDesc = v;
		this.desc = TU.exists(rawDesc) ? TU.translate(rawDesc) : rawDesc;
		return v;
	}

	public function reloadStrings() {
		this.rawDesc = rawDesc;
	}

	private function get_controls() {return PlayerSettings.solo.controls;}

	public function onSelect() {}

	public function onChangeSelection(change:Float) {}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		alpha = (selected ? 1 : 0.6);
	}
}
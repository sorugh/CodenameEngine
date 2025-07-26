package funkin.options.type;

import flixel.group.FlxSpriteGroup;
import funkin.backend.system.Controls;
import funkin.options.TreeMenu.ITreeOption;

/**
 * Base class for all option types.
 * Used in OptionsMenu.
**/
class OptionType extends FlxSpriteGroup implements ITreeOption {
	public var selected:Bool = false;

	public var text(default, set):String;
	public var rawText(default, set):String;
	public var desc:String;
	public var rawDesc(default, set):String;

	public function new(text:String, desc:String) {
		super();
		reloadStrings();
	}

	function set_text(v:String) return text = v;
	function set_rawText(v:String) {
		rawText = v;
		text = TU.exists(rawText) ? TU.translate(rawText) : rawText;
		return v;
	}

	function set_rawDesc(v:String) {
		rawDesc = v;
		desc = TU.exists(rawDesc) ? TU.translate(rawDesc) : rawDesc;
		return v;
	}

	public function reloadStrings() {
		rawText = rawText;
		rawDesc = rawDesc;
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		alpha = (selected ? 1 : 0.6);
	}

	public function changeSelection(change:Int) {}
	public function select() {}
}
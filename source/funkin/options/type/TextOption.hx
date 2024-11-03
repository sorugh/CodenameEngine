package funkin.options.type;

import flixel.effects.FlxFlicker;

class TextOption extends OptionType {
	public var selectCallback:Void->Void;

	private var __text:Alphabet;
	private var rawText(default, set):String;

	public var text(get, set):String;
	private function get_text() {return __text.text;}
	private function set_text(v:String) {return __text.text = v;}

	/**
	 * If you change this afterwards you will need to call `reloadStrings()`, or manually set rawText to rawText.
	**/
	public var suffix:String;

	public function new(text:String, desc:String, ?suffix:String = "", ?selectCallback:Void->Void = null) {
		super(desc);
		this.selectCallback = selectCallback;
		add(__text = new Alphabet(100, 20, text, "bold"));
		this.suffix = suffix;
		rawText = text;
	}

	override function reloadStrings() {
		super.reloadStrings();
		this.rawText = rawText;
	}

	function set_rawText(v:String) {
		rawText = v;
		__text.text = (TU.exists(rawText) ? TU.translate(rawText) : rawText) + suffix;
		return v;
	}

	public override function draw() {
		super.draw();
	}
	public override function onSelect() {
		super.onSelect();
		CoolUtil.playMenuSFX(CONFIRM);
		FlxFlicker.flicker(this, 1, Options.flashingMenu ? 0.06 : 0.15, true, false);
		selectCallback();
	}
}
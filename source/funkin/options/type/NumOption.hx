package funkin.options.type;

import flixel.effects.FlxFlicker;

/**
 * Option type that allows stepping through a number.
**/
class NumOption extends OptionType {
	public var selectCallback:Float->Void;

	private var __text:Alphabet;
	private var __number:Alphabet;

	public var min:Float;
	public var max:Float;

	public var currentSelection:Float;
	public var changeVal:Float;

	var optionName:String;

	public var parent:Dynamic;

	private var rawText(default, set):String;

	public var text(get, set):String;
	private function get_text() {return __text.text;}
	private function set_text(v:String) {return __text.text = v;}

	public function new(text:String, desc:String, min:Float, max:Float, changeVal:Float, optionName:String, ?selectCallback:Float->Void = null, ?parent:Dynamic) {
		super(desc);
		this.selectCallback = selectCallback;
		this.min = min;
		this.max = max;
		if (parent == null)
			parent = Options;

		this.parent = parent;

		if(Reflect.field(parent, optionName) != null)
			this.currentSelection = Reflect.field(parent, optionName);
		this.changeVal = changeVal;
		this.optionName = optionName;

		add(__text = new Alphabet(20, 20, "", "bold"));
		add(__number = new Alphabet(0, 20, ': $currentSelection', "bold"));
		rawText = text;
	}

	override function reloadStrings() {
		super.reloadStrings();
		this.rawText = rawText;
	}

	function set_rawText(v:String) {
		rawText = v;
		__text.text = TU.exists(rawText) ? TU.translate(rawText) : rawText;
		__number.x = __text.x + __text.width + 12;
		return v;
	}

	override function onChangeSelection(change:Float):Void
	{
		if(currentSelection <= min && change == -1 || currentSelection >= max && change == 1) return;
		currentSelection = FlxMath.roundDecimal(currentSelection + (change * changeVal), FlxMath.getDecimals(changeVal));
		__number.text = ': $currentSelection';

		Reflect.setField(parent, optionName, currentSelection);
		if(selectCallback != null)
			selectCallback(currentSelection);
	}
}
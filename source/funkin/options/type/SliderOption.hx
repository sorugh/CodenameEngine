package funkin.options.type;

class SliderOption extends OptionType {
	public var selectCallback:Float->Void;

	public var min:Float;
	public var max:Float;
	public var segmentVal:Float;

	public var currentSelection:Float;

	public var parent:Dynamic;

	//public var barWidth(get, set):Int;

	override function set_text(v:String) return __text.text = text = v;

	var __text:Alphabet;
	var optionName:String;

	public function new(text:String, desc:String, min:Float, max:Float, segmentVal:Float, optionName:String, barWidth:Int = 520,
		?selectCallback:Float->Void = null, ?parent:Dynamic)
	{
		super(text, desc);
	}
}
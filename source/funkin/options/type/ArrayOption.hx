package funkin.options.type;

class ArrayOption extends OptionType {
	public var selectCallback:String->Void;

	public var options:Array<Dynamic>;
	public var displayOptions:Array<String>;
	public var currentSelection:Int;

	public var parent:Dynamic;
	public var optionName:String;

	var __text:Alphabet;
	var __selectionText:Alphabet;

	public function new(text:String, desc:String, options:Array<Dynamic>, displayOptions:Array<String>, ?optionName:String, ?selectCallback:String->Void = null, ?parent:Dynamic) {
		super(text, desc);
		this.selectCallback = selectCallback;
		this.displayOptions = displayOptions;
		this.options = options;
		this.parent = parent = parent != null ? parent : Options;
		this.optionName = optionName;

		var fieldValue = Reflect.field(parent, optionName);
		if (fieldValue != null) currentSelection = CoolUtil.maxInt(0, options.indexOf(fieldValue));

		add(__text = new Alphabet(20, 0, text, 'bold'));
		add(__selectionText = new Alphabet(__text.x + __text.width + 12, 0, formatTextOption(), 'bold'));
	}

	override function reloadStrings() {
		super.reloadStrings();
		__selectiontext.x = __text.x + __text.width + 12;
		__selectiontext.text = formatTextOption();
	}

	override function changeSelection(change:Int) {
		currentSelection = FlxMath.wrap(currentSelection + change, 0, options.length - 1);
		__selectionText.text = formatTextOption();
		CoolUtil.playMenuSFX(SCROLL);

		if (selectCallback != null) selectCallback(options[currentSelection]);
	}

	function formatTextOption() {
		var s = ": ";

		if (currentSelection > 0) s += "< ";
		else s += "  ";

		s += TU.exists(displayOptions[currentSelection]) ? TU.translate(displayOptions[currentSelection]) : displayOptions[currentSelection];

		if (currentSelection < options.length - 1) s += " >";

		return s;
	}
}
package funkin.options.type;

/**
 * Option type that allows stepping through a number.
**/
class NumOption extends TextOption {
	public var changedCallback:Float->Void;

	public var min:Float;
	public var max:Float;
	public var step:Float;

	public var currentSelection:Float;

	public var parent:Dynamic;
	public var optionName:String;

	var __number:Alphabet;

	override function set_text(v:String) {
		super.set_text(v);
		__number.x = __text.x + __text.width + 12;
		return v;
	}

	public function new(text:String, desc:String, min:Float, max:Float, step:Float, optionName:String, ?changedCallback:Float->Void = null, ?parent:Dynamic) {
		this.changedCallback = changedCallback;
		this.min = min;
		this.max = max;
		this.step = step;
		this.optionName = optionName;
		this.parent = parent = parent != null ? parent : Options;

		var fieldValue = Reflect.field(parent, optionName);
		currentSelection = fieldValue != null ? fieldValue : 0;
	
		__number = new Alphabet(0, 20, ': $currentSelection', 'bold');
		super(text, desc);
		add(__number);
	}

	override function changeSelection(change:Int):Void {
		if (locked) return;
		if (currentSelection == (currentSelection = FlxMath.bound(currentSelection + change, min, max))) return;
		__number.text = ': $currentSelection';

		Reflect.setField(parent, optionName, currentSelection);
		if (changedCallback != null) changedCallback(currentSelection);

		CoolUtil.playMenuSFX(SCROLL);
	}

	override function select() {}
}
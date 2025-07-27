package funkin.options.type;

import funkin.menus.ui.Slider;
import funkin.options.TreeMenu.ITreeFloatOption;

class SliderOption extends TextOption implements ITreeFloatOption {
	public var changedCallback:Float->Void;

	public var min:Float;
	public var max:Float;
	public var step:Float;

	public var currentValue:Float;

	public var parent:Dynamic;
	public var optionName:String;

	public var slider:Slider;

	function getValue():Float return (currentValue - min) / (max - min);

	public function new(text:String, desc:String, min:Float, max:Float, step:Float, ?segments:Int, optionName:String, barWidth = 600.0,
		?changedCallback:Float->Void = null, ?parent:Dynamic)
	{
		super(text, desc);
		this.changedCallback = changedCallback;
		this.min = min;
		this.max = max;
		this.step = step;
		this.optionName = optionName;
		this.parent = parent = parent != null ? parent : Options;

		if (Reflect.field(parent, optionName) != null) currentValue = Reflect.field(parent, optionName);

		add(slider = new Slider(16, 0, getValue(), barWidth, segments));
		slider.scale.set(0.75, 0.75);
		slider.updateHitbox();
		slider.y = __text.y + (__text.height - slider.height) * 0.5;
	}

	override function update(elapsed:Float) {
		slider.selected = selected && !locked;
		slider.value = getValue();
		__text.x = slider.x + slider.width + 30;

		super.update(elapsed);
	}

	public function changeValue(change:Float):Void {
		if (locked) return;
		if (currentValue == (currentValue = FlxMath.bound(currentValue + change * step, min, max))) return;

		Reflect.setField(parent, optionName, currentValue);
		if (changedCallback != null) changedCallback(currentValue);
	}

	override function select() {}
}
package funkin.options.type;

import flixel.math.FlxPoint;

class RadioButton extends TextOption {
	public var radio:FlxSprite;
	public var checked(default, set):Bool;

	public var parent:Dynamic;
	public var value:Dynamic;
	public var forId:String;

	public var optionName:String;

	private var offsets:Map<String, FlxPoint> = [
		"unchecked" => FlxPoint.get(0, -65),
		"checked" => FlxPoint.get(0, -65),
		"unchecking" => FlxPoint.get(15, -55),
		"checking" => FlxPoint.get(17, -40)
	];

	public function new(text:String, desc:String, optionName:String, value:Dynamic, ?parent:Dynamic, ?forId:String, ?options:OptionsScreen) {
		super(text, desc, null);

		if (parent == null)
			parent = Options;

		if(forId == null)
			forId = optionName;

		this.parent = parent;
		this.forId = forId;

		if(options != null) {
			if(FlxG.state is OptionsMenu) {
				var menu:OptionsMenu = cast FlxG.state;
				options = menu.optionsTree.members.last();
			}
		}

		radio = new FlxSprite(10, -40);
		radio.frames = Paths.getFrames('menus/options/radioCrank');
		radio.animation.addByPrefix("unchecked", "Radio unselected0", 24);
		radio.animation.addByPrefix("checked", "Radio Selected Static0", 24);
		radio.animation.addByPrefix("unchecking", "Radio deselect animation0", 24, false);
		radio.animation.addByPrefix("checking", "Radio selecting animation0", 24, false);
		radio.antialiasing = true;
		radio.scale.set(0.75, 0.75);
		radio.updateHitbox();
		add(radio);

		this.value = value;

		this.optionName = optionName;
		if(optionName != null) {
			checked = Reflect.field(parent, optionName) == value;
		} else {
			checked = false;
		}
	}

	public var firstFrame:Bool = true;

	public override function update(elapsed:Float) {
		if(radio.animation.curAnim == null) {
			radio.animation.play(checked ? "checked" : "unchecked", true);
		}
		super.update(elapsed);
		switch(radio.animation.curAnim.name) {
			case "unchecking":
				if(radio.animation.curAnim.finished) {
					radio.animation.play("unchecked", true);
					trace("UNCHECKING finished");
				}
			case "checking":
				if(radio.animation.curAnim.finished) {
					radio.animation.play("checked", true);
					trace("CHECKING finished");
				}
		}

		firstFrame = false;
	}

	override function draw() {
		if(radio.animation.curAnim != null) {
			var offset = offsets[radio.animation.curAnim.name];
			if (offset != null)
				radio.frameOffset.set(offset.x, offset.y);
		}
		super.draw();
	}

	function set_checked(v:Bool) {
		if(checked != v) {
			checked = v;
			if(!firstFrame) {
				radio.animation.play(checked ? "checking" : "unchecking", true);
			}
		}
		return v;
	}

	public override function select() {
		if (locked) return;

		checked = true;
		if(checked) {
			onSet(value);
		}
	}

	public dynamic function onSet(value:Dynamic) {
		if(optionName != null) {
			Reflect.setField(parent, optionName, value);
		}
	}

	public override function destroy() {
		super.destroy();
		for(e in offsets) e.put();
	}
}
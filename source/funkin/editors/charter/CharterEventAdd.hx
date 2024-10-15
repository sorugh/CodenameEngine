package funkin.editors.charter;

class CharterEventAdd extends UISliceSprite {
	var text:UIText;
	public var sprAlpha:Float = 0;
	public var step:Float = 0;

	public var curCharterEvent:CharterEvent = null;

	public var global:Bool = false;

	public function new(global:Bool) {
		super(0, 0, 100, 34, 'editors/charter/event-spr-add');

		this.global = flipX = global;

		text = new UIText(0, 0, 0, "");
		members.push(text);

		cursor = CLICK;
	}

	public override function onHovered() {
		super.onHovered();
		if (FlxG.mouse.justReleased) {
			if (curCharterEvent != null)
				Charter.instance.openSubState(new CharterEventScreen(step, global, curCharterEvent));
			else
				Charter.instance.openSubState(new CharterEventScreen(step, global));
		}
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		text.follow(this, global ? bWidth - text.width - 20 : 20, (bHeight - text.height) / 2);
		alpha = sprAlpha * 0.75;
		text.alpha = sprAlpha;
	}

	public function updatePos(step:Float) {
		curCharterEvent = null;
		this.step = step;
		this.y = (step * 40) - (bHeight / 2);
		text.text = "Add event";
		framesOffset = 0; bWidth = 37 + Math.ceil(text.width);
		x = global ? Charter.instance.strumLines.members[Charter.instance.strumLines.members.length-1].x + (40*Charter.instance.strumLines.members[Charter.instance.strumLines.members.length-1].keyCount) : -(bWidth);
	}

	public function updateEdit(event:CharterEvent) {
		curCharterEvent = event;
		this.y = event.y;
		text.text = "Edit";
		framesOffset = 9; bWidth = 27 + Math.ceil(text.width) + event.bWidth;
		x = global ? Charter.instance.strumLines.members[Charter.instance.strumLines.members.length-1].x + (40*Charter.instance.strumLines.members[Charter.instance.strumLines.members.length-1].keyCount) : -(bWidth);
	}
}
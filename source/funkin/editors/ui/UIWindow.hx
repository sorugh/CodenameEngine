package funkin.editors.ui;

class UIWindow extends UISliceSprite {
	public var titleSpr:UIText;
	public var collapsable:Bool = false;
	public var content:FlxTypedGroup<FlxBasic>;

	public override function new(x:Float, y:Float, w:Int, h:Int, title:String) {
		super(x, y, w, h,  "editors/ui/normal-popup");

		members.push(titleSpr = new UIText(x + 25, y, bWidth - 50, title, 15, -1));
		titleSpr.y = y + ((30 - titleSpr.height) / 2);

		content = new FlxTypedGroup<FlxBasic>();
		members.push(content);
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		if(collapsable && FlxG.mouse.justPressed) {
			// TOOLBAR
			__rect.x = x; __rect.y = y;
			__rect.width = bWidth; __rect.height = 23;
			if(UIState.state.isOverlapping(this, __rect)) {
				content.exists = !content.exists;
				drawMiddle = !drawMiddle;
				drawBottom = !drawBottom;
			}
		}

		__rect.x = x; __rect.y = y+23;
		__rect.width = bWidth; __rect.height = bHeight-23;
		hovered = UIState.state.isOverlapping(this, __rect);
	}
}
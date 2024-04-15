package funkin.editors.character;

import flixel.math.FlxPoint;
import flixel.util.FlxColor;

class CharacterAnimButton extends UIButton {
	public var anim:String = "";

	public function new(x:Float,y:Float,anim:String, offset:FlxPoint) {
		this.anim = anim;
		super(x,y, ""/*'$anim (${offset.x}, ${offset.y})'*/, function () {
			CharacterEditor.instance.playAnimation(this.anim);
		}, Std.int(500-16), 100);


		autoAlpha = autoFrames = false;

		frames = Paths.getFrames('editors/ui/inputbox');
		framesOffset = 9;
	}

	public function updateInfo(anim:String, offset:FlxPoint, ghost:Bool) {
		this.anim = anim;
	}
}
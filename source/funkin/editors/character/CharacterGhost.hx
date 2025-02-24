package funkin.editors.character;

import openfl.geom.ColorTransform;
import flixel.animation.FlxAnimation;
import funkin.game.Character;

class CharacterGhost extends Character {
	public var ghosts:Array<String> = [];
	public override function draw() {
		ghostDraw = true;

		if (animateAtlas != null) {}
		else {
			for (anim in ghosts) @:privateAccess {
				alpha  = 0.4; color = 0xFFAEAEAE;
	
				var flxanim:FlxAnimation = animation._animations.get(anim);
				var frameIndex:Int = flxanim.frames.getDefault([0])[0];
				frame = frames.frames[frameIndex];
	
				setAnimOffset(anim);
				super.draw();
			}

			frame = frames.frames[animation.frameIndex];	
		}

		setAnimOffset(animation.name);
		alpha = 1; color = 0xFFFFFFFF;
		ghostDraw = false; 
		
		super.draw();
	}

	public function setAnimOffset(anim:String) {
		var daOffset:FlxPoint = animOffsets.get(anim);
		frameOffset.set(daOffset.x, daOffset.y);
		daOffset.putWeak();

		offset.set(globalOffset.x * (isPlayer != playerOffsets ? 1 : -1), -globalOffset.y);
	}
}
package funkin.editors.character;

import openfl.geom.ColorTransform;
import flixel.animation.FlxAnimation;
import funkin.game.Character;

class CharacterGhost extends Character {
	public var ghosts:Array<String> = [];
	public override function draw() @:privateAccess {
		ghostDraw = true;

		var wasInvalidFrame:Bool = !colorTransform.__isDefault(false);
		colorTransform.__identity();

		if (animateAtlas != null) {
			var ogFrame:Int = animateAtlas.anim.curFrame;
			var oldTick:Float = animateAtlas.anim._tick; 
			var oldPlaying:Bool = animateAtlas.anim.isPlaying;

			for (anim in ghosts) {
				animateAtlas.anim.play(anim, true, false, 0);
				setAnimOffset(anim);

				alpha = 0.4; color = 0xFFAEAEAE;
				super.draw();
			}

			if (ghosts.length > 0) {
				animateAtlas.anim.play(atlasPlayingAnim, true, false, ogFrame);
				animateAtlas.anim._tick = oldTick;
				animateAtlas.anim.isPlaying = oldPlaying;
			}
		}
		else {
			for (anim in ghosts) @:privateAccess {
				alpha = 0.4; color = 0xFFAEAEAE;
	
				var flxanim:FlxAnimation = animation._animations.get(anim);
				var frameIndex:Int = flxanim.frames.getDefault([0])[0];
				frame = frames.frames[frameIndex];
	
				setAnimOffset(anim);
				super.draw();
			}

			if (ghosts.length > 0)
				frame = frames.frames[animation.frameIndex];
		}
		ghostDraw = false; 

		alpha = 1; color = 0xFFFFFFFF;
		if (wasInvalidFrame) {
			frameOffset.set(0, 0); 
			offset.set(globalOffset.x * (isPlayer != playerOffsets ? 1 : -1), -globalOffset.y);
			colorTransform.color = 0xFFEF0202;
		} else
			setAnimOffset(animateAtlas != null ? atlasPlayingAnim : animation.name);
		super.draw();
	}

	public function setAnimOffset(anim:String) {
		var daOffset:FlxPoint = animOffsets.get(anim);
		frameOffset.set(daOffset.x, daOffset.y);
		daOffset.putWeak();

		offset.set(globalOffset.x * (isPlayer != playerOffsets ? 1 : -1), -globalOffset.y);
	}
}
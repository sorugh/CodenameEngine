package funkin.editors.character;

import funkin.backend.utils.XMLUtil.AnimData;
import flixel.animation.FlxAnimation;
import flixel.graphics.FlxGraphic;
import openfl.geom.Rectangle;
import flixel.graphics.frames.FlxFrame;
import funkin.game.Character;

using funkin.backend.utils.BitmapUtil;

class CharacterAnimsWindow extends UIButtonList<CharacterAnimButton> {
	public var character:CharacterGhost;

	public var displayWindowSprite:FlxSprite;
	public var displayWindowGraphic:FlxGraphic;
	public var displayAnimsFramesList:Map<String, {scale:Float, animBounds:Rectangle, frame:Int}> = [];

	public var animButtons:Map<String, CharacterAnimButton> = [];
	public var animsList:Array<String> = [];

	public function new(x:Float, y:Float, character:CharacterGhost) {
		super(x, y, Std.int(500-16), 419, "", FlxPoint.get(Std.int(500-16-32), 208));

		cameraSpacing = 0;
		frames = Paths.getFrames('editors/ui/inputbox');

		buttonCameras.pixelPerfectRender = true;

		if (Assets.exists(Paths.image('characters/${character.sprite}')))
			displayWindowGraphic = FlxG.bitmap.add(Assets.getBitmapData(Paths.image('characters/${character.sprite}'), true, false));

		displayWindowSprite = new FlxSprite();
		displayWindowSprite.loadGraphicFromSprite(character);
		displayWindowSprite.antialiasing = character.antialiasing;
		displayWindowSprite.flipX = character.flipX;

		alpha = 0.7;

		@:privateAccess
		for (name => anim in displayWindowSprite.animation._animations)
			buildAnimDisplay(name, anim);
			
		for (anim in character.getAnimOrder()) {
			var button:CharacterAnimButton = new CharacterAnimButton(0, 0, character.animDatas.get(anim), this);
			add(button); animButtons.set(anim, button);
		}
		this.character = character;
	}

	public var ghosts:Array<String> = [];
	public override function update(elapsed:Float) {
		super.update(elapsed);

		animsList = [for (button in buttons) button.anim];
		character.ghosts = ghosts;
	}

	public function buildAnimDisplay(name:String, anim:FlxAnimation) {
		var frameIndex:Int = anim.frames.getDefault([0])[0];
		var frame:FlxFrame = displayWindowSprite.frames.frames[frameIndex];

		var frameRect:Rectangle = new Rectangle(frame.offset.x, frame.offset.y, frame.sourceSize.x, frame.sourceSize.y);
		var animBounds:Rectangle = displayWindowGraphic != null ? displayWindowGraphic.bitmap.bounds(frameRect) : frameRect;

		displayAnimsFramesList.set(name, {frame: anim.frames.getDefault([0])[0], scale: 104/animBounds.height, animBounds: animBounds});
	}

	public function deleteAnimation(button:CharacterAnimButton) {
		if (buttons.members.length <= 1) return;
		if (character.getAnimName() == button.anim)
			@:privateAccess CharacterEditor.instance._animation_down(null);
		
		character.removeAnimation(button.anim);
		if (character.animOffsets.exists(button.anim)) character.animOffsets.remove(button.anim);
		if (character.animDatas.exists(button.anim)) character.animDatas.remove(button.anim);
		
		remove(button); button.destroy();
	}

	// public function createAnimation() {
	// 	var animData:AnimData = {
	// 		name: "New Animation"
	// 		x: 0, y: 0,
	// 	}
	// }
}
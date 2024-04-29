package funkin.editors.character;

import flixel.graphics.FlxGraphic;
import openfl.geom.Rectangle;
import flixel.graphics.frames.FlxFrame;
import funkin.game.Character;

using funkin.backend.utils.BitmapUtil;

class CharacterAnimsWindow extends UIButtonList<CharacterAnimButton> {
	public var character:Character;

	public var displayWindowSprite:FlxSprite;
	public var displayWindowGraphic:FlxGraphic;
	public var displayAnimsFramesList:Map<String, {scale:Float, animBounds:Rectangle, frame:Int}> = [];

	public function new(x:Float, y:Float, character:Character) {
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

		@:privateAccess
		for (name => anim in displayWindowSprite.animation._animations) {
			var frameIndex:Int = anim.frames.getDefault([0])[0];
			var frame:FlxFrame = displayWindowSprite.frames.frames[frameIndex];

			var frameRect:Rectangle = new Rectangle(frame.offset.x, frame.offset.y, frame.sourceSize.x, frame.sourceSize.y);
			var animBounds:Rectangle = displayWindowGraphic != null ? displayWindowGraphic.bitmap.bounds(frameRect) : frameRect;

			displayAnimsFramesList.set(name, {frame: anim.frames.getDefault([0])[0], scale: 104/animBounds.height, animBounds: animBounds});
		}
			
		for (anim in character.getAnimOrder())
			add(new CharacterAnimButton(0,0, character.animDatas.get(anim), this));
	}
}
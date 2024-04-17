package funkin.editors.character;

import flixel.graphics.frames.FlxFrame;
import funkin.game.Character;

class CharacterAnimsWindow extends UIButtonList<CharacterAnimButton> {
	public var character:Character;

	public var displayWindowSprite:FlxSprite;
	public var displayAnimsFramesList:Map<String, Int> = [];

	public function new(x:Float, y:Float, character:Character) {
		super(x, y, Std.int(500-16), 419, "", FlxPoint.get(Std.int(500-16-32), 184));

		cameraSpacing = 0;
		frames = Paths.getFrames('editors/ui/inputbox');

		buttonCameras.pixelPerfectRender = true;

		displayWindowSprite = new FlxSprite();
		displayWindowSprite.loadGraphicFromSprite(character);
		displayWindowSprite.antialiasing = character.antialiasing;
		displayWindowSprite.flipX = character.flipX;

		@:privateAccess
		for (name => anim in displayWindowSprite.animation._animations) 
			displayAnimsFramesList.set(name, anim.frames.getDefault([0])[0]);

		for (anim in character.getAnimOrder())
			add(new CharacterAnimButton(0,0, character.animDatas.get(anim), this));
	}

	
}
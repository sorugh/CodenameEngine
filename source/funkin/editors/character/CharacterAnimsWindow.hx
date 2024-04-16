package funkin.editors.character;

import funkin.game.Character;

class CharacterAnimsWindow extends UIButtonList<CharacterAnimButton> {
	public var character:Character;

	public var displayWindowSprite:FlxSprite;
	public var displayAnimsList:Array<String> = [];

	public function new(x:Float, y:Float, character:Character) {
		super(x, y, Std.int(500-16), 419, "", FlxPoint.get(Std.int(500-16-32), 184));

		cameraSpacing = 0;
		frames = Paths.getFrames('editors/ui/inputbox');

		displayWindowSprite = new FlxSprite();
		displayWindowSprite.loadGraphicFromSprite(character);
		
		displayAnimsList = displayWindowSprite.animation.getNameList();

		for (anim in character.getAnimOrder())
			add(new CharacterAnimButton(0,0, character.animDatas.get(anim), this));
	}

	
}
package funkin.editors.character;

class CharacterAnimsWindow extends UIButtonList<CharacterAnimButton> {
	public function new(x:Float, y:Float, animations:Array<String>) {
		super(x, y, Std.int(500-16), 419, "", FlxPoint.get(500-16, 100));

		cameraSpacing = 0;
		frames = Paths.getFrames('editors/ui/inputbox');

		for (anim in animations)
			add(new CharacterAnimButton(0,0, anim, FlxPoint.get()));

	}
}
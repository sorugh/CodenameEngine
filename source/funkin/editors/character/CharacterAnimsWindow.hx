package funkin.editors.character;

class CharacterAnimsWindow extends UIButtonList<CharacterAnimButton> {
	public function new(x:Float, y:Float, animations:Array<String>) {
		super(x, y, Std.int(500-16), 300, "Character Animations", FlxPoint.get(500-16, 32));
	}
}
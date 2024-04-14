package funkin.editors.stage.elements;

import haxe.xml.Access;
import flixel.util.FlxColor;

class StageSolidButton extends StageSpriteButton {

	public function new(x:Float,y:Float, sprite:FlxSprite, xml:Access) {
		super(x,y, sprite, xml);
		color = 0xFFD9FF50;
	}

	public override function onEdit() {
		// TODO: implement
	}
}
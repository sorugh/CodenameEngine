package funkin.editors.stager.elements;

import haxe.xml.Access;
import flixel.util.FlxColor;

class StageSpriteButton extends StageElementButton {
	public var sprite:FlxSprite;

	public function new(x:Float,y:Float, sprite:FlxSprite, xml:Access) {
		this.sprite = sprite;
		super(x,y, xml);

		//color = 0xFFD9FF50;

		updateInfo(sprite);
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
	}

	public override function updateInfo(sprite:Dynamic) {
		if(sprite is FlxSprite) {
			var sprite:FlxSprite = cast sprite;
			this.sprite = sprite;
			sprite.visible = !isHidden;
		}
		super.updateInfo(sprite);
	}

	public override function onGhostClick() {
		isHidden = !isHidden;
		updateInfo(this.sprite);
	}

	public override function onEdit() {
		// TODO: implement
	}

	public override function onDelete() {
		sprite.destroy();
		xml.x.parent.removeChild(xml.x);
		StageEditor.instance.xmlMap.remove(sprite);
		StageEditor.instance.stageSpritesWindow.remove(this);
	}

	public override function getInfoText():String {
		return '${xml.att.name} (${sprite.x}, ${sprite.y})';
	}

	public override function updatePos() {
		super.updatePos();
	}
}
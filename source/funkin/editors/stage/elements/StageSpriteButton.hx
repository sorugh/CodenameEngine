package funkin.editors.stage.elements;

import haxe.xml.Access;
import funkin.editors.stage.StageSpriteEditScreen;
import flixel.util.FlxColor;

class StageSpriteButton extends StageElementButton {
	public var sprite:FunkinSprite;

	public function new(x:Float,y:Float, sprite:FunkinSprite, xml:Access) {
		this.sprite = sprite;
		super(x,y, xml);

		//color = 0xFFD9FF50;

		updateInfo(sprite);
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
	}

	public override function updateInfo(sprite:Dynamic) {
		if(sprite is FunkinSprite) {
			var sprite:FunkinSprite = cast sprite;
			this.sprite = sprite;
			sprite.visible = !isHidden;
		}
		super.updateInfo(sprite);
	}

	public override function getSprite():FunkinSprite {
		return sprite;
	}

	public override function onGhostClick() {
		isHidden = !isHidden;
		updateInfo(this.sprite);
	}

	public override function onEdit() {
		// TODO: implement
		FlxG.state.openSubState(new StageSpriteEditScreen(this));
	}

	public override function onDelete() {
		sprite.destroy();
		xml.x.parent.removeChild(xml.x);
		StageEditor.instance.stage.stageSprites.remove(sprite.name);
		StageEditor.instance.xmlMap.remove(sprite);
		StageEditor.instance.stageSpritesWindow.remove(this);
	}

	public override function getName():String {
		return xml.att.name;
	}

	public override function getInfoText():String {
		return '${getName()} (${sprite.x}, ${sprite.y})';
	}

	public override function updatePos() {
		super.updatePos();
	}
}
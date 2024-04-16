package funkin.editors.stage.elements;

import funkin.game.Character;
import funkin.game.Stage.StageCharPos;
import haxe.xml.Access;

class StageCharacterButton extends StageElementButton {
	public var charPos:StageCharPos;
	public var char:Character;

	public function new(x:Float,y:Float, charPos:StageCharPos, xml:Access) {
		this.charPos = charPos;
		this.char = charPos.extra.get(StageEditor.exID("char"));
		super(x,y, xml);

		color = 0xff7aa8ff;

		updateInfo(charPos);
	}

	public override function update(elapsed:Float) {
		editButton.selectable = ghostButton.selectable = deleteButton.selectable = selectable;
		editButton.shouldPress = ghostButton.shouldPress = deleteButton.shouldPress = shouldPress;

		hovered = !deleteButton.hovered;
		updatePos();
		super.update(elapsed);
	}

	public override function updateInfo(charPos:Dynamic) {
		if(charPos is StageCharPos) {
			var charPos:StageCharPos = cast charPos;
			this.charPos = charPos;
			char.visible = !isHidden;
		}
		super.updateInfo(charPos);
	}

	public override function getSprite():FunkinSprite {
		return char;
	}

	public override function onSelect() {

	}

	public override function onGhostClick() {
		isHidden = !isHidden;
		updateInfo(this.charPos);
	}

	public override function getName():String {
		return charPos.name;
	}

	public override function getPos():FlxPoint {
		return FlxPoint.get(charPos.x, charPos.y);
	}

	public override function updatePos() {
		super.updatePos();
	}
}
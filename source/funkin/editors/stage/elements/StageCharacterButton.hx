package funkin.editors.stage.elements;

import funkin.editors.stage.StageEditor.StageXMLEditScreen;
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

		hasAdvancedEdit = true;

		updateInfo();
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
	}

	public override function updateInfo() {
		char.visible = !isHidden;
		char.alpha = 0.5 * charPos.alpha;
		var charScale = (char.xml.has.scale ? Std.parseFloat(char.xml.att.scale).getDefault(1) : 1);
		charPos.scale.x = char.scale.x / charScale;
		charPos.scale.y = char.scale.y / charScale;
		charPos.x = char.x;
		charPos.y = char.y;
		char.scale.copyFrom(charPos.scale);
		super.updateInfo();
		char.scale.scale(charScale);
	}

	public override function getSprite():FunkinSprite {
		return char;
	}

	public override function onSelect() {
		StageEditor.instance.selectSprite(char);
	}

	/*public override function onSelect() {
		UIState.state.displayNotification(new UIBaseNotification("Selecting a character isnt implemented yet!", 2, BOTTOM_LEFT));
		CoolUtil.playMenuSFX(WARNING, 0.45);
	}*/

	public override function onEdit() {
		if(!FlxG.keys.pressed.SHIFT) {
			FlxG.state.openSubState(new StageCharacterEditScreen(this));
		} else {
			FlxG.state.openSubState(new StageXMLEditScreen(this.xml, updateInfo, "Character"));
		}
	}

	//public override function onEdit() {
	//	UIState.state.displayNotification(new UIBaseNotification("Editing a character isnt implemented yet!", 2, BOTTOM_LEFT));
	//	CoolUtil.playMenuSFX(WARNING, 0.45);
	//}

	public override function onVisiblityToggle() {
		isHidden = !isHidden;
		updateInfo();
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

class StageCharacterEditScreen extends UISoftcodedWindow {
	public var button:StageCharacterButton;
	public var char:Character;
	public var charPos:StageCharPos;

	public function new(button:StageCharacterButton) {
		this.button = button;
		this.char = button.char;
		this.charPos = button.charPos;
		super("layouts/stage/characterEditScreen", [
			"stage" => StageEditor.instance.stage,
			"char" => char,
			"charPos" => charPos,
			"button" => button,
			"xml" => button.xml,
			"exID" => StageEditor.exID,
			"getEx" => function(name:String):Dynamic {
				return char.extra.get(StageEditor.exID(name));
			},
			"setEx" => function(name:String, value:Dynamic) {
				char.extra.set(StageEditor.exID(name), value);
				charPos.extra.set(StageEditor.exID(name), value);
			},
		]);
	}

	public override function create() {
		super.create();
	}

	public override function saveData() {
		super.saveData();
		button.updateInfo();
	}
}
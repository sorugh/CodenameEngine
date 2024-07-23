package funkin.editors.character;

import funkin.game.Character;

class CharacterPropertiesWindow extends UISliceSprite {
	public var character:Character;

	public var positionXStepper:UINumericStepper;
	public var positionYStepper:UINumericStepper;
	public var scaleStepper:UINumericStepper;
	public var editCharacterButton:UIButton;
	public var flipXCheckbox:UICheckbox;

	public var cameraXStepper:UINumericStepper;
	public var cameraYStepper:UINumericStepper;
	public var antialiasingCheckbox:UICheckbox;
	public var testAsDropDown:UIDropDown;
	public var designedAsDropDown:UIDropDown;

	public function new(x:Float, y:Float, character:Character) @:privateAccess {
		super(x, y, 424+16, 204+20, "editors/ui/inputbox");

		function addLabelOn(ui:UISprite, text:String)
			members.push(new UIText(ui.x, ui.y - 24, 0, text));

		positionXStepper = new UINumericStepper(x+16, y+36, character.globalOffset.x, 0.001, 2, null, null, 104);
		positionXStepper.onChange = (text:String) -> {
			@:privateAccess positionXStepper.__onChange(text);
			this.changePosition(positionXStepper.value, null);
		};
		members.push(positionXStepper);
		addLabelOn(positionXStepper, "Position (X,Y)");

		members.push(new UIText(positionXStepper.x+104-32+0, positionXStepper.y + 9, 0, ",", 22));

		positionYStepper = new UINumericStepper(positionXStepper.x+104-32+26, positionXStepper.y, character.globalOffset.y, 0.001, 2, null, null, 104);
		positionYStepper.onChange = (text:String) -> {
			@:privateAccess positionYStepper.__onChange(text);
			this.changePosition(null, positionYStepper.value);
		};
		members.push(positionYStepper);

		scaleStepper = new UINumericStepper(positionYStepper.x+104-32+26, positionYStepper.y, character.scale.x, 0.001, 2, 0, null, 90);
		scaleStepper.onChange = (text:String) -> {
			@:privateAccess scaleStepper.__onChange(text);
			this.changeScale(scaleStepper.value);
		};
		members.push(scaleStepper);
		addLabelOn(scaleStepper, "Scale");

		editCharacterButton = new UIButton(scaleStepper.x + 90 -32 + 26, scaleStepper.y, "Edit Info", null);
		members.push(editCharacterButton);

		flipXCheckbox = new UICheckbox(scaleStepper.x+22, scaleStepper.y+32+14, "Flipped?", character.isPlayer ? !character.__baseFlipped : character.__baseFlipped);
		flipXCheckbox.onChecked = (checked:Bool) -> {this.changeFlipX(checked);};
		members.push(flipXCheckbox);

		cameraXStepper = new UINumericStepper(positionXStepper.x, positionXStepper.y+32+32+4, character.cameraOffset.x, 0.001, 2, null, null, 104);
		cameraXStepper.onChange = (text:String) -> {
			@:privateAccess cameraXStepper.__onChange(text);
			this.changeCamPosition(cameraXStepper.value, null);
		};
		members.push(cameraXStepper);
		addLabelOn(cameraXStepper, "Camera Position (X,Y)");

		members.push(new UIText(cameraXStepper.x + 104-32+0, cameraXStepper.y+9, 0, ",", 22));

		cameraYStepper = new UINumericStepper(cameraXStepper.x+104-32+26, cameraXStepper.y, character.cameraOffset.y, 0.001, 2, null, null, 104);
		cameraYStepper.onChange = (text:String) -> {
			@:privateAccess cameraYStepper.__onChange(text);
			this.changeCamPosition(null, cameraYStepper.value);
		};
		members.push(cameraYStepper);

		antialiasingCheckbox = new UICheckbox(scaleStepper.x+22, flipXCheckbox.y+32, "Antialiased?", character.antialiasing);
		antialiasingCheckbox.onChecked = (checked:Bool) -> {this.changeAntialiasing(checked);};
		members.push(antialiasingCheckbox);

		testAsDropDown = new UIDropDown(cameraXStepper.x, cameraXStepper.y+32+32+4, 193, 32, ["BOYFRIEND", "DAD"], character.playerOffsets ? 0 : 1);
		testAsDropDown.onChange = (index:Int) -> {
			CharacterEditor.instance.changeStagePosition(testAsDropDown.options[index]);
		};
		members.push(testAsDropDown);
		addLabelOn(testAsDropDown, "Test Character As...");
		testAsDropDown.bWidth = 193; //REFUSES TO FUCKING SET TO 170 PIECE OF SHIT!!

		designedAsDropDown = new UIDropDown(testAsDropDown.x+193+22, testAsDropDown.y, 193, 32, ["BOYFRIEND", "DAD"], character.playerOffsets ? 0 : 1);
		designedAsDropDown.onChange = (index:Int) -> {
			CharacterEditor.instance.changeCharacterDesginedAs(designedAsDropDown.options[index] == "BOYFRIEND");
		};
		members.push(designedAsDropDown);
		addLabelOn(designedAsDropDown, "Char Desgined As...");
		designedAsDropDown.bWidth = 193;

		alpha = 0.7;

		this.character = character;
	}

	public function changePosition(newPosX:Null<Float>, newPosY:Null<Float>) {
		if (newPosX != null && newPosY != null && newPosX == character.globalOffset.x && newPosY == character.globalOffset.y)
			return;
		else {
			if (newPosX != null && newPosX == character.globalOffset.x) return;
			if (newPosY != null && newPosY == character.globalOffset.y) return;
		}

		if (newPosX != null) character.globalOffset.x = newPosX;
		if (newPosY != null) character.globalOffset.y = newPosY;

		CharacterEditor.instance.playAnimation(character.getAnimName());
	}

	public function changeScale(newScale:Float) {
		if (character.scale.x == newScale) return;

		character.scale.set(newScale, newScale);
		character.updateHitbox();

		CharacterEditor.instance.playAnimation(character.getAnimName());
	}

	public function changeFlipX(newFlipX:Bool) @:privateAccess {
		character.flipX = character.isPlayer ? !newFlipX : newFlipX;
		character.__baseFlipped = character.flipX;

		CharacterEditor.instance.playAnimation(character.getAnimName());
	}

	public function changeCamPosition(newPosX:Null<Float>, newPosY:Null<Float>) {
		if (newPosX != null && newPosY != null && newPosX == character.cameraOffset.x && newPosY == character.cameraOffset.y)
			return;
		else {
			if (newPosX != null && newPosX == character.cameraOffset.x) return;
			if (newPosY != null && newPosY == character.cameraOffset.y) return;
		}

		if (newPosX != null) character.cameraOffset.x = newPosX;
		if (newPosY != null) character.cameraOffset.y = newPosY;
	}

	public function changeAntialiasing(newAntialiasing:Bool) {
		if (character.antialiasing == newAntialiasing) return;
		character.antialiasing = newAntialiasing;
	}
}
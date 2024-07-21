package funkin.editors.character;

import funkin.game.Character;

class CharacterPropertiesWindow extends UISliceSprite {
	public var character:Character;

	public var positionXStepper:UINumericStepper;
	public var positionYStepper:UINumericStepper;
	public var scaleStepper:UINumericStepper;
	public var flipXCheckbox:UICheckbox;

	public var cameraXStepper:UINumericStepper;
	public var cameraYStepper:UINumericStepper;
	public var antialiasingCheckbox:UICheckbox;
	public var testAsDropDown:UIDropDown;
	public var designedAsDropDown:UIDropDown;
	
	public function new(x:Float, y:Float, character:Character) @:privateAccess {
		super(x, y, Std.int(500-16), 204+20, "editors/ui/inputbox");

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

		scaleStepper = new UINumericStepper(positionYStepper.x+104-32+32, positionYStepper.y, character.scale.x, 0.001, 2, 0, null, 104);
		scaleStepper.onChange = (text:String) -> {
			@:privateAccess scaleStepper.__onChange(text);
			this.changeScale(scaleStepper.value);
		};
		members.push(scaleStepper);
		addLabelOn(scaleStepper, "Scale");

		flipXCheckbox = new UICheckbox(scaleStepper.x+104-32+24, scaleStepper.y, "Flipped?", character.isPlayer ? !character.__baseFlipped : character.__baseFlipped);
		flipXCheckbox.onChecked = (checked:Bool) -> {this.changeFlipX(checked);};
		members.push(flipXCheckbox);
		addLabelOn(flipXCheckbox, "Flipped X");

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

		antialiasingCheckbox = new UICheckbox(cameraYStepper.x+104-32+32+24, cameraYStepper.y, "Antialiased?", character.antialiasing);
		antialiasingCheckbox.onChecked = (checked:Bool) -> {this.changeAntialiasing(checked);};
		members.push(antialiasingCheckbox);
		addLabelOn(antialiasingCheckbox, "Antialiasing");

		testAsDropDown = new UIDropDown(cameraXStepper.x, cameraXStepper.y+32+32+4, 238, 32, ["BOYFRIEND", "DAD"], character.playerOffsets ? 0 : 1);
		testAsDropDown.onChange = (index:Int) -> {
			CharacterEditor.instance.changeStagePosition(testAsDropDown.options[index]);
		};
		members.push(testAsDropDown);
		addLabelOn(testAsDropDown, "Test Character As...");

		designedAsDropDown = new UIDropDown(testAsDropDown.x+238, testAsDropDown.y, 238, 32, ["BOYFRIEND", "DAD"], character.playerOffsets ? 0 : 1);
		designedAsDropDown.onChange = (index:Int) -> {
			CharacterEditor.instance.changeCharacterDesginedAs(designedAsDropDown.options[index] == "BOYFRIEND");
		};
		members.push(designedAsDropDown);
		addLabelOn(designedAsDropDown, "Char Desgined As...");

		antialiasingCheckbox.x+=14;
		for (checkbox in [flipXCheckbox, antialiasingCheckbox])
			{checkbox.y += 3; checkbox.x += 12;}

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
		if (character.isPlayer ? !character.__baseFlipped : character.__baseFlipped == newFlipX) return;

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
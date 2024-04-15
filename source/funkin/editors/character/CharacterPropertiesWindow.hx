package funkin.editors.character;

import funkin.game.Character;

class CharacterPropertiesWindow extends UISliceSprite {
	public var positionXStepper:UINumericStepper;
	public var positionYStepper:UINumericStepper;
	public var scaleStepper:UINumericStepper;
	public var flipXCheckbox:UICheckbox;

	public var cameraXStepper:UINumericStepper;
	public var cameraYStepper:UINumericStepper;
	public var antialiasingCheckbox:UICheckbox;
	public var testAsDropDown:UIDropDown;
	public var designedAsDropDown:UIDropDown;
	
	public function new(x:Float, y:Float, character:Character) {
		super(x, y, Std.int(500-32), 204+20, "editors/ui/inputbox");

		function addLabelOn(ui:UISprite, text:String)
			members.push(new UIText(ui.x, ui.y - 24, 0, text));

		positionXStepper = new UINumericStepper(x+16, y + 36, character.globalOffset.x, 0.001, 2, null, null, 100);
		members.push(positionXStepper);
		addLabelOn(positionXStepper, "Position (X,Y)");

		members.push(new UIText(positionXStepper.x + 100 - 32 + 0, positionXStepper.y + 9, 0, ",", 22));

		positionYStepper = new UINumericStepper(positionXStepper.x + 100 - 32 + 26, positionXStepper.y, character.globalOffset.y, 0.001, 2, null, null, 100);
		members.push(positionYStepper);

		scaleStepper = new UINumericStepper(positionYStepper.x + 100 - 32 + 32, positionYStepper.y, character.scale.x, 0.001, 2, null, null, 100);
		members.push(scaleStepper);
		addLabelOn(scaleStepper, "Scale");

		flipXCheckbox = new UICheckbox(scaleStepper.x + 100 - 32 + 24, scaleStepper.y, "Flipped?", character.flipX);
		members.push(flipXCheckbox);
		addLabelOn(flipXCheckbox, "Flipped X");

		cameraXStepper = new UINumericStepper(positionXStepper.x, positionXStepper.y+32+32+4, character.cameraOffset.x, 0.001, 2, null, null, 100);
		members.push(cameraXStepper);
		addLabelOn(cameraXStepper, "Camera Position (X,Y)");

		members.push(new UIText(cameraXStepper.x + 100 - 32 + 0, cameraXStepper.y + 9, 0, ",", 22));

		cameraYStepper = new UINumericStepper(cameraXStepper.x + 100 - 32 + 26, cameraXStepper.y, character.cameraOffset.y, 0.001, 2, null, null, 100);
		members.push(cameraYStepper);

		antialiasingCheckbox = new UICheckbox(cameraYStepper.x+100-32+32+32, cameraYStepper.y, "Antialiased?", character.antialiasing);
		members.push(antialiasingCheckbox);
		addLabelOn(antialiasingCheckbox, "Antialiasing");

		testAsDropDown = new UIDropDown(cameraXStepper.x, cameraXStepper.y+32+32+4, 226+8, 32, ["PLAYER", "OPPONENT"], 0);
		members.push(testAsDropDown);
		addLabelOn(testAsDropDown, "Test Character As...");

		designedAsDropDown = new UIDropDown(testAsDropDown.x+226+8, testAsDropDown.y, 226+8, 32, ["PLAYER", "OPPONENT"], 0);
		members.push(designedAsDropDown);
		addLabelOn(designedAsDropDown, "Char Desgined As...");

		antialiasingCheckbox.x+=14;
		for (checkbox in [flipXCheckbox, antialiasingCheckbox])
			{checkbox.y += 3; checkbox.x += 12;}
	}
}
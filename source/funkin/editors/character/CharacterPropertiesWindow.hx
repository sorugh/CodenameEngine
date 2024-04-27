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
		super(x, y, Std.int(500-16), 204+20, "editors/ui/inputbox");

		function addLabelOn(ui:UISprite, text:String)
			members.push(new UIText(ui.x, ui.y - 24, 0, text));

		positionXStepper = new UINumericStepper(x+16, y+36, character.globalOffset.x, 0.001, 2, null, null, 104);
		members.push(positionXStepper);
		addLabelOn(positionXStepper, "Position (X,Y)");

		members.push(new UIText(positionXStepper.x+104-32+0, positionXStepper.y + 9, 0, ",", 22));

		positionYStepper = new UINumericStepper(positionXStepper.x+104-32+26, positionXStepper.y, character.globalOffset.y, 0.001, 2, null, null, 104);
		members.push(positionYStepper);

		scaleStepper = new UINumericStepper(positionYStepper.x+104-32+32, positionYStepper.y, character.scale.x, 0.001, 2, null, null, 104);
		members.push(scaleStepper);
		addLabelOn(scaleStepper, "Scale");

		flipXCheckbox = new UICheckbox(scaleStepper.x+104-32+24, scaleStepper.y, "Flipped?", character.flipX);
		members.push(flipXCheckbox);
		addLabelOn(flipXCheckbox, "Flipped X");

		cameraXStepper = new UINumericStepper(positionXStepper.x, positionXStepper.y+32+32+4, character.cameraOffset.x, 0.001, 2, null, null, 104);
		members.push(cameraXStepper);
		addLabelOn(cameraXStepper, "Camera Position (X,Y)");

		members.push(new UIText(cameraXStepper.x + 104-32+0, cameraXStepper.y+9, 0, ",", 22));

		cameraYStepper = new UINumericStepper(cameraXStepper.x+104-32+26, cameraXStepper.y, character.cameraOffset.y, 0.001, 2, null, null, 104);
		members.push(cameraYStepper);

		antialiasingCheckbox = new UICheckbox(cameraYStepper.x+104-32+32+24, cameraYStepper.y, "Antialiased?", character.antialiasing);
		members.push(antialiasingCheckbox);
		addLabelOn(antialiasingCheckbox, "Antialiasing");

		testAsDropDown = new UIDropDown(cameraXStepper.x, cameraXStepper.y+32+32+4, 238, 32, ["PLAYER", "OPPONENT"], 0);
		members.push(testAsDropDown);
		addLabelOn(testAsDropDown, "Test Character As...");

		designedAsDropDown = new UIDropDown(testAsDropDown.x+238, testAsDropDown.y, 238, 32, ["PLAYER", "OPPONENT"], 0);
		members.push(designedAsDropDown);
		addLabelOn(designedAsDropDown, "Char Desgined As...");

		antialiasingCheckbox.x+=14;
		for (checkbox in [flipXCheckbox, antialiasingCheckbox])
			{checkbox.y += 3; checkbox.x += 12;}
	}
}
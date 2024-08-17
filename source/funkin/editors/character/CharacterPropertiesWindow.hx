
package funkin.editors.character;

import flixel.util.FlxColor;

class CharacterPropertiesWindow extends UIWindow {
	public var newButton:UIButton;
	public var editButton:UIButton;

	public var characterInfo:UIText;

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("characterEditor.characterPropertiesWindow." + id, args);

	public function new() {
		super(800-23,23 + 23, 450 + 23, 140, translate("name"));

		newButton = new UIButton( x +(450 + 23)- 25 - 3 - 200, y + 12 + 31, translate("newCharacter"), null, 200);
		members.push(newButton);
		newButton.color = FlxColor.GREEN;

		editButton = new UIButton(newButton.x, newButton.y + 12 + 30 + 4, translate("editCharacter"), function () {
			CharacterEditor.instance.editInfoWithUI();
		}, 200);
		members.push(editButton);

		characterInfo = new UIText(x + 450 + 20 - 42 - 400, y + 36 + 10, 400, "");
		characterInfo.alignment = LEFT;
		members.push(characterInfo);
	}
}
package funkin.editors.character;

import funkin.game.Character;
import funkin.options.OptionsScreen;
import funkin.options.type.IconOption;
import funkin.options.type.NewOption;
import funkin.options.type.TextOption;
import funkin.options.type.OptionType;

class CharacterSelection extends EditorTreeMenu
{
	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("characterSelection." + id, args);

	public override function create()
	{
		bgType = "charter";
		super.create();

		var isMods:Bool = true;
		var modsList:Array<String> = Character.getList(true, true);

		if(modsList.length == 0) {
			modsList = Character.getList(false, true);
			isMods = false;
		}

		function generateList(modsList:Array<String>, isMods:Bool, folderPath:String = ""):Array<OptionType> {
			var list:Array<OptionType> = [];

			for(char in modsList) {
				if(char.endsWith("/")) {
					var folderName = CoolUtil.getFilename(char.substr(0, char.length-1));

					list.push(new TextOption(folderName + " >", translate("acceptFolder"), function() {
						var newModsList = Character.getList(isMods, true, char);
						var newList:Array<OptionType> = generateList(newModsList, isMods, folderPath + folderName + "/");
						optionsTree.add(new OptionsScreen(folderPath + folderName, translate("desc-folder", [folderPath + folderName + "/"]), newList));
					}));
				} else {
					list.push(new IconOption(char, translate("acceptCharacter"), Character.getIconFromCharName(folderPath + char, char),
						function() {
							FlxG.switchState(new CharacterEditor(folderPath + char));
						})
					);
				}
			}

			var newChar = translate("newCharacter");
			list.insert(0, new NewOption(newChar, newChar, function() {
				openSubState(new UIWarningSubstate(translate("warnings.notImplemented-title"), translate("warnings.notImplemented-body"), [
					{label: TU.translate("editor.ok"), color: 0xFFFF0000, onClick: function(t) {}}
				]));
			}));

			return list;
		}

		var list = generateList(modsList, isMods);

		main = new OptionsScreen(TU.translate("characterEditor.name"), translate("desc"), list);

		DiscordUtil.call("onEditorTreeLoaded", ["Character Editor"]);
	}

	override function createPost() {
		super.createPost();

		main.changeSelection(1);
	}
}
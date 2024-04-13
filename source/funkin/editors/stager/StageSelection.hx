package funkin.editors.stager;

import funkin.options.OptionsScreen;
import funkin.game.Stage;
import funkin.options.type.IconOption;
import funkin.options.type.NewOption;
import funkin.options.type.OptionType;
import funkin.options.type.TextOption;

class StageSelection extends EditorTreeMenu
{
	public override function create()
	{
		bgType = "charter";
		super.create();

		var modsList:Array<String> = Stage.getList(true, true);

		var list:Array<OptionType> = [
			for (char in (modsList.length == 0 ? Stage.getList(false, true) : modsList))
				new TextOption(char, "Press ACCEPT to edit this stage.",
			 	function() {
					FlxG.switchState(new StageEditor(char));
				})
		];

		list.insert(0, new NewOption("New Stage", "New Stage", function() {
			openSubState(new UIWarningSubstate("New Stage: Feature Not Implemented!", "This feature isnt implemented yet. Please wait for more cne updates to have this functional.\n\n\n- Codename Devs", [
				{label: "Ok", color: 0xFFFF0000, onClick: function(t) {}}
			]));
		}));

		main = new OptionsScreen("Stage Editor", "Select a stage to edit. HSCRIPT only stages are not supported.", list);

		DiscordUtil.call("onEditorTreeLoaded", ["Stage Editor"]);
	}

	override function createPost() {
		super.createPost();

		main.changeSelection(1);
	}
}
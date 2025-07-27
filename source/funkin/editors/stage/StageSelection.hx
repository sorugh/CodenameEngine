package funkin.editors.stage;

import funkin.editors.stage.StageCreationScreen.StageCreationData;
import funkin.game.Stage;
import funkin.options.OptionsScreen;
import funkin.options.type.NewOption;
import funkin.options.type.OptionType;
import funkin.options.type.TextOption;

class StageSelection extends EditorTreeMenu
{
	public var stages:Array<String> = [];

	public override function create()
	{
		bgType = "charter";
		super.create();

		var modsList:Array<String> = Stage.getList(true, true);

		var list:Array<OptionType> = [
			for (stage in (modsList.length == 0 ? Stage.getList(false, true) : modsList)) {
				stages.push(stage);
				new TextOption(stage, TU.translate("stageSelection.acceptStage"),
			 	function() {
					FlxG.switchState(new StageEditor(stage));
				});
			}
		];

		list.insert(0, new NewOption(TU.translate("stageSelection.newStage"), TU.translate("stageSelection.acceptNewStage"), function() {
			FlxG.state.openSubState(new StageCreationScreen(saveStage));
		}));

		main = new OptionsScreen(TU.translate("editor.stage.name"), TU.translate("stageSelection.desc"), list);

		DiscordUtil.call("onEditorTreeLoaded", ["Stage Editor"]);
	}

	public function saveStage(creation:StageCreationData) {
		if ([for (s in stages) s.toLowerCase()].contains(creation.name.toLowerCase())) {
			openSubState(new UIWarningSubstate("Creating Stage: Error!", "The stage you are trying to create alreadly exists, if you would like to override it delete the stage first!", [
				{label: "Ok", color: 0xFFFF0000, onClick: function(t) {}}
			]));
			return;
		}

		#if sys
		// Save File
		CoolUtil.safeSaveFile('${Paths.getAssetsRoot()}/data/stages/${creation.name}.xml', '<!DOCTYPE codename-engine-stage>\n<stage folder="${creation.path}">\n</stage>');
		#end

		// Add to List
		var option = new TextOption(creation.name, TU.translate("stageSelection.acceptStage"), function() {
			FlxG.switchState(new StageEditor(creation.name));
		});
		optionsTree.members[optionsTree.members.length-1].insert(1, option);
	}

	override function createPost() {
		super.createPost();

		main.changeSelection(1);
	}
}
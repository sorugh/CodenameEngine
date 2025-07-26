package funkin.options;

import funkin.options.categories.*;
import funkin.options.type.*;

typedef OptionCategory = {
	var name:String;
	var desc:String;
	var ?state:OneOfThree<OptionsScreen, Class<OptionsScreen>, (name:String, desc:String) -> OptionsScreen>;
	var ?substate:OneOfThree<MusicBeatSubstate, Class<MusicBeatSubstate>, (name:String, desc:String) -> MusicBeatSubstate>;
	var ?suffix:String;
}

class OptionsMenu extends TreeMenu {
	public static var mainOptions:Array<OptionCategory> = [
		{  // name and desc are actually the translations ids!  - Nex
			name: 'optionsTree.controls-name',
			desc: 'optionsTree.controls-desc',
			suffix: '';
			substate: funkin.options.keybinds.KeybindsOptions;
		},
		{
			name: 'optionsTree.gameplay-name',
			desc: 'optionsTree.gameplay-desc',
			state: GameplayOptions
		},
		{
			name: 'optionsTree.appearance-name',
			desc: 'optionsTree.appearance-desc',
			state: AppearanceOptions
		},
		#if TRANSLATIONS_SUPPORT
		{
			name: 'optionsTree.language-name',
			desc: 'optionsTree.language-desc',
			state: LanguageOptions
		},
		#end
		{
			name: 'optionsTree.miscellaneous-name',
			desc: 'optionsTree.miscellaneous-desc',
			state: MiscOptions
		}
	];

	var bg:FunkinSprite;

	override function create() {
		super.create();

		CoolUtil.playMenuSong();

		DiscordUtil.call("onMenuLoaded", ["Options Menu"]);

		add(bg = new FunkinSprite().loadAnimatedGraphic(Paths.image('menus/menuBGBlue')));
		bg.antialiasing = true;
		bg.scrollFactor.set();
		updateBG();

		/*tree = [
			for (o in mainOptions) {

			}
		];*/

	}

	public function updateBG() {
		var scaleX:Float = FlxG.width / bg.width;
		var scaleY:Float = FlxG.height / bg.height;
		bg.scale.x = bg.scale.y = Math.max(scaleX, scaleY);
		bg.screenCenter();
	}

	override function onResize(width:Int, height:Int) {
		super.onResize(width, height);
		if (!UIState.resolutionAware) return;

		updateBG();
	}

	override function exit() {
		Options.save();
		Options.applySettings();
		super.exit();
	}
}
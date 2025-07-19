package funkin.editors;

class ModConfigWarning extends UIState {

	var libraryToMakeConfigIn:Dynamic = null;
	public static var defaultModConfigText = 
'[Common]
MOD_NAME="YOUR MOD NAME HERE"
MOD_DESCRIPTION="YOUR MOD DESCRIPTION HERE"

# DO NOT EDIT!! this is used to check for version compatibility!
MOD_API_VERSION=1

MOD_DOWNLOADED_LINK="YOUR MOD PAGE LINK HERE"

# Not supported yet
;MOD_ICON64="path/to/icon64.png"
;MOD_ICON32="path/to/icon32.png"
;MOD_ICON16="path/to/icon16.png"
;MOD_ICON="path/to/icon.ico"

[Flags]
DISABLE_BETA_WARNING_SCREEN=true

[Discord]
MOD_DISCORD_CLIENT_ID=""
MOD_DISCORD_LOGO_KEY=""';

	public function new(library) {
		super();

		libraryToMakeConfigIn = library;
	}

	override function create() {
		super.create();

		openSubState(new UIWarningSubstate("Missing mod config!", "Your mod is currently missing a mod config file!\n\n\nWould you like to automatically generate one?\n\n(PS: If this is not your mod please disable Developer mode to stop this popup from appearing.)",
		[
			{
				label: "Not Now",
				color: 0x969533,
				onClick: function (_) {
					funkin.menus.MainMenuState.hadPopup = true;
					MusicBeatState.skipTransIn = false;
					MusicBeatState.skipTransOut = false;
					FlxG.switchState(new funkin.menus.MainMenuState());
				}
			},
			{
				label: "Yes",
				onClick: function(_) {
					trace(libraryToMakeConfigIn.getPath("data/config/modpack.ini"));
					sys.io.File.saveContent(libraryToMakeConfigIn.getPath("data/config/modpack.ini"), defaultModConfigText);
					openSubState(new UIWarningSubstate("Created mod config!", "Your mod config file has been created at " + libraryToMakeConfigIn.getPath("data/config/modpack.ini") + "!", [
						{
							label: "Ok",
							onClick: function (_) {
								funkin.menus.MainMenuState.hadPopup = true;
								MusicBeatState.skipTransIn = false;
								MusicBeatState.skipTransOut = false;
								FlxG.switchState(new funkin.menus.MainMenuState());
							}
						},
					], false));
				}
			}
		], false));
	}

	override function update(elapsed) {
		super.update(elapsed);
	}
}
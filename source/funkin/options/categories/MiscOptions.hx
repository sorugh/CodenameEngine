package funkin.options.categories;


class MiscOptions extends OptionsScreen {
	public override function new() {
		super("Miscellaneous", "Use this menu to reset save data or engine settings.");

		{ // Language Option
			var lanArray:Array<String> = TranslationUtil.foundLanguages;

			// TODO: add credits based on the config file
			add(new ArrayOption(
				"Language",
				'The language that the engine currently uses (the default one is ${TranslationUtil.DEFAULT_LANGUAGE}).',
				[for(lan in lanArray) lan.split("/").first()],
				[for(lan in lanArray) lan.split("/").last()], "language",
				function(path:String) {
					TranslationUtil.setLanguage(path);
					parent.remove(this);
					// Reload the current screen
					// todo add parent.reload();
					this.clear();
					parent.add(new MiscOptions());
			}));
		}

		add(new TextOption(
			"Force Crash",
			"Select this option to force a crash.",
			() -> { throw new haxe.Exception("Forced crash."); }
		));
		#if UPDATE_CHECKING
		add(new Checkbox(
			"Enable Nightly Updates",
			"If checked, will also include nightly builds in the update checking.",
			"betaUpdates"));,
		add(new TextOption(
			"Check for Updates",
			"Select this option to check for new engine updates.",
			function() {
				var report = funkin.backend.system.updating.UpdateUtil.checkForUpdates();
				if (report.newUpdate) {
					FlxG.switchState(new funkin.backend.system.updating.UpdateAvailableScreen(report));
				} else {
					CoolUtil.playMenuSFX(CANCEL);
					updateDescText("No update found.");
				}
		}));,
		#end
		add(new TextOption(
			"Reset Save Data",
			"Select this option to reset save data. This will remove all of your highscores.",
			function() {
				// TODO: SAVE DATA RESETTING
		}));
	}
}

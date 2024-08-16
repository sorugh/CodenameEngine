package funkin.options.categories;


class MiscOptions extends OptionsScreen {
	public override function new(title:String, desc:String) {
		super(title, desc, "MiscOptions");

		{ // Language Option
			var lanArray:Array<String> = TranslationUtil.foundLanguages;

			// TODO: add credits based on the config file
			add(new ArrayOption(
				getName("language"),
				getDesc("language", [TranslationUtil.DEFAULT_LANGUAGE]),
				[for(lan in lanArray) lan.split("/").first()],
				[for(lan in lanArray) lan.split("/").last()],
				"language",
				function(path:String) {
					TranslationUtil.setLanguage(path);
					parent.remove(this);
					// Reload the current screen
					// todo add parent.reload();
					this.clear();
					parent.add(new MiscOptions(title, desc));
			}));
		}

		add(new TextOption(
			getName("forceCrash"),
			getDesc("forceCrash"),
			() -> { throw new haxe.Exception("Forced crash."); }
		));
		#if UPDATE_CHECKING
		add(new Checkbox(
			getName("betaUpdates"),
			getDesc("betaUpdates"),
			"betaUpdates"));
		add(new TextOption(
			getName("checkForUpdates"),
			getDesc("checkForUpdates"),
			function() {
				var report = funkin.backend.system.updating.UpdateUtil.checkForUpdates();
				if (report.newUpdate) {
					FlxG.switchState(new funkin.backend.system.updating.UpdateAvailableScreen(report));
				} else {
					CoolUtil.playMenuSFX(CANCEL);
					updateDescText(TU.translate(prefix + "checkForUpdates-noUpdateFound"));
				}
		}));
		#end
		add(new TextOption(
			getName("resetSaveData"),
			getDesc("resetSaveData"),
			function() {
				// TODO: SAVE DATA RESETTING
		}));
	}
}

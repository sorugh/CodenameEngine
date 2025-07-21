package funkin.options.categories;

class MiscOptions extends OptionsScreen {
	public override function new(title:String, desc:String) {
		super(title, desc, "MiscOptions.");
		add(new Checkbox(
			getName("devMode"),
			getDesc("devMode"),
			"devMode"));
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

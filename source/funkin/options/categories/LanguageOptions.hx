package funkin.options.categories;

class LanguageBox extends Checkbox {
	public var langID:String;

	public function new(name:String, langID:String) {
		this.langID = langID;
		super(name, "LanguageOptions.language-desc", null, null);
	}

	override function reloadStrings() {
		super.reloadStrings();
	}

	override function set_rawDesc(v:String) {
		rawDesc = v;
		var config = TU.getConfig(langID);
		this.desc = TU.exists(rawDesc) ? TU.translate(
			rawDesc, [config["credits"], config["version"]]
		) : rawDesc;
		return v;
	}

	override function update(elapsed:Float) {
		var lastChecked = checked;
		checked = langID == TU.curLanguage;
		if(lastChecked != checked)
			checkbox.animation.play("checking", true, !checked);
		super.update(elapsed);
	}

	override function onSelect() {
		checked = !checked;
		if(checked) {
			TranslationUtil.setLanguage(langID);
			if(FlxG.state is OptionsMenu) {
				var menu:OptionsMenu = cast FlxG.state;
				menu.reloadStrings();
				trace("Reloading strings");
			}
		}
		checkbox.animation.play("checking", true, !checked);
	}
}

class LanguageOptions extends OptionsScreen {
	public override function new(title:String, desc:String) {
		super(title, desc, "LanguageOptions.");

		var langArray:Array<String> = TranslationUtil.foundLanguages;

		for(lang in langArray) {
			var split = lang.split("/");
			var langId = split.first();
			var langName = split.last();
			var checkbox = new LanguageBox(langName, langId);
			add(checkbox);
		}
	}
}

package funkin.options.categories;

class LanguageRadio extends RadioButton {
	public var langID:String;

	public function new(name:String, langID:String) {
		this.langID = langID;
		super(name, "LanguageOptions.language-desc", null, langID, null, "languageSelector");

		checked = langID == TU.curLanguage;
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

	override dynamic function onSet(value:Dynamic) {
		TranslationUtil.setLanguage(value);
		if(FlxG.state is OptionsMenu) {
			var menu:OptionsMenu = cast FlxG.state;
			menu.reloadStrings();
			trace("Reloading strings");
		}
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
			var radio = new LanguageRadio(langName, langId);
			add(radio);
		}
	}
}

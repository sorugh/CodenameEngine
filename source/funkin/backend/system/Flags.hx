package funkin.backend.system;

import lime.utils.AssetLibrary;
import lime.utils.AssetType;

import funkin.backend.assets.IModsAssetLibrary;
import funkin.backend.assets.ScriptedAssetLibrary;

/**
 * A class that reads the `flags.ini` file, allowing to read settable Flags (customs too).
 */
@:build(funkin.backend.system.macros.FlagMacro.build())
class Flags {
	public static var SONGS_LIST_MOD_MODE:Allow<"prepend", "override", "append"> = "override";
	public static var WEEKS_LIST_MOD_MODE:Allow<"prepend", "override", "append"> = "override";

	// Translations system //
	public static var DEFAULT_LANGUAGE:String = "en";
	public static var DEFAULT_LANGUAGE_NAME:String = "English";
	/**
	 * **NOTICE:** This will only contain the id of the language, not the full name.
	 * If you blacklist the default language, you will need to change DEFAULT_LANGUAGE and DEFAULT_LANGUAGE_NAME.
	 */
	public static var BLACKLISTED_LANGUAGES:Array<String> = [];
	/**
	 * **NOTICE:** This will only contain the id of the language, not the full name.
	 * If this list is not empty, the languages listed will be the only ones able to be used.
	 */
	public static var WHITELISTED_LANGUAGES:Array<String> = [];

	// Internal stuff

	@:bypass public static var customFlags:Map<String, String> = [];

	public static function load() {
		var flags:Map<String, String> = [];

		final flagsPath = Paths.getPath("flags.ini");

		for(lib in Paths.assetsTree.libraries) {
			#if TRANSLATIONS_SUPPORT
			// skip translations since it would be useless, if you wanna modify it set the flags inside of global.hx
			if(lib is funkin.backend.assets.TranslatedAssetLibrary) continue;
			#end

			if(lib.exists(flagsPath, AssetType.TEXT)) {
				var data:String = lib.getAsset(flagsPath, AssetType.TEXT);
				var trimmed:String;
				var splitContent = [for(e in data.split("\n")) if ((trimmed = e.trim()) != "") trimmed];

				for(line in splitContent) {
					if(line.startsWith(";")) continue;
					if(line.startsWith("#")) continue;
					if(line.startsWith("//")) continue;
					if(line.length == 0) continue;
					if(line.charAt(0) == "[" && line.charAt(line.length-1) == "]") continue;

					var index = line.indexOf("=");
					if(index == -1) continue;
					var name = line.substr(0, index).trim();
					var value = line.substr(index+1).trim();

					var wasQuoted = value.length > 1 && value.charCodeAt(0) == '"'.code && value.charCodeAt(value.length-1) == '"'.code;
					if(wasQuoted) value = value.substr(1, value.length - 2);
					if((!wasQuoted && value.length == 0) || name.length == 0)
						continue;

					if(!flags.exists(name))
						flags[name] = value;
				}
			}
		}

		customFlags = [];
		reset();
		for(name=>value in flags)
			if(!parse(name, value)) {
				customFlags.set(name, value);
			}
	}
}